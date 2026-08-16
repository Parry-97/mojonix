struct Node[ElementType: ImplicitlyCopyable & Writable & Deinitable]:
    """
    MutUntrackedOrigin lets the pointer represent dynamically-allocated memory
    that won't be tracked by the lifetime checker. You'll need to both allocate
    and deallocate memory as needed.
    """

    comptime NodePointer = Pointer[Self, MutUntrackedOrigin]

    var value: Optional[Self.ElementType]  # The `Node`'s value
    var next: Optional[Self.NodePointer]  # Pointer to the next `Node`

    #
    # Uses an `Optional` value to allow 'empty' Node construction
    # that can be moved into newly allocated memory
    def __init__(out self, value: Optional[Self.ElementType] = None):
        self.value = value
        self.next = None

    @staticmethod
    def make_node(value: Self.ElementType) -> Self.NodePointer:
        """
        Here's the key pattern you'll use in many reference structures:
        1. Allocate space.
        2. Construct a value-holding node.
        3. Move it into the allocated memory.
        4. Return the pointer.
        """
        var node_ptr = alloc[Self](1)
        node_ptr.unsafe_write(Self(value))
        return node_ptr

    def append(mut self, value: Self.ElementType):
        # Free chain if replacing `next`
        if self.next:
            var next_ptr = self.next.value()
            next_ptr[].free_chain()
            next_ptr.unsafe_deinit_pointee()
            next_ptr.unsafe_free()

        self.next = Self.make_node(value)

    @staticmethod
    def print_list(node: Optional[Self.NodePointer]):
        if not node:
            print("Empty list")
            return

        var node_ptr = node.value()

        var current_value: Optional[Self.ElementType] = node_ptr[].value
        if current_value:
            print(current_value.value(), end=" ")

        if node_ptr[].next:
            Self.print_list(node_ptr[].next)
        else:
            print()

    def free_chain(self):
        """
        Because you allocate each node yourself, you're also responsible for
        freeing it. This cleanup walks the chain and frees each node after
        destroying its pointee.
        """
        var current = self.next
        while current:
            var current_ptr = current.value()
            var next_node = current_ptr[].next
            current_ptr.unsafe_deinit_pointee()
            current_ptr.unsafe_free()
            current = next_node


comptime Element = String
comptime ListNode = Node[Element]


def main():
    var values: List[Element] = ["one", "one", "two", "three", "five", "eight"]
    var list_head = ListNode.make_node(values[0])

    var current = list_head
    for idx in range(1, len(values), 1):
        current[].append(values[idx])
        current = current[].next.value()

    ListNode.print_list(list_head)

    # Demonstrates cleanup. In short-lived programs, the OS reclaims memory
    # at exit
    list_head[].free_chain()
    list_head.unsafe_deinit_pointee()
    list_head.unsafe_free()
