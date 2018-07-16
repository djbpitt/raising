<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
    version="1.0"
    exclude-result-prefixes="xsl xs th">

    <!--* Simple 1.0 implementation of inside-out approach.
	* The stylesheet performs one pass over the input.
	* To transform the data fully, keep running the stylesheet
	* until the output no longer changes.
	*-->
    
    <xsl:output method="xml" indent="no"/>

    <!--* Set $debug parameter to any non-null value to output messages *-->
    <xsl:param name="debug" static="yes" required="no"/>
    
    <xsl:key name="end-markers" match="*[@th:eID]" use="@th:eID"/>
    <xsl:key name="virtual-children"
	     match="node()
		    [preceding-sibling::*[@th:sID][1]/@th:sID
		    =
		    following-sibling::*[@th:eID][1]/@th:eID]"
	     use="preceding-sibling::*[@th:sID][1]/@th:sID"/>
    
    <!-- Traditional identity template for root and its children -->
    <xsl:template match="@* | node()">
        <xsl:copy>
            <xsl:apply-templates select="@* | node()"/>
        </xsl:copy>
    </xsl:template>
    
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

    <!--
        Innermost start-markers
        @priority needed here and below because otherwise ambiguous with identity templates
    -->
    <xsl:template match="*[@th:sID = following-sibling::*[@th:eID][1]/@th:eID]" priority="1">
        <xsl:copy>
	    <xsl:apply-templates select="@*" mode="raising"/>
	    <xsl:apply-templates select="key('virtual-children', @th:sID)" mode="raising"/>	    
        </xsl:copy>
    </xsl:template>

    <!-- nodes inside new wrapper: suppress, since they have already been copied -->
    <xsl:template
        match="node()
	       [preceding-sibling::*[@th:sID][1]/@th:sID
	       =
	       following-sibling::*[@th:eID][1]/@th:eID]"
        priority="1"/>

    <!-- end-tag for new wrapper; suppress because it has already been copied -->
    <xsl:template match="*
			 [@th:eID
			 =
			 preceding-sibling::*[@th:sID][1]/@th:sID]"
		  priority="1"/>

</xsl:stylesheet>
