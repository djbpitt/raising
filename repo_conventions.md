# Repo conventions

These are conventions, proposed for discussion and evaluation, for how to clean up the mess in the repo. This preamble will be revised once we have agreed on a protocol.

## Main repo

The main repo has seven subdirectories, one for all input files and one for each of the six code methods. The subdirectory names and their contents are discussed below. The main repo also contains our Balisage paper and the Balisage author-kit artifacts.

## Four input types, each in a separate subdirectory of an `input` directory

The main repo contains a single `input` directory with four separate subdirectories, one for each type of input, with the following directory names:

1. `input/basic` Uses Trojan attributes in `th:` namespace. No overlap, no non-Trojan attributes, no non-Trojan empty elements. Basic test of whether the method works.
2. `input/extended` As above, but with non-Trojan attributes (on start-markers only) and with non-Trojan empty elements. Makes sure that the method doesn’t over-generalize.
3. `input/overlap` Uses Trojan attribute in the `th:` namespace. Simple example of overlapping hierarchies to see what the method produces. Four possible outcomes (I think): a) throws an error, b) raises as much as it can without creating overlap and leaves other markers unraised, c) raises everything, moving tags (as it were) to force proper nesting, or d) creates overlapping markup, which is not well formed.
4. `input/frankenstein` Uses `@ana` and `@loc`. Raising all flattened elements that use `@ana` and `@loc` is guaranteed to be well-formed. Other flattened elements, not to be raised on the pass we are discussing, may use other markup (e.g., the `<seg>` elements). I would suggest that for _Frankenstein_ we put `flattened.xml` in the TEI namespace if that’s what it’s in in Real Life, which means that the output must respect that namespace.

## Contents of input directory

Each of the four input subdirectories described above _must_ include two files: 

* `flattened.xml`, which must be raised
* `target.xml`, which is what it should be raised to

Each input directory _may_ also include (in a subdirectory called `aux`) files used to create `flattened.xml`, such as `original.xml` and a flattening script. This genetic subdirectory is optional because information about how the files were flattened is not crucial for the purpose of raising them. The contents and filenames in the `aux` subdirectory are not standardized.

## Raising requirements for all four input types

Remove all Trojan markup, including namespace declaration. For _Frankenstein_, refactor `@loc` as `@xml:id`.

## Code directories

There are six code subdirectories inside the main repo, one for each method, called `accumulator`, `inside-out`, `python_string`, `python_xml`, `right-sibling`, and `regex`. 

Each code directory _must_ contain, as a single file (if possible) `raise` with an appropriate filename extension (e.g., `raise.xsl`, `raise.py`). The same file should work for the first three of our four input types: basic, extended, and overlap. If _Frankenstein_ input requires a different transformation file, it should be called `raise_frankenstein.xsl`, etc. Notes:

* If I write the XSLT 1.0 version of inside-out, I’ll call them `raise_3.0.xsl` and `raise_1.0.xsl`; otherwise I’ll stick with just `raise.xsl`. Similarly for other methods that may have multiple implementations.
* To avoid operating-system-specific command-line oddities with regex, I’ll embed the code for the regex method in a Python file called `raise.py`, instead of using sed inside a shell script.

Code directories _must_ contain a subdirectory called `output` that contains the results of the raising operations on the four input files in four sub-subdirectories, all with the filename `raised.xml`. For example, the result of raising the basic input with regex would be in `regex/output/basic/raised.xml`. If raising with the overlap example throws an error and does not produce output, the corresponding output subdirectory _must_ be omitted.

Code directories _must_ contain a very brief markdown file called `README.md` that explains how to run the transformation. It should not, at least for now explain how the code works (that’s in our paper); its purpose is just to tell users what they have to type to produce output. It should also include dependency information, e.g., Python 3 but not Python 2, XSLT 3.0 but not XSLT 1.0.

Code directories _may_ optionally contain a shell script or Windows batch file to run the transformations that use that code. These should be called `raise.sh` or `raise.bat`. If the shell script depends on a particular shell or on system-specific configuration information (e.g., how to run saxon on the command line may differ from user to user), that should be documented in the `README.md` file. Include this only if you find it personally useful.

Additional files go in an optional subdirectory called `aux`. For example, the Python files were developed in a Jupyter notebook interface, and the notebook files will be placed in `aux`.
