<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="th xs">
    <xsl:output method="xml" indent="no"/>
    <!-- identity templates, 1.0 style -->
    <xsl:template match="@* | node()" mode="loop">
        <xsl:call-template name="identity"/>
    </xsl:template>
    <xsl:template name="identity" match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    <!-- named template, called recursively -->
    <xsl:template name="raise">
        <xsl:param name="input"/>
        <xsl:choose>
            <xsl:when test="descendant::*/@th:sID">
                <xsl:variable name="result">
                    <xsl:apply-templates select="$input" mode="loop"/>
                </xsl:variable>
                <xsl:call-template name="raise">
                    <xsl:with-param name="input" select="$result"/>
                </xsl:call-template>
            </xsl:when>
            <xsl:otherwise>
                <xsl:copy-of select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- templates for document nodes (original and created) -->
    <xsl:template match="/">
        <xsl:call-template name="raise">
            <xsl:with-param name="input" select="."/>
        </xsl:call-template>
    </xsl:template>
    <xsl:template match="/" mode="loop">
        <xsl:apply-templates/>
    </xsl:template>
    <!-- start-tag, content, end-tag -->
    <xsl:template match="*[@th:sID]">
        <!-- innermost start-tag -->
        <xsl:variable name="sID" select="@th:sID"/>
        <xsl:choose>
            <xsl:when test="following-sibling::*[@th:eID][1]/@th:eID = $sID">
                <xsl:element name="{name()}">
                    <xsl:copy-of
                        select="following-sibling::node()[following-sibling::*/@th:eID = current()/@th:sID]"
                    />
                </xsl:element>
            </xsl:when>
            <xsl:otherwise>
                <xsl:call-template name="identity"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    <!-- nodes inside new wrapper -->
    <xsl:template
        match="node()[preceding-sibling::*[@th:sID][1]/@th:sID = following-sibling::*[@th:eID][1]/@th:eID]"/>
    <xsl:template match="*[@th:eID]">
        <xsl:variable name="eID" select="@th:eID"/>
        <xsl:choose>
            <xsl:when test="preceding-sibling::*[@th:sID][1]/@th:sID = $eID"/>
            <xsl:otherwise>
                <xsl:call-template name="identity"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
</xsl:stylesheet>
