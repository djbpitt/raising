# Status

Divided by method (e.g., accumulators, inside-out, etc.) and then subdivided by input directory (e.g., basic, extended, etc.). Mapping (expressed with `→`) means that the output has no XML-significant differences from the target (verified with [diffxml](https://sourceforge.net/projects/diffxml/files/diffxml/) unless otherwise noted). 

## accumulators

## inside-out

### basic

* `flattened.xml` → `raised.xml`

### extended

* `flattened.xml` → `raised.xml`

### frankenstein

* `flattened.xml` → `raised.xml`

### brown

* `r02_flattened.xml` → `r02_raised.xml`
* `Corpus_flattened.xml` → `Corpus_raised.xml`

Note: Full corpus file are too large to compare with `xmldiff` or similar tools. Both output and target have been wrapped with `xmllint --format`, with output as `Corpus_raised_wrapped.xml` and `Corpus_target_wrapped.xml`, and then compared with regular `diff`. (`xmllint` is installed by default with Anaconda Python.)

## python_string

### basic

* `flattened.xml` → `raised.xml`

### extended

* `flattened.xml` → `raised.xml`

### frankenstein

* `flattened.xml` → `raised.xml`

### brown

* `r02_flattened.xml` → `r02_raised.xml`
* `Corpus_flattened.xml` → `Corpus_raised.xml`

Note: Full corpus file are too large to compare with `xmldiff` or similar tools. Both output and target have been wrapped with `xmllint --format`, with output as `Corpus_raised_wrapped.xml` and `Corpus_target_wrapped.xml`, and then compared with regular `diff`. (`xmllint` is installed by default with Anaconda Python.)

## python_xml

## outside-in

## regex

## right-sibling

## tumbling-windows