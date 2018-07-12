from xml.dom.pulldom import CHARACTERS, START_ELEMENT, parseString, END_ELEMENT

output = []
with open('../input/basic/flattened.xml') as input:
    for event, node in parseString(input.read()):
        if event == START_ELEMENT:
            if node.hasAttribute('th:eID'): # Trojan end tag  
                output.append('</')
            else: # Trojan start tags and non-Trojan elements
                output.append('<')
            output.append(node.nodeName)
            for attname, attvalue in node.attributes.items(): # remove Trojan attributes and namespace declaration
                if not (attname.startswith('th:') or attname == 'xmlns:th'):
                    output.append(' ' + attname + '="' + attvalue + '"')
            output.append('>')
        if event == END_ELEMENT: 
            if not (node.hasAttribute('th:sID') or node.hasAttribute('th:eID')): # non-Trojan only
                output.append('</' + node.localName + '>')
        elif event == CHARACTERS:
            output.append(node.data)
print("".join(output))
