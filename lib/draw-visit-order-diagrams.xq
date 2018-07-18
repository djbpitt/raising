(: draw-visit-order-diagrams.xq:  ad-hoc code to read a (small) XML document
   and emit dot files (for GraphViz) illustrating a flattened version of 
   the document and illustrating the order in which virtual elements are
   rasied in the inside-out, outside-in, or left-right solutions to the
   raising problem.
   
   Revisions:
   2018-07-17 : CMSMcQ : clean up a bit, and change the form of the tree
   2018-07-14f : CMSMcQ : made first version
:)

(: To do:  
   1 Refactor a bit for clarity
   2 Make style of markers depend on $th:markerstyle
:)

(: 0 Setup :)
declare namespace th = "http://www.blackmesatech.com/2017/nss/trojan-horse";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: ****************************************************************
   * 1 Variables to set 
   ****************************************************************:)
(: Yes, these should probably be parameters, but that kind of 
   generality seems pointless here. So they're not.
   :)
   
(: th:traversal:  What traversal order are we using?  oi, io, lr? :)
declare variable $th:traversal as xs:string := 'lr';

(: th:markershape:  How shall we draw markers?  point or oval? :)
declare variable $th:markershape as xs:string := 'oval';

(: th:inputdir:  where is the input? :)
declare variable $th:inputdir := '../input/basic/aux';

(: th:inputfile:  what is the filename of the input? :)
declare variable $th:inputfile := ('basho.xml', 
                                   'basho2.xml'
                                   'coleridge-quote.xml',
                                   'coleridge.xml'
                                  )[2];

(: th:outputdir:  where does the output go? :)
declare variable $th:outputdir := file:base-dir() || '../doc/images/left-right';

(: ****************************************************************
   * 2 Utilities (not particularly graphical)
   ****************************************************************:)
(: th:is-marker():  true iff argument is start- or end-marker :)
declare function th:is-marker(
  $n as node()
) as xs:boolean {
  th:is-start-marker($n) or th:is-end-marker($n)
};

declare function th:is-start-marker(
  $n as node()
) as xs:boolean {
  exists($n/@th:sID)
};

declare function th:is-end-marker(
  $n as node()
) as xs:boolean {
  exists($n/@th:eID)
};

(: height, i.e. how many generations of descendants? (for io generations) :)
declare function th:height(
  $n as node()
) as xs:integer {
  let $ld := $n/descendant::*
  return if (not($n instance of element()))
     then 0
     else if (empty($ld))
     then 1
     else let $h0 := max(for $d in $n/descendant::* 
                         return count($d/ancestor::*))
          let $h1 := count($n/ancestor::*)
          return 1 + $h0 - $h1
          (:
  (max(for $d in $n/descendant::* return count($d/ancestor::*)),
  - count($n/ancestor::*)
  :)
};

(: calculate an identifier for dot to use for a node :)
(: N.B. for elements should probably also count ancestors, not just preceding;
   as it is, parent and first child get the same number, which is confusing. :)
declare function th:identify(
  $n as node()
) as xs:string {
  if ($n instance of text())
  then 'pcd' || string(1 + count($n/preceding::text()))
  else if ($n instance of element())
  then local-name($n) || '_' || string(count($n/preceding::*))
  else 'fubar'
};

(: hue and markerhue():  what color am I? :)
(: Nodes and arcs are currently one of:  future, current, inflight, past :)

(: These functions for calculating hue for content nodes, arcs, and markers
   have not worn well, might benefit from revision. :)
declare function th:hue(
  $kw as xs:string
) as xs:string {
  if ($kw eq 'future') then 'gray'
  else if ($kw eq 'current') then 'red'
  else if ($kw eq 'inflight') then 'red'
  else 'black'
};

declare function th:markerhue(
  $kw as xs:string
) as xs:string {
  if ($kw eq 'future') then 'black'
  else if ($kw eq 'current') then 'red'
  else 'transparent'
};

(: **************************************************************** 
   * Drawing things (emitting dot code)
   ****************************************************************:)
(: draw a leaf :)


(: draw a node representing a marker :)
declare function th:drawmarker(
  $id as xs:string, 
  $gi as xs:string, 
  $kwSE as xs:string (: 'start', 'end' :), 
  $color as xs:string
) as xs:string {
  let $paren := if ($kwSE eq 'start') then '(' 
                else if ($kwSE eq 'end') then ')'
                else '???',
      $style := if ($color eq 'transparent')
                then ', style=invis'
                else if ($th:markershape eq 'oval')
                then ', style=filled'
                else '',
      $fillcolor := if ($color eq 'red')
                then ', fillcolor=pink'
                else ', fillcolor="#EEEEEE"'
  return if ($th:markershape eq 'point') then 
      $kwSE || '_' || $id || ' ['
            || 'label="' || $gi || '\n' || $paren || '"'
            || ', shape=' || $th:markershape
            || ', color=' || $color
            || $style
            || '];&#xA;'
  else (: if ($th:markershape eq 'oval') :)
      $kwSE || '_' || $id || ' ['
            || 'label="' || $gi || '\n' || $paren || '"'
            || ', shape=ellipse'
            || ', width=0.3'
            || ', margin=0'
            || ', fontsize=11'
            || ', color=' || $color
            || $style
            || $fillcolor
            || '];&#xA;'
};

(: draw a node representing a PCDATA node :)
declare function th:drawtextnode(
  $id as xs:string, 
  $s  as xs:string, 
  $color as xs:string
) as xs:string {
  $id || ' ['
  || 'shape=box'
  || ', label="' || normalize-space(
                      replace($s,'\s*&#xA;\s*','\\n')
                    ) || '"'
  || ', color=' || $color
  || '];&#xA;'
}; 

(: draw all leaves :)
declare function th:drawleaf(
  $n as node(),
  $kw as xs:string,
  $phase as xs:string?
) as xs:string {
  let $gi := local-name($n),
      $id := th:identify($n),
      $hue := th:hue($kw),
      $markerhue := th:markerhue($kw)
  return 
     '// ' || $id || ' is ' || $kw || ' at ' || $phase || '&#xA;' ||
     (if ($n/@th:sID) then
        let $color := if ($th:traversal eq 'lr' 
                          and $kw eq 'current'
                          and $phase eq 'pre')
                      then th:markerhue('current')
                      else if ($th:traversal eq 'lr' 
                          and $kw eq 'current'
                          and $phase eq 'post')
                      then th:markerhue('past')
                      else $markerhue
        return th:drawmarker($id, $gi, 'start', $color)
       
     else if ($n/@th:eID) then
        let $color := if ($th:traversal eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'pre')
                      then th:markerhue('future')
                      else if ($th:traversal eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'post')
                      then th:markerhue('current')
                      else if ($th:traversal eq 'lr'
                         and $kw eq 'inflight')
                      then th:markerhue('future')
                      else $markerhue
        return th:drawmarker($id, $gi, 'end', $color)
        
     else if ($n instance of element()) then 
        let $colorSM := if ($th:traversal eq 'lr' 
                           and $kw eq 'current'
                           and $phase eq 'pre')
                        then th:markerhue('current')
                        else if ($th:traversal eq 'lr' 
                           and $kw eq 'current'
                           and $phase eq 'post')
                        then th:markerhue('past')
                        else $markerhue
        let $colorEM := if ($th:traversal eq 'lr' 
                           and $kw eq 'current'
                           and $phase eq 'pre')
                        then th:markerhue('future')
                        else if ($th:traversal eq 'lr' 
                           and $kw eq 'current'
                           and $phase eq 'post')
                        then th:markerhue('current')
                        else if ($th:traversal eq 'lr'
                           and $kw eq 'inflight')
                        then th:markerhue('future')
                        else $markerhue
        return th:drawmarker($id, $gi, 'start', $colorSM)
            || th:drawmarker($id, $gi, 'end', $colorEM)
      
     else if ($n instance of text() and normalize-space($n)) then
        let $color := if ($th:traversal eq 'lr' and $kw eq 'current') 
                      then $hue
                      else 'black'
        return th:drawtextnode($id, string($n), $color)
     
     else if ($n instance of text() and not(normalize-space($n))) then 
         ''
     else '// node missing &#xA;'
  )
};


declare function th:drawleaf0(
  $n as node(),
  $kw as xs:string,
  $phase as xs:string?
) as xs:string {
  let $gi := local-name($n),
      $id := th:identify($n),
      $hue := th:hue($kw),
      $markerhue := th:markerhue($kw)
  return 
     '// ' || $id || ' is ' || $kw || ' at ' || $phase || '&#xA;' ||
     (if ($n/@th:sID) then
        'start_' || $id || ' ['
                 || 'label="' || $gi || '\nstart", '
                 || 'shape=point, '
                 || 'color=' (: this color assignment is 
                                almost certainly wrong 
                                for unmatchable elements :)
                 || (if ($th:traversal eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'pre')
                     then th:markerhue('current')
                     else if ($th:traversal eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'post')
                     then th:markerhue('past')
                     else $markerhue)
                 || '];&#xA;'
     else if ($n/@th:eID) then
        'end_' || $id || ' ['
               || 'label="' || $gi || '\nend", '
               || 'shape=point, '
               || 'color=' 
               || (if ($th:traversal eq 'lr' 
                      and $kw eq 'current'
                      and $phase eq 'pre')
                  then th:markerhue('future')
                  else if ($th:traversal eq 'lr' 
                      and $kw eq 'current'
                      and $phase eq 'post')
                  then th:markerhue('current')
                  else if ($th:traversal eq 'lr'
                      and $kw eq 'inflight')
                    then th:markerhue('future')
                  else $markerhue)
               || '];&#xA;'
     else if ($n instance of element()) then 
        'start_' || $id || ' ['
                 || 'label="' || $gi || '\nstart", '
                 || 'shape=point, '
                 || 'color='
                 || (if ($th:traversal eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'pre')
                     then th:markerhue('current')
                     else if ($th:traversal eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'post')
                     then th:markerhue('past')
                     else $markerhue)
                 || '];&#xA;'
       || 'end_' || $id || ' ['
                 || 'label="' || $gi || '\nend", '
                 || 'shape=point, '
                 || 'color=' 
                 || (if ($th:traversal eq 'lr' 
                        and $kw eq 'current'
                        and $phase eq 'pre')
                    then th:markerhue('future')
                    else if ($th:traversal eq 'lr' 
                        and $kw eq 'current'
                        and $phase eq 'post')
                    then th:markerhue('current')
                    else if ($th:traversal eq 'lr'
                        and $kw eq 'inflight')
                    then th:markerhue('future')
                    else $markerhue)
                 || '];&#xA;'
  else if ($n instance of text() and normalize-space($n)) then
     let $id := th:identify($n)
     return $id || ' [shape=box, label="' || string($n) || '"'
             || (if ($th:traversal eq 'lr') 
                 then 'color=' || $hue else '')
             || '];&#xA;'
  else if ($n instance of text() and not(normalize-space($n))) then 
      ''
  else '// node missing &#xA;'
  )
};


(: draw a node representing a content element :)
declare function th:drawnode(
  $e as element(),
  $kw as xs:string
) as xs:string {
  let $id := th:identify($e)
  return $id || ' [' 
      || 'label=' || local-name($e) 
      || ', color=' || th:hue($kw)
      || ', shape=oval'
      || (if ($kw = ('current', 'inflight')) 
          then ', style=filled, fillcolor=pink' 
          else '')
      || ']; &#xA;'
};

(: Draw one arc :)
declare function th:drawarc(
  $sFrom as xs:string,
  $sTo as xs:string,
  $color as xs:string,
  $style as xs:string
) as xs:string {
  concat( $sFrom,
          ' -> ',
          $sTo,
          ' [',
          'color=', $color,
          ', style=', $style,
          (if ($style='invis')
          then ', arrowhead=none'
          else ''),
          '];&#xA;'
        )
};

(: draw arcs from a node to its children :)
declare function th:drawchildarcs(
  $e as node(),
  $kw as xs:string,
  $eCur as node()?,
  $phase as xs:string?
) {
  
  let $pid := th:identify($e),
      $color := th:hue($kw),
      $styleMarker := if ($kw eq 'past') then 'invis' else 'dotted'
  
  return if ($th:traversal eq 'io') then 
       string-join((
         th:drawarc($pid, 'start_'||$pid, $color, $styleMarker),         
         for $ch in $e/node()
                    [. instance of element() 
                    or normalize-space(.)]
         return th:drawarc($pid, th:identify($ch), $color, 'solid'),
         th:drawarc($pid, 'end_' || $pid, $color, $styleMarker)
       ),'')
  else if ($th:traversal eq 'oi') then
       string-join((
         (: needs checking, copied from io :)
         th:drawarc($pid, 'start_'||$pid, $color, $styleMarker),         
         for $ch in $e/node()
                    [. instance of element() 
                    or normalize-space(.)]
         let $colorCh := th:hue(th:oi-kw-from-n-n($ch, $eCur))
         return th:drawarc($pid, th:identify($ch), $colorCh, 'solid'),
         th:drawarc($pid, 'end_' || $pid, $color, $styleMarker)
       ),'')
  else if ($th:traversal eq 'lr') then
       let $styleSM := if (($kw eq 'inflight') 
                          or ($kw eq 'current' and $phase eq 'post')) then 
                          'invis'
                       else $styleMarker,
           $colorEM := if (($kw eq 'inflight') or 
                          ($kw eq 'current' and $phase eq 'pre')) then 
                           th:hue('future')
                       else $color
       return string-join((
         th:drawarc($pid, 'start_'||$pid, $color, $styleSM),
         for $ch in $e/node()
                    [. instance of element() 
                    or normalize-space(.)]
         let $kwPar := th:lr-kw-from-n-n-kw($e, $eCur, $phase),
             $kwCh := th:lr-kw-from-n-n-kw($ch, $eCur, $phase),
             $colorCh := if ($kwPar eq 'inflight') then
                             if ($kwCh eq 'current'
                                  and $phase eq 'post') then 
                                  th:hue('past')
                             else if ($kwCh eq 'current') then
                                  th:hue('current')
                             else if ($kwCh eq 'inflight') then
                                  th:hue('past')
                             else th:hue($kwCh)
                             
                        else if ($kwPar eq 'current') then
                             if ($phase eq 'post') then
                                  th:hue('past')
                             else if ($kwCh eq 'future') then 
                                  th:hue('future')
                             else $color
                             
                        else if ($kwPar eq 'past') then
                             th:hue('past')
                             
                        else th:hue('future')
         return th:drawarc($pid, th:identify($ch), $colorCh, 'solid'),
         th:drawarc($pid, 'end_' || $pid, $colorEM, $styleMarker)
       ),'')
  else ''
 
};

(: draw arcs from a node to its children :)
(: This varies with the algorithm we are drawing; the solution
   has grown gradually so it's a bit ad-hoc.
:)
declare function th:drawchildarc0(
  $e as node(),
  $kw as xs:string,
  $eCur as node()?,
  $phase as xs:string?
) {
  let $pid := th:identify($e),
      $hue := th:hue($kw)
  return concat(
    
      (: pointer to start-marker :)
      concat($pid, ' -> start_', $pid,
             ' [',
             (if ($th:traversal = 'lr' and $kw eq 'inflight')
             then 'style=invis, arrowhead=none'
             else if ($th:traversal eq 'lr' 
                      and $kw eq 'current' and $phase eq 'pre')
             then concat('color=', $hue, ', style=dotted')
             else if ($th:traversal eq 'lr' 
                      and $kw eq 'current' and $phase eq 'post')
             then 'style=invis, arrowhead=none'
             else if ($kw eq 'future') 
             then concat('color=', $hue, ', style=dotted')
             else if ($kw eq 'current')
             then concat('color=', $hue, ', style=dotted')
           
             else concat('style=invis',', arrowhead=none')),
             '];&#xA;'),
      
      (: pointers to child nodes :)
      string-join(
        for $ch in $e/node()[. instance of element() or normalize-space(.)]
        return concat($pid, 
                    ' -> ',
                    th:identify($ch),
                    ' [color=', 
                    if ($th:traversal eq 'io')
                    then $hue
                    else if ($th:traversal eq 'oi')
                    then th:hue(th:oi-kw-from-n-n($ch, $eCur))
                    else (: th:traversal should be lr :)
                      let $kwPar := th:lr-kw-from-n-n-kw($e, $eCur, $phase),
                          $kwCh := th:lr-kw-from-n-n-kw($ch, $eCur, $phase)
                      return 
                        if ($kwPar eq 'inflight' and $kwCh eq 'current'
                                 and $phase eq 'post')
                        then th:hue('past')
                        else if ($kwCh eq 'current')
                        then th:hue('current')
                        else if ($kwPar eq 'inflight' and $kwCh eq 'inflight')
                        then th:hue('past')
                        else if ($kwPar eq 'inflight')
                        then th:hue($kwCh)
                        else if ($kwPar eq 'current' and $phase eq 'post')
                        then th:hue('past')
                        else th:hue('future')
                    ,
                    '];&#xA;'),
        ''),
                    
      (: pointer to end-marker :)
      $pid || ' -> end_' || $pid 
      || ' [' 
      || (if ($th:traversal eq 'lr' and $kw eq 'inflight')
         then concat('color=', th:hue('future'), ', style=dotted')
         else if ($th:traversal eq 'lr' and $kw eq 'current' and $phase='pre')
         then concat('color=', th:hue('future'), ', style=dotted')
         else if ($kw eq 'future') 
         then concat('color=', $hue, ', style=dotted')
         else if ($kw eq 'current')
         then concat('color=', $hue, ', style=dotted')
         else concat('style=invis',', arrowhead=none'))
      || '];&#xA;'
  )
};


(: ****************************************************************
   * Inside-out graphs
   ****************************************************************:)
(: io-kw-from-n-level():  from node and level return keyword for node :)
declare function th:io-kw-from-n-level(
  $n as node(),
  $c as xs:integer
) as xs:string {
  let $h := th:height($n)
  return if ($h gt $c)
         then 'future'
         else if ($h eq $c)
         then 'current'
         else 'past'
};

(: graph-inside-out():  draw one diagram for inside-out traversal,
   given root node and level :)
declare function th:graph-inside-out(
  $doc as element(),
  $cLevel as xs:integer
) as xs:string {
  'digraph { &#xA;'
  || '  node [ordering=out]; &#xA;'
  
  || '  subgraph { &#xA;'
  || '    rank=same; &#xA;' 
  || string-join(
        for $node in $doc/descendant-or-self::node()
        return th:drawleaf($node, th:io-kw-from-n-level($node, $cLevel), ())
        
        , ''
      )    
  || '  } &#xA;'
  || '&#xA;' 
  
  || string-join(
        for $e in $doc/descendant-or-self::*
        return th:drawnode($e, th:io-kw-from-n-level($e, $cLevel) )
        ,'')    
  || '&#xA;' 
  
  || string-join(
        for $e in $doc/descendant-or-self::*
        return th:drawchildarcs($e, th:io-kw-from-n-level($e, $cLevel), (), () )
        ,'') 
  || '}&#xA;'
};


(: ****************************************************************
   * Outside-in graphs
   ****************************************************************:)
(: oi-kw-from-n-n(): from node we are drawing and current node, 
return status keyword :)
declare function th:oi-kw-from-n-n(
  $n as node(),
  $eCur as element()
) as xs:string {
  (: special cases for initial and final states :)
  if ($eCur/self::th:initial-state )
  then 'future'
  else if ($eCur/self::th:final-state)
  then 'past'
  
  (: normal cases :)
  else if ($n >> $eCur)
  then 'future'
  else if ($n is $eCur)
  then 'current'
  else 'past'
};


(: graph-outside-in():  draw one outside-in diagram given root element and
   current element :)
declare function th:graph-outside-in(
  $doc as element(),
  $eCur as element()
) as xs:string {
  'digraph { &#xA;'
  || '  node [ordering=out]; &#xA;'
  
  || '  subgraph { &#xA;'
  || '    rank=same; &#xA;' 
  || string-join(
        for $node in $doc/descendant-or-self::node()
        return th:drawleaf($node,th:oi-kw-from-n-n($node, $eCur), () )
        , ''
      )    
  || '  } &#xA;'
  || '&#xA;' 
  
  || string-join(
        for $e in $doc/descendant-or-self::*
        return th:drawnode($e, th:oi-kw-from-n-n($e, $eCur) )
        ,'')    
  || '&#xA;' 
  
  || string-join(
        for $e in $doc/descendant-or-self::*
        return th:drawchildarcs($e, th:oi-kw-from-n-n($e, $eCur), $eCur, () )
        ,'') 
  || '}&#xA;'
};


(: ****************************************************************
   * Left-right graphs
   ****************************************************************:)
(: lr-kw-from-n-n-kw() given node 1, current node, and current phase,
   return status keyword for first node.
:)
declare function th:lr-kw-from-n-n-kw(
  $n as node(),
  $eCur as node(),
  $phase as xs:string
) as xs:string {
  (: :)
  if ($phase eq 'pre') 
  then if ($n is $eCur)
       then 'current'
       else if (exists($n intersect $eCur/ancestor::*))
       then 'inflight'
       else if ($n << $eCur)
       then 'past'
       else if ($n >> $eCur)
       then 'future'
       else 'future'
  else if ($phase eq 'post')
  then if ($n is $eCur)
       then 'current'
       else if (exists($n intersect $eCur/ancestor::*))
       then 'inflight'
       else if ($n << $eCur)
       then 'past'
       else if (exists($n intersect $eCur/descendant::node()))
       then 'past'
       else 'future'
  else 'gargoyles'
       
};


(: graph-left-right() :)
declare function th:graph-left-right(
  $doc as element(),
  $eCur as node(),
  $phase as xs:string
) as xs:string {
  'digraph { &#xA;'
  || '  node [ordering=out]; &#xA;'
  
  || '  subgraph { &#xA;'
  || '    rank=same; &#xA;' 
  || string-join(
        for $node in $doc/descendant-or-self::node()
        return th:drawleaf($node,
                           th:lr-kw-from-n-n-kw($node, $eCur, $phase), 
                           $phase )
        , ''
      )    
  || '  } &#xA;'
  || '&#xA;' 
  
  || string-join(
        for $e in $doc/descendant-or-self::*
        return th:drawnode($e, th:lr-kw-from-n-n-kw($e, $eCur, $phase) )
        ,'')    
  || '&#xA;' 
  
  || string-join(
        for $e in $doc/descendant-or-self::*
        return th:drawchildarcs($e, 
                               th:lr-kw-from-n-n-kw($e, $eCur, $phase), 
                               $eCur, 
                               $phase )
        ,'') 
  || '}&#xA;'
};

(: ****************************************************************
   * draw(): do the work, draw the pictures, write the files
   ****************************************************************:)
declare function th:draw(
  $indir as xs:string,
  $fn as xs:string,
  $outdir as xs:string,
  $kwRoot as xs:string
) {

let $doc := doc( concat($indir, '/', $fn) ),
    $stem := replace($fn, '\.xml$',''),
    $example-root := if ($kwRoot eq 'root') 
                     then $doc/*
                     else $doc//tei:text
  
return

  if ($th:traversal eq 'io') 
  then for $i in 0 to 1 + th:height($example-root)
       let $dotfile := th:graph-inside-out($example-root, $i),
           $filename := $outdir || '/' || $stem 
                        || '.io.' || string($i) || '.dot'
       return file:write($filename, $dotfile, map {"method": "text"}) 
   
  else if ($th:traversal eq 'oi') then
       for $elem at $i0 in (<th:initial-state/>,
                            $example-root/descendant-or-self::*,
                            <th:final-state/>)
       let $i := $i0 - 1
       let $dotfile := th:graph-outside-in($example-root, $elem),
           $filename := $outdir || '/' || $stem 
                        || '.oi.' || string($i) || '.dot'
       return file:write($filename, $dotfile, map {"method": "text"}) 
   
  else if ($th:traversal eq 'lr') then
       for $node at $i in ($example-root/..,
                            $example-root/descendant-or-self::node()
                            [self::* or normalize-space()])
       for $phase in ('pre', 'post')
       let $dotfile := th:graph-left-right($example-root, $node, $phase),
           $ph := if ($node instance of text() and $phase eq 'pre')
                  then 'pcdata'
                  else $phase,
           $filename := $outdir || '/' || $stem
                        || '.lr.' || string($i) || '.' || $ph || '.dot'
       where not($node instance of text() and $phase eq 'post')
       return file:write($filename, $dotfile, map {"method": "text"}) 
   
  else 'Sorry, I don''t understand that style keyword'
};
   
(: ****************************************************************
   * Main expression (call the function we want, 
   * write files)
   ****************************************************************:)
   
(: 
let $doc := doc('../input/basic/aux/basho.xml')
let $outdir := file:base-dir() || '../doc/images/regression'

return 
:)

th:draw(
  $th:inputdir,
  $th:inputfile, 
  $th:outputdir,
  'root'
)

