<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:xs="http://www.w3.org/2001/XMLSchema"
		xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse"
		exclude-result-prefixes="#all"
		version="3.0"
		>

  <!--* outside-in:  demonstration of raising first the outermost
      * elements, and then their children, recursively.  Intended as
      * a mirror image of inside-out.
      *-->

  <!--* Revisions:
      * 2018-07-08 : CMSMcQ : first sketch
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

  <!--* Overview:  In the input, we choose the first
      * virtual element not contained by any other (so:
      * the one with the left-most start-tag).  We make it
      * into an element and recur on its content.  Then we
      * choose the next virtual element (if any) not contained by
      * any other.
      *
      * If we knew how to get all outermost virtual elements in
      * a single pass, we would do so.
      *
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
  <xsl:param name="th-style" select=" 'th' " static="yes"/>

  <!--* debug:  issue debugging messages?  yes or no  *-->
  <xsl:param name="debug" as="xs:string" select=" 'no' " static="yes"/>

  <!--* instrument:  issue instrumentation messages? yes or no *-->
  <!--* Instrumentation messages include things like monitoring
      * size of various node sets; we turn off for timing, on for
      * diagnostics and sometimes for debugging. *-->
  <xsl:param name="instrument" as="xs:string" select=" 'no' " static="yes"/>
  
  <!--* declare default mode as requiring templates *-->
  <xsl:mode on-no-match="shallow-copy"/>
  <xsl:mode name="loop" on-no-match="shallow-copy"/>


  <!--****************************************************************
      * 1.  Document node (we start here)
      ****************************************************************-->
  <xsl:template match="/">
    <xsl:apply-templates/>
  </xsl:template>

  <!--****************************************************************
      * 2.  Empty elements:  just write them to the result tree
      ****************************************************************-->
  <xsl:template match="*[empty(node())]">
    <xsl:copy-of select="."/>
  </xsl:template>

  <!--****************************************************************
      * 3.  Content elements:  raise their children
      ****************************************************************-->    
  <xsl:template match="*[exists(node())]">
    <xsl:copy>
      <xsl:sequence select="@*, th:raise-sequence(child::node())"/>
    </xsl:copy>
  </xsl:template>

    
  <!--****************************************************************
      * 4.  Functions 
      ****************************************************************-->
  <!--* th:start-marker($e as element()):  true iff $e is a start-marker
      * we want to process.
      *-->
  <xsl:function name="th:start-marker" as="xs:boolean">
    <xsl:param name="e" as="node()"/>
    
    <xsl:value-of use-when="$th-style = 'th' "
	select="exists($e/@th:sID)"/>
    <xsl:value-of use-when="$th-style = 'ana' "
	select="$e/@ana='start' "/>
    <xsl:value-of use-when="$th-style = 'xmlid' "
	select="ends-with($e/@xml:id,'_start')"/>
    
  </xsl:function>
  
  <!--* th:end-marker($e as element()):  true iff $e is an end-marker
      * we want to process.
      *-->
  <xsl:function name="th:end-marker" as="xs:boolean">
    <xsl:param name="e" as="node()"/>
    
    <xsl:value-of use-when="$th-style = 'th' "
	select="exists($e/@th:eID)"/>
    <xsl:value-of use-when="$th-style = 'ana' "
	select="$e/@ana='end' "/>
    <xsl:value-of use-when="$th-style = 'xmlid' "
		  select="ends-with($e/@xml:id,'_end')"/>
    
  </xsl:function>

  <!--* th:markers-match($e1, $e2):  true iff $e1 and $e2 are
      matching start- and end-markers *-->
  <xsl:function name="th:markers-match" as="xs:boolean">
    <xsl:param name="e1" as="node()"/>
    <xsl:param name="e2" as="node()"/>
    
    <xsl:value-of use-when="$th-style = 'th' "
	select="$e1/@th:sID eq $e2/@th:eID"/>
    <xsl:value-of use-when="$th-style = 'ana' "
		  select="name($e1) eq name($e2)
			  and $e1/@ana eq 'start' 
			  and $e2/@ana eq 'end' 
			  and $e1/@loc eq $e2/@loc 
			  "/>
    <xsl:value-of use-when="$th-style = 'xmlid' "
		  select="substring-before($e1/@xml:id,'_start')
			  eq substring-before($e2/@xml:id,'_end')			  
			  "/>
    
  </xsl:function>

  <!--* th:id($e):  returns element identifier of start- or end-marker *-->
  <xsl:function name="th:id" as="xs:string?">
    <xsl:param name="e" as="node()"/>
    
    <xsl:value-of use-when="$th-style = 'th' "
	select="($e/@th:sID, $e/@th:eID)"/>
    <xsl:value-of use-when="$th-style = 'ana' "
		  select="($e/@loc)"/>
    <xsl:value-of use-when="$th-style = 'xmlid' "
		  select="replace($e/@xml:id,'(_start|_end)$','')"/>
    
  </xsl:function>

  <!--* th:raise-sequence():  raise outermost elements in a sequence of nodes *-->
  <xsl:function name="th:raise-sequence" as="node()*">
    <xsl:param name="ln" as="node()*"/>

    <!--* lidStarts, lidEnds:  lists of IDs for start- and end-markers *-->
    
    <xsl:variable name="lidStarts" as="xs:string*"
		  select="for $n in $ln[th:start-marker(.)] return th:id($n)"/>
    <xsl:variable name="lidEnds" as="xs:string*"
		  select="for $n in $ln[th:end-marker(.)] return th:id($n)"/>
    
    <xsl:choose>
      <!--* base case:  no start-marker / end-marker pairs present *-->
      <xsl:when test="empty($lidStarts[. = $lidEnds])">
	<!--* The sequence may contain elements with markers inside,
	    * so we apply templates, instead of just returning $ln *-->
	<xsl:apply-templates select="$ln"/>
      </xsl:when>

      <!--* 'normal' case: take first start-marker with matching end-marker *-->
      <xsl:otherwise>
	<!--* find ID of first start-marker with matching end-marker *-->
	<xsl:variable name="id" as="xs:string"
		      select="$lidStarts[. = $lidEnds][1]"/>
	<!--* find position of start- and end-markers with that ID *-->
	<xsl:variable name="posStartEnd" as="xs:integer+"
		      select="for $i in 1 to count($ln) return
			      if ($ln[$i][(th:start-marker(.) or th:end-marker(.))
			          and th:id(.) eq $id])
				  then $i else ()"/>
	<xsl:variable name="posStart" as="xs:integer"
		      select="$posStartEnd[1]"/>
	<xsl:variable name="posEnd" as="xs:integer"
		      select="$posStartEnd[2]"/>

	<!--* Apply templates to all items to left of start. These may
	    * include markers, but if so they are not matched and not
	    * raisable. They may also include elements which contain
	    * markers, so we need to apply templates, not just return
	    * them. *-->
	<xsl:apply-templates select="$ln[position() lt $posStart]"/>
	
	<!--* Raise the element and call raise-sequence() on its
	    * content. *-->
	<xsl:copy select="$ln[$posStart]">
	  <!--* copy the attributes (filtering as needed) *-->
	  <xsl:sequence use-when="$th-style = 'th'"
			select="$ln[$posStart]/(@* except @th:*)"/>
	  <xsl:sequence use-when="$th-style = 'ana'">
	    <xsl:sequence select="$ln[$posStart]/(@* except (@ana, @loc))"/>
	    <xsl:attribute name="xml:id" select="$ln[$posStart]/@loc"/>
	  </xsl:sequence>
	  <xsl:sequence use-when="$th-style = 'xmlid'">
	    <xsl:sequence select="$ln[$posStart]/(@* except @th:*)"/>
	    <xsl:attribute name="xml:id" select="th:id($ln[$posStart])"/>
	  </xsl:sequence>

	  <!--* handle children *-->	  
	  <xsl:sequence select="th:raise-sequence($ln[position() gt $posStart
				and position() lt $posEnd])"/>	  
	</xsl:copy>
	
	<!--* call raise-sequence() on all items to right of end *-->
	<xsl:sequence select="th:raise-sequence($ln[position() gt $posEnd])"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>  
		
</xsl:stylesheet>
