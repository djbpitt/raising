#!/bin/bash
# Use xsltproc to run raise.xsl

if test "$1" = "-?" -o "$1" = "?" -o $# -eq 0; then
    echo "Usage:  raise.sh INPUT OUTPUT [options]"
    echo "xsltproc options that may be helpful:"
    echo "  --repeat (run 20 times)"
    echo "  --profile (dump profiling info)"
    echo "  --stringparam name value (stylesheet parameters)"
    echo "  --stringparam debug yes|*no (turns debug messaging on)"
    echo "  --stringparam th-style ana|*th (how are markers written?)"
    exit 0
elif test $# -lt 2; then
    echo "raise.sh:  2 arguments needed (input, output)"
    exit 1
fi

xsltproc --timing $3 $4 $5 $6 $7 $8 $9 --output $2 raise_1.0.xsl $1

