"""Run our original diagnostic through a compiled libretro core, without commercial ROMs."""
import ctypes as C
from pathlib import Path
import sys
import tempfile
from make_diagnostic import write_container

class Variable(C.Structure):
    _fields_ = [("key", C.c_char_p), ("value", C.c_char_p)]
class Game(C.Structure):
    _fields_ = [("path", C.c_char_p), ("data", C.c_void_p), ("size", C.c_size_t), ("meta", C.c_char_p)]
class Visual(C.Structure):
    _fields_ = [(name, C.c_int) for name in ("id", "x", "y", "width", "height", "sprite")] + [("pixels", C.c_uint32 * 256)]

def main():
    core = C.CDLL(sys.argv[1])
    variables, keepalive = {}, []
    video_frames, audio_frames = 0, 0
    held = set()
    log_messages = []
    def keep(value):
        buffer = C.create_string_buffer(value); keepalive.append(buffer); return C.cast(buffer, C.c_char_p)
    @C.CFUNCTYPE(None, C.c_int, C.c_char_p)
    def log(level, text):
        if level >= 2: log_messages.append(text.decode(errors="replace"))
    @C.CFUNCTYPE(C.c_bool, C.c_uint, C.c_void_p)
    def environment(command, data):
        if command in (9,30,31):
            C.cast(data, C.POINTER(C.c_char_p))[0] = directory
        elif command == 27:
            C.cast(data, C.POINTER(C.c_void_p))[0] = C.cast(log, C.c_void_p).value
        elif command in (3,17):
            C.cast(data, C.POINTER(C.c_bool))[0] = command == 3
        elif command in (39,52):
            C.cast(data, C.POINTER(C.c_uint))[0] = 0
        elif command == 16:
            entries = C.cast(data, C.POINTER(Variable)); index = 0
            while entries[index].key:
                key = entries[index].key
                value = entries[index].value.split(b";",1)[-1].strip().split(b"|",1)[0]
                if b"skip_disclaimer" in key or b"skip_warnings" in key: value = b"enabled"
                if b"input_interface" in key: value = b"retropad"
                variables[key] = keep(value); index += 1
        elif command == 15:
            entry = C.cast(data, C.POINTER(Variable)).contents
            entry.value = variables.get(entry.key)
            return entry.key in variables
        elif command not in (6,10,11,18,35,37):
            return False
        return True
    @C.CFUNCTYPE(None, C.c_void_p, C.c_uint, C.c_uint, C.c_size_t)
    def video(data, width, height, pitch):
        nonlocal video_frames
        if data and width and height and pitch: video_frames += 1
    @C.CFUNCTYPE(C.c_size_t, C.POINTER(C.c_int16), C.c_size_t)
    def audio(data, count):
        nonlocal audio_frames
        audio_frames += count; return count
    @C.CFUNCTYPE(None)
    def poll(): pass
    @C.CFUNCTYPE(C.c_int16, C.c_uint, C.c_uint, C.c_uint, C.c_uint)
    def input_state(port, device, index, identifier):
        return int(port == 0 and device == 1 and identifier in held)
    for name, callback in [("environment",environment),("video_refresh",video),("audio_sample_batch",audio),
                           ("input_poll",poll),("input_state",input_state)]:
        function = getattr(core, "retro_set_" + name)
        function.argtypes = [type(callback)]; function(callback)
    core.retro_load_game.argtypes = [C.POINTER(Game)]; core.retro_load_game.restype = C.c_bool
    core.am_visuals.argtypes = [C.POINTER(Visual), C.c_size_t]; core.am_visuals.restype = C.c_size_t
    core.retro_serialize_size.restype = C.c_size_t
    core.retro_serialize.argtypes = [C.c_void_p,C.c_size_t]; core.retro_serialize.restype = C.c_bool
    core.retro_unserialize.argtypes = [C.c_void_p,C.c_size_t]; core.retro_unserialize.restype = C.c_bool
    objects = (Visual * 1024)()
    def sprite():
        count = core.am_visuals(objects, 1024)
        assert count >= 1008, f"Missing extracted hardware objects: {count}"
        return next((v.x, v.y) for v in objects[:count] if v.id == 2000)
    with tempfile.TemporaryDirectory() as temporary:
        directory = keep(temporary.encode())
        path = Path(temporary) / "armtest.zip"; write_container(path)
        core.retro_init()
        try:
            assert core.retro_load_game(C.byref(Game(str(path).encode(),None,0,None))), log_messages[-10:]
            core.retro_set_controller_port_device(0,1)
            for _ in range(12): core.retro_run()
            initial = sprite()
            count = core.am_visuals(objects,1024)
            assert any(any(v.pixels) for v in objects[:count]), "Decoded graphics are empty"
            held.add(6)
            for _ in range(6): core.retro_run()
            held.clear()
            moved = sprite()
            assert moved != initial, ("Input did not change emulated sprite RAM",initial,moved,log_messages[-10:])
            assert video_frames > 0 and audio_frames > 0, (video_frames,audio_frames)
            size = core.retro_serialize_size()
            if size:
                state = C.create_string_buffer(size)
                if core.retro_serialize(state,size):
                    held.add(7)
                    for _ in range(6): core.retro_run()
                    held.clear()
                    assert core.retro_unserialize(state,size), "Diagnostic state restore failed"
                    assert sprite() == moved, ("Hardware state differs after restore",sprite(),moved)
                    print("Diagnostic state round-trip passed")
            print(f"Original Z80 diagnostic: {video_frames} video callbacks, {audio_frames} audio frames; sprite {initial} -> {moved}")
            core.retro_unload_game()
        finally:
            core.retro_deinit()

if __name__ == "__main__": main()
