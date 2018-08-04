<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:x="http://lmnl-markup.org/ns/xLMNL"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    
    xmlns:th="urn:trojan-horses"
    exclude-result-prefixes="xs math x"
    version="3.0">
    
    <xsl:strip-space elements="*"/>
    <xsl:preserve-space elements="x:span"/>

    <xsl:output indent="yes"/>
    
    <!-- xsl:mode/@on-no-match copies namespaces, so -->
    <xsl:template match="node() | @*">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="node() | @*"/>
        </xsl:copy>
    </xsl:template>
    
    
    <xsl:template match="/*">
        <xsl:apply-templates select="sonneteer/sonnet"/>
    </xsl:template>
    
    <xsl:template match="sonnet">
       <xsl:copy copy-namespaces="no">
           <xsl:copy-of select="@*"/>
           <xsl:namespace name="th">urn:trojan-horses</xsl:namespace>
           <xsl:apply-templates/>
       </xsl:copy>
    </xsl:template>
    
    <xsl:template match="x:span">
        <xsl:apply-templates/>
    </xsl:template>
    
    <xsl:template match="x:start | x:end">
        <xsl:element name="{@name}">
            <xsl:apply-templates select="@*"/>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="x:start/@rID">
        <xsl:variable name="gi" select="../@name"/>
        <xsl:attribute name="th:sID" namespace="urn:trojan-horses">
            <xsl:value-of select="$gi"/>
            <xsl:number level="any" count="x:start[@name=$gi]"/>
        </xsl:attribute>
    </xsl:template>
    
    <xsl:template match="x:end/@rID">
        <xsl:variable name="gi" select="../@name"/>
        <xsl:attribute name="th:eID" namespace="urn:trojan-horses">
            <xsl:value-of select="$gi"/>
            <xsl:number level="any" count="x:end[@name=$gi]"/>
        </xsl:attribute>
    </xsl:template>
    
</xsl:stylesheet>