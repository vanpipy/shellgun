import unittest
from sllist import SLList

instance = SLList()

def read_SLList_as_string(sllist):
    result = ''
    node = sllist.head
    while True:
        result += node.x
        if node.next:
            node = node.next
        else: 
            break
    return result

class TestSLList(unittest.TestCase):
    def test_setup(self):
        self.interat_items()

    def interat_items(self):
        instance.add('a')
        instance.add('b')
        instance.add('c')
        instance.add('d')
        instance.add('e')
        print(f">> 1. {read_SLList_as_string(instance)}")
        self.assertEqual(instance.n, 5)
        self.assertEqual(read_SLList_as_string(instance), 'abcde')
        instance.push('f')
        print(f">> 2. {read_SLList_as_string(instance)}")
        self.assertEqual(read_SLList_as_string(instance), 'fabcde')
        instance.push('g')
        print(f">> 3. {read_SLList_as_string(instance)}")
        self.assertEqual(read_SLList_as_string(instance), 'gfabcde')
        instance.pop()
        print(f">> 4. {read_SLList_as_string(instance)}")
        self.assertEqual(read_SLList_as_string(instance), 'fabcde')
        instance.pop()
        print(f">> 5. {read_SLList_as_string(instance)}")
        self.assertEqual(read_SLList_as_string(instance), 'abcde')
        instance.remove()
        print(f">> 6. {read_SLList_as_string(instance)}")
        self.assertEqual(read_SLList_as_string(instance), 'abcde')
        instance.remove()
        print(f">> 7. {read_SLList_as_string(instance)}")
        self.assertEqual(read_SLList_as_string(instance), 'abcde')

if __name__ == '__main__':
    unittest.main()
