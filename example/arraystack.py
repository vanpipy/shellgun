def new_array(n = 0, h = ''):
    return ['' for _ in range(n)]

class ArrayStack:
    def __init__(self, iterate=[]):
        self._initialize(iterate)

    def _initialize(self, iterate):
        self.a = new_array()
        self.n = 0
        for i in iterate:
            self.add(self.n, i)

    def get(self, i):
        return self.a[i]

    def set(self, i, x):
        temp = self.a[i]
        self.a[i] = x
        return temp

    def add(self, i, x):
        if len(self.a) == self.n:
            self._resize()

        self.a[i + 1:self.n + 1] = self.a[i:self.n]
        self.a[i] = x
        self.n += 1

    def remove(self, i):
        temp = self.a[i]
        self.a[i:self.n - 1] = self.a[i + 1:self.n] 
        self.a[self.n - 1] = ''
        self.n -= 1

        if len(self.a) > 3 * self.n:
            self._resize()

        return temp

    def size(self):
        return self.n

    def _resize(self):
        b = new_array(max(1, 2 * self.n))
        b[0:self.n] = self.a[0:self.n]
        self.a = b
