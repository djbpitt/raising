# Accumulator solution

This solution uses an XSLT 3.0 accumulator to perform the task.

## Shell scripts ##

`raise_he.sh` calls Saxon HE to run `raise.xsl`. The first argument is the input file name, the second the output file name.  Later arguments can specify Java or Saxon options.

Other shell scripts may / will be added to run other processors.

## Options

Useful options include: 

* `-XmsNNNNm` to set initial Java heap size to NNNN megabytes. 
* `-XmxNNNNm` to set maximum Java heap size to NNNN megabytes. 

* `-t` to ask Saxon to record time and memory usage from its point of view. 
* `debug=...` to specify whether debugging messages should be issued.  Expects values `yes` and `no`. 
* `thstyle=...` to specify what style of marker is in use: `th`, `ana`, or `xmlid`. 


