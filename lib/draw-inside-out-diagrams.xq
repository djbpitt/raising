declare namespace th = "http://www.blackmesatech.com/2017/nss/trojan-horse";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

(: Utilities :)
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

declare function th:height(
  $n as node()
) as xs:integer {
  let $ld := $n/descendant::*
  return if (empty($ld))
     then 0
     else let $h0 := max(for $d in $n/descendant::* 
                         return count($d/ancestor::*))
          let $h1 := count($n/ancestor::*)
          return $h0 - $h1
          (:
  (max(for $d in $n/descendant::* return count($d/ancestor::*)),
  - count($n/ancestor::*)
  :)
};

(: calculate an identifier for dot :)
declare function th:identify(
  $n as node()
) as xs:string {
  if ($n instance of text())
  then 'pcd' || string(1 + count($n/preceding::text()))
  else if ($n instance of element())
  then local-name($n) || '_' || string(count($n/preceding::*))
  else 'fubar'
};

declare function th:hue(
  $kw as xs:string
) as xs:string {
  if ($kw eq 'future') then 'gray'
              else if ($kw eq 'current') then 'red'
              else 'black'
};

declare function th:markerhue(
  $kw as xs:string
) as xs:string {
  if ($kw eq 'future') then 'black'
              else if ($kw eq 'current') then 'red'
              else 'transparent'
};


(: draw a leaf :)
declare function th:drawleaf(
  $n as node(),
  $kw as xs:string
) as xs:string {
  let $gi := local-name($n),
      $id := th:identify($n),
      $hue := th:hue($kw),
      $markerhue := th:markerhue($kw)
  return 
     if ($n/@th:sID) then
        'start_' || $id || ' ['
                 || 'label="' || $gi || '\nstart", '
                 || 'shape=point, '
                 || 'color=' || $markerhue
                 || '];&#xA;'
     else if ($n/@th:eID) then
        'end_' || $id || ' ['
               || 'label="' || $gi || '\nend", '
               || 'shape=point, '
               || 'color=' || $markerhue
               || '];&#xA;'
     else if ($n instance of element()) then 
        'start_' || $id || ' ['
                 || 'label="' || $gi || '\nstart", '
                 || 'shape=point, '
                 || 'color=' || $markerhue
                 || '];&#xA;'
       || 'end_' || $id || ' ['
                 || 'label="' || $gi || '\nend", '
                 || 'shape=point, '
                 || 'color=' || $markerhue
                 || '];&#xA;'
  else if ($n instance of text() and normalize-space($n)) then
     let $id := th:identify($n)
     return $id || ' [shape=box, label="' || string($n) || '"];&#xA;'
  else '// node missing &#xA;'
};

declare function th:drawnode(
  $e as element(),
  $kw as xs:string
) as xs:string {
  let $id := th:identify($e)
  return $id || ' [' 
      || 'label=' || local-name($e) 
      || ', color=' || th:hue($kw)
      || ', shape=oval'
      || (if ($kw eq 'current') then 'style=filled, fillcolor=pink' else '')
      || ']; &#xA;'
};

declare function th:drawchildarc(
  $e as node(),
  $kw as xs:string
) {
  let $pid := th:identify($e),
      $hue := th:hue($kw)
  return concat(
      concat($pid, ' -> start_', $pid,
             ' [',
             (if ($kw eq 'future') 
             then concat('color=', $hue, ', style=dotted')
             else if ($kw eq 'current')
             then concat('color=', $hue, ', style=dotted')
             else concat('style=invis',', arrowhead=none')),
             '];&#xA;'),
      
      string-join(
        for $ch in $e/node()[. instance of element() or normalize-space(.)]
        return concat($pid, 
                    ' -> ',
                    th:identify($ch),
                    ' [color=', $hue, '];&#xA;'),
        ''),
                    
      $pid || ' -> end_' || $pid 
      || ' [' 
      || (if ($kw eq 'future') 
         then concat('color=', $hue, ', style=dotted')
         else if ($kw eq 'current')
         then concat('color=', $hue, ', style=dotted')
         else concat('style=invis',', arrowhead=none'))
      || '];&#xA;'
  )
};


declare function th:graph(
  $doc as element(),
  $cLevel as xs:integer
) as xs:string {
  'digraph { &#xA;'
  || '  node [ordering=out]; &#xA;'
  
  || '  subgraph { &#xA;'
  || '    rank=same; &#xA;' 
  || string-join(
        for $node in $doc/descendant-or-self::node()
        return th:drawleaf($node, 'future')
        , ''
      )    
  || '  } &#xA;'
  || '&#xA;' 
  
  || string-join(
        for $e in $doc/descendant-or-self::*
        return th:drawnode($e, 'future')
        ,'')    
  || '&#xA;' 
  
  || string-join(
        for $e in $doc/descendant-or-self::*
        return th:drawchildarc($e, 'future')
        ,'') 
  || '}&#xA;'
};

let $doc := doc('../input/basic/aux/basho.xml')

return th:graph($doc//tei:text, 0)