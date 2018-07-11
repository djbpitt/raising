<?xml version='1.0'?>
<xsl:stylesheet 
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>

<!--* A stylesheet which performs the identity transform:
    * For purposes of the XPath 1.0 data model, the output
    * is the same as the input.  (But no DTD ...)
    *-->

 <xsl:template match='comment()'>
  <xsl:comment>
   <xsl:value-of select="."/>
  </xsl:comment>
 </xsl:template>
 
 <xsl:template match='processing-instruction()'>
  <xsl:variable name="pitarget" select="name()"/>
  <xsl:processing-instruction name="{$pitarget}">
   <xsl:value-of select="."/>
  </xsl:processing-instruction>
 </xsl:template>

 <xsl:template match="/">
  <xsl:apply-templates/>
 </xsl:template>

 <xsl:template match="@*|*">
  <xsl:copy>
   <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
 </xsl:template>
 
</xsl:stylesheet>

