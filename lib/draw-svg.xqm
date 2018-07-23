(: draw-svg.xq:  plot some points in an SVG plot :)

(: 2018-07-22 : CMSMcQ : make a module out of this, or try to :)
(: 2016-09-09 : CMSMcQ : reread, add comments :)
(: 2016-01-18 : CMSMcQ : made initial version :)

(: To do: 
   - make into a module with a clean interface; pass in data
     and a list of options
:)

(: Module for drawing SVG, given
   - a set of items from which to draw data
   - functions for extracting x, y, and z values from those nodes
   
   Functions:
   
   draw:draw($kw, $data, $fx, $fy, $fz, $fzlabel):  draw the kind of diagram
     specified by $kw, given the data and the three functions.
     
     This is only suitable when there are a finite (and small) number 
     of $z variables.  The $zlabel function specifies how to label
     the line (for a linegraph) for each z value, or what symbol to use
     for each plot point (for a scatter plot)
     
     Returns an SVG element.
     
   draw:scatterplot($data, $fx, $fy, $fz)
   
   draw:linegraph($data, $fx $fy, $fz)
     
     When there is more than one z value, there will be more than
     one line.
    
   Internal use only:
   draw:tickunit($n)
:)

(: For sample use see 2018/misc/sample-svg-draw.xq :)

(: **************************************************************** 
   * 
   ****************************************************************:)

module namespace draw = "http://blackmesatech.com/2018/nss/draw-svg";

declare namespace svg = "http://www.w3.org/2000/svg";


(: **************************************************************** 
   * 
   ****************************************************************:)
declare variable $draw:ns as xs:string := "http://blackmesatech.com/2018/nss/draw-svg";

(: Goal: find a number of the form 1En or 5en that will produce 
   between five and fifteen ticks :)
declare function draw:tickunit(
  $n as xs:double
) as xs:double {
  (: $oom = order of magnitude
     $tic = 10 ** $oom (base tickmark)
     $mag = magnitude (ratio $n : $tic) 
  :)
  let $oom := floor(math:log10($n)),
      $tic := math:pow(10, $oom),
      $mag := $n div $tic
  return if ($mag ge 5) (: 5-9 ticks :)
         then $tic
         else if ($mag ge 3) 
         then $tic div 2 (: yields 6-9 ticks :)
         else if ($mag ge 1.5)
         then $tic div 5 (: yields 7-14 ticks :)
         else $tic div 10 (: yields 10-14 ticks :)
};

(: **************************************************************** 
   * 
   ****************************************************************:)

(: valuepath():  plot a line from plot point to plot point,
   selecting all observations that have the z = $gv.
  
   (Should parameterize this to include or omit the actual
   plot line, to specify graphic properties for the plot
   points, and to specify graphic properties for the line
   if one is drawn.) 

Arguments: 

  $gv value on z axis 
  $getx: function from observation to x value
  $gety: function from observation to y value
  $getz: function from observation to z value
  $scalex: function from x value to x-coordinate in plot
  $scaley: function from x value to y-coordinate in plot
  $U: set of observations (any items will do)
:)

declare function draw:valuepath(
  $gv   as item(),
  $getx as function(*),
  $gety as function(*),
  $getz as function(*),
  $scalex as function(*),
  $scaley as function(*),
  $U    as item()*
) as element()* {
  <polyline xmlns="http://www.w3.org/2000/svg"
   points="{
     string-join(
       for $o in $U[$getz(.) eq $gv]
       let $x := $getx($o),
           $y := $gety($o)
       order by $x
       return concat($scalex($x), ',', $scaley($y)),
       ' ')
   }"/>,
   (: find rightmost point (first one, if there are 
      several), place a label 3 units to its right.
      This should be better parameterized, as to
      placement, as to text styling, and as to text.      
   :)
   let $xmax := max(for $o in $U[$getz(.) eq $gv]
                    return $getx($o)),
       $ultima := $U[$getz(.) eq $gv][$getx(.) eq $xmax][1],
       $ymax := $gety($ultima)
   return 
   <text xmlns="http://www.w3.org/2000/svg"
         x="{$scalex($xmax) + 3}" y="{$scaley($ymax)}">{$gv}</text>
};

(: **************************************************************** 
   * draw:linegraph()
   ****************************************************************:)
declare function draw:linegraph(
  $map as map(*)
)
as element(svg:svg) {
  
     
    (: define scaling functions for x and y values :)
let $U := $map('universe'),
    $getx := $map('getvalue')('x'),
    $gety := $map('getvalue')('y'),
    $getz := $map('getvalue')('z'),
    $normalsize := $map('normalsize')
    
let    
    $xmax := max(for $obs in $U return $getx($obs)),
    $ymax := max(for $obs in $U return $gety($obs)),
    $scale-x := function($n as xs:double) { ($n div $xmax) * $normalsize },
    $scale-y := function($n as xs:double) { (($n div $ymax) * $normalsize * -1) + $normalsize },
    
    (: draw the axes :)
    $xaxis := <line xmlns="http://www.w3.org/2000/svg"
                    class="axis"
                    x1="{$scale-x(0)}" y1="{$scale-y(0)}"
                    x2="{$scale-x($xmax)}" y2="{$scale-y(0)}"/>,
    $yaxis := <line xmlns="http://www.w3.org/2000/svg"
                    class="axis"
                    x1="{$scale-x(0)}" y1="{$scale-y(0)}"
                    x2="{$scale-x(0)}" y2="{$scale-y($ymax)}"/>,
   
    (: tick marks.  need to figure a way to get reasonable units :)
    (: find a number of the form 1En or 5en that will produce between five and fifteen ticks :)
    $xtickunit := draw:tickunit($xmax),
    $ytickunit := draw:tickunit($ymax),
    $xticks := for $i in 1 to floor($xmax idiv $xtickunit)
               let $j := $i * $xtickunit
               return (<line xmlns="http://www.w3.org/2000/svg" 
                            class="grid" 
                            x1="{$scale-x($j)}" y1="{$scale-y(0)}"
                            x2="{$scale-x($j)}" y2="{$scale-y($ymax)}"/>,
                       <text xmlns="http://www.w3.org/2000/svg"
                            x="{$scale-x($j) - 15}" y="{$scale-y(0) + 20}">{$j}</text>
                          ),
    $yticks := for $i in 1 to floor($ymax idiv $ytickunit)
               let $j := $i * $ytickunit
               return (<line xmlns="http://www.w3.org/2000/svg"
                            class="grid" 
                            x1="{$scale-x(0)}" y1="{$scale-y($j)}"
                            x2="{$scale-x($xmax)}" y2="{$scale-y($j)}"/>,
                       <text xmlns="http://www.w3.org/2000/svg"
                            x="{$scale-x(0) - 60}" y="{$scale-y($j) + 5}">{$j}</text>)
  
  return
  
  <svg xmlns="http://www.w3.org/2000/svg">
    <defs>
      <style type="text/css"><![CDATA[
        line.axis {
          fill: none;
          stroke: black;
          stroke-width: 1
        }
        line.grid {
          fill: none;
          stroke: #888;
          stroke-width: 0.5
        }
        polyline {
          fill: none;
          stroke: blue;
          stroke-width: 1;
        }
      ]]></style>
    </defs>
    <g transform="translate(100,100)">{ 
      comment { 'x axis' },
      $xaxis, 
      comment { 'y axis' },
      $yaxis,
      comment { 'x ticks' },
      $xticks, 
      comment { 'y ticks' },
      $yticks,
      <text xmlns="http://www.w3.org/2000/svg"
            x="{$scale-x(0)}" y="{$scale-y(0) + 50}"
            >x = {
              $map('getlabel')('x')
            }, y = {
              $map('getlabel')('y')
            }, z (lines) = {
              $map('getlabel')('y')
            }</text>,
    
      for $gv in distinct-values(for $o in $U return $getz($o))
      order by $gv ascending
      return draw:valuepath($gv, $getx, $gety, $getz, $scale-x, $scale-y, $U)
    }</g>
  </svg>
};

(: **************************************************************** 
   * draw:scatterplot()
   ****************************************************************:)

declare function draw:scatterplot(
  $map as map(*)
)
as element(svg:svg) {
  <svg:SVG>{comment{ '* Sorry, no scatter plots yet. *'}}</svg:SVG>
};


(: **************************************************************** 
   * draw:draw()
   ****************************************************************:)
(: draw:draw($kw, $map):  draw a diagram using the map :)
(: Map should be:
 map{
               'universe' : $Universe-of-discourase,
               'getvalue' : map{
                              'x' : $getx,
                              'y' : $gety,
                              'z' : $getz 
                            },
               'getlabel' : map{
                              'x' : $xlabel,
                              'y' : $ylabel,
                              'z' : $zlabel 
                            }
            }
:)

declare function draw:draw(
  $kw as xs:string,
  $map as map(xs:string, item()*)
) as element(svg:svg) {
  if (not($map('universe') instance of item()*)) then
     error(QName($draw:ns,'draw:draw-02'), 
           '$map("universe") should be universe of discourse.')
           
  else if (not($map('getvalue') instance of map(xs:string, function(*)))) then 
     error(QName($draw:ns,'draw:draw-02'), 
           '$map("getvalue") should be map of functions.')
  else if (not($map('getvalue')('x') instance of 
          function(*))) then 
     error(QName($draw:ns,'draw:draw-03'), 
           '$map("getvalue")("x") should be a function from item() to number.')
  else if (not($map('getvalue')('y') instance of 
          function(*))) then 
     error(QName($draw:ns,'draw:draw-04'), 
           '$map("getvalue")("y") should be a function from item() to number.')
  else if (not($map('getvalue')('z') instance of 
          function(*))) then 
     error(QName($draw:ns,'draw:draw-05'), 
           '$map("getvalue")("z") should be a function from item() to number.')
           
  else if (not($map('getlabel') instance of map(*))) then 
     error(QName($draw:ns,'draw:draw-06'), 
           '$map("getlabel") should be map of functions.')
  else if (not($map('getlabel')('x') instance of 	
          xs:string)) then 
     error(QName($draw:ns,'draw:draw-07'), 
           '$map("getlabel")("x") should be a function from item() to string.')
  else if (not($map('getlabel')('y') instance of 
          xs:string)) then 
     error(QName($draw:ns,'draw:draw-08'), 
           '$map("getlabel")("y") should be a function from item() to string.')
  else if (not($map('getlabel')('z') instance of 
          xs:string)) then 
     error(QName($draw:ns,'draw:draw-09'), 
           '$map("getlabel")("z") should be a function from item() to string.')
           
  else if ($kw eq 'linegraph') then
     draw:linegraph($map)
  else if ($kw eq 'scatterplot') then
     draw:scatterplot($map)
  else 
     error(QName($draw:ns,'draw:draw-01'), 
         "Unexpected diagram type",
         $kw)
};