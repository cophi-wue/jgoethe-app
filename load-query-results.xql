xquery version "1.0";

import module namespace req="http://exist-db.org/xquery/request";
import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";

declare option exist:serialize "media-type=text/html";

declare namespace ed="http://exist-db.org/xquery/jgoethe";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare function ed:follow-xinclude($col as xs:string, $sect as element()) as element()* {
    let $includes := $sect/xi:include
    return
        if ($includes) then
            for $xi in $includes return doc(concat($col, "/", $xi/@href))/*
        else
            $sect
};

declare function ed:query($col as xs:string, $id as xs:string, $page as element(),
    $anchor as node()) as empty() {
    let $mode := req:get-parameter("mode", ())
    let $query := req:get-parameter("query", ())
    let $hits := util:eval(concat("$page[.", $query, "]"))
    let $pageNr := xs:int($page/@num)
    return
        utils:transform(
            $hits,
            utils:xsl-params("top.queryResultsLoaded", $pageNr, $pageNr + 1, $page/@sect, ($page//head)[1], (), $id)
        )
};

declare function ed:query-by-id($col as xs:string, $id as xs:string) as empty() {
    let $anchor := collection(concat($col, "/pages"))//id($id)
    let $page := $anchor/ancestor-or-self::page
    return
        ed:query($col, $id, $page, $anchor)
};

let $id := req:get-parameter("id", ())
let $col := request:get-parameter("c", ())
return
    ed:query-by-id($col, $id)