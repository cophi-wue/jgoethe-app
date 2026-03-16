xquery version "3.1";
module namespace prep="http://digital-humanities.de/jgoethe/prepare";

import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";
import module namespace xdb="http://exist-db.org/xquery/xmldb";

declare function prep:init($baseCollection as xs:string) as item()* {
    if (collection(concat($baseCollection, "/pages"))) then
        xdb:remove(concat($baseCollection, "/pages"))
    else (),
    let $collection := xdb:create-collection($baseCollection, "pages")
    return ()
};

declare function prep:store-page($col as xs:string, $sectId as xs:string, $page as xs:int, $root as element()) {
    let $name := concat($sectId, "-", $page, ".xml")
    return
        xdb:store(concat($col, "/pages"), $name, $root, "text/xml")
};

declare function prep:store-page($col as xs:string, $sectId as xs:string, $content as element()*) {
    let $pageNum := prep:next-page($col, $sectId)
    return
        prep:store-page($col, $sectId, $pageNum, 
            <page sect="{$sectId}" num="{$pageNum}">
                {$content}
            </page>
        )
};

declare function prep:next-page($col as xs:string, $sectId as xs:string) as xs:int {
	let $pages := collection(concat($col, "/pages"))//page[@sect = $sectId]/@num 
    let $log := util:log("DEBUG", ("Section: ", $sectId, ": ", count($pages)))
    return 
        if ($pages) then
            max(for $p in $pages return xs:int($p)) + 1
        else
            1
};

declare function prep:process-pages($col as xs:string, $partId as xs:string, $parts as element()*, 
    $level as xs:int) {
    util:log("DEBUG", ("Processing: ", $partId, "; level: ", $level, "; parts: ", count($parts))),
    util:log-system-err(("Preparing: ", $partId, "; level: ", xs:string($level), "; parts: ", xs:string(count($parts)))),
    for $part in $parts
    let $divs := 
        $part/div2 | $part/div3 | $part/div4
    return (
        util:log("DEBUG", ("Part: ", node-name($part), "; Divs: ", count($divs), "; ", count($part/div3))),
        let $prec := $divs[1]/preceding-sibling::*
        return
            if ($prec) then
                let $pageNum := prep:next-page($col, $partId)
                return
                    prep:store-page($col, $partId, $pageNum, 
                        <page sect="{$partId}" num="{$pageNum}">
                            {$part/@xml:id, $prec}
                        </page>
                    )
            else (),
        if ($divs) then
            if ($level > 1) then
                prep:process-pages($col, $partId, $divs, $level - 1)
            else
                for $div in $divs return
                    prep:store-page($col, $partId, $div)
        else
            prep:store-page($col, $partId, $part)
    )
};

declare function prep:fix-xpath($col as xs:string, $xpath as xs:string) {
	if (starts-with($xpath, "collection(")) then
		$xpath
	else
		concat("collection('", $col, "')/", $xpath)
};

declare function prep:process-section($col as xs:string, $section as element()) {
    let $xpath := $section/@xpath
    return
        if ($xpath) then
            let $sect := util:eval(prep:fix-xpath($col, $section/@xpath))
            return
                prep:process-pages($col, $section/@ref, $sect, 2)
        else
            util:log("DEBUG", ("No path. Skip section: ", $section))
};

declare function prep:prepare($collection as xs:string) {
  let $coll := if (exists($collection)) then $collection else "/db/lenz"
  let $dummy := prep:init($coll)
  for $section in collection($coll)/configuration/structure//section
  return
      prep:process-section($coll, $section)
};
