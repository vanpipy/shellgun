import unittest
from arrayqueue import ArrayQueue

instance = ArrayQueue()

class TestArrayStack(unittest.TestCase):
    def test_setup(self):
        self.add_item()
        self.remove_item()

    def add_item(self):
        print(f">> 1. {instance.a}")
        instance.add('a')
        instance.add('b')
        instance.add('c')
        instance.add('d')
        instance.add('e')
        instance.add('f')
        print(f">> 2. {instance.a} Added")
        self.assertEqual(''.join(instance.a), 'abcdef')

    def remove_item(self):
        instance.remove()
        print(f">> 3. {instance.a} Removed")
        instance.remove()
        print(f">> 4. {instance.a} Removed")
        instance.remove()
        print(f">> 5. {instance.a} Removed")
        instance.remove()
        print(f">> 6. {instance.a} Removed")
        instance.remove()
        print(f">> 7. {instance.a} Removed")
        self.assertEqual(''.join(instance.a), 'f')

if __name__ == '__main__':
    unittest.main()
