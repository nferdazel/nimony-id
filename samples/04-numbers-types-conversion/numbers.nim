import std/syncio

# `int` is the general-purpose integer; its width follows the pointer size of the machine.
echo sizeof(int)          # 8 on this 64-bit host
echo low(int8)            # -128
echo high(int8)           # 127

# Signed overflow wraps. There is no overflow exception to catch.
var edge: int8 = 127
edge = edge + 1'i8
echo edge                 # -128

# Unsigned arithmetic wraps too.
var count: uint8 = 255
count = count + 1'u8
echo count                # 0

# If you need to notice the wrap, keep the overflow flag.
var top: int64 = 9223372036854775807'i64
var wrapped: int64
var overflowed = false
{.keepOverflowFlag.}:
  wrapped = top + 1'i64
  overflowed = overflowFlag()
echo wrapped              # -9223372036854775808
echo overflowed           # true

# Integer division and modulo are separate operators.
echo 7 div 2              # 3
echo 7 mod 2              # 1
echo 7 / 2                # 3.5 — `/` always yields a float

# Conversion is written as a call on the type name, and it truncates.
echo int(3.9)             # 3
echo int(-3.9)            # -3
echo float(3)             # 3.0
echo int8(200)            # -56 — narrowing conversion wraps, it does not raise

# `bool` and `char` are one byte each.
echo sizeof(bool)         # 1
echo sizeof(char)         # 1
echo ord('a')             # 97
echo chr(97)              # a
echo 'a' < 'b'            # true

# A range is a type whose bounds are part of the type.
type Digit = range[0..9]
var five: Digit = 5
echo five                 # 5
echo ord(five)            # 5
