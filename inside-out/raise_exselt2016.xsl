<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
    exclude-result-prefixes="#all">

  <!--* Revisions:
      * 2018-07-22 : CMSMcQ : hack to try to get Exselt to run this
      * 2018-07-20 : CMSMcQ : correct problems with debug and 
      *     instrument parameters
      * 2018-07-20 : CMSMcQ : import marker-recognition library, 
      *     generalize away from the form of the input      
      * 2018-07-20 : CMSMcQ : add revision history and instrument parameter. 
      * 2018-07-17 : CMSMcQ : mostly cosmetic changes
      * 2018-07-13 : DJB : clean up to match prose (line numbers)
      * 2018-07-13 : DJB : set priority, control messages with parameter 
      * 2018-07-12 : DJB : further renaming 
      * 2018-07-11 : DJB : clean up directories, rename things 
      *-->
        
    <!--* Setup *-->
    <xsl:import href="../lib/marker-recognition_exselt.xsl"/>

    <xsl:output method="xml" indent="no"/>
    
    <!--* What kind of Trojan-Horse elements are we merging? *-->
    <!--* Expected values are 'th' for @th:sID and @th:eID,
	* 'ana' for @ana=start|end 
	* 'anaplus' for @ana=start|end|*_Start|*_End
	* 'xmlid' for @xml:id matching (_start|_end)$
	*-->
    <xsl:param name="th-style2" select=" 'th' " static="yes"/>

    <!--* Set $debug parameter to any non-null value to output messages *-->
    <xsl:param name="debug" as="xs:boolean" static="yes" required="no"
	       select="xs:boolean('0')"/>

    <!--* instrument:  issue instrumentation messages? yes or no *-->
    <!--* Instrumentation messages include things like monitoring
	* size of various node sets; we turn off for timing, on for
	* diagnostics and sometimes for debugging. *-->
    <xsl:param name="instrument" as="xs:boolean" static="yes"
	       required="no"
	       select="xs:boolean('0')"/>

    <!--* Key for finding end-markers; is this faster? *-->
    <!--* I don't think we need these, but I'm not sure yet 
    <xsl:key name="end-markers" match="*[@th:eID]" use="@th:eID"
	     use-when="$th-style2 eq 'th'" />
    <xsl:key name="end-markers" match="*[th:is-end-marker(.)]"
	     use="@loc"
	     use-when="$th-style2 eq ('ana', 'anaplus')" />
	     *-->

    <xsl:key name="end-markers" match="*[th:is-end-marker(.)]"
	     use="th:coindex(.)"/>

    <!-- 
        Identity template of anything lower than grandchildren of the root
        Just copy; they cannot contain markers
    -->
    <xsl:template match="/*/*/descendant::node()" mode="#all">
      <xsl:message use-when="$debug">Grandchild template on <xsl:value-of select="name()" /> element.</xsl:message>
        <xsl:sequence select="."/>
    </xsl:template>

    <!-- Traditional identity template for root and its children -->
    <xsl:template match="@* | node()" mode="#all">
      <xsl:message use-when="$debug">Identity template on
      <xsl:value-of select="
			    if (. instance of element()) then name() || ' element' 
			    else if (. instance of attribute()) then name() || ' attribute' 
			    else if (. instance of text() and not(normalize-space())) then ' ws' 
			    else if (. instance of text()) then ' text node ' || substring(., 1, 10) 
			    else 'misc node'
			    " />.</xsl:message>
        <xsl:copy copy-namespaces="no">
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>

    <!-- 
        th:raise(.):  raise all innermost elements within the document
        messages controlled by $debug and $instrument stylesheet parameters
    -->
    <xsl:function name="th:raise">
        <xsl:param name="input" as="document-node()"/>
        <xsl:message use-when="$instrument or $debug">raise() called with 
            <xsl:value-of select="count($input//*)"/>-element document 
            (<xsl:value-of select="count($input//*[th:is-start-marker(.)])"/> Trojan pairs)</xsl:message>
        <xsl:choose>
            <!--* <xsl:when test="exists($input//*[@th:sID eq
		following-sibling::*[@th:eID][1]/@th:eID])"> *-->
            <xsl:when test="exists($input//*
			    [th:is-start-marker(.) and
			       th:coindex(.)
			       eq
			       th:coindex(
			          following-sibling::*[th:is-end-marker(.)][1]
			       )])">
                <!-- If we have more work to do, do it -->
		<xsl:message use-when="$debug">raise() applying templates ...</xsl:message>
                <xsl:variable name="result" as="document-node()">
                    <xsl:document>
                        <xsl:apply-templates select="$input" mode="loop"/>
                    </xsl:document>
                </xsl:variable>
		<xsl:message use-when="$debug">result of templates has <xsl:value-of select="count($result//*)"
			      /> elements ...</xsl:message>
                <xsl:sequence select="th:raise($result)"/>
            </xsl:when>
            <xsl:otherwise>
                <!-- We have no more work to do, return the input unchanged. -->
                <xsl:message use-when="$debug">raise() returning.</xsl:message>
                <xsl:sequence select="$input"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>

    <xsl:template match="/">
        <xsl:sequence select="th:raise(.)"/>
    </xsl:template>

    <xsl:template match="/" mode="loop">
      <xsl:message use-when="$debug">Processing document node in loop mode ...</xsl:message>
      <xsl:message use-when="$debug">Applying templates to
      <xsl:value-of
	  select="count(child::node())"/> nodes:  <xsl:value-of
	  select="
	  for $e in child::node() return name($e)"/> ...</xsl:message>
        <xsl:apply-templates/>
    </xsl:template>

    <!--
        Innermost start-markers
        @priority needed here and below because otherwise ambiguous with identity templates
    -->
    <!--* xsl:template match="*[@th:sID eq
	following-sibling::*[@th:eID][1]/@th:eID]" priority="1" *-->
    <xsl:template match="*[th:is-start-marker(.)
			 and th:coindex(.)
			 eq
			 th:coindex(following-sibling::*[th:is-end-marker(.)][1])]"
		  priority="1">
      <xsl:message use-when="$debug">Raising <xsl:value-of select="name()" /> ...</xsl:message>
        <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@* except @th:sID"
			 use-when="$th-style2 = 'th'"/>
            <xsl:copy-of select="@* except @ana"
			 use-when="$th-style2 = ('ana', 'anaplus') "/>
            <xsl:variable name="end-marker" as="element()"
			  select="key('end-markers', th:coindex(.))[1]"/>
            <xsl:copy-of select="following-sibling::node()[. &lt;&lt; $end-marker]"/>
        </xsl:copy>
    </xsl:template>

    <!-- nodes inside new wrapper: suppress, since they have alredy been copied -->
    <!--* <xsl:template
        match="node()[preceding-sibling::*[@th:sID][1]/@th:sID eq following-sibling::*[@th:eID][1]/@th:eID]"
        priority="1"/> *-->

    <xsl:template
        match="node()[
               let $start-marker := preceding-sibling::*[th:is-start-marker(.)][1],
                   $end-marker := following-sibling::*[th:is-end-marker(.)][1]
               return (exists($start-marker)
                   and exists($end-marker)     
                   and th:coindex($start-marker) eq th:coindex($end-marker) )
               ]"
        priority="1">
      <xsl:message use-when="$debug">Swallowing node <xsl:value-of
      select="if (. instance of element()) then name(.)
      else if (. instance of text()) then 'text node'
      else 'misc node'"/></xsl:message>      
    </xsl:template>

    <!-- end-tag for new wrapper; suppress because it has already been copied -->
    <!--*
	<xsl:template match="*[@th:eID eq
	preceding-sibling::*[@th:sID][1]/@th:sID]" priority="1"/>
	*-->
    <xsl:template match="*[th:is-end-marker(.)
			 and th:coindex(.)
			 eq
			 th:coindex(preceding-sibling::*[th:is-start-marker(.)][1])]"
		  priority="1"/>

</xsl:stylesheet>
