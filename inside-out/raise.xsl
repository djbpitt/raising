<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
    exclude-result-prefixes="#all">

    <!--* Setup *-->
    <xsl:output method="xml" indent="no"/>

    <!--* Set $debug parameter to any non-null value to output messages *-->
    <xsl:param name="debug" static="yes" required="no"/>

    <!--* Key for finding end-markers; is this faster? *-->
    <xsl:key name="end-markers" match="*[@th:eID]" use="@th:eID"/>

    <!-- 
        Identity template of anything lower than grandchildren of the root
        Just copy; they cannot contain markers
    -->
    <xsl:template match="/*/*/descendant::node()" mode="#all">
        <xsl:sequence select="."/>
    </xsl:template>

    <!-- Traditional identity template for root and its children -->
    <xsl:template match="@* | node()" mode="#all">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- 
        th:raise(.):  raise all innermost elements within the document
        messages controlled by $debug stylesheet parameter
    -->
    <xsl:function name="th:raise">
        <xsl:param name="input" as="document-node()"/>
        <xsl:message use-when="$debug">raise() called with 
            <xsl:value-of select="count($input//*)"/>-element document 
            (<xsl:value-of select="count($input//*[@th:sID])"/> Trojan pairs)</xsl:message>
        <xsl:choose>
            <xsl:when test="exists($input//*[@th:sID eq following-sibling::*[@th:eID][1]/@th:eID])">
                <!-- If we have more work to do, do it -->
                <xsl:variable name="result" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$input" mode="loop"/>
                    </xsl:document>
                </xsl:variable>
                <xsl:sequence select="th:raise($result)"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- We have no more work to do, return the input unchanged. -->
                <xsl:message use-when="$debug">raise() returning.</xsl:message>
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

    <!--
        Innermost start-markers
        @priority needed here and below because otherwise ambiguous with identity templates
    -->
    <xsl:template match="*[@th:sID eq following-sibling::*[@th:eID][1]/@th:eID]" priority="1">
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@* except @th:sID"/>
            <xsl:variable name="end-marker" as="element()" select="key('end-markers', @th:sID)[1]"/>
            <xsl:copy-of select="following-sibling::node()[. &lt;&lt; $end-marker]"/>
        </xsl:copy>
    </xsl:template>

    <!-- nodes inside new wrapper: suppress, since they have alredy been copied -->
    <xsl:template
        match="node()[preceding-sibling::*[@th:sID][1]/@th:sID eq following-sibling::*[@th:eID][1]/@th:eID]"
        priority="1"/>

    <!-- end-tag for new wrapper; suppress because it has already been copied -->
    <xsl:template match="*[@th:eID eq preceding-sibling::*[@th:sID][1]/@th:sID]" priority="1"/>

</xsl:stylesheet>
