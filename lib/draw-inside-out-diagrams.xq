declare namespace th = "http://www.blackmesatech.com/2017/nss/trojan-horse";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $th:style as xs:string := 'lr';
(: oi, io, lr :)

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


(: height (for io generations) :)
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

(: hue and markerhue():  what color am i? :)
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

(: ******************************** 
   * Drawing things (emitting dot code)
   ********************************:)
(: draw a leaf :)
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
     if ($n/@th:sID) then
        'start_' || $id || ' ['
                 || 'label="' || $gi || '\nstart", '
                 || 'shape=point, '
                 || 'color=' (: this color assignment is 
                                almost certainly wrong 
                                for unmatchable elements :)
                 || (if ($th:style eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'pre')
                     then th:markerhue('current')
                     else if ($th:style eq 'lr' 
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
               || (if ($th:style eq 'lr' 
                      and $kw eq 'current'
                      and $phase eq 'pre')
                  then th:markerhue('future')
                  else if ($th:style eq 'lr' 
                      and $kw eq 'current'
                      and $phase eq 'post')
                  then th:markerhue('current')
                  else if ($th:style eq 'lr'
                      and $kw eq 'inflight')
                    then th:markerhue('future')
                  else $markerhue)
               || '];&#xA;'
     else if ($n instance of element()) then 
        'start_' || $id || ' ['
                 || 'label="' || $gi || '\nstart", '
                 || 'shape=point, '
                 || 'color='
                 || (if ($th:style eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'pre')
                     then th:markerhue('current')
                     else if ($th:style eq 'lr' 
                         and $kw eq 'current'
                         and $phase eq 'post')
                     then th:markerhue('past')
                     else $markerhue)
                 || '];&#xA;'
       || 'end_' || $id || ' ['
                 || 'label="' || $gi || '\nend", '
                 || 'shape=point, '
                 || 'color=' 
                 || (if ($th:style eq 'lr' 
                        and $kw eq 'current'
                        and $phase eq 'pre')
                    then th:markerhue('future')
                    else if ($th:style eq 'lr' 
                        and $kw eq 'current'
                        and $phase eq 'post')
                    then th:markerhue('current')
                    else if ($th:style eq 'lr'
                        and $kw eq 'inflight')
                    then th:markerhue('future')
                    else $markerhue)
                 || '];&#xA;'
  else if ($n instance of text() and normalize-space($n)) then
     let $id := th:identify($n)
     return $id || ' [shape=box, label="' || string($n) || '"'
             || (if ($th:style eq 'lr') 
                 then 'color=' || $hue else '')
             || '];&#xA;'
  else '// node missing &#xA;'
};

(: draw a node :)
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

(: draw arcs from a node to its children :)
(: This varies with the algorithm we are drawing; the solution
   has grown gradually so it's a bit ad-hoc.
:)
declare function th:drawchildarc(
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
             (if ($th:style = 'lr' and $kw eq 'inflight')
             then 'style=invis, arrowhead=none'
             else if ($th:style eq 'lr' 
                      and $kw eq 'current' and $phase eq 'pre')
             then concat('color=', $hue, ', style=dotted')
             else if ($th:style eq 'lr' 
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
                    if ($th:style eq 'io')
                    then $hue
                    else if ($th:style eq 'oi')
                    then th:hue(th:oi-kw-from-n-n($ch, $eCur))
                    else (: th:style should be lr :)
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
      || (if ($th:style eq 'lr' and $kw eq 'inflight')
         then concat('color=', th:hue('future'), ', style=dotted')
         else if ($th:style eq 'lr' and $kw eq 'current' and $phase='pre')
         then concat('color=', th:hue('future'), ', style=dotted')
         else if ($kw eq 'future') 
         then concat('color=', $hue, ', style=dotted')
         else if ($kw eq 'current')
         then concat('color=', $hue, ', style=dotted')
         else concat('style=invis',', arrowhead=none'))
      || '];&#xA;'
  )
};


(: ************************************************
   * Inside-out graphs
   ************************************************ :)
(: io-kw-from-n-level():  from node and level return keyword :)
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
        return th:drawchildarc($e, th:io-kw-from-n-level($e, $cLevel), (), () )
        ,'') 
  || '}&#xA;'
};


(: ************************************************
   * Outside-in graphs
   ************************************************ :)
(: oi-kw-from-n-n(): from node we are drawing and current node, 
return keyword :)
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


(: graph-outside-in() :)
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
        return th:drawchildarc($e, th:oi-kw-from-n-n($e, $eCur), $eCur, () )
        ,'') 
  || '}&#xA;'
};


(: ************************************************
   * Left-right graphs
   ************************************************ :)

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
        return th:drawchildarc($e, 
                               th:lr-kw-from-n-n-kw($e, $eCur, $phase), 
                               $eCur, 
                               $phase )
        ,'') 
  || '}&#xA;'
};

(: ************************************************
   * Main expression (call the function we want, 
   * write files)
   ************************************************ :)
   
let $doc := doc('../input/basic/aux/basho.xml')
let $outdir := file:base-dir() || '../doc/images'

return if ($th:style eq 'io') then 
   for $i in 0 to 5 
   let $dotfile := th:graph-inside-out($doc//tei:text, $i),
       $filename := $outdir || '/basho-versetree.io.bis.' 
                    || string($i) || '.dot'
   return file:write($filename, $dotfile, map {"method": "text"}) 
   
else if ($th:style eq 'oi') then
   let $example-root := $doc//tei:text
   for $elem at $i0 in (<th:initial-state/>,
                        $example-root/descendant-or-self::*,
                        <th:final-state/>)
   let $i := $i0 - 1
   let $dotfile := th:graph-outside-in($example-root, $elem),
       $filename := $outdir || '/basho-versetree.oi.bis.' 
                    || string($i) || '.dot'
   return file:write($filename, $dotfile, map {"method": "text"}) 
   
else if ($th:style eq 'lr') then
   let $example-root := $doc//tei:text
   for $node at $i in ($example-root/..,
                        $example-root/descendant-or-self::node()
                        [self::* or normalize-space()])
   for $phase in ('pre', 'post')
   let $dotfile := th:graph-left-right($example-root, $node, $phase),
       $filename := $outdir || '/basho-versetree.lr.bis.' 
                    || string($i) || '.' || $phase || '.dot'
   where not($node instance of text() and $phase eq 'post')
   return file:write($filename, $dotfile, map {"method": "text"}) 
   
else 'Sorry, I don''t understand that style keyword'


