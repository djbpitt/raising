#!/bin/bash
# Use Saxon HE to run raise.xsl

if test "$1" = "-?" -o "$1" = "?" -o $# -eq 0; then
    echo "Usage:  raise.sh INPUT OUTPUT [options] [p1='val1' p2='val2' ...]"
    echo "Java options that may be helpful:"
    echo "  -Xms128m (initial Java heap size, defaults to max(128m?, 1/64 of real memory))"
    echo "  -Xmx512m (maximum Java heap size, defaults to min(1G, 1/4 of real memory))"
    echo "Saxon parameters that may be helpful:"
    echo "  debug=yes"
    echo "  th-style={th, ana, xmlid}"
    exit 0
elif test $# -lt 2; then
    echo "raise.sh:  2 arguments needed (input, output)"
    exit 1
fi

JOPTS= # Java options
SOPTS= # Saxon options
for i do
    case "$i" in
	-Xm* ) JOPTS="$JOPTS $i";;
	-*:* ) SOPTS="$SOPTS $i";;
	*=*  ) SOPTS="$SOPTS $i";;
    esac
done
    	

SAX="${SAX_HOME:-/opt/local/bin/saxon-he/saxon9he.jar}"

### echo /usr/bin/time -l /usr/bin/java $JOPTS -jar $SAX -l -s:$1 -xsl:raise.xsl -o:$2 $SOPTS
/usr/bin/java $JOPTS -jar $SAX -l -s:$1 -xsl:raise.xsl -o:$2 $SOPTS

### time /usr/bin/java $JOPTS -jar $SAX -l -s:$1 -xsl:raise.xsl -o:$2 $SOPTS
