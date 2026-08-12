from max.gpu.host import DeviceContext

def main() raises:
    var ctx = DeviceContext()
    print("GPU:", ctx.name())
