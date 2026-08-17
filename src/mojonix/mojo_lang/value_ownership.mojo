def add_two(y: Int):
    """
    The default behavior for function arguments is fully value semantic:
    arguments are immutable references, and any living variable from the
    caller is not affected by the function.
    So if the function wants to modify the value in the local scope,
    it needs to make a local copy.
    """
    # y += 2  # This would cause a compiler error because `y` is immutable
    # We can instead make an explicit copy:
    var z = y
    z += 2
    print("z:", z)


def mutate(mut l: List[Int]):
    """
    If you'd like your function to receive a mutable reference, add the
    mut keyword in front of the argument name. You can think of mut like
    this: it means any changes to the value inside the function are visible
    outside the function.
    """
    l.append(5)


def append_twice(mut s: String, other: String):
    # Mojo knows 's' and 'other' can't be the same string.
    s += other
    s += other


def invalid_access():
    """
    Mojo enforces argument exclusivity for mutable references. This means that
    if a function receives a mutable reference to a value (such as an mut argument),
    it can't receive any other references to the same value—mutable or immutable.
    That is, a mutable reference can't have any other references that alias it.

    Note that argument exclusivity isn't enforced for register-passable trivial types
    (like Int and Bool) as they're always passed by copy. When passing the same value
    into two Int arguments, the callee receives two copies of the value.
    """
    var my_string = "o"  # Create a run-time String value

    # error: passing `my_string` mut is invalid since it's also passed
    # as an immutable reference
    # append_twice(my_string, my_string)
    print(my_string)


def take_text(var text: String):
    text += "!"
    print(text)


def add_to_list(var name: String, mut list: List[String]):
    list.append(name^)


def main():
    var x = 1
    add_two(x)
    print("x:", x)

    var message = "Hello"  # Create a run-time String value
    # NOTE: The following code works by making a copy of the string,
    # because take_text() uses the var convention, and the caller
    # doesn't include the transfer sigil:
    take_text(message)
    print(message)

    # WARN: However, if you add the ^ transfer sigil when calling take_text(),
    # the compiler complains about print(message), because at that point,
    # the message variable is no longer initialized. That is, this version doesn't compile:
    take_text(message^)

    # WARN: This is a critical feature of Mojo's lifetime checker, because it ensures
    # that no two variables have ownership of the same value. To fix the error, you must
    # not use the message variable after you end its lifetime with the ^ transfer sigil.
    #
    # print(message)
