# Brown corpus files

## TODO

* Figure out how to raise full corpus before my coffee gets cold
* Add raised version of full corpus
* Switch full corpus files to GitHub large file storage so that GitHub will stop scolding me

## Files

* `Corpus.xml` Entire Brown corpus as a single TEI file
* `Corpus_flattened.xml` Version flattened with `flatten.xsl` (below)
* `r02.xml` Sample corpus file (56k)
* `r02_flattened.xml` Flattened version of sample
* `r02_raised.xml` Raised version of sample

## Source

<http://www.nltk.org/nltk_data/packages/corpora/brown_tei.zip>

## XSLT utilities

### `flatten.xsl`

```xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math" exclude-result-prefixes="#all"
    version="3.0">
    <xsl:output method="xml" indent="no"/>
    <xsl:template match="/*">
        <xsl:copy>
            <xsl:namespace name="th" select="'http://www.blackmesatech.com/2017/nss/trojan-horse'"/>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="*">
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="th:sID" select="generate-id()"/>
        </xsl:element>
        <xsl:apply-templates/>
        <xsl:copy copy-namespaces="no">
            <xsl:attribute name="th:eID" select="generate-id()"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
```

### `raise.xsl`

```xslt
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="no"/>
    <xsl:template match="@* | node()" mode="#all">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <xsl:function name="th:raise">
        <xsl:param name="input" as="document-node()"/>
        <xsl:choose>
            <xsl:when test="exists($input//*[@th:sID eq following-sibling::*[@th:eID][1]/@th:eID])">
                <xsl:variable name="result" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$input" mode="loop"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:sequence select="th:raise($result)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>
    <xsl:template match="/">
        <xsl:sequence select="th:raise(.)"/>
    </xsl:template>
    <xsl:template match="/" mode="loop">
        <xsl:apply-templates/>
    </xsl:template>
    <xsl:template match="*[@th:sID eq following-sibling::*[@th:eID][1]/@th:eID]">
        <!-- innermost start-tag -->
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@* except @th:sID"/>
            <!-- textual content of raised element-->
            <xsl:copy-of
                select="following-sibling::node()[following-sibling::*[@th:eID eq current()/@th:sID]]"
            />
        </xsl:copy>
    </xsl:template>
    <!-- nodes inside new wrapper -->
    <xsl:template
        match="node()[preceding-sibling::*[@th:sID][1]/@th:sID eq following-sibling::*[@th:eID][1]/@th:eID]"/>
    <!-- end-tag for new wrapper -->
    <xsl:template match="*[@th:eID eq preceding-sibling::*[@th:sID][1]/@th:sID]"/>
</xsl:stylesheet>
```