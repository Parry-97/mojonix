from std.python import Python

trait SomeTrait:
    # NOTE: the '...' after the method signature is mojo syntax indicating the
    # method has no implementation
    def required_method(self, x: Int): ...

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

def sum(*values: Int) -> Int:
  var sum: Int = 0
  for value in values:
    sum = sum + value
  return sum

