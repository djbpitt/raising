<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    exclude-result-prefixes="xs"
    version="3.0">
  
<xsl:output method="xml" indent="no"/>
    <xsl:mode on-no-match="shallow-copy"/>
    
    <xsl:template match="*[matches(@ana, '[Ss]tart')]">
        <xsl:element name="{name()}">
            <xsl:for-each select="@*[not(name() = 'ana')]">
                <xsl:attribute name="{name()}">
                    <xsl:value-of select="current()"/>
                </xsl:attribute>
            </xsl:for-each>
            <xsl:attribute name="ana">
                <xsl:value-of select="start"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
    <xsl:template match="*[matches(@ana, '[Ee]nd')]">
        <xsl:element name="{name()}">
            <xsl:for-each select="@*[not(name() = 'ana')]">
                <xsl:attribute name="{name()}">
                    <xsl:value-of select="current()"/>
                </xsl:attribute>
            </xsl:for-each>
            <xsl:attribute name="ana">
                <xsl:value-of select="end"/>
            </xsl:attribute>
            <xsl:apply-templates/>
        </xsl:element>
    </xsl:template>
    
  
</xsl:stylesheet>