#import "EmulatorBridge.h"
#include "libretro.h"
#include "ARCore.h"
#include <map>
#include <string>
#include <vector>
#include <cstdarg>

/* All core calls occur on one emulation queue. The libretro core is a singleton. */
static EmulatorBridge *active;
static std::string systemPath, savePath, contentPath;
static std::map<std::string, std::string> variables;
static std::map<uint64_t, int16_t> inputs;
static NSMutableArray<NSDictionary *> *descriptors;
static NSData *framePixels;
static unsigned frameWidth, frameHeight, pixelFormat = RETRO_PIXEL_FORMAT_0RGB1555;
static NSString *message = @"";
static BOOL loaded, initialized;
static uint64_t key(unsigned p, unsigned d, unsigned i, unsigned id) {
    return ((uint64_t)p << 48) | ((uint64_t)(d & RETRO_DEVICE_MASK) << 32) | ((uint64_t)i << 16) | id;
}
static void logger(enum retro_log_level level, const char *format, ...) {
    char buffer[4096]; va_list args; va_start(args, format);
    vsnprintf(buffer, sizeof(buffer), format, args); va_end(args);
    NSLog(@"MAME: %s", buffer);
    if (level >= RETRO_LOG_WARN) message = [NSString stringWithUTF8String:buffer] ?: @"MAME error";
}
static bool environment(unsigned command, void *data) {
    switch (command) {
        case RETRO_ENVIRONMENT_GET_LOG_INTERFACE:
            ((retro_log_callback *)data)->log = logger; return true;
        case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY: *(const char **)data = systemPath.c_str(); return true;
        case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY: *(const char **)data = savePath.c_str(); return true;
        case RETRO_ENVIRONMENT_GET_CONTENT_DIRECTORY: *(const char **)data = contentPath.c_str(); return true;
        case RETRO_ENVIRONMENT_GET_CAN_DUPE: *(bool *)data = true; return true;
        case RETRO_ENVIRONMENT_GET_LANGUAGE: *(unsigned *)data = RETRO_LANGUAGE_ENGLISH; return true;
        case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT: {
            unsigned fmt = *(unsigned *)data;
            if (fmt > RETRO_PIXEL_FORMAT_RGB565) return false;
            pixelFormat = fmt; return true;
        }
        case RETRO_ENVIRONMENT_SET_ROTATION:
            return false; /* Core performs its native output rotation. Hardware objects use profile rotation. */
        case RETRO_ENVIRONMENT_GET_CORE_OPTIONS_VERSION: *(unsigned *)data = 0; return true;
        case RETRO_ENVIRONMENT_SET_VARIABLES: {
            auto variable = (retro_variable *)data;
            for (; variable && variable->key; variable++) {
                std::string value = variable->value ?: "";
                auto start = value.find(';');
                if (start != std::string::npos) {
                    start = value.find_first_not_of(' ', start + 1);
                    value = start == std::string::npos ? "" : value.substr(start);
                }
                value = value.substr(0, value.find('|'));
                std::string name(variable->key);
                if (name.find("input_interface") != std::string::npos) value = "retropad";
                if (name.find("frameskip") != std::string::npos) value = "disabled";
                variables[name] = value;
            }
            return true;
        }
        case RETRO_ENVIRONMENT_GET_VARIABLE: {
            auto variable = (retro_variable *)data;
            auto found = variables.find(variable->key);
            variable->value = found == variables.end() ? nullptr : found->second.c_str();
            return found != variables.end();
        }
        case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE: *(bool *)data = false; return true;
        case RETRO_ENVIRONMENT_SET_INPUT_DESCRIPTORS: {
            [descriptors removeAllObjects];
            auto item = (retro_input_descriptor *)data;
            for (; item && item->description; item++) {
                [descriptors addObject:@{@"port": @(item->port), @"device": @(item->device),
                    @"index": @(item->index), @"id": @(item->id),
                    @"label": [NSString stringWithUTF8String:item->description] ?: @"Input"}];
            }
            return true;
        }
        case RETRO_ENVIRONMENT_SET_MESSAGE: {
            auto item = (retro_message *)data;
            message = [NSString stringWithUTF8String:item->msg] ?: @""; return true;
        }
        case RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME:
        case RETRO_ENVIRONMENT_SET_PERFORMANCE_LEVEL:
        case RETRO_ENVIRONMENT_SET_CONTROLLER_INFO:
        case RETRO_ENVIRONMENT_SET_GEOMETRY: return true;
        default: return false;
    }
}
static void video(const void *data, unsigned width, unsigned height, size_t pitch) {
    if (!data || data == RETRO_HW_FRAME_BUFFER_VALID || !width || !height) return;
    NSMutableData *rgba = [NSMutableData dataWithLength:width * height * 4];
    auto dst = (uint8_t *)rgba.mutableBytes;
    for (unsigned y = 0; y < height; y++) for (unsigned x = 0; x < width; x++) {
        const uint8_t *row = (const uint8_t *)data + y * pitch;
        unsigned r, g, b;
        if (pixelFormat == RETRO_PIXEL_FORMAT_XRGB8888) {
            uint32_t value; memcpy(&value, row + x * 4, 4);
            r = (value >> 16) & 255; g = (value >> 8) & 255; b = value & 255;
        } else {
            uint16_t value; memcpy(&value, row + x * 2, 2);
            bool rgb565 = pixelFormat == RETRO_PIXEL_FORMAT_RGB565;
            r = ((value >> (rgb565 ? 11 : 10)) & 31) * 255 / 31;
            g = ((value >> 5) & (rgb565 ? 63 : 31)) * 255 / (rgb565 ? 63 : 31);
            b = (value & 31) * 255 / 31;
        }
        size_t p = (y * width + x) * 4;
        dst[p] = r; dst[p+1] = g; dst[p+2] = b; dst[p+3] = 255;
    }
    framePixels = rgba; frameWidth = width; frameHeight = height;
}
static size_t audio(const int16_t *data, size_t frames) {
    if (active.audioHandler) active.audioHandler([NSData dataWithBytes:data length:frames * 4]);
    return frames;
}
static void audioSingle(int16_t left, int16_t right) { int16_t values[] = {left, right}; audio(values, 1); }
static void poll(void) {}
static int16_t input(unsigned p, unsigned d, unsigned i, unsigned id) {
    auto found = inputs.find(key(p,d,i,id)); return found == inputs.end() ? 0 : found->second;
}
@implementation EmulatorBridge {
    double _framesPerSecond, _sampleRate;
}
- (double)framesPerSecond { return _framesPerSecond; }
- (double)sampleRate { return _sampleRate; }
- (NSString *)lastMessage { return message; }
- (NSDictionary *)machine:(NSString *)name {
    AMMachine info;
    if (!am_machine(name.UTF8String, &info)) return @{};
    return @{@"name": name, @"title": @(info.title), @"year": @(info.year),
        @"manufacturer": @(info.manufacturer), @"parent": @(info.parent ?: ""),
        @"buttons": @(info.buttons), @"players": @(info.players), @"fourWay": @(info.four_way),
        @"analog": @(info.analog), @"orientation": @(info.orientation)};
}
- (BOOL)loadROM:(NSString *)path systemDirectory:(NSString *)system saveDirectory:(NSString *)save {
    [self stop]; active = self; descriptors = [NSMutableArray new]; variables.clear(); inputs.clear();
    message = @""; framePixels = nil; pixelFormat = RETRO_PIXEL_FORMAT_0RGB1555;
    systemPath = system.UTF8String; savePath = save.UTF8String;
    contentPath = path.stringByDeletingLastPathComponent.UTF8String;
    retro_set_environment(environment); retro_set_video_refresh(video);
    retro_set_audio_sample_batch(audio); retro_set_audio_sample(audioSingle);
    retro_set_input_poll(poll); retro_set_input_state(input); retro_init(); initialized = YES;
    retro_game_info game = {path.UTF8String, nullptr, 0, nullptr};
    loaded = retro_load_game(&game);
    if (!loaded) { retro_deinit(); initialized = NO; return NO; }
    retro_set_controller_port_device(0, RETRO_DEVICE_JOYPAD);
    retro_system_av_info av; retro_get_system_av_info(&av);
    _framesPerSecond = av.timing.fps; _sampleRate = av.timing.sample_rate;
    return YES;
}
- (void)runFrame { if (loaded) retro_run(); }
- (void)stop {
    if (loaded) retro_unload_game(); if (initialized) retro_deinit();
    loaded = initialized = NO; inputs.clear(); framePixels = nil;
}
- (void)reset { if (loaded) retro_reset(); }
- (void)setInputPort:(unsigned)p device:(unsigned)d index:(unsigned)i identifier:(unsigned)id value:(int16_t)v {
    inputs[key(p,d,i,id)] = v;
}
- (void)releaseInputs { inputs.clear(); }
- (NSArray<NSDictionary *> *)inputDescriptors { return [descriptors copy] ?: @[]; }
- (NSArray<NSDictionary *> *)visualObjects {
    std::vector<AMVisual> objects(1024);
    size_t count = loaded ? am_visuals(objects.data(), objects.size()) : 0;
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:count];
    for (size_t i = 0; i < count; i++) {
        auto &v = objects[i];
        [result addObject:@{@"id": @(v.id), @"x": @(v.x), @"y": @(v.y), @"width": @(v.width),
            @"height": @(v.height), @"sprite": @(v.sprite),
            @"pixels": [NSData dataWithBytes:v.pixels length:sizeof(v.pixels)]}];
    }
    return result;
}
- (UIImage *)frameImage {
    if (!framePixels) return nil;
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)framePixels);
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGImageRef cg = CGImageCreate(frameWidth, frameHeight, 8, 32, frameWidth * 4, space,
        kCGImageAlphaLast | kCGBitmapByteOrderDefault, provider, nullptr, false, kCGRenderingIntentDefault);
    UIImage *image = cg ? [UIImage imageWithCGImage:cg] : nil;
    if (cg) CGImageRelease(cg); CGColorSpaceRelease(space); CGDataProviderRelease(provider);
    return image;
}
- (NSData *)saveState {
    size_t size = loaded ? retro_serialize_size() : 0; if (!size) return nil;
    NSMutableData *data = [NSMutableData dataWithLength:size];
    return retro_serialize(data.mutableBytes, size) ? data : nil;
}
- (BOOL)restoreState:(NSData *)state {
    return loaded && state.length == retro_serialize_size() && retro_unserialize(state.bytes, state.length);
}
@end
