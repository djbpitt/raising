<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="no"/>
    <!--
        Input document properties:
        
        1. The document is in no namespace
        2. Only Trojan milestones have @ana attributes, the values of which start with (are not necessarily
            equal to) 'start' or 'end' (case-insensitive). Actual values are 'start', 'Start', and 'startTag',
            and the corresponding end values. There are no other uses of @ana.
        3. @loc holds a unique identifier that can be used to match up start- and end-tags
        4. There are no attributes in the document other than @ana and @loc
        
        Output requirements:
        
        1. Raise Trojan milestones as container elements where possible
        2. Remove @ana attributes
        3. Copy the @loc attribute value as the value of a new @xml:id attribute
    -->
    <!-- identity template (all modes) -->
    <xsl:template match="@* | node()" mode="#all">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- recursive function that does the raising -->
    <xsl:function name="th:raise">
        <xsl:param name="input" as="document-node()"/>
        <xsl:choose>
            <xsl:when test="exists($input//@ana)">
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
    <xsl:template
        match="*[@ana eq 'start'][@loc eq following-sibling::*[@ana eq 'end'][1]/@loc]">
        <!-- innermost start-tag -->
        <xsl:element name="{name()}">
            <!-- textual content of raised element-->
            <xsl:attribute name="xml:id" select="@loc"/>
            <xsl:copy-of
                select="following-sibling::node()[following-sibling::*[@loc eq current()/@loc]]"/>
        </xsl:element>
    </xsl:template>
    <!-- nodes inside new wrapper -->
    <xsl:template
        match="node()[preceding-sibling::*[@ana eq 'start'][1]/@loc eq following-sibling::*[@ana eq 'end'][1]/@loc]"/> 
    <!-- end-tag for new wrapper -->
    <xsl:template
        match="*[@ana eq 'end'][@loc eq preceding-sibling::*[@ana eq 'start'][1]/@loc]"
    />
</xsl:stylesheet>
