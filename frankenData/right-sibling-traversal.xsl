<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="no"/>
    <!--2018-07-07 ebb: Rewriting this to try right-sibling traversal on Frankenstein. -->
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
   <xsl:template match="/">
    <TEI>   <xsl:copy-of select="//teiHeader"/>
    <text><body><div type="collation"> <xsl:apply-templates select="//text/body/div[@type='collation']"/>
    </div></body></text>
<!--ebb:  -->   </TEI>    
   </xsl:template>
 <xsl:template match="div[@type='collation']">
     <xsl:apply-templates select="child::node()[1]" mode="shallow-to-deep"/>
 </xsl:template>  
    <xsl:template match="*[@loc and @ana='start']" mode="shallow-to-deep">
        <xsl:comment>In shallow-to-deep mode, template match on *[@loc and @ana='start'] is matching now.</xsl:comment>
        <!--   <xsl:variable name="ns" select="namespace-uri()"/>-->
        <!--<xsl:variable name="ln" as="xs:string" select="local-name()"/> ebb: Note that local-name() is used for retrieving the part of the name that isn't namespaced. That doesn't apply to the Frankenstein data. -->      
        <xsl:variable name="ln" as="xs:string" select="name()"/>
        <xsl:variable name="sID" as="xs:string" select="@loc"/>
        
        <!--* 1: handle this element *-->
        <xsl:copy>
           <xsl:attribute name="xml:id">
               <xsl:value-of select="@loc"/>
           </xsl:attribute>
            <xsl:apply-templates select="following-sibling::node()[1]" mode="shallow-to-deep">
            </xsl:apply-templates>
        </xsl:copy>
        
        <!--* 2: continue after this element *-->
      <xsl:apply-templates select="following-sibling::*
            [@ana='end' and @loc= $sID 
            and name()=$ln]
            /following-sibling::node()[1]"
            mode="shallow-to-deep">
        </xsl:apply-templates>
    </xsl:template>
  <xsl:template match="text()
        | comment() 
        | processing-instruction 
        | *[not(@loc)]"
        mode="shallow-to-deep"
        >
        <xsl:copy-of select="."/>
        <xsl:apply-templates 
            select="following-sibling::node()[1]"
            mode="shallow-to-deep"/>
    </xsl:template>
    <xsl:template match="*[@loc and @ana='end']" mode="shallow-to-deep">
        <xsl:comment>Template match on *[@loc and @ana='end'] is matching now.</xsl:comment>
        <!--* No action necessary *-->
        <!--* We do NOT recur to our right.
        * We leave it to our parent to do that.
        *-->      
        
    </xsl:template>
   
   
   
</xsl:stylesheet>
