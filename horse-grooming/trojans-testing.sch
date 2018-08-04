<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt2"
    xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    
    <sch:ns prefix="th"  uri="urn:trojan-horses"/>
    <sch:ns prefix="tei" uri="http://www.tei-c.org/ns/1.0"/>
    
    <xsl:key name="start-by-id" match="*[exists(@th:sID)]" use="@th:sID"/>
    <xsl:key name="end-by-id" match="*[exists(@th:eID)]" use="@th:eID"/>
    
    <sch:pattern>
        <!-- testing a Trojan end tag -->
        <sch:rule context="*[exists(@th:sID)]">
            <sch:assert test="empty(../@th:eID)">Sorry, a marker may have @sID or @eID, not both.</sch:assert>
            <sch:assert test="count(key('start-by-id',@th:sID)) eq 1">@sID values must be unique within the document (good hygiene)</sch:assert>
            
        </sch:rule>
            <sch:rule context="*[exists(@th:eID)]">
                <!-- If a pair does not match up, we have no clean start. -->
            <sch:let name="clean-start" value="if (count(key('start-by-id',@th:eID) / (. | key('end-by-id',@th:sID))) eq 2)
                then key('start-by-id',@th:eID) else ()"/>
            <sch:assert test="exists($clean-start)">Which start tag does this end tag correspond to?</sch:assert>
            <sch:assert test="empty($clean-start) or (. >> $clean-start)">End tag
            '<sch:value-of select="@th:eID"/>' has no preceding start tag.</sch:assert>

          
            <sch:assert test="empty($clean-start) or empty(th:unclosed-at(.))">OVERLAP/SLIPPAGE:
                an end tag for '<sch:value-of select="@th:eID"/>'
                appears before an end <sch:value-of select="if (count(th:unclosed-at(.)) eq 1) then 'tag' else 'tags'"/> for
                <sch:value-of select="string-join(th:unclosed-at(.)/concat('''',.,''''),', ')"/>
            </sch:assert>            
        </sch:rule>
    </sch:pattern>

    <!-- function returns @sID attributes for start trojans
         after the argument node's start, that are not ended before the argument node;
         these are unclosed, hence overlapping. -->
    <!-- To find them we start at the argument's start and walk forward. -->
    <!-- Potentially an accumulator could do this but it would have to push and pop from a stack,
         and I have not worked out how to do that. -->
    <!-- So we do it here with templates. -->
    <xsl:function name="th:unclosed-at" as="attribute()*">
        <xsl:param name="here" as="element()"/>
        <xsl:apply-templates mode="collect-unclosed" select="key('start-by-id',$here/@th:eID,root($here))">
            <xsl:with-param name="to" tunnel="yes" select="$here"/>
        </xsl:apply-templates>
    </xsl:function>

    <!-- The mode walks across sID|eID trojans until it hits $to. -->
    <xsl:template match="*" mode="collect-unclosed">
        <xsl:param tunnel="yes" name="to"       as="element()"/>
        <!-- $unclosed is the accumulator -->
        <xsl:param              name="unclosed" as="attribute()*" select="()"/>
        <xsl:choose>
            <!-- When we don't care, keep going. -->
            <!-- As coded, we always care, so test="false()" but this
                 is an extension point if you want to test your implicit trees
                 separately, for example if your Trojans are distinguished
                 by namespaces. -->
            <xsl:when test="false()">
                <xsl:apply-templates mode="collect-unclosed" select="following::*[exists(@th:sID|@th:eID)][1]">
                    <xsl:with-param name="unclosed" select="$unclosed"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- We care. -->
            <!-- Reaching $to, pop the start trojan, and return the rest of $unclosed -->
            <xsl:when test=". is $to">
                <xsl:sequence select="$unclosed[not(.=$to/@th:eID)]"/>
            </xsl:when>
            <!-- I'm a start: push me onto the stack and keep going -->
            <xsl:when test="exists(@th:sID)">
                <xsl:apply-templates mode="collect-unclosed" select="following::*[exists(@th:sID|@th:eID)][1]">
                    <xsl:with-param name="unclosed" select="$unclosed,@th:sID"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- I'm an end: pop me and keep going -->
            <xsl:when test="exists(@th:eID)">
                <xsl:apply-templates mode="collect-unclosed" select="following::*[exists(@th:sID|@th:eID)][1]">
                    <xsl:with-param name="unclosed" select="$unclosed[not(.=current()/@th:eID)]"/>
                </xsl:apply-templates>
            </xsl:when>
            <!-- no xsl:otherwise since only nodes with (@th:sID|@th:eID) are examined -->
        </xsl:choose>
    </xsl:template>

</sch:schema>
