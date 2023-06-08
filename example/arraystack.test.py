import unittest
from arraystack import ArrayStack

instance = ArrayStack()

class TestArrayStack(unittest.TestCase):
    def test_setup(self):
        self.add_item()
        self.remove_item()
        self.get_item()
        self.set_item()

    def add_item(self):
        print(f">> 1. {instance.a}")
        instance.add(0, 0)
        print(f">> 2. {instance.a}")
        self.assertEqual(instance.get(0), 0)

    def remove_item(self):
        instance.add(1, 1)
        print(f">> 3. {instance.a}")
        temp = instance.remove(0)
        print(f">> 4. {instance.a}")
        self.assertEqual(temp, 0)

    def get_item(self):
        instance.add(1, 1)
        print(f">> 5. {instance.a}")
        instance.add(2, 2)
        print(f">> 6. {instance.a}")
        self.assertEqual(instance.get(2), 2)

    def set_item(self):
        instance.set(0, 10)
        print(f">> 7. {instance.a}")
        self.assertEqual(instance.get(0), 10)

    def set_default(self):
        pass

if __name__ == '__main__':
    unittest.main()
