from xml.dom.pulldom import CHARACTERS, START_ELEMENT, parseString, END_ELEMENT

output = []
with open('Thomas_C10.xml') as input:
    for event, node in parseString(input.read()):
        if event == START_ELEMENT:
            if node.getAttribute('ana') == 'end':
                output.append('</' + node.tagName + '>')
            else: # Trojan start tags and non-Trojan
                output.append('<')
            output.append(node.nodeName)
            for attname, attvalue in node.attributes.items():
                if not(attname.startswith('ana:')):
                    output.append(' ' + attname + '="' + attvalue + '"')
            output.append('>')
        if event == END_ELEMENT:
            if not node.hasAttribute('ana'):
                output.append('</' + node.localName + '>')
        elif event == CHARACTERS:
            output.append(node.data)
print("".join(output))
