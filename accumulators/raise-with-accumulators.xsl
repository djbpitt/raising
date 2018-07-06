<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:array="http://www.w3.org/2005/xpath-functions/array"
		xmlns:map="http://www.w3.org/2005/xpath-functions/map"
		xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
		exclude-result-prefixes="#all"
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
      indent="no"
      />

  <!--* What kind of Trojan-Horse elements are we merging? *-->
  <!--* Expected values are 'th' for @th:sID and @th:eID,
      * 'ana' for @ana=start|end
      * 'xmlid' for @xml:id matching (_start|_end)$
      *-->
  <xsl:param name="th-style" select=" 'ana' " static="yes"/>

  <!--* declare default mode as shallow-copy *-->
  <xsl:mode on-no-match="fail"
	    use-accumulators="level stack"
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

  <!--* Declare stack accumulator to keep track of contents. *-->
  <!--* Start with empty array. *-->
  <xsl:accumulator name="stack" as="array(node()*)"
		   initial-value="[]"
		   streamable="yes"
		   >
    <!--* On Trojan start-tag, push the start-tag onto the stack *-->
    <xsl:accumulator-rule match="*[th:trojan-start(.)]"
			  select="array:append($value, .)"/>
    
    <!--* On Trojan end-tag, make the currently pending element,
	pop the stack, and insert the pending element at the
	end of the new top item. *-->
    <xsl:accumulator-rule match="*[th:trojan-end(.)]"			  
			  phase="end">
      
      <xsl:variable name="level" as="xs:integer"
		    select="array:size($value)"/>
      <xsl:variable name="e" as="element()"
		    select="th:make-element($value($level))"/>
      <xsl:choose>
	<xsl:when test="$level eq 1">
	  <!--* at outermost level, we have no previous
	      level to add anything to, so we just pop the
	      stack. *-->
	  <xsl:sequence select="[]"/>
	</xsl:when>
	<xsl:otherwise>	  
	  <xsl:sequence select="array:put(
				array:remove($value, $level),
				$level - 1,
				($value($level - 1), $e))"/>
	</xsl:otherwise>
      </xsl:choose>
    </xsl:accumulator-rule>
    
    <!--* On any other node, append current node to the top sequence in the stack *-->
    <xsl:accumulator-rule match="node()[not(self::element())
				 or (not(th:trojan-start(.)) and not(th:trojan-end(.)))]"
			  select="for $level in array:size($value) return
				  if ($level eq 0)
				  then []
				  else array:put($value, $level, ($value($level), .))"/>
  </xsl:accumulator>  


  <!--****************************************************************
      * 1.  Virtual start-tags 
      ****************************************************************-->
  <xsl:template match="*[th:trojan-start(.)]" priority="10">
    <!--* nothing to do, all the work is done by the accumulator *-->
  </xsl:template>
  
  <!--****************************************************************
      * 2.  Virtual end-tags 
      ****************************************************************-->  
  <xsl:template match="*[th:trojan-end(.)]" priority="10">
    <xsl:choose>
      <xsl:when test="array:size(accumulator-before('stack')) eq 1">	
	<!--* if this end-tag ends the outermost element, emit the element *-->
	<xsl:sequence select="th:make-element(accumulator-before('stack')(1))"/>	
      </xsl:when>
      <xsl:otherwise>
	<!--* Otherwise, nothing to do *-->
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--****************************************************************
      * 3.  All other nodes 
      ****************************************************************-->
  <!--* 3.1 Document node *-->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>
  
  <!--* 3.2 Non-trojan element nodes *-->
  <xsl:template match="node()[self::element()
		       and not(th:trojan-start(.))
		       and not(th:trojan-end(.)) ]">
    <!--* If we are outside the flattened area, copy the node;
	* otherwise, do nothing and leave everything to the accumulator *-->
    <xsl:choose>
      <xsl:when test="array:size(accumulator-before('stack')) eq 0">
	<xsl:copy>
	  <xsl:copy-of select="@*"/>
	  <xsl:apply-templates/>
	</xsl:copy>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>    
  </xsl:template>
  
  <!--* 3.3 Non-element nodes *-->
  <xsl:template match="node()[not(self::element())]">
    <!--* If we are outside the flattened area, copy the node;
	* otherwise, do nothing and leave everything to the accumulator *-->
    <xsl:choose>
      <xsl:when test="array:size(accumulator-before('stack')) eq 0">
	<xsl:sequence select="."/>
      </xsl:when>
      <xsl:otherwise/>
    </xsl:choose>    
  </xsl:template>
    
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
    
    <xsl:value-of use-when="$th-style = 'th' "
	select="exists($e/@th:sID)"/>
    <xsl:value-of use-when="$th-style = 'ana' "
	select="$e/@ana='start' "/>
    <xsl:value-of use-when="$th-style = 'xmlid' "
	select="ends-with($e/@xml:id,'_start')"/>
    
  </xsl:function>
  
  <!--* th:trojan-end($e as element()):  true iff $e is a Trojan
      * end-tag we want to process.
      * (Current implementation assumes we always process
      * anything with @th:eID.)
      *-->
  <xsl:function name="th:trojan-end" as="xs:boolean">
    <xsl:param name="e" as="element()"/>
    
    <xsl:value-of use-when="$th-style = 'th' "
	select="exists($e/@th:eID)"/>
    <xsl:value-of use-when="$th-style = 'ana' "
	select="$e/@ana='end' "/>
    <xsl:value-of use-when="$th-style = 'xmlid' "
		  select="ends-with($e/@xml:id,'_end')"/>
    
  </xsl:function>

  <!--* th:make-element($ln as node()+):  make an element out of
      * one stack entry *-->
  <!--* We package this as a function because it's called from
      * two different locations in the stylesheet *-->
  <xsl:function name="th:make-element" as="element()">
    <xsl:param name="ln" as="node()+"/>
    
    <xsl:copy select="$ln[1]">
      <!--* first copy (and filter) attributes *-->
      <xsl:sequence select="$ln[1]/(@* except @th:*)"
		    use-when="$th-style = 'th' "/>
      <xsl:sequence use-when="$th-style = 'ana' ">
	<xsl:sequence select="$ln[1]/(@* except (@ana, @loc))"/>
	<xsl:attribute name="xml:id" select="$ln[1]/@loc"/>
      </xsl:sequence>
		    
      <xsl:sequence use-when="$th-style='xmlid'">
	<xsl:sequence select="$ln[1]/@*"/>
	<xsl:attribute name="xml:id" select="replace($ln[1]/@xml:id, '_start$','')"/>
      </xsl:sequence>
      
      <!--* then copy children *-->
      <xsl:sequence select="$ln[position() gt 1]"/>
    </xsl:copy>
    
  </xsl:function>
		
</xsl:stylesheet>
