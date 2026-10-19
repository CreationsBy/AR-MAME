#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN
@interface EmulatorBridge : NSObject
@property(nonatomic, readonly) double framesPerSecond;
@property(nonatomic, readonly) double sampleRate;
@property(nonatomic, readonly) NSString *lastMessage;
@property(nonatomic, copy, nullable) void (^audioHandler)(NSData *samples);
- (NSDictionary<NSString *, id> *)machine:(NSString *)name;
- (BOOL)loadROM:(NSString *)path systemDirectory:(NSString *)system saveDirectory:(NSString *)save;
- (void)runFrame;
- (void)stop;
- (void)reset;
- (void)setInputPort:(unsigned)port device:(unsigned)device index:(unsigned)index identifier:(unsigned)identifier value:(int16_t)value;
- (void)releaseInputs;
- (NSArray<NSDictionary<NSString *, id> *> *)inputDescriptors;
- (NSArray<NSDictionary<NSString *, id> *> *)visualObjects;
- (nullable UIImage *)frameImage;
- (nullable NSData *)saveState;
- (BOOL)restoreState:(NSData *)state;
@end
NS_ASSUME_NONNULL_END
