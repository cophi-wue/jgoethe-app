xquery version "3.1";

import module namespace config="http://digital-humanities.de/jgoethe/config" at "config.xqm";
import module namespace response="http://exist-db.org/xquery/response";
import module namespace util="http://exist-db.org/xquery/util";

let $id := request:get-parameter("id", ())
return
    if (empty($id)) then
        ()
    else
        let $url := doc($config:col || "/graphics.xml")//id($id),
            $data := util:binary-doc($config:col || "/" || $url/@url)
        return response:stream-binary($data, "image/gif")
