xquery version "3.1";

import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";
import module namespace config="http://digital-humanities.de/jgoethe/config" at "config.xqm";

	
declare namespace ed="http://exist-db.org/xquery/jgoethe";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare option exist:serialize "media-type=text/html indent=no";

declare function ed:last-page($col as xs:string, $id as xs:string) as xs:int {
    let $max := max(for $p in collection(concat($col, "/pages"))/page[@sect = $id]/@num return xs:int($p))
    return
        $max
};

declare function ed:display($col as xs:string, $id as xs:string) as empty-sequence() {
    let $pageParam := request:get-parameter("page", 1) cast as xs:int
    let $part := collection(concat($col, "/pages"))/page[@sect = $id][@num = $pageParam]
    (: let $log := util:log("DEBUG", ("Loading: ", $part)) :)
    let $sectId := ($part/@xml:id | $part/*/@xml:id)[1]
    let $np := if ($pageParam eq ed:last-page($col, $id)) then -1 else $pageParam + 1
    return
        utils:transform(
            $part, 
            utils:xsl-params("top.sectionLoaded", $pageParam, $np, $id, ($part//head)[1], 
            $sectId, ""))
};

declare function ed:display-by-id($col as xs:string, $sectId as xs:string, $page as element(),
    $anchor as node()) as empty-sequence() {
    let $simple := request:get-parameter("simple", ())
    let $hits :=
        if ($simple) then
            util:expand($page[.//(p|l|head|cell)[ft:query(., $simple)]])
        else
            $page
    let $log := util:log("INFO", ("Loading: ", count($hits)))
    let $function := if ($simple) then "top.queryResultsLoaded" else "top.sectionLoaded"
    let $section := xs:string($page/@sect)
    let $subSectionId := utils:subsection-id($anchor)
    let $pageNr := xs:int($page/@num)
    let $np := if ($pageNr eq ed:last-page($col, $section)) then -1 else $pageNr + 1
    return
        utils:transform(
            $hits,
            utils:xsl-params($function, $pageNr, $np, $section, ($page//head)[1], $subSectionId, $sectId)
        )
};

declare function ed:load-by-id($col as xs:string, $id as xs:string) as empty-sequence() {
    let $anchor := (collection(concat($col, "/pages"))//id($id))[1]
    let $debug := util:log("INFO", ("ID: ", $id, ": ", $anchor)) 
    let $page := $anchor/ancestor-or-self::page
    return
        ed:display-by-id($col, $id, $page, $anchor)
};

declare function ed:load($col as xs:string) as empty-sequence() {
    let $parts := request:get-parameter("part", ())
    return
        if (exists($parts)) then
            ed:display($col, $parts[1])
        else
            ()
};

let $id := request:get-parameter("id", ())
let $col_ := request:get-parameter("c", ())
let $colname := replace($col_, '^.*/([^/]+)$', '$1')
let $col := $config:data || '/' || $colname
let $r :=
    if ($id) then
        ed:load-by-id($col, $id)
    else
        ed:load($col)
return
    $r
