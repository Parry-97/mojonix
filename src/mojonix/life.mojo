from std import time

from gridv1 import Grid
from std.python import Python


# def grid_str(rows: Int, cols: Int, grid: List[List[Int]]) -> String:
def grid_str(grid: Grid) -> String:
    """
    When we pass a value to a Mojo function, the default behavior is that an argument is treated
    as an immutable reference to the value. This is particularly useful for values like `List`s,
    where copying them could be expensive. As we'll see later, we can specify different behavior
    by including an explicit argument convention.
    """
    var str = String()

    for row in range(grid.rows):
        for col in range(grid.cols):
            if grid.data[row][col] == 1:
                str += "*"
            else:
                str += " "

        if row != grid.rows - 1:
            str += "\n"
    return str


def run_display(
    var grid: Grid,
    window_height: Int = 600,
    window_width: Int = 600,
    background_color: String = "black",
    cell_color: String = "green",
    pause: Float64 = 0.1,
) raises -> None:
    # Import the pygame Python package
    var pygame = Python.import_module("pygame")

    # Initialize pygame modules
    pygame.init()

    # Create a window and set its title
    var window = pygame.display.set_mode(
        Python.tuple(window_width, window_height)
    )
    pygame.display.set_caption("Conway's Game of Life")

    var cell_height = Float64(window_height) / Float64(grid.rows)
    var cell_width = Float64(window_width) / Float64(grid.cols)
    var border_size = 1
    var cell_fill_color = pygame.Color(cell_color)
    var background_fill_color = pygame.Color(background_color)

    var running = True
    while running:
        # Poll for events
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                # Quit if the window is closed
                running = False
            elif event.type == pygame.KEYDOWN:
                # Also quit if the user presses <Escape> or 'q'
                if event.key == pygame.K_ESCAPE or event.key == pygame.K_q:
                    running = False

        # Clear the window by painting with the background color
        window.fill(background_fill_color)

        # Draw each live cell in the grid
        for row in range(grid.rows):
            for col in range(grid.cols):
                if grid[row, col]:
                    var x = Float64(col) * cell_width + Float64(border_size)
                    var y = Float64(row) * cell_height + Float64(border_size)
                    var width = cell_width - Float64(border_size)
                    var height = cell_height - Float64(border_size)
                    pygame.draw.rect(
                        window,
                        cell_fill_color,
                        Python.tuple(x, y, width, height),
                    )

        # Update the display
        pygame.display.flip()

        # Pause to let the user appreciate the scene
        time.sleep(pause)

        # Next generation
        grid = grid.evolve()

    # Shut down pygame cleanly
    pygame.quit()


def main() raises:
    var start = Grid.random(128, 128)
    run_display(start^)


def initial_main() raises:
    # var name: String = input("Who are you? ")
    # var greeting: String = "Hi, " + name + "!"
    # print(greeting)
    #
    # var row = List[Int]();
    # var names = List[String]();
    #
    # var nums: List[Int] = [12, -7, 64]
    # nums.append(-937)
    # print("Number of elements in the list:", len(nums))
    # print("Popping last element off the list:", nums.pop())
    # print("First element of the list:", nums[0])
    # print("Second element of the list:", nums[1])
    # print("Last element of the list:", nums[len(nums) - 1])
    #
    # var grid: List[List[Int]] = [
    #     [11, 22],
    #     [33, 44]
    # ]
    # print("Row 0, Column 0:", grid[0][0])
    # print("Row 0, Column 1:", grid[0][1])
    # print("Row 1, Column 0:", grid[1][0])
    # print("Row 1, Column 1:", grid[1][1])

    var num_rows = 8
    var num_cols = 8

    # We can also nest list like this
    # var glider: List[List[Int]] = [
    #     [0, 1, 0, 0, 0, 0, 0, 0],
    #     [0, 0, 1, 0, 0, 0, 0, 0],
    #     [1, 1, 1, 0, 0, 0, 0, 0],
    #     [0, 0, 0, 0, 0, 0, 0, 0],
    #     [0, 0, 0, 0, 0, 0, 0, 0],
    #     [0, 0, 0, 0, 0, 0, 0, 0],
    #     [0, 0, 0, 0, 0, 0, 0, 0],
    #     [0, 0, 0, 0, 0, 0, 0, 0],
    # ]

    # var start = Grid(num_rows, num_cols, glider^);
    var start = Grid.random(num_rows, num_cols)
    print(start.grid_str())
    print(String(start))
    # print(grid_str(start));
    # print(grid_str(num_rows, num_cols, glider));
