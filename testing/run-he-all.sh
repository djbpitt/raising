# run-he-all.sh
# A quick and dirty shell script to run HE on all inputs
# NOT YET WORKING, SET ASIDE FOR THE MOMENT

# invocation:  cd .../raising; ./testing/run-he-all.sh

################################################################
# Usage
################################################################
function usage() {
    echo "Usage:  run-he-all.sh STYLESHEET [options] [p1='val1' p2='val2' ...]"
    echo "Must be run from raising directory (root of repo)."
    echo "Java options that may be helpful:"
    echo "  -Xms128m (initial Java heap size, defaults to max(128m?, 1/64 of real memory))"
    echo "  -Xmx512m (maximum Java heap size, defaults to min(1G, 1/4 of real memory))"
    echo "Saxon parameters that may be helpful:"
    echo "  debug=yes"
    echo "  th-style={th, ana, xmlid}"
}

################################################################
# runonce()
################################################################
function runonce() {
    # globals: METHOD
    # $1 STYLESHEET
    # $2 INPUT
    # $3 SHELL SCRIPT
    # $4 VARIANT FLAT, e.g. "_xslt10" or "_3.0" or ""

    local STYLESHEET="$1"
    local INPUT="$2"
    local SCRIPT="$3"

    local IFILE="${INPUT##*/}"
    local IPAT0="${INPUT#input/}"
    local IPATH="${IPAT0%/*}"
    local FSTEM="${IFILE%.xml}"
    local OUTPUT="output/${IPATH}/raised_${FSTEM}_HE.xml"

    cd "${METHOD}"
    echo "<run>";
    echo "  <date>"`date`"</date>";
    echo "  <syst>${HOSTNAME}</syst>";
    echo "  <proc>HE</proc>";
    echo "  <meth>${METHOD}</meth>";
    echo "  <impl>${STYLESHEET}</impl>";
    echo "  <input>${INPUT}</input>";
    echo "  <output>${OUTPUT}</output>";
    echo "  <processor-messages>";
    # echo "  <!--* arg 1 = $1 *-->"
    # echo "  <!--* arg 2 = $2 *-->"
    # echo "  <!--* arg 3 = $3 *-->"
    # echo "  <!--* arg 4 = $4 *-->"
    # echo "  <!--* IFILE = $IFILE *-->"
    # echo "  <!--* IPAT0 = $IPAT0 *-->"
    # echo "  <!--* IPATH = $IPATH *-->"
    # echo "  <!--* FSTEM = $FSTEM *-->"
    # echo "  <!--* OUTPUT = $OUTPUT *-->"
    # echo "  <!--* time (${SCRIPT} $INPUT $OUTPUT; ... ); *-->"
    time (./${SCRIPT} ../$INPUT $OUTPUT;
	  echo "  </processor-messages>";
	  echo "  <timing>");
    echo "  </timing>";
    echo "</run>";
    echo;
    cd ..
}

################################################################
# Check arguments
################################################################

if test "$1" = "-?" -o "$1" = "?" -o $# -eq 0; then
    usage
    exit 0
elif test $# -lt 1; then
    usage
    exit 1
fi
    
################################################################
# Variables
################################################################

SSPATH="$1"
METHOD="${SSPATH%/*}"
SS="${SSPATH#*/}"

CURPATH=`pwd`
CURDIR="${CURPATH##*/}"

ISODATE=`date "+%Y-%m-%d"`
OUTDIR="testing/${ISODATE}"
OUTFN="testdata.${METHOD}.xml"
OUTPATH="${OUTDIR}/${OUTFN}"

HOSTNAME=`hostname -s`

BASIC="input/basic/flattened.xml \
  input/basic/basho.xml \
  input/basic/coleridge-quote.xml"
EXTENDED="input/extended/flattened.xml \
  input/extended/basho.xml \
  input/extended/coleridge-quote.xml"
OVERLAP="input/overlap/page-and-para.xml\
  input/overlap/basho.xml \
  input/overlap/frost.xml \
  input/overlap/peergynt"
BROWN0="input/brown/r02.0052 \
  input/brown/r02.0125 \
  input/brown/r02.0225 \
  input/brown/r02.0329 \
  input/brown/r02.0368 \
  input/brown/r02.0441 \
  input/brown/r02.1041 \
  input/brown/r02.1477"
BROWN1="input/brown/r02_flattened.xml"
BROWN2="input/brown/Corpus_flattened.xml"
LOCAL1="input/local/flattened.l18.xml"
LOCAL2="input/local/flattened.brown02.xml \
  input/local/flattened.brown04.xml \
  input/local/flattened.brown16.xml"
LOCAL3="input/local/flattened.brown64.xml"

################################################################
# where are we?  If not in 'raising', bail.
################################################################

if test "$CURDIR" != "raising"; then
    echo "You need to run this from the raising repo's root directory."
    echo "PWD returns " `pwd`
    echo "CURPATH is $CURPATH"
    echo "CURDIR is $CURDIR"
fi

################################################################
# OK, now do the work
################################################################

mkdir -p $OUTDIR

echo "<testdata>" > $OUTPATH
echo "<p>Automated test run, using HE, on ${SSPATH}.</p>" >> $OUTPATH

# BROWN1 and LOCAL1:  single Brown samples, v slow sometimes
# LOCAL2:  set of 2, 4, 16 Brown samples (no longer 64)
# LOCAL3:  64 Brown samples
# BROWN2:  entire Brown Corpus 
for i in $BASIC $EXTENDED $OVERLAP $BROWN0 $BROWN1 $LOCAL1 $LOCAL2
do
    echo -n `date` " ... " 
    echo runonce "${SS}" "${i}" "raise_he.sh" "" 
    runonce "${SS}" "${i}" "raise_he.sh" "" >> $OUTPATH 2>&1
done
    
echo "</testdata>" >> $OUTPATH

