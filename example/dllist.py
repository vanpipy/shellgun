class DLList:
    class Node:
        def __init__(self, x):
            self.x = x
            self.prev = ''
            self.next = ''

    def __init__(self):
        self._initialize()

    def _initialize(self):
        self.n = 0
        self.dummy = DLList.Node('')
        self.dummy.prev = self.dummy
        self.dummy.next = self.dummy

    def get_node(self, i):
        if i < self.n / 2:
            p = self.dummy.next
            while i > 0:
                p = p.next
                i -= 1
        else:
            p = self.dummy
            i = self.n - i
            while i > 0:
                p = p.prev
                i -= 1
        return p

    def set(self, i, x):
        w = self.get_node(i)
        y = w.x
        w.x = x
        return y

    def get(self, i):
        u = self.get_node(i)
        return u.x

    def add(self, i, x):
        u = DLList.Node(x)
        w = self.get_node(i)
        w.prev.next = u
        u.prev = w.prev
        u.next = w
        w.prev = u
        self.n += 1
        return u

    def remove(self, i):
        w = self.get_node(i)
        u = w.next
        u.prev = w.prev
        u.prev.next = u
        w.prev = None
        w.next = None
        self.n -= 1
        return w
