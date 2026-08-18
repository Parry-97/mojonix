from std.sys import has_accelerator
from layout import TileTensor, row_major
from max.gpu.host import DeviceContext
from std.gpu import block_idx, thread_idx, block_dim
from std.math import ceildiv

comptime vector_size = 1024

# NOTE: Calculate the number of thread blocks needed by dividing the vector size
# by the block size and rounding up.
comptime block_size = 256
comptime num_blocks = ceildiv(vector_size, block_size)


def main() raises:
    comptime if not has_accelerator():
        print("No compatible GPU found")
    else:
        var ctx = DeviceContext()
        # NOTE: Create a HostBuffer for input vectors
        var lhs = ctx.enqueue_create_host_buffer[DType.float32](vector_size)
        var rhs = ctx.enqueue_create_host_buffer[DType.float32](vector_size)

        # WARN:
        # As with all DeviceContext methods whose name starts with enqueue_,
        # the method is asynchronous and returns immediately, adding the operation
        # to the queue to be executed by the DeviceContext. Therefore, we need to
        # call the synchronize() method to ensure that the operation has completed
        # before we use the HostBuffer object. Then we can initialize the input
        # vectors with values and print them.
        ctx.synchronize()

        for i in range(vector_size):
            lhs[i] = Float32(i)
            rhs[i] = Float32(Float64(i) * 0.5)

        print("LHS buffer: ", lhs)
        print("RHS buffer: ", rhs)

        # NOTE:
        # You might notice that we don't explicitly call any methods to free the
        # host memory allocated by our HostBuffers like we do in CUDA C++.
        # That's because a HostBuffer is subject to Mojo's standard ownership and
        # lifecycle mechanisms. The Mojo compiler analyzes our program to determine
        # the last point that the owner of or a reference to an object is used and
        # automatically adds a call to the object's destructor.

        # NOTE: Create a DeviceBuffer  for input vectors
        var lhs_device = ctx.enqueue_create_buffer[DType.float32](vector_size)
        var rhs_device = ctx.enqueue_create_buffer[DType.float32](vector_size)

        # NOTE:  Copy the host buffers to Device buffers
        ctx.enqueue_copy(dst_buf=lhs_device, src_buf=lhs)
        ctx.enqueue_copy(dst_buf=rhs_device, src_buf=rhs)

        # NOTE: Create a device buffer for the result
        var result_device = ctx.enqueue_create_buffer[DType.float32](
            vector_size
        )

        # INFO: A Layout is a representation of memory layouts using
        # shape and stride information, and it maps between logical
        # coordinates and linear memory indices.

        # INFO: TileTensor provides a powerful abstraction for multi-dimensional
        # data with precise control over memory organization. It supports various
        # memory layouts (row-major, column-major, tiled), hardware-specific optimizations,
        # and efficient parallel access patterns.

        # Wrap the DeviceBuffers in TileTensors
        var lhs_tensor = TileTensor(lhs_device, layout)
        var rhs_tensor = TileTensor(rhs_device, layout)
        var result_tensor = TileTensor(result_device, layout)

        # Compile and enqueue the kernel
        ctx.enqueue_function[vector_addition](
            lhs_tensor,
            rhs_tensor,
            result_tensor,
            grid_dim=num_blocks,
            block_dim=block_size,
        )

        # Create a HostBuffer for the result vector
        var result_host = ctx.enqueue_create_host_buffer[DType.float32](
            vector_size
        )

        # Copy the result vector from the DeviceBuffer to the HostBuffer
        ctx.enqueue_copy(dst_buf=result_host, src_buf=result_device)

        # Finally, synchronize the DeviceContext to run all enqueued operations
        ctx.synchronize()

        print("Result vector:", result_host)


comptime layout = row_major[vector_size]()


def vector_addition(
    lhs_tensor: TileTensor[DType.float32, type_of(layout), MutAnyOrigin],
    rhs_tensor: TileTensor[DType.float32, type_of(layout), MutAnyOrigin],
    out_tensor: TileTensor[DType.float32, type_of(layout), MutAnyOrigin],
):
    """
    Calculate the elementwise sum of two vectors on the GPU.
    """

    # NOTE: As a convenience, the `gpu` package includes a `global_idx` comptime value
    # that contains the unique "global" x, y, and z indices of the thread within
    # the grid of thread blocks. So for our one-dimensional grid of one-dimensional
    # thread blocks, global_idx.x is equivalent to the value of tid that we calculated above.

    # Calculate the index of the vector element for the thread to process
    var tid = block_idx.x * block_dim.x + thread_idx.x

    # WARN: Don't process out of bounds elements
    if tid < vector_size:
        out_tensor[tid] = lhs_tensor[tid] + rhs_tensor[tid]
