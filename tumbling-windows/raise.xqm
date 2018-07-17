module namespace th = "http://www.blackmesatech.com/2017/nss/trojan-horse";

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

(:th:matching($n1, $n2):  true iff n1 and n2 are a pair :)
declare function th:matching(
  $n1 as node(),
  $n2 as node()
) as xs:boolean {
  exists($n1/@th:sID)
  and exists($n2/@th:eID)
  and ($n1/@th:sID eq $n2/@th:eID)
};

(: th:inside-out($ln):  returns input sequence with 
   one level of inner pairs bound  :)
declare function th:inside-out(
  $ln as node()*
) as node()* {
  (: trace((), 'th:inside-out() called with &#xA;' ||
    string-join($ln, '&#xA;  - ')),
    :)
  for    tumbling window $n as node()*
  in     $ln
  start  $nStart at $posStart
  when   true()
  end    $nEnd at $posEnd
  when   $nEnd is ($ln[position() gt $posStart
                   and th:is-end-marker(.)]
                   [1]
                   [th:matching($nStart, .)],
                 $nStart)[1]
  (: original form used following-sibling but did
     not work: are nodes appear to retaining identity
     across calls? or are we not always coming in with
     a fresh document?
     :)
  (:
  when   $nEnd is ($nStart
                   /following-sibling::*
                   [th:is-end-marker(.)]
                   [1]
                   [th:matching($nStart, .)],
                 $nStart)[1]
  :)       
  return if ($posStart eq $posEnd)
         then $n
         else element {name($nEnd)} {
           $nEnd/@* except $nEnd/@th:*,
           $ln[position() gt $posStart and position() lt $posEnd]
         }      
};

(: th:outside0in($ln):  returns input sequence with 
   all pairs bound (if possible), with depth-first
   pre-post traversal :)
declare function th:outside-in(
  $ln as node()*
) as node()* {
      for tumbling window $n as node()*
       in $ln
    start $nStart at $posStart
     when true()
      end $nEnd at $posEnd
     when if (th:is-start-marker($nStart)
              and 
              exists($ln[position() gt $posStart
               and th:matching($nStart, .)]))
          then (th:matching($nStart,$nEnd))
          else true() (: ($nEnd is $nStart) :)
     (:
     when ($nEnd is (
            $ln[position() gt $posStart]
               [th:matching($nStart,.)]
               [1],
            $nStart
          )[1])
     :)
   return if ($posStart eq $posEnd)
          then $n
          else element {name($nStart)} {
            $nStart/@* except $nStart/@th:*,
            th:outside-in($n
              [position() gt 1
              and position() lt last()])
          }  
};

declare function th:raise-outside-in(
  $n as node()
) as node() {
  if ($n instance of element())
  then element { name($n) } {
    $n/@*,
    th:outside-in($n/node())
  }
  else if ($n instance of document-node())
  then document {
    for $c in $n/node()
    return th:raise-outside-in($c)
  }
  else $n
};

declare function th:raise-inside-out(
  $n as node()
) as node() {
  if ($n instance of element())
  then element { name($n) } {
    $n/@*,
    (:
    trace( (), 
    'rio: building element ' || name($n) || '. &#xA;' ),
    :)
    if (exists($n/*[th:is-marker(.)]))
    then th:inside-out($n/node())
    else for $c in $n/node()
         return th:raise-inside-out($c)
  }
  else if ($n instance of document-node())
  then let $d := document {
                   for $c in $n/node()
                   return th:raise-inside-out($c)
                 }
       return if (deep-equal($n, $d))
              then $d
              else th:raise-inside-out($d)
  else $n
};

declare function th:raise(
  $n as node()
) as node() {
  th:raise-inside-out($n)
};