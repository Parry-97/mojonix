from std.python import Python


trait SomeTrait:
    # NOTE: the '...' after the method signature is mojo syntax indicating the
    # method has no implementation
    def required_method(self, x: Int):
        ...


@fieldwise_init
struct SomeStruct(SomeTrait):
    """
    Here is a struct conforming to the `SomeTrait` trait
    defined above.
    """

    def required_method(self, x: Int):
        print("hello traits", x)


def fun_with_traits[T: SomeTrait](x: T):
    """
    Here's a function that uses the trait as an argument type
    instead of the struct type.
    """
    x.required_method(42)


def use_trait_function():
    var thing = SomeStruct()
    fun_with_traits(thing)


def repeat[count: Int](msg: String):
    """
    By specifying count as a compile time parameter, the Mojo compiler can optimize the
    function because this value can't change at runtime. And the comptime
    keyword in the code tells the compiler to evaluate the for loop at
    compile time, not runtime.

    We can think of a parameter as a compile-time variable that becomes a run-time
    constant.

    The compiler effectively generates a unique version of the repeat()
    function that repeats the message only 3 times. This makes the code more performant
    because there's less to compute at runtime.
    """

    # evaluate the following for loop at compile time
    comptime for i in range(count):
        print(msg)


def call_repeat():
    repeat[3]("Hello")


def main() raises:
    # call_repeat()
    """
    Mojo supports the ability to import Python modules as-is, so you can leverage existing Python code right away.
    For example, here's how you can import and use NumPy.
    """
    var np = Python.import_module("numpy")
    var ar = np.arange(15).reshape(3, 5)
    print(ar)
    print(ar.shape)

    var source = String("Hello")
    var copied = source  # A copy
    var moved = source^  # A transfer
    # print(source)  error: use of uninitliazed value

    var items: List[Int] = [99, 77, 33, 12]
    var item = items[1]  # item is a copy of items[1]
    item += 1  # increments item
    print(items[1])  # prints 77

    # Reference bindings can't be re-assigned:
    ref item_ref = items[1]  # item_ref is a reference to item[1]
    item_ref += 1  # increments items[1]
    print(items[1])  # prints 78
    # ref item_ref = items[2]  # error: invalid redefinition of item_ref


def sum(*values: Int) -> Int:
    var sum: Int = 0
    for value in values:
        sum = sum + value
    return sum


def run_action[
    ErrorType: AnyType
](action: def() thin raises ErrorType -> Int) raises ErrorType -> Int:
    return action()


struct MyPair:
    var first: Int
    var second: Int

    def __init__(out self, first: Int, second: Int):
        self.first = first
        self.second = second


struct MyStruct:
    var value: Int

    def increment(mut self):
        self.value += 1  # Works: Mutable `self` allows assignment

    # ...
