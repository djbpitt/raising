# Right-sibling traversal solution #

This solution uses a right-sibling traversal of the input to perform the task. 

Two versions:  `raise_1.0.xsl` and `raise_3.0.xsl`, provide general solutions for
XSLT 1.0 and 3.0, respectively.  Both use `apply-templates` for the
traversal.

`raise-frankenstein.xsl` is adapted to raise the Frankenstein novel collection, and processes a teiHeader separately from a portion of the document which contains markup to be raised. This solution is adapted for XSLT 3.0 and trojan-style markers.


## Shell scripts ##

`raise_he.sh` calls Saxon HE to run `raise.xsl`. The first argument is 
the input file name, the second the output file name.  Later arguments 
can specify Java or Saxon options. 

The shell script assumes that the JAR file saxon9he.jar is in
`/opt/local/bin/saxon-he/saxon9he.jar`.  Change the definition
of the variable SAX in the script to adjust to local conditions.

The script `raise_xsltproc.sh` calls xsltproc to run `raise.xsl`. The
first argument is the input file name, the second the output file
name.  Later arguments can specify xsltproc options.  The --timing
option is specified by the shell script.

Other shell scripts may / will be added to run other processors.

## Options

Useful Saxon options include: 

* `-t` to ask Saxon to record time and memory usage from its point of view. 

Useful xsltproc options include: 

* `--repeat` to ask xsltproc to run the transform 20 times 
* `--profile` to ask xsltproc for profiling information 

Stylesheet parameters include: 

* `debug=...` to specify whether debugging messages should be issued.  Expects values `yes` and `no`. 
* `thstyle=...` to specify what style of marker is in use: `th`, `ana`, or `xmlid`. 


