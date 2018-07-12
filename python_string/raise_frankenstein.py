import sys
from xml.dom.pulldom import CHARACTERS, START_ELEMENT, parseString, END_ELEMENT

def entities(input):
    return input.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
output = []
with open(sys.argv[1], 'r') if len(sys.argv) > 1 else sys.stdin as input:
    for event, node in parseString(input.read()):
        if event == START_ELEMENT:
            if node.hasAttribute('ana') and node.getAttribute('ana') == 'end': # Trojan end-marker
                output.append('</')
            else: # Trojan start-marker and non-Trojan elements
                output.append('<')
            output.append(node.nodeName)
            if not (node.hasAttribute('ana') and node.getAttribute('ana') == 'end'): # no attributes on Trojan end-marker
                for attname, attvalue in node.attributes.items(): # remove Trojan attributes
                    if attname == 'ana':
                        continue
                    elif attname == 'loc':
                        output.append(' xml:id="' + attvalue + '"')
                    else:
                        output.append(' ' + attname + '="' + attvalue + '"')
            output.append('>')
        if event == END_ELEMENT: 
            if not node.hasAttribute('ana'): # non-Trojan only
                output.append('</' + node.nodeName + '>')
        elif event == CHARACTERS:
            output.append(entities(node.data))
print("".join(output))
