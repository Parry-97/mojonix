# Content of test_quickstart.mojo
from std.testing import assert_equal, TestSuite

def inc(n: Int) -> Int:
    return n + 1

def test_inc_zero() raises:
    # This test contains an intentional logical error to show an example of
    # what a test failure looks like at runtime.
    assert_equal(inc(0), 0)

def test_inc_one() raises:
    assert_equal(inc(1), 2)

def main() raises:
    TestSuite.discover_tests[__functions_in_module()]().run()
