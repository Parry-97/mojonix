from std.memory.alloc import alloc, dealloc, ThinAllocation, Layout


struct ParameterizedArray[T: Copyable & Deinitable](
    Writable where conforms_to(T, Writable)
):
    var _data: ThinAllocation[Self.T]
    var _size: Int

    def __init__(out self, var *elements: Self.T):
        self._size = len(elements)
        self._data = alloc[Self.T]({count = self._size}).into_thin()
        var ptr = self._data.unsafe_ptr()
        for i in range(self._size):
            ptr.unsafe_offset(i).unsafe_write(elements[i].copy())

    def __init__(out self, *, count: Int, value: Self.T):
        self._size = count
        self._data = alloc[Self.T]({count = count}).into_thin()
        var ptr = self._data.unsafe_ptr()
        for i in range(self._size):
            ptr.unsafe_offset(i).unsafe_write(copy=value)

    def __deinit__(deinit self):
        var ptr = self._data.unsafe_ptr()
        for i in range(self._size):
            ptr.unsafe_offset(i).unsafe_deinit_pointee()
        dealloc(self._data^.unsafe_with_layout({count = self._size}))

    def __getitem__(self, i: Int) raises -> ref[self] Self.T:
        if i < self._size:
            return self._data.unsafe_ptr().unsafe_origin_cast[
                origin_of(self)
            ]()[unsafe_offset=i]
        else:
            raise Error("Out of bounds")

    def write_to(
        self, mut writer: Some[Writer]
    ) where conforms_to(Self.T, Writable):
        writer.write("[")
        var ptr = self._data.unsafe_ptr()
        for i in range(self._size):
            writer.write(ptr[unsafe_offset=i])
            if i < self._size - 1:
                writer.write(", ")
        writer.write("]")


struct Circle[radius: Float64]:
    """
    We can also define comptime values as members of a struct or type definition.
    """

    comptime pi = 3.14159265359
    comptime circumference = 2 * Self.pi * Self.radius


@fieldwise_init
struct Sentiment(Equatable, ImplicitlyCopyable):
    """
    Some Mojo types use comptime members to express enumerations.
    For example, the following code defines a Sentiment type that defines
    comptime constants for different sentiment values.
    """

    var _value: Int

    comptime NEGATIVE = Sentiment(0)
    comptime NEUTRAL = Sentiment(1)
    comptime POSITIVE = Sentiment(2)

    def __eq__(self, other: Self) -> Bool:
        return self._value == other._value

    def __ne__(self, other: Self) -> Bool:
        return not (self == other)


def is_happy(s: Sentiment):
    if s == Sentiment.POSITIVE:
        print("Yes. 😀")
    else:
        print("No. ☹️")


def main() raises:
    var array = ParameterizedArray(1, 2, 3)
    print(array)

    # NOTE:
    # Using parametrized types
    #
    # Make a vector of 4 floats.
    var small_vec = SIMD[DType.float32, 4](1.0, 2.0, 3.0, 4.0)

    # Make a big vector containing 1.0 in float16 format.
    var big_vec = SIMD[DType.float16, 32](1.0)

    # Do some math and convert the elements to float32.
    var bigger_vec = (big_vec + big_vec).cast[DType.float32]()
