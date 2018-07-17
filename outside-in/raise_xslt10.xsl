<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
    version="1.0"
    exclude-result-prefixes="xsl xs th">

  <!--* Simple 1.0 implementation of outside-out approach.
      * The stylesheet performs one pass over the input and
      * transforms outermost virtual elements only.
      *
      * To transform the data fully, keep running the stylesheet
      * until the output no longer changes.
      *-->
  
  <xsl:output method="xml" indent="no"/>
  
  <!--****************************************************************
      * 0. Setup 
      ****************************************************************-->
  <!--* Set $debug parameter to 'yes' to output messages *-->
  <xsl:param name="debug" select=" 'no' "/>
  
  <xsl:key name="end-markers" match="*[@th:eID]" use="@th:eID"/>
  <xsl:key name="start-markers" match="*[@th:sID]" use="@th:sID"/>
  
  <!--****************************************************************
      * 1. Default templates (identity transform) 
      ****************************************************************-->
  
  <!-- Traditional identity template for root and its children -->
  <xsl:template match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>
  
  <!--****************************************************************
      * 2. Transition to doing the raising work
      ****************************************************************-->
  <xsl:template match="*[*/@th:sID or */@th:eID]">
    <!--* Copy the container element and its attributes,
	* then call raise-sequence with its children.
	*-->
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:call-template name="raise-sequence">
	<xsl:with-param name="nodes" select="child::node()"/>
      </xsl:call-template>
    </xsl:copy>
  </xsl:template>
  
  <!--****************************************************************
      * 3. Raise-sequence template 
      ****************************************************************-->
  <xsl:template name="raise-sequence">
    <!--* $nodes: the sequence of nodes to work on *-->
    <!--* QUESTION:  does position() work as expected here?
	* or do we need a place-holder? *-->
    <xsl:param name="nodes" />
    <xsl:param name="ids-to-skip" select=" '//' "/>
    
    <xsl:variable name="nodecount" select="count($nodes)"/>
    <xsl:if test="$debug = 'yes' ">
      <xsl:message>raise-sequence called with <xsl:value-of
      select="count($nodes)"/> nodes.</xsl:message>
    </xsl:if>    
    
    <!--* (a) Identify leftmost start-marker.
	* If there is none, return our input; we are done.
	*-->
    <xsl:variable name="start-marker"
		  select="$nodes[@th:sID]
			  [not(
			  contains($ids-to-skip,
			  concat('/', @th:sID, '/')))]
			  [1]"/>
    <xsl:choose>
      <xsl:when test="count($start-marker) = 0">
	<xsl:if test="$debug = 'yes' ">
	  <xsl:message>No start-markers found, raise-sequence stopping with <xsl:value-of
	  select="count($nodes)"/> nodes in the sequence.</xsl:message>
	  <xsl:text>&#xA;</xsl:text>
	  <xsl:comment> No start-markers found, raise-sequence stopping with <xsl:value-of
	  select="count($nodes)"/> nodes in the sequence. </xsl:comment>
	  <xsl:text>&#xA;</xsl:text>
	</xsl:if>
	<xsl:apply-templates select="$nodes"/>
      </xsl:when>
      <xsl:otherwise>
	<!--* assert:  we have a start-marker *-->
	
	<!--* (b) Identify the matching end-marker.
	    * If there is none, add the unmatched sID
	    * to ids-to-skip and try again. *-->
	<xsl:variable name="ID"
		      select="$start-marker/@th:sID"/>
	<!--*
	    <xsl:variable name="end-marker"
	    select="$nodes[@th:eID]
	    [@th:eID = $ID]
	    [1]"/>
	    *-->
	<xsl:variable name="end-marker-candidates"
		      select="key('end-markers', $ID)"/>
	<xsl:variable name="end-marker"
		      select="$end-marker-candidates
			      [ count(. | $nodes) = $nodecount ][1] "/>
	<xsl:choose>
	  <xsl:when test="count($end-marker) = 0">
	    <!--* We have a start- but no matching
		* end-marker.  Make a note to skip this ID
		* and try again.
		*-->
	    <xsl:if test="$debug = 'yes' ">
	      <xsl:message>No matching end-markers found for <xsl:value-of
	      select="$ID"/>.  Trying again.</xsl:message>
	    </xsl:if>
	    <xsl:call-template name="raise-sequence">
	      <xsl:with-param name="nodes" select="$nodes"/>
	      <xsl:with-param name="ids-to-skip"
			      select="concat('/', $ID, $ids-to-skip)"/>
	    </xsl:call-template>
	  </xsl:when>
	  <xsl:otherwise>
	    <!--* assert:  we have a start-marker *-->
	    <!--* assert:  we have an end-marker *-->
	    
	    <!--* (c) Raise the element just identified
		* and call raise-sequence recursively on
		* its children. *-->
	    
	    <!--* (c)(i) Deal with beginning of sequence 
		*-->
	    <!--* The following select expression will
		* have unfortunate properties in long
		* sequences of flattened elements.
		*-->
	    <!--
	    <xsl:if test="$debug = 'yes' ">
	      <xsl:comment>* Prefix for  <xsl:value-of
	      select="$ID"/>. *</xsl:comment>
	    </xsl:if> -->
	    <xsl:apply-templates select="$nodes
					 [following-sibling::*
					 [@th:sID = $ID]]"/>
	    <!--
	    <xsl:if test="$debug = 'yes' ">
	      <xsl:comment>* End prefix for  <xsl:value-of
	      select="$ID"/>. *</xsl:comment>
	      </xsl:if>
	      -->
	    <!--* Possible alternative *-->
	    <!--
		<xsl:apply-templates select="$nodes
		[not(preceding-sibling::*
		[@th:sID = $ID])]"/>
		*-->
	    
	    <!--* (c)(ii) Raise the element. *-->
	    <xsl:variable
		name="children"
		select="$nodes
			    [preceding-sibling::*
			    [@th:sID = $ID]]
			    [following-sibling::*
			    [@th:eID = $ID]]"/>
	    <xsl:if test="$debug = 'yes' ">
	      <xsl:message>Raising  <xsl:value-of
	      select="concat(name($start-marker), ' id=', $ID)"
	      />, recurring on <xsl:value-of select="count($children)"/> children.</xsl:message>
	    </xsl:if>
	    <xsl:element name="{name($start-marker)}"
			 namespace="{namespace-uri($start-marker)}">
	      <xsl:apply-templates
		  select="$start-marker/@*"
		  mode="raising"/>	      
	      <xsl:call-template name="raise-sequence">
		<xsl:with-param
		    name="nodes"
		    select="$nodes
			    [preceding-sibling::*
			    [@th:sID = $ID]]
			    [following-sibling::*
			    [@th:eID = $ID]]"/>
		<xsl:with-param name="ids-to-skip"
				select="$ids-to-skip"/>
	      </xsl:call-template>

	    </xsl:element>
	    <!--* (d) Call raise-sequence recursively on the
		* remainder of the input sequence. *-->
	    <!--
	    <xsl:if test="$debug = 'yes' ">
	      <xsl:comment>* Suffix for <xsl:value-of
	      select="$ID"/>. *</xsl:comment>
	      </xsl:if>
	      -->
	    <xsl:if test="$debug = 'yes' ">
	      <xsl:variable
		  name="rsibs"
		  select="$nodes
			  [preceding-sibling::*
			  [@th:eID = $ID]]"/>
	      <xsl:message>Done raising  <xsl:value-of
	      select="concat(name($start-marker), ' id=', $ID)"
	      />, recurring on <xsl:value-of
	      select="count($rsibs)"/> right siblings.</xsl:message>
	    </xsl:if>
	    <xsl:call-template name="raise-sequence">
	      <xsl:with-param
		  name="nodes"
		  select="$nodes
			  [preceding-sibling::*
			  [@th:eID = $ID]]"/>
	      <xsl:with-param name="ids-to-skip"
			      select="$ids-to-skip"/>
	    </xsl:call-template>
	    <!--
	    <xsl:if test="$debug = 'yes' ">
	      <xsl:comment>* End suffix for <xsl:value-of
	      select="$ID"/>. *</xsl:comment>
	      </xsl:if>
	      -->
	  </xsl:otherwise>
	</xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
    
  </xsl:template>
  
  <!--****************************************************************
      * 4. Raising mode (suppress @th:*, copy everything else through)
      ****************************************************************-->
  <xsl:template match="* | text() | comment() | processing-instruction()" mode="raising">
    <xsl:copy>
      <xsl:apply-templates select="@* | node()"/>
    </xsl:copy>
  </xsl:template>    
  
  <!--* suppress th:* attributes *-->
  <xsl:template mode="raising" match="@*">
    <xsl:copy/>
  </xsl:template>
  <xsl:template mode="raising" match="@th:sID | @th:eID | @th:doc | @th:soleID" priority="2"/>
  
  
</xsl:stylesheet>
