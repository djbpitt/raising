import sys
import re

start = re.compile(r'(<[^>]+?)th:sID\s*?=\s*[\'"]\w+?[\'"](.*?)\/(>)', re.S)
end =   re.compile(r'(<)(\S+?)\s+[^>]*?th:eID=[\'"]\w+[\'"][^>]*?\/(>)', re.S)

with open(sys.argv[1], 'r') if len(sys.argv) > 1 else sys.stdin as f:
	doc = f.read()
	interim = start.sub(r'\1\2\3', doc)
	result = end.sub(r'\1/\2\3', interim)
	print(result)
