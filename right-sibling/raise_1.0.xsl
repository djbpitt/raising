<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
  exclude-result-prefixes="xs th"
  version="1.0">
  
  <!--* right-sibling/raise.xsl:  translate a document with start-
      * and end-markers into conventional XML
      *-->

  <!--* Revision history:
      * 2018-07-10 : CMSMcQ : make this file by stripping down
      *     uyghur.ittc.ku.edu/lib/shallow-to-deep.xsl.
      *     Use library functions for marker recognition.
      *-->
  
  <!--*
    * 
    * Input:  XML document.
    * 
    * Parameters:  
    *
    *   debug:  'yes' or 'no'
    * 
    *   th-style: keyword 'th', 'ana', or 'xmlid':
    *         'th' uses @th:sID and @th:eID 
    *         'ana' uses @ana=start and @ana=end
    *         'xmlid' uses @xml:id with values ending _start, _end
    *
    * 
    * Output:  XML document with virtual elements raised (made
    * into content elements).
    *-->

  
  <!--****************************************************************
      * 0 Setup (parameters, global variables, ...)
      ****************************************************************-->
  <xsl:import href="../lib/identity.xsl"/>

  <!--* What kind of Trojan-Horse elements are we merging? *-->
  <!--* Expected values are 'th' for @th:sID and @th:eID,
      * 'ana' for @ana=start|end
      * 'xmlid' for @xml:id matching (_start|_end)$
      *-->
  <xsl:param name="th-style" select=" 'th' " static="yes"/>

  <!--* debug:  yes or no *-->
  <xsl:param name="debug" as="xs:string" select=" 'no' " static="yes"/>

  <xsl:output indent="no"/>

  
  <!--****************************************************************
      * 1 Identity transform (default behavior outside the
      * container)
      ****************************************************************-->

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

 <xsl:template match="@*">
  <xsl:copy/>
 </xsl:template>

 <xsl:template match="*" name="shallow-copy">
  <xsl:copy>
   <xsl:apply-templates select="@*|node()"/>
  </xsl:copy>
 </xsl:template>

 <!--* special rule for root *-->
 <xsl:template match="/*" priority="100">
   <xsl:element name="{name()}" namespace="{namespace-uri()}">
     <xsl:copy-of select="namespace::*
			  [not(. = 'http://www.blackmesatech.com/2017/nss/trojan-horse')
			  or not($th-style='th')]"/>
     <xsl:apply-templates select="@*"/>
     <!--* ah.  The standard error.
	 <xsl:apply-templates select="node()" mode="shallow-to-deep"/>
	 *-->
     <xsl:apply-templates select="node()[1]" mode="shallow-to-deep"/>
     </xsl:element>
 </xsl:template>
 
  
  <!--****************************************************************
      * 2 Shifting to shallow-to-deep mode / Container element
      *-->
  <!--* When we hit the container element, shift to shallow-to-deep
      * mode.  We know it's the container element, because it has
      * at least one marker element as a child.
      *-->
  
  <xsl:template match="*[*[@th:sID or @th:eID]]">
    <xsl:choose>
      <xsl:when test="$th-style = 'th'">
	<xsl:copy>
	  <xsl:apply-templates select="@*"/>
	  <xsl:apply-templates mode="shallow-to-deep" select="child::node()[1]"/>
	</xsl:copy>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="shallow-copy"/>
      </xsl:otherwise>
    </xsl:choose>	
  </xsl:template>
  
  <xsl:template match="*[*[@ana='start' or @ana='end']]">
    <xsl:choose>
      <xsl:when test="$th-style = 'ana'">
	<xsl:copy>
	  <xsl:apply-templates select="@*"/>
	  <xsl:apply-templates mode="shallow-to-deep-ana" select="child::node()[1]"/>
	</xsl:copy>
      </xsl:when>
      <xsl:otherwise>
	<xsl:call-template name="shallow-copy"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <!--****************************************************************
      * 3 Start-marker:  make an element and carry on
      *-->

  <xsl:template match="*[@th:sID]" mode="shallow-to-deep">
    <xsl:variable name="ns" select="namespace-uri()"/>
    <xsl:variable name="ln" as="xs:string" select="local-name()"/>
    <xsl:variable name="sID" as="xs:string" select="@th:sID"/>

    <!--* 1: handle this element *-->
    
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="no-th"/>
      <xsl:apply-templates select="following-sibling::node()[1]"
			   mode="shallow-to-deep">
      </xsl:apply-templates>
    </xsl:copy>
    
    <!--* 2: continue after this element *-->
    <xsl:apply-templates select="following-sibling::*[@th:eID = $sID 
				 and namespace-uri()=$ns
				 and local-name()=$ln]
				 /following-sibling::node()[1]"
			 mode="shallow-to-deep">
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="*[@ana='start']" mode="ana-shallow-to-deep">
    <xsl:variable name="ns" select="namespace-uri()"/>
    <xsl:variable name="ln" as="xs:string" select="local-name()"/>
    <xsl:variable name="ID" as="xs:string" select="@loc"/>
    
    <!--* 1: handle this element *-->
    <xsl:copy>
      <xsl:apply-templates select="@*" mode="no-ana"/>
      <xsl:apply-templates select="following-sibling::node()[1]"
			   mode="ana-shallow-to-deep">
      </xsl:apply-templates>
    </xsl:copy>
    
    <!--* 2: continue after this element *-->
    <xsl:apply-templates select="following-sibling::*[@loc = $ID 
				 and namespace-uri()=$ns
				 and local-name()=$ln]
				 /following-sibling::node()[1]"
			 mode="ana-shallow-to-deep">
    </xsl:apply-templates>
  </xsl:template>


  <!--****************************************************************
      * 4. no-th and no-ana modes
      ****************************************************************-->
  <!--* These modes suppress and rename attributes selectively. *-->
  
  <!--* no-th suppresses @th:* and copies everything else. *-->
  <xsl:template match="@th:sID" mode="no-th" priority="10"/>
  <xsl:template match="@th:eID" mode="no-th" priority="10"/>
  
  <xsl:template match="@*" mode="no-th" priority="1">
    <xsl:copy/>
  </xsl:template>

  <!--* no-ana suppresses @ana, renames @loc, and copies everything else. *-->  
  <xsl:template match="@ana" mode="no-ana" priority="10"/>
  
  <xsl:template match="@loc" mode="no-ana" priority="10">
    <xsl:attribute name="xml:id">
      <xsl:value-of select="."/>
    </xsl:attribute>
  </xsl:template>
  
  <xsl:template match="@*" mode="no-ana" priority="1">
    <xsl:copy/>
  </xsl:template>  

  <!--****************************************************************
      * 5 End-markers
      *-->

  <xsl:template match="*[@th:eID]" mode="shallow-to-deep">

    <xsl:variable name="ns" select="namespace-uri()"/>
    <xsl:variable name="ln" as="xs:string" select="local-name()"/>
    <xsl:variable name="eID" as="xs:string" select="@th:eID"/>
    
    <!--* no action necessary *-->
    <!--* we do NOT recur to our right.  We leave it to our parent to do 
	that. *-->
    
  </xsl:template>

  
  <!--****************************************************************
      * 6 Other elements, in shallow-to-deep mode 
      *-->
  
  <!--* If these contain Trojan Horse descendants, they need to
      * be processed recursively; otherwise just copy
      * Oddly this is almost identical to what deep-to-shallow does
      *-->  
  <xsl:template match="*[not(@th:sID or @th:eID)]"
		mode="shallow-to-deep">
    <xsl:apply-templates select="."/>
    <!--* and recur to right sibling *-->
    <xsl:apply-templates select="following-sibling::node()[1]"
			 mode="shallow-to-deep"/>
  </xsl:template>
  
  <!--****************************************************************
      * 7 Other node types, in shallow-to-deep mode 
      *-->
  <xsl:template match="comment() | processing-instruction()"
		mode="shallow-to-deep">
    <xsl:copy/>
    <xsl:apply-templates select="following-sibling::node()[1]"
			 mode="shallow-to-deep"/>
  </xsl:template>
  
  <xsl:template match="text()"
		mode="shallow-to-deep">
    <xsl:copy/>
    <xsl:apply-templates select="following-sibling::node()[1]"
			 mode="shallow-to-deep"/>
  </xsl:template>

  
</xsl:stylesheet>
