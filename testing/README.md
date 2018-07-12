# Testing directory #

This directory houses information relevant to testing.

At the time of writing, it's mostly empty, but the idea is that scripts for running tests, scripts for processing test output, and test results will all end up here.

## Catalogs ##

The directory contains a number of catalogs which record information about various entities relevant for testing. At the time of writing, these include:

* `inputs.xml`:  a list of input documents, with path to the document and (when available) path to the original (pre-flattening) and target (post-raising) versions.  (The target and original forms are not necessarily the same file.)

* `methods.xml`:  a list of methods for solving the problem.  For each method, several implementions may be listed.

* `processors.xml`: a list of processors

## Profiles ##

The goal is that an intelligent test harness can read the catalogs and run appropriate tests, based possibly on a profile which selects particular inputs, particular methods, particular processors, or particular implementation variants.  Such a harness might be an interactive program or a process that reads the catalogs and a profile document and produces a shell script for running the tests.

A mockup of a profile is in `profile.all.xml` but at the moment it's a symbol of a pious hope, not a working profile.

## Open questions ##

Open questions include the following.

The exact form of the shell command to run a particular test will vary with:
* input document
* method / algorithm
* implementation
* processor
* whether we are checking correctness or gathering time and space data

Each of these may affect the others.  For example, since the input files use different syntaxes, diferent inputs will require different command lines; depending on the implementation this may take the form of a different implementation or a run-time option passed to a single implementation; depending on the processor, run-time options may be passed in different ways.

* Where and how does the form of command used get recorded?

* How do we handle patterns of usage, so as to avoid having to write (and maintain) a separate command line for every tuple of input file, processor, implementation, and set of runtime options?




