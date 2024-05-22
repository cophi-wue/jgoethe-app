xquery version "1.0";

declare namespace ed="http://exist-db.org/xquery/jgoethe";

import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "webapp/jgoethe/util.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";

declare variable $collection external;
 
declare function ed:init($baseCollection as xs:string) as empty() {
    if (collection(concat($baseCollection, "/pages"))) then
        xdb:remove(concat($baseCollection, "/pages"))
    else (),
    let $collection := xdb:create-collection($baseCollection, "pages")
    return ()
};

declare function ed:store-page($col as xs:string, $sectId as xs:string, $page as xs:int, $root as element()) {
    let $name := concat($sectId, "-", $page, ".xml")
    return
        xdb:store(concat($col, "/pages"), $name, $root, "text/xml")
};

declare function ed:store-page($col as xs:string, $sectId as xs:string, $content as element()*) {
    let $pageNum := ed:next-page($col, $sectId)
    return
        ed:store-page($col, $sectId, $pageNum, 
            <page sect="{$sectId}" num="{$pageNum}">
                {$content}
            </page>
        )
};

declare function ed:next-page($col as xs:string, $sectId as xs:string) as xs:int {
	let $pages := collection(concat($col, "/pages"))//page[@sect = $sectId]/@num 
    let $log := util:log("DEBUG", ("Section: ", $sectId, ": ", count($pages)))
    return 
        if ($pages) then
            max(for $p in $pages return xs:int($p)) + 1
        else
            1
};

declare function ed:process-pages($col as xs:string, $partId as xs:string, $parts as element()*, 
    $level as xs:int) {
    util:log("DEBUG", ("Processing: ", $partId, "; level: ", $level, "; parts: ", count($parts))),
    for $part in $parts
    let $divs := 
        $part/div2 | $part/div3 | $part/div4
    return (
        util:log("DEBUG", ("Part: ", node-name($part), "; Divs: ", count($divs), "; ", count($part/div3))),
        let $prec := $divs[1]/preceding-sibling::*
        return
            if ($prec) then
                let $pageNum := ed:next-page($col, $partId)
                return
                    ed:store-page($col, $partId, $pageNum, 
                        <page sect="{$partId}" num="{$pageNum}">
                            {$part/@xml:id, $prec}
                        </page>
                    )
            else (),
        if ($divs) then
            if ($level > 1) then
                ed:process-pages($col, $partId, $divs, $level - 1)
            else
                for $div in $divs return
                    ed:store-page($col, $partId, $div)
        else
            ed:store-page($col, $partId, $part)
    )
};

declare function ed:fix-xpath($col as xs:string, $xpath as xs:string) {
	if (starts-with($xpath, "collection(")) then
		$xpath
	else
		concat("collection('", $col, "')/", $xpath)
};

declare function ed:process-section($col as xs:string, $section as element()) {
    let $xpath := $section/@xpath
    return
        if ($xpath) then
            let $sect := util:eval(ed:fix-xpath($col, $section/@xpath))
            return
                ed:process-pages($col, $section/@ref, $sect, 2)
        else
            util:log("DEBUG", ("No path. Skip section: ", $section))
};

let $coll := if (exists($collection)) then $collection else "/db/lenz"
let $dummy := ed:init($coll)
for $section in collection($coll)/configuration/structure//section
return
    ed:process-section($coll, $section)
