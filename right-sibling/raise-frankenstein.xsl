<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xpath-default-namespace="http://www.tei-c.org/ns/1.0"
    xmlns="http://www.tei-c.org/ns/1.0"   xmlns:pitt="https://github.com/ebeshero/Pittsburgh_Frankenstein"    xmlns:mith="http://mith.umd.edu/sc/ns1#"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" exclude-result-prefixes="#all">
    <xsl:output method="xml" indent="no"/>
    <!--2018-07-29 ebb: XSLT for right-sibling traversal to raise a single flattened Frankenstein document or over a collection of Frankenstein files using a command line Saxon parser with a command like:
   java -jar saxon9he.jar -s:novel-coll/ -xsl:raise-frankenstein.xsl -o:output/frankenstein/novel-coll/ 
    -->
    <!--
        Input document properties:
        
        1. The document is in the TEI namespace and a project-specific pitt namespace.
        2. Trojan milestones are marked on the elements to be raised in the usual way with the th: namespace prefix as @th:sID and @th:eID.

        Output requirements:
        
        1. Raise Trojan milestones as container elements where possible
        2. Convert @th:sID and @th:eID into @xml:id on raising. 
    -->
   <xsl:template match="/">
       <TEI xmlns="http://www.tei-c.org/ns/1.0" xmlns:pitt="https://github.com/ebeshero/Pittsburgh_Frankenstein" xmlns:mith="http://mith.umd.edu/sc/ns1#" xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse">   <xsl:apply-templates select="//teiHeader"/>
    <text><body><div type="collation"> <xsl:apply-templates select="//text/body/div[@type='collation']"/>
    </div></body></text>
</TEI>    
   </xsl:template>
    <xsl:template match="teiHeader">
        <teiHeader>
            <fileDesc>
                <titleStmt><xsl:apply-templates select="descendant::titleStmt/title"/></titleStmt>
                <xsl:copy-of select="descendant::publicationStmt" copy-namespaces="no"/>
                <xsl:copy-of select="descendant::sourceDesc" copy-namespaces="no"/>
            </fileDesc>
        </teiHeader>
    </xsl:template>
    
    <xsl:template match="titleStmt/title">
        <title>
            <xsl:text>Bridge Phase 4:</xsl:text><xsl:value-of select="tokenize(., ':')[last()]"/>
        </title>
    </xsl:template>
    
 <xsl:template match="div[@type='collation']">
     <xsl:apply-templates select="child::node()[1]" mode="shallow-to-deep"/>
 </xsl:template>  
    <xsl:template match="*[@th:sID]" mode="shallow-to-deep">
        <!--   <xsl:variable name="ns" select="namespace-uri()"/>-->
        <!--<xsl:variable name="ln" as="xs:string" select="local-name()"/> ebb: Note that local-name() is used for retrieving the part of the name that isn't namespaced. That doesn't apply to the Frankenstein data. -->      
        <xsl:variable name="ln" as="xs:string" select="name()"/>
        <xsl:variable name="sID" as="xs:string" select="@th:sID"/>
        
        <!--* 1: handle this element *-->
        <xsl:copy copy-namespaces="no">
           <xsl:attribute name="xml:id">
               <xsl:value-of select="@th:sID"/>
           </xsl:attribute>
            <xsl:apply-templates select="following-sibling::node()[1]" mode="shallow-to-deep">
            </xsl:apply-templates>
        </xsl:copy>       
        <!--* 2: continue after this element *-->
      <xsl:apply-templates select="following-sibling::*
            [@th:eID= $sID 
            and name()=$ln]
            /following-sibling::node()[1]"
            mode="shallow-to-deep">
        </xsl:apply-templates>
    </xsl:template>
  <xsl:template match="text()
        | comment() 
        | processing-instruction 
        | *[not(@th:sID) and not(@th:eID)]"
        mode="shallow-to-deep">
        <xsl:copy-of select="." copy-namespaces="no"/>
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
