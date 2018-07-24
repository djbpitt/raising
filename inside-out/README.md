# inside-out

## Files

### Trojan markup

* **raise.xsl** Trojan markup, does not recur below children of root
* **raise-deep.xsl** Trojan markup, full recursion
* **raise_two-pass.xsl** Experimental; does not do anything interesting yet

### Frankenmarkup

* **raise-frankensteinColl.xsl** Trojan markup in collection of files, full recursion. Adapts raise_deep.xsl, so that the th:raise function runs not over a document-node() but a container element()
* **raise_frankenstein.xsl** 
