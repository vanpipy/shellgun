class SLList:
    class Node:
        def __init__(self, x):
            self.x = x
            self.next = None

    def __init__(self):
        self._initialize()

    def _initialize(self):
        self.n = 0
        self.head = None
        self.tail = None

    def push(self, x):
        u = SLList.Node(x)
        u.next = self.head
        self.head = u
        if self.n == 0:
            self.tail = u
        self.n += 1
        return x

    def pop(self):
        if self.n == 0:
            return None
        x = self.head.x
        self.head = self.head.next
        self.n -= 1
        if self.n == 0:
            self.tail = None
        return x

    def add(self, x):
        u = SLList.Node(x)
        if self.n == 0:
            self.head = u
        else:
            self.tail.next = u
        self.tail = u
        self.n += 1
        return True

    def remove(self):
        """
        Cannnot remove from the tail cause the tail cannot access the previous node.next,
        even reset the tail as None, but the previous node.next is still to legacy tail node.
        """
        pass
