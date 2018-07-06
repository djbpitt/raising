<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xpath-default-namespace="http://www.tei-c.org/ns/1.0"  xmlns:pitt="https://github.com/ebeshero/Pittsburgh_Frankenstein"
    xmlns="http://www.tei-c.org/ns/1.0"  
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" exclude-result-prefixes="xs" version="3.0">
<!--2018-07-05 ebb: retooling this to work recursively from "outside in", that is, from processing elements intended to be "outer" elements holding elements inside them, and to process elements with no more content to raise last.  -->
<!--<xsl:mode on-no-match="shallow-copy"/>-->
    <xsl:variable name="P3-BridgeColl-C10" as="document-node()+" select="collection('bridge-P3-C10')"/>
    <xsl:variable name="testerDoc" as="document-node()" select="doc('bridge-P3-C10/P3-fThomas_C10.xml')"/>  
<!--In Bridge Construction Phase 4, we are converting self-closed edition elements into full elements to "unflatten" the edition files . -->    
   <xsl:template match="/">
       <xsl:for-each select="$P3-BridgeColl-C10//TEI">
           <xsl:variable name="currentP3File" as="element()" select="current()"/>
           <xsl:variable name="filename">
              <xsl:text>P4-</xsl:text><xsl:value-of select="tokenize(base-uri(), '/')[last()] ! substring-after(., 'P3-')"/>
           </xsl:variable>
         <xsl:variable name="chunk" as="xs:string" select="substring-after(substring-before(tokenize(base-uri(), '/')[last()], '.'), '_')"/> 
           <xsl:variable name="flat-not-p" select="$currentP3File//*[@ana and @loc and not(self::p)]" as="element()+"/>
           <xsl:result-document method="xml" indent="yes" href="frankenColl-output/oi-{$filename}">
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
        <div type="collation">
           <!--ebb: stylesheet produces all nodes, but heavily duplicates them with this general xsl:apply-templates call
               <xsl:apply-templates/>-->
            
       <xsl:apply-templates select="descendant::*[@loc and @ana='start'][@loc = following-sibling::*[@ana='start']/following-sibling::*[@ana='end']/@loc]"/>  
            
           <!--ebb: If I wanted to start from "inside out", to raise the innermost level of the hierarchy first, I'd uncomment this. 
               <xsl:apply-templates select="descendant::*[@loc = following-sibling::*[@loc][1]/@loc]"/> -->
            
        <!--ebb: Starting processing from the "outside in". -->
          <!--  <xsl:apply-templates select="*[@ana='start' and @loc = following-sibling::*[@ana][1]/following-sibling::*[@ana='end']/@loc]"/> -->   
        </div>
    </xsl:template>   
    
    <xsl:template match="*[@ana='start' and @loc = following-sibling::*[@ana][1]/following-sibling::*[@ana='end']/@loc]">
        <xsl:comment>This template rule for "outer-hull" elements is firing now.</xsl:comment>
        <xsl:variable name="currentNode" as="node()" select="current()"/>
        <xsl:variable name="currentLoc" as="xs:string" select="@loc"/>
        <xsl:comment>The value of currentLoc is <xsl:value-of select="$currentLoc"/></xsl:comment>
        <xsl:variable name="thisEndTag" select="following-sibling::*[@loc = $currentLoc and @ana='end']" as="element()"/>
        <xsl:variable name="thisEndTagName" select="$thisEndTag/name()" as="xs:string"/> 
        <xsl:element name="{name()}">
            <xsl:for-each select="@*[not(name() = 'ana')]">
                <xsl:attribute name="{name()}">
                    <xsl:value-of select="current()"/>
                </xsl:attribute>   
            </xsl:for-each>
          <xsl:apply-templates select="following-sibling::node()[following-sibling::*[@loc][1]]"/>
            <xsl:choose><xsl:when test="following-sibling::*[@loc and @ana='start'][1][@loc ne $currentLoc]"><xsl:apply-templates select="following-sibling::*[@loc and @ana='start'][1][@loc ne $currentLoc]"/></xsl:when>
            <xsl:otherwise>
                <xsl:apply-templates select="following-sibling::node()[preceding-sibling::*[@loc = $currentNode/following-sibling::*[@loc][1]/@loc and @ana='end']][following-sibling::*[@loc = $currentLoc]]"/>
            </xsl:otherwise>
            </xsl:choose>
        </xsl:element>
     <!--  <xsl:apply-templates select="$currentNode/following-sibling::node()[preceding-sibling::*[@loc][1][@loc = $currentLoc and @ana='end']][following-sibling::*[@loc and @ana='start'][1][@loc = $currentNode/following-sibling::*[@loc][1]/@loc] or self::*[@loc and @ana='start'][@loc = $currentNode/following-sibling::*[@loc][1]/@loc]]"/>-->
    </xsl:template>
    
 <xsl:template match="*[@loc = following-sibling::*[@loc][1]/@loc]">
     <xsl:variable name="currNode" select="current()" as="node()"/>
        <xsl:variable name="currLoc" select="@loc" as="xs:string"/>
        <xsl:comment>This template rule for text- and sig-bearing loc nodes is firing now.</xsl:comment>
        <xsl:element name="{name()}">
            <xsl:for-each select="@*[not(name() = 'ana')]">
                <xsl:attribute name="{current()/name()}">
                    <xsl:value-of select="current()"/>
                </xsl:attribute>
            </xsl:for-each>
            <xsl:copy-of select="following-sibling::node()[following-sibling::*[@loc = $currLoc]]"/>
        </xsl:element>
    </xsl:template>
    <xsl:template match="div[@type='collation']//*[not(@loc)]">
        <xsl:copy-of select="."/>
    </xsl:template>    
  <xsl:template match="*[@ana='end'][@loc = preceding-sibling::*[@ana='start']/@loc]">
    </xsl:template>
</xsl:stylesheet>


