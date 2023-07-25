import unittest
from dllist import DLList

instance = DLList()

def read_dllist_as_string(dllist):
    result = ''
    node = dllist.dummy.next
    l = dllist.n
    i = 0
    while i < l:
        result += node.x
        node = node.next
        i += 1
    return result

class TestDLList(unittest.TestCase):
    def test_setup(self):
        self.interat_items()

    def interat_items(self):
        instance.add(0, 'e')
        instance.add(0, 'd')
        instance.add(0, 'c')
        instance.add(0, 'b')
        instance.add(0, 'a')
        print(f">> 1. {read_dllist_as_string(instance)}")
        self.assertEqual(instance.n, 5)
        self.assertEqual(read_dllist_as_string(instance), 'abcde')
        instance.remove(4)
        print(f">> 2. {read_dllist_as_string(instance)}")
        self.assertEqual(instance.n, 4)
        self.assertEqual(read_dllist_as_string(instance), 'abcd')
        instance.remove(0)
        print(f">> 3. {read_dllist_as_string(instance)}")
        self.assertEqual(instance.n, 3)
        self.assertEqual(read_dllist_as_string(instance), 'bcd')
        self.assertEqual(instance.get(0), 'b')
        instance.set(0, 'x')
        print(f">> 4. {read_dllist_as_string(instance)}")
        self.assertEqual(instance.get(0), 'x')
        self.assertEqual(read_dllist_as_string(instance), 'xcd')

if __name__ == '__main__':
    unittest.main()
