xquery version "1.0";

import module namespace response="http://exist-db.org/xquery/response";
import module namespace util="http://exist-db.org/xquery/util";

let $id := request:get-parameter("id", ())
return
    if (empty($id)) then
        ()
    else
        let $url := doc("/db/jgoethe/graphics.xml")//id($id)
        let $data := util:binary-doc(concat("/db/jgoethe/", $url/@url))
        return response:stream-binary($data, "image/gif")
