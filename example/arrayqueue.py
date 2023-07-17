def new_array(n = 0, h = ''):
    return [h for _ in range(n)]

class ArrayQueue:
    def __init__(self):
        self._initialize();

    def _initialize(self):
        self.a = new_array()
        self.j = 0
        self.n = 0

    def add(self, x):
        if self.n + 1 > len(self.a):
            self.resize()
        self.a[(self.j + self.n % len(self.a))] = x
        self.n += 1
        return True

    def remove(self):
        x = self.a[self.j]
        self.a[self.j] = ''
        self.j = (self.j + 1) % len(self.a)
        self.n -= 1
        if len(self.a) >= 3 * self.n:
            self.resize()
        return x

    def resize(self):
        b = new_array(max(1, 2 * self.n))
        for k in range(0, self.n):
            b[k] = self.a[(self.j + k) % len(self.a)]
        self.a = b
        self.j = 0
