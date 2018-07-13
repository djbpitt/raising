import sys
import re

# removes all instances of @ana and changes all instances of @loc to @xml:id
# to account for alternative orders of @ana and @loc:

loc_ana = re.compile(r'(<)([^>]+?)(\sloc="([^>]+?)")([^>]*?)(\sana="start")([^>]*?)/(>)',re.S)
ana_loc = re.compile(r'(<)([^>]+?)(\sana="start")([^>]*?)(\sloc="([^>]+?)")([^>]*?)/(>)',re.S)
ana_end = re.compile(r'(<)([^>]*?)\sana="end"([^>]*?)(>)',re.S)
loc =     re.compile(r'(<)(\S+)[^>]*?\sloc="[^>]*?(>)',re.S)

with open(sys.argv[1], 'r') if len(sys.argv) > 1 else sys.stdin as f:
	doc = f.read()
	interim1 = loc_ana.sub(r'\1\2 xml:id="\4" \7\8',doc)
	interim2 = ana_loc.sub(r'\1\2\4  xml:id="\6" \7\8',interim1)
	interim3 = ana_end.sub(r'\1\2\3\4', interim2)
	result = loc.sub(r'\1/\2\3',interim3)
	print(result)

