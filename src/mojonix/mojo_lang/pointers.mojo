from std.memory import OwnedPointer
from mypackage.mymodule import MyPair

# INFO:
# A pointer is an indirect reference to one or more values stored in memory.
# The pointer is a value that holds an address to memory, and provides APIs
# to store and retrieve values to that memory. The value pointed to by a pointer
# is also known as a pointee.


def main() raises:
    var owned_ptr: OwnedPointer[Int]
    owned_ptr = OwnedPointer(100)

    # NOTE: Accessing the memory—to retrieve or update a value—is called
    # dereferencing the pointer. You can dereference a pointer by following
    # the variable name with an empty pair of square brackets:
    owned_ptr[] += 10
    # Access an initialized value
    print(owned_ptr[])

    # INFO:
    # The Pointer type is Mojo's primary pointer type. It can access a block
    # of contiguous memory locations, which might be uninitialized.
    # Heap-allocated memory is accessed through a Pointer; the other pointer types
    # wrap a Pointer to access heap memory.
    # The Pointer type is safe when used to point to an existing value:
    var ptr = Pointer(to=42)
    print(ptr[])

    # INFO:
    # The OwnedPointer type is a smart pointer designed for cases
    # where there is single ownership of the underlying data.
    # An OwnedPointer points to a single item, which is passed in
    # when you initialize the OwnedPointer. The OwnedPointer allocates
    # memory and moves or copies the value into the reserved memory.
    var pair = MyPair(3, 4)
    # NOTE: An owned pointer can hold almost any type of item, but
    # when constructing an OwnedPointer, the stored item must be either Movable or Copyable.
    var o_ptr = OwnedPointer(pair^)

    # WARN: Since an OwnedPointer is designed to enforce single ownership,
    # the pointer itself can be moved, but not copied.
