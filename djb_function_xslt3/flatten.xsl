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
        <xsl:element name="{name()}">
            <xsl:copy-of select="@*"/>
            <xsl:attribute name="th:sID" select="generate-id()"/>
        </xsl:element>
        <xsl:apply-templates/>
        <xsl:element name="{name()}">
            <xsl:attribute name="th:eID" select="generate-id()"/>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
