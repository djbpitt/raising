<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
		exclude-result-prefixes="xs"
		version="3.0"
		>

  <!--* raise-with-accumulators:  demonstration of using
      * XSLT 3.0 accumulators for this task.
      *-->

  <!--* Revisions:
      * 2018-07-05 : CMSMcQ : try to make good on that
      *     conjecture:  start with just keeping track of level.
      * 2018-06-28 : CMSMcQ : conjecture that a solution with
      *     accumulators should be possible.
      *-->
  
  <!--* Task:  accept input with Trojan-Horse markup;
      * turn selected elements into content elements.
      * We allow ourselves to assume the input has
      * correctly matching Trojan-Horse elements; if
      * it doesn't we are allowed to fail or to produce
      * regrettable results.
      *
      * To keep things simple, we move the decision on
      * whether an element is a Trojan-Horse start- or end-tag
      * that we want to process into a function.
      *-->

  <!--* Overview:  we use accumulators to keep a stack of
      * elements being processed (which we represent as an array).
      *
      * Each level of the stack contains a sequence of nodes,
      * beginning with the most recent unclosed Trojan Horse
      * start-tag at that level and continuing with the contents
      * of that logical element.
      *
      * When we see a Trojan-Horse start-tag, we add a
      * new level of the stack.
      *
      * When we see a Trojan-Horse end-tag, we take the
      * top-most level of the stack and make an element with
      *
      *   gi = gi of $stack($level)[1]
      *   attributes = attributes of $stack($level)[1] except @th:*
      *   contents = $stack($level) [position() gt 1]
      *
      * We then delete that level of the stack, and add the newly
      * created element to the end of the sequence on the
      * new top level of the stack.
      *
      * When we see anything else, we copy it into the current
      * stack level, if there is one. (If there is none, we just write
      * it to the output tree.)
      *-->

  <!--****************************************************************
      * 0.  Setup:  parameters, variables, accumulators etc. 
      ****************************************************************-->
  <xsl:output
      indent="yes"
      />
  
  <!--* declare default mode as shallow-copy *-->
  <xsl:mode on-no-match="shallow-copy"
	    use-accumulators="level"
	    streamable="yes"/>

  <!--* declare level accumulator to keep track of stack depth *-->
  <xsl:accumulator name="level" as="xs:integer"
		   initial-value="0"
		   streamable="yes"
		   >
    <xsl:accumulator-rule match="*[th:trojan-start(.)]"
			  select="$value + 1"/>
    <xsl:accumulator-rule match="*[th:trojan-end(.)]"
			  select="$value - 1"/>
  </xsl:accumulator>


  <!--****************************************************************
      * 1.  Virtual start-tags 
      ****************************************************************-->
  <xsl:template match="*[th:trojan-start(.)]" priority="10">
    
    <xsl:copy-of select="."/>
    
    <xsl:text>&#xA;</xsl:text>
    <xsl:comment>* level = <xsl:value-of select="accumulator-after('level')"/> *</xsl:comment>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>
  
  <!--****************************************************************
      * 2.  Virtual end-tags 
      ****************************************************************-->  
  <xsl:template match="*[th:trojan-end(.)]" priority="10">
    
    <xsl:copy-of select="."/>
    
    <xsl:text>&#xA;</xsl:text>
    <xsl:comment>* level = <xsl:value-of select="accumulator-after('level')"/> *</xsl:comment>
    <xsl:text>&#xA;</xsl:text>
  </xsl:template>

  <!--****************************************************************
      * 3.  All other nodes 
      ****************************************************************-->

  <!--****************************************************************
      * 4.  Functions 
      ****************************************************************-->
  <!--* th:trojan-start($e as element()):  true iff $e is a Trojan
      * start-tag we want to process.
      * (Current implementation assumes we always process
      * anything with @th:sID.)
      *-->
  <xsl:function name="th:trojan-start" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:value-of select="exists($e/@th:sID)"/>
  </xsl:function>
  
  <!--* th:trojan-end($e as element()):  true iff $e is a Trojan
      * end-tag we want to process.
      * (Current implementation assumes we always process
      * anything with @th:eID.)
      *-->
  <xsl:function name="th:trojan-end" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    <xsl:value-of select="exists($e/@th:eID)"/>
  </xsl:function>
  
</xsl:stylesheet>
