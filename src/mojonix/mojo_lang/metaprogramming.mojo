from std.sys import has_accelerator

# INFO:
# To understand Mojo's metaprogramming, you need to understand how Mojo runs code at compile time.
# Several things can trigger compile-time code execution:
# 1. Assigning an expression to a comptime value.
# 2. Evaluating a comptime conditional or loop.
# 3. Assigning an expression to a compile-time parameter.
# And a few less common cases, all identified with the comptime keyword.

# Here the expression invokes the IntLiteral.__floordiv__() method.
# Since it occurs in a comptime assignment, the method must be run at compile time.
comptime SIZE = 1024 // 32


def _calculate_block_size() -> Int:
    return 32


def run_on_gpu():
    pass


def run_on_cpu():
    pass


def main() raises:
    comptime for i in range(4):
        print(i)
    # NOTE: When the compiler encounters a function call in a compile-time context, the compiler
    # runs the function separately, as if it was a small separate program.
    # While most code can run at compile time, Mojo won't run code that depends on the execution environment.
    # The following are examples of code that Mojo won't run at compile time:
    # 1. File I/O.
    # 2. Foreign function calls (for example, to external libraries).
    # 3. Functions that can raise errors.

    # WARN:
    # When the compiler encounters a function call in a compile-time context, the compiler runs
    # the function separately, as if it was a small separate program. This is similar in concept
    # to how C++ evaluates a constexpr.
    # While most code can run at compile time, Mojo won't run code that depends on the execution
    # environment.

    # WARN: The following are examples of code that Mojo won't run at compile time:
    # 1. File I/O.
    # 2. Foreign function calls (for example, to external libraries).
    # 3. Functions that can raise errors.
    # In addition, the compiler can't run functions on the GPU. Compile-time functions in GPU
    # code are actually run on the CPU.
    # When running code, the compiler can allocate memory and instantiate types that allocate
    # memory, such as strings and collections. With some limitations, it can pass compile-time
    # values on to run-time code, a process called materialization.

    # A comptime value is always evaluated at compile time, so you can
    # use comptime to force a function to run at compile time.
    # You can use this to calculate constant values based on information available at compile time, such as hardware parameters.
    comptime block_size = _calculate_block_size()

    # Compile time conditionals
    comptime if has_accelerator():
        run_on_gpu()
    else:
        run_on_cpu()

    # Compile time loop unrolling
    var a: List[Int] = [1, 2, 3, 4, 5]
    var b: List[Int] = [0, 0, 0, 0, 0]
    comptime for i in range(1, 5):
        b[i - 1] = a[i] + a[i - 1]

    # This is effectively unrolled to the following runtime code
    b[0] = a[1] + a[0]
    b[1] = a[2] + a[1]
    b[2] = a[3] + a[2]
    b[3] = a[4] + a[3]
