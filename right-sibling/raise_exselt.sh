#!/bin/bash
# Use Exselt to run the stylesheet on whatever input the user specifies

if test "$1" = "-?" -o "$1" = "?" -o $# -eq 0; then
    echo "Usage:  raise_exselt.sh INPUT OUTPUT"
    exit 0
elif test $# -lt 2; then
    echo "raise_exselt.sh:  2 arguments needed (input, output)"
    exit 1
fi


STYLESHEET=raise_exselt2016.xsl
MONO=${MONO_HOME:-/usr/local/bin/mono}
EXSELT=${EXSELT_HOME:-/opt/local/Exselt-20160516/exselt/lib/exselt/Exselt.exe}

### Note that the 20160516 version of Exselt does not
### handle relative file paths for the -xml and -o options.
### so we absolutize them.

${MONO} ${EXSELT} -xml:`pwd`/$1 -xsl:`pwd`/${STYLESHEET} -o:`pwd`/$2 $3 $4 $5 $6 $7 $8 $9

### Help on using Exselt.exe command-line interface.
### Available arguments are:
### -apc     Analyze package catalog
### -da      Disable assertions
### -de      Disable xsl:evaluate
### -h       Help
### -icn     Initial context node
### -if      Initial stylesheet function name (has lower priority than initial template name and default template name 'xsl:initial-template')
### -im      Initial mode name
### -it      Initial template name (has higher priority than initial stylesheet function name)
### -ll      Logging level
### -mt      Multiple threads
### -nf      Files naming rules
### -o       Output file name
### -param   (multiple declarations allowed) Initial parameter
### -pc      Package catalog URI
### -q       Silent mode
### -xml     Source XML file name
### -xsl     (required) XSL file name

### See also http://exselt.net/support/documentation/commandline-reference/
