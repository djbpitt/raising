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
            
     $doc := doc($docnames[6])
     (: N.B. 6-9 don't work because we are not set up
        for markers using @ana :)
  
  return th:raise($doc)
