<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="#all">
    <xsl:template match="root">
        <root><xsl:apply-templates mode="shallow-to-deep" /></root> 
    </xsl:template>
    <xsl:template match="*[@th:sID]" mode="shallow-to-deep">
        <xsl:variable name="ns" select="namespace-uri()"/>
        <xsl:variable name="ln" as="xs:string" select="local-name()"/>
        <xsl:variable name="sID" as="xs:string" select="@th:sID"/>
        
        <!--* 1: handle this element *-->
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@* except @th:sID"/>
            <xsl:apply-templates select="following-sibling::node()[1]"
                mode="shallow-to-deep">
            </xsl:apply-templates>
        </xsl:copy>
        
        <!--* 2: continue after this element *-->
        <xsl:apply-templates select="following-sibling::*
            [@th:eID = $sID 
            and namespace-uri()=$ns
            and local-name()=$ln]
            /following-sibling::node()[1]"
            mode="shallow-to-deep">
        </xsl:apply-templates>
    </xsl:template>
    <xsl:template match="text()
        | comment() 
        | processing-instruction 
        | *[not(@th:*)]"
        mode="shallow-to-deep"
        >
        <xsl:copy-of select="."/>
        <xsl:apply-templates 
            select="following-sibling::node()[1]"
            mode="shallow-to-deep"/>
    </xsl:template>
    <xsl:template match="*[@th:eID]" mode="shallow-to-deep">
        
        <!--* No action necessary *-->
        <!--* We do NOT recur to our right.
        * We leave it to our parent to do that.
        *-->      
        
    </xsl:template>
    
</xsl:stylesheet>