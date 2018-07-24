#!/bin/bash

# Use xsltproc to run raise_xslt10.xsl

# raise_xslt10_xsltproc.sh:  Run raise_xslt10.xsl on
# given input repeatedly until there are no further changes
# (or until you have run 100 times).

# Revisions:
# 16 July 2018 : CMSMcQ : first version of this shell script

if test "$1" = "-?" -o "$1" = "?" -o $# -eq 0; then
    echo "Usage:  raise_xslt10_xsltproc.sh INPUT OUTPUT [options] [p1='val1' p2='val2' ...]"
    echo "  This shell script runs raise_xslt10 repeatedly, until the output stops changing."
    exit 0
elif test $# -lt 2; then
    echo "raise_xslt10_xsltproc.sh:  2 arguments needed (input, output)"
    exit 1
fi

# Some basic variables
CURDIR=`pwd`
ACC1="$CURDIR/output/tmp.accumulator.1.xml"
ACC2="$CURDIR/output/tmp.accumulator.2.xml"
TRANSFORM=raise_xslt10.xsl
MAX=100
SOFAR=0

# Set up input and output (these change on each round)
INDOC=$1
OUTDOC=$2
cp -p $INDOC $ACC1

# Now run until it stops moving (or you hit MAX)
while [ $SOFAR -lt $MAX ]; do
  SOFAR=$[$SOFAR + 1]
  xsltproc --timing --output $ACC2 $TRANSFORM $ACC1
  diff -q $ACC1 $ACC2 > /dev/null
  if [ $? -eq 0 ]; then 
      echo "After $SOFAR runs, fixed point has been reached."
      mv $ACC2 $OUTDOC
      rm $ACC1
      exit 0
  else
      ### mv $ACC1 $ACC1.$SOFAR.xml
      echo "After run $SOFAR, output differs from input."
      mv $ACC2 $ACC1
  fi
done
echo "Fixed point not reached in $SOFAR runs"
exit 1
