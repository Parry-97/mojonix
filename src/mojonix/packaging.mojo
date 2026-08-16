# Note that if the package name is not a valid identifier, an escaped identifier may be used instead:
from `mojo-package`.mymodule import MyPair


def main():
    var mine = MyPair(2, 4)
    mine.dump()
