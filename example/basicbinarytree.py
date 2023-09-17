class BasicBinaryree:
    class Node:
        def __init__(self, x):
            self.x = x
            self.left = self.right = self.parent = None

    def __init__(self):
        self._initialize()

    def _initialize(self):
        self.nil = None
        self.r = None

    def depth(self, u):
        d = 0
        while u != self.r:
            u = u.parent
            d += 1
        return d

    def size(self, u):
        if u == self.nil:
            return 0
        return 1 + self.size(u.left) + self.size(u.right)

    def height(self, u):
        if u == self.nil:
            return 0
        return 1 + max(self.height(u.left), self.height(u.right))

    def traverse(self, u):
        if u == self.nil:
            return
        print(u.x)
        self.traverse(u.left)
        self.traverse(u.right)
