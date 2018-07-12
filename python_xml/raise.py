import sys
from xml.dom.pulldom import CHARACTERS, START_ELEMENT, parseString, END_ELEMENT
from xml.dom.minidom import Document


class Stack(list):
    def push(self, item):
        self.append(item)

    def peek(self):
        return self[-1]


open_elements = Stack()
d = Document()
open_elements.push(d)

with open(sys.argv[1], 'r') if len(sys.argv) > 1 else sys.stdin as input:
    for event, node in parseString(input.read()):
        if event == START_ELEMENT and not node.hasAttribute('th:eID'): # process pseudo-end-tags on END_ELEMENT event
            # Can’t remove attributes from the original, so work with a clone
            clone = node.cloneNode(deep=False)
            if clone.hasAttribute('th:sID'):
                clone.removeAttribute('th:sID')
            if clone.hasAttribute('xmlns:th'):
                clone.removeAttribute('xmlns:th')
            open_elements.peek().appendChild(clone)
            open_elements.push(clone)
        elif event == END_ELEMENT and not node.hasAttribute('th:sID'): # process pseudo-start-tags on START_ELEMENT event
            open_elements.pop()
        elif event == CHARACTERS:
            t = d.createTextNode(node.data)
            open_elements.peek().appendChild(t)
        else:
            continue

result = open_elements[0].toxml()
print(result)
