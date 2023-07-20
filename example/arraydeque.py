def new_array(n = 0, h = ''):
    return [h for _ in range(n)]

class ArrayDeque:
    def __init__(self, iterate=[]):
        self._initialize(iterate);

    def _initialize(self, iterate):
        self.a = new_array(max(1, 2 * len(iterate)))
        self.j = 0
        self.n = max(0, len(iterate))
        for i in range(0, len(iterate)):
            self.a[(i + self.j) % len(self.a)] = iterate[i]

    def get(self, i):
        return self.a[(i + self.n) % len(self.a)]

    def set(self, i, x):
        index = (i + self .n) % len(self.a)
        temp = self.a[index]
        self.a[index] = x
        return temp

    def add(self, i, x):
        if self.n + 1 > len(self.a):
            self.resize()
        if i < self.n / 2:
            for k in range(0, i):
                self.a[(k + self.j - 1) % len(self.a)] = self.a[(k + self.j) % len(self.a)]
                self.a[(k + self.j) % len(self.a)] = ''
            self.j = (self.j - 1) % len(self.a)
        else:
            for k in range(self.n - 1, i - 1, -1):
                self.a[(k + self.j + 1) % len(self.a)] = self.a[(k + self.j) % len(self.a)]
                self.a[(k + self.j) % len(self.a)] = ''
        self.a[(i + self.j) % len(self.a)] = x
        self.n += 1

    def remove(self, i):
        x = self.get(i)
        if i < self.n / 2:
            for k in range(i, 0, -1):
                self.a[(k + self.j) % len(self.a)] = self.a[(k + self.j - 1) % len(self.a)]
                self.a[(k + self.j - 1) % len(self.a)] = ''
            self.j = (self.j + 1) % len(self.a)
        else:
            for k in range(i, n - 1):
                self.a[(k + self.j) % len(self.a)] = self.a[(k + self.j + 1) % len(self.a)]
                self.a[(k + self.j + 1) % len(self.a)] = ''
        self.n -= 1
        if len(self.a) > 3 * self.n:
            self.resize()

    def resize(self):
        b = new_array((max(1, 2 * self.n)))
        for i in range(0, self.n):
            b[i] = self.a[(self.j + i) % len(self.a)]
        self.a = b
        self.j = 0
