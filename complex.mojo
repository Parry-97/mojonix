from std.math import sqrt


@fieldwise_init
struct Complex(
    Boolable,
    Equatable,
    TrivialRegisterPassable,
    Writable,
):
    var re: Float64
    var im: Float64

    def __bool__(self) -> Bool:
        return self.re != 0.0 or self.im != 0.0

    def write_to(self, mut writer: Some[Writer]):
        writer.write("(", self.re)
        if self.im < 0:
            writer.write(" - ", -self.im)
        else:
            writer.write(" + ", self.im)

        writer.write("i)")

    # Struct method for printable
    def write_repr_to(self, mut writer: Some[Writer]):
        t"Complex(re = {self.re}, im = {self.im})".write_to(writer)

    def __init__(out self, re: Float64):
        self.re = re
        self.im = 0

    # methods for unary operator support
    def __pos__(self) -> Self:
        return self

    def __neg__(self) -> Self:
        return Self(-self.re, -self.im)

    # Support for binary arithmetic
    def __add__(self, rhs: Self) -> Self:
        return Self(self.re + rhs.re, self.im + rhs.im)

    def __sub__(self, rhs: Self) -> Self:
        return Self(self.re - rhs.re, self.im - rhs.im)

    def __mul__(self, rhs: Self) -> Self:
        return Self(
            self.re * rhs.re - self.im * rhs.im,
            self.re * rhs.im + self.im * rhs.re,
        )

    def __truediv__(self, rhs: Self) -> Self:
        var denom = rhs.squared_norm()
        return Self(
            (self.re * rhs.re + self.im * rhs.im) / denom,
            (self.im * rhs.re - self.re * rhs.im) / denom,
        )

    def squared_norm(self) -> Float64:
        return self.re * self.re + self.im * self.im

    def norm(self) -> Float64:
        return sqrt(self.squared_norm())


def main():
    var c = Complex(3.14, -2.72)
    var d = Complex(3.14)
    print(c)  # (3.14 - 2.72i)
    print(repr(c))  # Complex(re = 3.14, im = -2.72)
    print(d)

    var cd = Complex(-1.2, 6.5)
    print(+cd)  # (-1.2 + 6.5i)
    print(-cd)  # (1.2 - 6.5i)
