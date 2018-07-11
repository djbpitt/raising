# Repo conventions

These are conventions for organizing the repository, proposed for discussion and evaluation. This preamble will be revised once we have agreed on a protocol.

## Main repo

The main repo has several subdirectories:

* `input` for all input files and all canonical results
* one directory for each solution to the task (at the time of writing, these are `accumulators`, `inside-out`, `python_string`, `python_xml`, `right-sibling`, and `regex`, but more may be added as we think of new solutions)
* `doc` for our Balisage paper and the Balisage author-kit artifacts
* `lib` for any shared code
* `testing` for data and code related to testing for correctness or performance

The subdirectory names and their contents are discussed below. 

## Four input types, each in a separate subdirectory of an `input` directory

The main repo contains a single `input` directory with four separate subdirectories, one for each type of input, with the following directory names:

1. `input/basic` Uses Trojan attributes in `th:` namespace. No overlap, no non-Trojan attributes, no non-Trojan empty elements. Basic test of whether the method works.
2. `input/extended` As above, but with non-Trojan attributes (on start-markers only) and with non-Trojan empty elements. Makes sure that the method doesn’t over-generalize.
3. `input/overlap` Uses Trojan attribute in the `th:` namespace. Simple example of overlapping hierarchies to see what the method produces. Four possible outcomes (I think): a) throws an error, b) raises as much as it can without creating overlap and leaves other markers unraised, c) raises everything, moving tags (as it were) to force proper nesting, or d) creates overlapping markup, which is not well formed.
4. `input/frankenstein` Uses `@ana` and `@loc`. Raising all flattened elements that use `@ana` and `@loc` is guaranteed to be well-formed. Other flattened elements, not to be raised on the pass we are discussing, may use other markup (e.g., the `<seg>` elements). I would suggest that for _Frankenstein_ we put the flattened version in the TEI namespace if that’s what it’s in in Real Life, which means that the output must respect that namespace.



## Contents of input directory

Each of the four input subdirectories described above _must_ include two versions of each logically distinct input file, named 

* _filename_`.xml`, which must be raised
* `target.`_filename_`.xml`, which is what it should be raised to

where _filename_ uniquely identifies each logically distinct input file.

Each input directory _may_ also include (in a subdirectory called `aux`) files used to create `flattened.`_filename_`.xml`, such as `original.`_filename_`.xml` and a flattening script. This genetic subdirectory is optional because information about how the files were flattened is not crucial for the purpose of raising them. The contents and filenames in the `aux` subdirectory are not standardized.

The _Frankenstein_ data uses two forms of start- and end-marker:

* empty TEI elements with `@ana` attributes whose values are `start` or `end`, coindexed by the `@loc` attribute
* `tei:seg` elements with `@xml:id` attributes whose values end in `_start` or `_end`, coindexed by the part of the `@xml:id` attribute before that suffix

All other data uses co-indexed `@th:sID` and `@th:eID` attributes in namespace `http://www.blackmesatech.com/2017/nss/trojan-horse` to signal start- and end-markers.  (At the time of writing we make no use of the `@th:soleID` or `@th:doc` attributes.)

## Raising requirements for all four input types

When raising elements marked with `@th:*`: remove all `@th:*` attributes and the relevant namespace declaration.

When raising (in _Frankenstein_) elements marked with `@ana`: remove `@ana`, refactor `@loc` as `@xml:id`. 

When raising (in _Frankenstein_) elements marked with `@xml:id`: include `@xml:id` on the raised element, with the prefix (before `_start` or `_end`) of the input value.

## Code directories

There is one code subdirectory in the main repo for each method, called `accumulators`, `inside-out`, `python_string`, `python_xml`, `right-sibling`, and `regex` (etc.).

### Code of the solution

Each code directory _must_ contain, as a single file (if possible) `raise` with an appropriate filename extension (e.g., `raise.xsl`, `raise.py`, `raise.sh`). The same file should work for the first three of our four input types: basic, extended, and overlap. If _Frankenstein_ input requires a different transformation file, it should be called `raise_frankenstein.xsl`, etc. Notes:

* If we write multiple versions of any given method, their names should have the form `raise` + _infix_ + `.` + _extension_.   For example, versions written for XSLT 1.0 and 3.0 might be `raise_1.0.xsl` and `raise_3.0.xsl`; versions which differ in using a function or a named template might be `raise_f.xsl` and `raise_t.xsl`.  The simplest version (the one for someone to look at first to understand the method) should be `raise.xsl`. 
* To avoid operating-system-specific command-line oddities with regex, regular expressions should be either in a Python file (`raise.py`) or a sed file (`raise.sed`).  The latter may be invoked by a shell script.

### Output of the solution

Code directories _must_ contain a subdirectory called `output` that contains the results of the raising operations on the input files.  The `output` directory should contain sub-subdirectories matching those of `input`.  The output for an input file whose name is of the form `flattened.` + _filename_ + `.xml` should be `raised.` + _filename_ + `xml`. For example, the result of raising `input/basic/flattened.xml` would be in `.../output/basic/raised.xml`. If an attempt at raising produces no output (e.g. because the method dies on that particular input), an empty output file may be left to signal the failure.  If possible, a file named _filename_ + `.stderr` should be provided to record the error(s) raised.

When there are multiple versions of the implementation (e.g. `raise_1.0` and `raise_3.0`), and when we test with multiple processors (e.g. xsltproc, Saxon 6.5.3, Saxon 9.8 HE), the output filename should take the form `raised_` + _version_ + `_` + _processor_ + `.xml`.

### Readme and shell scripts

Code directories _must_ contain a very brief markdown file called `README.md` that explains how to run the transformation. It should not, at least for now explain how the code works (that’s in our paper); its purpose is just to tell users what they have to type to produce output. It should also include dependency information, e.g., Python 3 but not Python 2, XSLT 3.0 but not XSLT 1.0.

Code directories _may_ optionally contain a shell script or Windows batch file to run the transformations that use that code. These should be called `raise.sh` or `raise.bat`. If the shell script depends on a particular shell or on system-specific configuration information (e.g., how to run saxon on the command line may differ from user to user), that should be documented in the `README.md` file. Include this only if you find it personally useful.

### Anything else ###

Additional files go in an optional subdirectory called `aux`. For example, the Python files were developed in a Jupyter notebook interface, and the notebook files will be placed in `aux`.

### Coding conventions

Each XSLT stylesheet should accept a parameter named `debug`, which can be used to guard debugging code (typically surrounded by `<xsl:if test="$debug">...</xsl:if>`).

To minimize the effect of the debugging code on the runtime of the final product, in XSLT 3.0 the parameter should be declared with `static="yes"`.  (If this is done, we can add `use-when="$debug"` to the `xsl:message` or other debugging code, and dispense with the surrounding `xsl:if`.)

To eliminate the need for separate stylesheets for the different styles of markers, stylesheets can (should?) also accept a parameter named `th-style` with values `th`, `ana`, or `xmlid`, which can be used to signal which kind of marker the stylesheet should process.  

## The `doc` directory

The `doc` directory will contain our Balisage paper, a stylesheet named `local.xsl`, and a subdirectory named `balisage` with the Balisage authors' kit (stylesheets, sample document and its images, etc.).  The main purpose of `local.xsl` is to redefine various parameters so that the CSS and XSLT stylesheets do not need to be in the same directory as the document.

## The `lib` directory 

As we attempt to improve our code, we may find ourselves reusing bits (for example, functions to determine whether a given node is or is not a start- or end-marker).  To simplify maintenance, modules containing such reused code should be placed in the `lib` directory.

## The `testing` directory 

*At the time of writing, it's not clear exactly what will need to go here; the following proposal will need revision in the light of experience.*

The `testing` directory has several subdirectories:

* `bin` for testing scripts, processing scripts, etc.
* `raw` for raw test output (if, for example, we acquire timing data by copying stderr and stdout into files to be parsed for the times, the raw logs go here).
* `reports` for final output of a test script

It also contains a `README.md` file to record any special information needed.

For the moment, we assume all test reports will be XML, either in an ad hoc vocabulary or in XHTML.

A test report should begin with a summary, but should normally either contain or link to full data on the test results.  If full data and summary are in separate files, the filename should have the form `full.` or `summary.` + _yyyymmddThhmmss.ss_ + '.xml' or `.xhtml`.  If they are in the same document, the filename prefix should be `report.`.

If the test report is selective (only certain input data, only certain methods), the file name should use infixes to signal what it covers, and the meaning of the infixes used should be recorded in `README.md`.

We give test reports names include a creation time in order to allow ourselves to keep more than one set of test results around.
