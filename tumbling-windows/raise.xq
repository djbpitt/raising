(: Sample usage of raise.xqm module:
     - import the module
     - load document
     - call th:raise() on document
:)
import module 
  namespace th = "http://www.blackmesatech.com/2017/nss/trojan-horse" 
  at "raise.xqm";

   
let $inputdir := '../input',
    $docnames := (($inputdir || '/basic/flattened.xml'),
                  ($inputdir || '/extended/flattened.xml'),
                  ($inputdir || '/overlap/page-and-para.xml'),
                  ($inputdir || '/overlap/frost.xml'),
         (: 5 :)  ($inputdir || '/overlap/peergynt.xml'),
                  ($inputdir || '/frankenstein/c10-coll'
                                   || '/1818_c10.xml'),
                  ($inputdir || '/frankenstein/c10-coll'
                                   || '/1823_c10.xml'),
                  ($inputdir || '/frankenstein/c10-coll'
                                   || '/1831_c10.xml'),
                  ($inputdir || '/frankenstein/c10-coll'
                                   || '/thomas_c10.xml'),
         (: 10 :) ($inputdir || '/brown/r02_flattened.xml'),
                  (: and some local tests, not in the repo :)
                  ($inputdir || '/local/flattened.l18.xml'),
                  ($inputdir || '/local/flattened.brown02.xml'),
                  ($inputdir || '/local/flattened.brown04.xml'),
                  ($inputdir || '/local/flattened.brown16.xml'),
         (: 15 :) ($inputdir || '/local/flattened.brown64.xml'),
                  ($inputdir || '/local/flattened.Corpus.xml')
            ),
            
     $doc := doc($docnames[14])
     (: N.B. 6-9 don't work because we are not set up
        for markers using @ana :)
     (: 10-16 are from the Brown Corpus, varying in number
        of samples included.  First time is inside-out,
        second is outside-in :)
     (: 10   (1):   18922.82 ms   157352.32 ms (!) :)
     (: 11   (1):   18081.68 ms   158477.41 ms :)
     (: 12   (2):   68887.08 ms   462262.34 ms :)
     (: 13   (4):  284094.94 ms  1243142.58 ms :)
     (: 14  (16): 3680705.28 ms  9839151.19 ms 
                = 1h 2m20.705 s   2h43m59.1519s :)
     (: 15  (64): n ms :)
     (: 16 (500): n ms :)
  
  return (: th:raise($doc) :)
         (: th:raise-inside-out($doc) :)
         ( 
         th:raise-inside-out($doc)
         )