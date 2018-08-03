<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="#all">

    <!--* Setup *-->
    <xsl:output method="xml" indent="no"/>

    <!--* Experimental:  try adding a key *-->
    <xsl:key name="start-markers" match="*[@th:sID]" use="@th:sID"/>
    <xsl:key name="end-markers" match="*[@th:eID]" use="@th:eID"/>

    <!--* th:raise(.):  raise all innermost elements within the document
	passed as parameter *-->
    <xsl:function name="th:raise">
        <xsl:param name="input" as="document-node()"/>
        <xsl:message>raise() called with <xsl:value-of select="count($input//*)"/>-element document (<xsl:value-of select="count($input//*[@th:sID])"/> Trojan pairs)</xsl:message>
        <xsl:choose>
            <xsl:when test="exists($input//*[@th:sID eq following-sibling::*[@th:eID][1]/@th:eID])">
                <!--* If we have more work to do, do it *-->
                <xsl:variable name="result" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$input" mode="loop"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:sequence select="th:raise($result)"/>
            </xsl:when>
            <xsl:otherwise>
                <!--* We have no more work to do, return the input unchanged. *-->
                <xsl:message>raise() returning.</xsl:message>
                <xsl:sequence select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <!--* On the input document node, call th:raise() *-->
    <xsl:template match="/">
        <xsl:sequence select="th:raise(.)"/>
    </xsl:template>

    <!--* Loop mode (applies to document node only). *-->
    <!--* Loop mode for document node:  just apply templates in
	default unnamed mode. *-->
    <xsl:template match="/" mode="loop">
        <xsl:variable name="raise-starts" as="element()+"
            select="
                *[@th:sID eq
                following-sibling::*[@th:eID][1]/@th:eID]"/>
        <xsl:variable name="raise-ends" as="element()+" select="key('end-markers', $raise-starts)"/>
        <xsl:variable name="raise-contents" as="node()*"
            select="
                for $raise-start in $raise-starts
                return
                    $raise-start/following-sibling::node()[. &lt;&lt; key('end-markers', $raise-start/@th:sID)]"/>
        <xsl:apply-templates>
            <xsl:with-param name="raise-starts" as="element()+" select="$raise-starts" tunnel="yes"/>
            <xsl:with-param name="raise-contents" as="node()*" select="$raise-contents" tunnel="yes"/>
            <xsl:with-param name="raise-ends" as="element()+" select="$raise-ends" tunnel="yes"/>
        </xsl:apply-templates>
    </xsl:template>

    <xsl:template match="*">
        <xsl:param name="raise-starts"/>
        <xsl:param name="raise-contents"/>
        <xsl:param name="raise-ends"/>
        <xsl:choose>
            <xsl:when test="current() intersect $raise-starts">
                <xsl:variable name="end-marker" as="element()" select="key('end-markers', @th:sID)"/>
                <xsl:copy copy-namespaces="no">
                    <xsl:copy-of select="@* except @th:*"/>
                    <xsl:copy-of
                        select="current()/following-sibling::node()[. &lt;&lt; $end-marker]"/>
                </xsl:copy>
            </xsl:when>
            <xsl:when test="current() intersect $raise-contents or current() intersect $raise-ends"/>
            <xsl:otherwise>
                <xsl:copy copy-namespaces="no">
                    <xsl:copy-of select="@*"/>
                    <xsl:apply-templates select="node()"/>
                </xsl:copy>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

    <!-- nodes inside new wrapper:  do nothing -->
    <xsl:template
        match="node()[preceding-sibling::*[@th:sID][1]/@th:sID eq following-sibling::*[@th:eID][1]/@th:eID]"/>

    <!-- end-tag for new wrapper -->
    <xsl:template match="*[@th:eID eq preceding-sibling::*[@th:sID][1]/@th:sID]"/>

</xsl:stylesheet>
