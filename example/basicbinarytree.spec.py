import unittest
from basicbinarytree import BasicBinaryree

tree = BasicBinaryree()

class TestBinaryTree(unittest.TestCase):
    def test_setup(self):
        root = BasicBinaryree.Node(0)
        tree.r = root
        node = BasicBinaryree.Node(1)
        node.parent = root
        root.left = node
        node = BasicBinaryree.Node(2)
        node.parent = root
        root.right = node
        node = BasicBinaryree.Node(3)
        node.parent = root.left
        root.left.left = node
        node = BasicBinaryree.Node(4)
        node.parent = root.left
        root.left.right = node
        node = BasicBinaryree.Node(5)
        node.parent = root.right
        root.right.left = node
        node = BasicBinaryree.Node(6)
        node.parent = root.right
        root.right.right = node
        self.interat_items()

    def interat_items(self):
        size = tree.size(tree.r)
        height = tree.height(tree.r)
        self.assertEqual(size, 7)
        self.assertEqual(height, 3)
        depth = tree.depth(tree.r)
        self.assertEqual(depth, 0)
        depth = tree.depth(tree.r.left)
        self.assertEqual(depth, 1)
        depth = tree.depth(tree.r.right)
        self.assertEqual(depth, 1)
        depth = tree.depth(tree.r.left.left)
        self.assertEqual(depth, 2)
        tree.traverse(tree.r)

if __name__ == '__main__':
    unittest.main()
