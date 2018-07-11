# Tumbling-windows solution #

This solution uses the tumbling window expressions of XQuery 3.1 to perform the task.

## Shell scripts ##

No shell scripts available yet.

## Module structure

The file `raise.xqm` is an XQuery library module, which declares one function
relevant to the user:  `th:raise()`, which accepts a node (e.g. a document node)
as argument.

Currently there are two forms of `th:raise()`, one working top down and the
other bottom up.  The `th:raise()` function just calls one or the other of them.
(Currently it calls `th:raise-inside-out()` because that's the one that took
longer to get working correctly.)

The file `raise.xq` illustrates the use of the library module (and until I clean out
the commented-out code provides a short summary of my attempts to understand
the behavior of early versions of the module that didnt work as expected).

## Options 

None.


