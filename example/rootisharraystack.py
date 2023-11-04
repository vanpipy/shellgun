from arraystack import ArrayStack, new_array
from math import ceil, sqrt

class RootishArrayStack:
    def __init__(self):
        self.initialize()

    def initialize(self):
        self.n = 0
        self.blocks = ArrayStack()

    def i2b(self, i):
        closing_block_index = (-3.0 + sqrt(9 + (8 * i))) / 2.0
        return int(ceil(closing_block_index))

    def get(self, i):
        block_index = self.i2b(i)
        at_block = int(i - block_index * (block_index + 1) / 2)
        expected = self.blocks.get(block_index)[at_block]
        return expected

    def set(self, i, x):
        block_index = self.i2b(i)
        at_block = int(i - block_index * (block_index + 1) / 2)
        legacy_value = self.blocks.get(block_index)[at_block]
        self.blocks.get(block_index)[at_block] = x
        return legacy_value

    def add(self, i, x):
        r = self.blocks.size()
        if r * (r + 1) / 2 < self.n + 1:
            self.grow()
        self.n += 1
        for j in range(self.n - 1, i, -1):
            self.set(j, self.get(j - 1))
        self.set(i, x)

    def grow(self):
        self.blocks.add(self.blocks.size(), new_array(self.blocks.size() + 1))

    def remove(self, i):
        x = self.get(i)
        for j in range(i, self.n - 1):
            self.set(j, self.get(j + 1))
        self.n -= 1
        r = self.blocks.size()
        if (r - 2) * (r - 1) >= self.n:
            self.shrink()
        return x

    def shrink(self):
        r = self.blocks.size()
        while r > 0 and (r - 2) * (r - 1) >= self.n:
            self.blocks.remove(self.blocks.size() - 1)
            r -= 1
