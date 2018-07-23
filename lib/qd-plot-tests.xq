(: quick and dirty module for drawing plots of run times :)
(: By 'quick and dirty', I think I mean I am not sure I
   know what I am doing.
   :)
   
(: Current status:  we need a normalizing stylesheet to make
   the data a little easier to process.
   :)
   
(: Revisions:
   2018-07-22 : CMSMcQ : begin making this after making draw-svg.xqm module
:)
import module namespace draw = "http://blackmesatech.com/2018/nss/draw-svg"
    at "draw-svg.xqm";
declare namespace svg = "http://www.w3.org/2000/svg";

let $lfnTestdata := file:list('../testing', true(), 'testdata*.xml')
let $docs := for $fn in $lfnTestdata
             return doc('../testing/' || $fn)
             
(: set generic parameters here :)

let $normalsize := 480


(: define getx, gety, getz functions :)

let $gettime := function($e as element(run)) { $e/@geometry/number() },
    $gety := function($e as element(observation)) { $e/@filesize/number() },
    $getx := function($e as element(observation)) { $e/@quality/number() },
    $zlabel := 'geometry (pixels)',
    $ylabel := 'file size (bytes)',
    $xlabel := 'quality (-q)',
    
    (: Universe of discourse :)
    $U := $doc//observation,
    
    $xyz as map(xs:string, item()*) := map{
               'universe' : $U,
               'getvalue' : map{
                              'x' : $getx,
                              'y' : $gety,
                              'z' : $getz 
                            },
               'getlabel' : map{
                              'x' : $xlabel,
                              'y' : $ylabel,
                              'z' : $zlabel 
                            },
               'normalsize' : $normalsize,
               'bygroup' : $bygroup
            }
        
return draw:draw('linegraph', $xyz)