from xml.dom.pulldom import CHARACTERS, START_ELEMENT, parseString, END_ELEMENT

output = []
with open('flattened.xml') as input:
    for event, node in parseString(input.read()):
        if event == START_ELEMENT:
            if node.hasAttribute('th:eID'):    
                output.append('</')
            else: # Trojan start tags and non-Trojan
                output.append('<')
            output.append(node.nodeName)
            for attname, attvalue in node.attributes.items():
                if not(attname.startswith('th:')):
                    output.append(' ' + attname + '="' + attvalue + '"')
            output.append('>')
        if event == END_ELEMENT:
            if not node.hasAttribute('th:sID') and not node.hasAttribute('th:eID'):
                output.append('</' + node.localName + '>')
        elif event == CHARACTERS:
            output.append(node.data)
print("".join(output))
