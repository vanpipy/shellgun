from arraystack import ArrayStack

class DualArrayDeque:
    def __init__(self):
        self._initialize()

    def _initialize(self):
        self.front = ArrayStack()
        self.back = ArrayStack()

    def size(self):
        return self.front.size() + self.back.size()

    def get(self, i):
        if i < self.front.size():
            return self.front.get(self.front.size() - i - 1)
        else:
            return self.back.get(i - self.front.size())

    def set(self, i, x):
        if i < self.front.size():
            self.front.set(self.front.size() - i - 1, x)
        else:
            self.back.set(i - self.front.size(), x)

    def add(self, i, x):
        if i < self.front.size():
            self.front.add(self.front.size() - i, x)
        else:
            self.back.add(i - self.front.size(), x)
        self.balance()

    def remove(self, i):
        if i < self.front.size():
            x = self.front.remove(i)
        else:
            x = self.back.remove(i - self.front.size())
        self.balance()
        return x

    def balance(self):
        n = self.size()
        mid = int(n / 2)
        if 3 * self.front.size() < self.back.size() or 3 * self.back.size() < self.front.size():
            f = ArrayStack()
            for i in range(0, mid):
                f.add(i, self.get(i))
            b = ArrayStack()
            for i in range(0, n - mid):
                b.add(i, self.get(mid + i))
            self.front = f
            self.back = b
