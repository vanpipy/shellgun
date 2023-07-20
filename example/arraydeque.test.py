import unittest
from arraydeque import ArrayDeque

instance = ArrayDeque(['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'])

class TestArrayDeque(unittest.TestCase):
    def test_setup(self):
        self.test_items()
        self.interat_items()

    def test_items(self):
        print(f">> 1. {instance.a}")
        self.assertEqual(''.join(instance.a), 'abcdefgh')

    def interat_items(self):
        instance.remove(2)
        print(f">> 2. {instance.a}")
        self.assertEqual(''.join(instance.a), 'abdefgh')
        instance.add(4, 'x')
        print(f">> 3. {instance.a}")
        self.assertEqual(''.join(instance.a), 'abdexfgh')
        instance.add(3, 'y')
        print(f">> 4. {instance.a}")
        self.assertEqual(''.join(instance.a), 'abdyexfgh')
        instance.add(4, 'z')
        print(f">> 5. {instance.a}")
        self.assertEqual(''.join(instance.a), 'bdyzexfgha')

if __name__ == '__main__':
    unittest.main()
