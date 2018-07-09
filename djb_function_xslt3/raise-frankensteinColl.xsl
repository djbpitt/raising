<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xpath-default-namespace="http://www.tei-c.org/ns/1.0"  xmlns:pitt="https://github.com/ebeshero/Pittsburgh_Frankenstein"    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="#all" version="3.0">
    <xsl:output method="xml" indent="no"/>
    <!--2018-07-07 ebb: This stylesheet works to raise "trojan elements" from the inside out, this time over a collection of Frankenstein files output from collation. It also adapts djb's function to process an element node rather than a document node in memory to perform its recursive processing. -->
   <!--<xsl:mode on-no-match="shallow-copy"/>-->
<xsl:template match="@* | node()" mode="#all">
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@* | node()"/>
       </xsl:copy>
    </xsl:template>
    <xsl:variable name="C10-coll" as="document-node()+" select="collection('../input/frankenstein/c10-coll/')"/>  
    <xsl:function name="th:raise">
        <xsl:param name="input" as="element()"/>
        <xsl:choose>
            <xsl:when test="exists($input//@ana)">
                <xsl:variable name="result" as="element()">
                    <div type="collation">
                        <xsl:apply-templates select="$input" mode="loop"/>                            
                    </div>
                </xsl:variable>
                <xsl:sequence select="th:raise($result)"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>  
   <xsl:template match="/">
       <xsl:for-each select="$C10-coll//TEI">
           <xsl:variable name="currentP3File" as="element()" select="current()"/>
           <xsl:variable name="filename">
              <xsl:text>target-</xsl:text><xsl:value-of select="tokenize(base-uri(), '/')[last()]"/>
           </xsl:variable>
         <xsl:variable name="chunk" as="xs:string" select="substring-after(substring-before(tokenize(base-uri(), '/')[last()], '.'), '_')"/> 
           <xsl:result-document method="xml" indent="yes" href="target-c10-coll/{$filename}">
        <TEI>
            <xsl:apply-templates select="descendant::teiHeader"/>
        <text>
            <body>
                <xsl:apply-templates select="descendant::div[@type='collation']"/>
            </body>
        </text>
        </TEI>
         </xsl:result-document>
       </xsl:for-each>
      
   </xsl:template>
 <xsl:template match="teiHeader">
     <teiHeader>
         <fileDesc>
         <titleStmt><xsl:apply-templates select="descendant::titleStmt/title"/></titleStmt>
         <xsl:copy-of select="descendant::publicationStmt"/>
         <xsl:copy-of select="descendant::sourceDesc"/>
     </fileDesc>
     </teiHeader>
 </xsl:template>
    <xsl:template match="titleStmt/title">
        <title>
            <xsl:text>Bridge Phase 4:</xsl:text><xsl:value-of select="tokenize(., ':')[last()]"/>
        </title>
    </xsl:template>
    <xsl:template match="div[@type='collation']">
        <xsl:sequence select="th:raise(.)"/>
    </xsl:template>
    <xsl:template match="div[@type='collation']" mode="loop">
        <xsl:apply-templates/>
    </xsl:template> 
    <xsl:template match="*[@ana='start' and @loc eq following-sibling::*[@ana eq 'end'][1]/@loc]">
     <xsl:variable name="currNode" select="current()" as="element()"/>
        <xsl:variable name="currLoc" select="@loc" as="xs:string"/>
        <xsl:element name="{name()}">
                <xsl:attribute name="xml:id">
                    <xsl:value-of select="@loc"/>
                </xsl:attribute>
            <xsl:copy-of select="following-sibling::node()[following-sibling::*[@loc = $currLoc]]"/>
        </xsl:element>
    </xsl:template>
   <!-- <xsl:template match="div//*[not(@ana)][not(preceding-sibling::*[@ana eq 'start'][1]/@loc eq following-sibling::*[@ana eq 'end'][1]/@loc)]">
       <xsl:copy-of copy-namespaces="no" select="."/>
   </xsl:template>-->
<!--suppressing nodes that are being reconstructed. --> 
    <xsl:template       match="node()[preceding-sibling::*[@ana eq 'start'][1]/@loc eq following-sibling::*[@ana eq 'end'][1]/@loc]"/>
      
      
  <xsl:template match="*[@ana='end'][@loc = preceding-sibling::*[@ana='start'][1]/@loc]"/>
    
</xsl:stylesheet>


