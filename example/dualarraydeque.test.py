import unittest
from dualarraydeque import DualArrayDeque

instance = DualArrayDeque()

class TestDualArrayDeque(unittest.TestCase):
    def test_setup(self):
        self.interat_items()

    def interat_items(self):
        print(f">> 0. {instance.front.a} {instance.back.a}")
        instance.add(0, 'b')
        print(f">> 1. {instance.front.a} {instance.back.a}")
        instance.add(0, 'a')
        print(f">> 2. {instance.front.a} {instance.back.a}")
        instance.add(2, 'c')
        print(f">> 3. {instance.front.a} {instance.back.a}")
        instance.add(3, 'd')
        print(f">> 4. {instance.front.a} {instance.back.a}")
        self.assertEqual(''.join(instance.front.a) + ''.join(instance.back.a), 'abcd')
        instance.add(3, 'x')
        print(f">> 5. {instance.front.a} {instance.back.a}")
        self.assertEqual(''.join(instance.front.a) + ''.join(instance.back.a), 'abcxd')
        instance.add(4, 'y')
        print(f">> 6. {instance.front.a} {instance.back.a}")
        self.assertEqual(''.join(instance.front.a) + ''.join(instance.back.a), 'abcxyd')
        instance.remove(0)
        print(f">> 7. {instance.front.a} {instance.back.a}")
        self.assertEqual(''.join(instance.front.a) + ''.join(instance.back.a), 'bcxyd')
        instance.remove(2)
        print(f">> 8. {instance.front.a} {instance.back.a}")
        self.assertEqual(''.join(instance.front.a) + ''.join(instance.back.a), 'bcyd')

if __name__ == '__main__':
    unittest.main()
