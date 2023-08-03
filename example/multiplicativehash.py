import random

def new_array(n = 0, h = ''):
    return [h for _ in range(n)]

w = 32

class MultiplicativeHash():
    def __init__(self):
        pass

    def initialize(self):
        self.d = 1
        self.t = new_array(pow(2, self.d), [])
        self.z = random.random() * 20
        self.n = 0

    def hash(self, x):
        return (self.z * hash(x) % pow(2, w) >> (w - self.d))

    def find(self, x):
        l = self.t[self.hash(x)]
        for y in l:
            if y == x:
                return y
        return False

    def add(self, x):
        if self.find(x) != '':
            return False
        if self.n + 1 > len(self.t):
            self.resize()
        self.t[self.hash(x)].append(x)
        self.n += 1
        return True

    def remove(self, x):
        l = self.t[self.hash(x)]
        for y in l:
            if y == x:
                l.remove(y)
                self.n -= 1
                if 3 * n < len(self.t):
                    self.resize()
                return y
        return None

    def size(self):
        return self.n

    def resize(self):
        self.d = 1
        while 1 << self.d <= self.n:
            self.d += 1
        old_t = self.t
        self.t = new_array(pow(2, self.d), [])
        for i in range(len(old_t)):
            for x in old_t[i]:
                self.add(x)

