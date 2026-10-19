"""Exercise the compiled native adapter without shipping or executing a commercial ROM."""
import ctypes as C
import sys

class Machine(C.Structure):
    _fields_ = [(name, C.c_char_p) for name in ("name", "title", "year", "manufacturer", "parent")] + [
        (name, C.c_uint) for name in ("buttons", "players", "four_way", "analog", "orientation")]

core = C.CDLL(sys.argv[1])
core.am_machine.argtypes = [C.c_char_p, C.POINTER(Machine)]
core.am_machine.restype = C.c_int
for name, minimum_buttons, four_way, analog in [
    ("pacman", 0, True, False), ("sf2", 6, False, False),
    ("mslug", 3, False, False), ("arkanoid", 1, False, True),
    ("centiped", 1, False, True), ("outrun", 2, False, True),
]:
    result = Machine()
    assert core.am_machine(name.encode(), C.byref(result)), name
    assert result.buttons >= minimum_buttons, (name, result.buttons)
    assert bool(result.four_way) == four_way, name
    assert bool(result.analog) == analog, name
    print(name, result.title.decode(), "buttons", result.buttons, "players", result.players)
assert not core.am_machine(b"this-is-not-a-driver", C.byref(Machine()))
print("Native metadata checks passed; no ROM gameplay or AR claims made.")
