<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="xs"
    version="1.0">
    <xsl:output method="xml" indent="no"/>
    <xsl:template match="/*">
        <!--
            is there a way to declare the th: namespace on the root element, 
            to avoid having the declaration copied onto all of its children? In 3.0
            we can use <xsl:namespace>. With a literal result element we can just
            declare it, but how do we do that in 1.0 if we don't know the name of the 
            root element in advance?
        -->
        <xsl:copy>
            <xsl:apply-templates/>
        </xsl:copy>
    </xsl:template>
    <xsl:template match="*">
        <xsl:element name="{name()}">
            <xsl:attribute name="th:sID">
                <xsl:value-of select="generate-id()"/>
            </xsl:attribute>
        </xsl:element>
        <xsl:apply-templates/>
        <xsl:element name="{name()}">
            <xsl:attribute name="th:eID">
                <xsl:value-of select="generate-id()"/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>
