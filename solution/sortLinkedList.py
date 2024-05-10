class ListNode(object):
    def __init__(self, val = 0, next = None):
        self.val = val
        self.next = next

class Solution(object):
    def sortList(self, head):
        root = head
        head = head.next
        root.next = None
        compare = root
        while True:
            start, end = [compare, compare.next]
            if start.val < head.val:
                compare = head
                head = head.next
                compare.next = start
                root = compare
            elif start.val > head.val and head.val >= end.val:
                start.next = head
                head = head.next
                start.next.next = end
            elif start.val > head.val and end.val is None:
                start.next = head
                head = head.next
                start.next.next = end
            elif start.val > head.val and end.val > head.val:
                compare = end.next

            if compare is None or head is None:
                break
        return root

    def createNodes(self, vals = []):
        nodes = [ListNode(v) for v in vals]
        for i in range(len(nodes) - 1):
            nodes[i].next = nodes[i + 1]
        return nodes[0]

    def readNodes(self, head):
        vals = [head.val]
        while head.next is not None:
            head = head.next
            vals.append(head.val)
        return vals

if __name__ == '__main__':
    solution = Solution()
    head = solution.createNodes([-1, 5, 3, 4, 0])
    head = solution.sortList(head)
    result = solution.readNodes(head)
    print(result)
