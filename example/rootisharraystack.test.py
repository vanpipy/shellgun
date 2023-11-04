import unittest
from rootisharraystack import RootishArrayStack

instance = RootishArrayStack()

class TestRootishArrayStack(unittest.TestCase):
    def test_interat(self):
        instance.add(0, 0)
        print(">", instance.blocks.a)
        instance.add(0, 1)
        print(">", instance.blocks.a)
        instance.add(0, 2)
        print(">", instance.blocks.a)
        instance.add(3, 3)
        print(">", instance.blocks.a)
        instance.add(4, 4)
        print(">", instance.blocks.a)
        instance.add(5, 5)
        print(">", instance.blocks.a)
        instance.add(1, 6)
        print(">", instance.blocks.a)
        instance.remove(2)
        print(">", instance.blocks.a)
        assert instance.get(2) == 0

if __name__ == '__main__':
    unittest.main()
