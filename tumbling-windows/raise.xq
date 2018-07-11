(: Sample usage of raise.xqm module:
     - import the module
     - load document
     - call th:raise() on document
:)
import module 
  namespace th = "http://www.blackmesatech.com/2017/nss/trojan-horse" 
  at "raise.xqm";

   
let $inputdir := 'file:///Users/cmsmcq/2018/talks'
                 || '/Balisage-late-breaking/raising'
                 || '/input',
    $dir := $inputdir || '/basic',
    $doc := doc($dir || '/flattened.xml')
    
    
(: 
  return $th:raise($doc)
:)

(:
return ( $doc, <tmp>{ 'foo' eq () }</tmp>, 
  <result xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse">{
  th:inside-out($doc/root/node())
}</result>
)
:)

return th:raise($doc)

(: 
for $nS in $doc/root/*[th:is-start-marker(.)]
let $nE := $nS/following-sibling::*[th:is-end-marker(.)][1]
where th:matching($nS,$nE)
    
return <list xmlns:th="http://www.blackmesatech.com/2017/nss/trojan-horse" >
<start>{$nS}</start>
<end>{$nE}</end>
</list>
:)