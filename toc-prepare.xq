xquery version "3.1";

(:~ ----------------------------------------------------------------------------------
     Module for generating extended table of contents.
     ---------------------------------------------------------------------------------- :)
     
module namespace toc-prep="http://digital-humanities.de/jgoethe/toc-prepare";

import module namespace xdb="http://exist-db.org/xquery/xmldb";
import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";

declare namespace xi="http://www.w3.org/2001/XInclude";

declare function toc-prep:init($baseCollection as xs:string) {
    if (xmldb:collection-available(concat($baseCollection, "/toc"))) then
        xdb:remove(concat($baseCollection, "/toc"))
    else (),
    xdb:create-collection($baseCollection, "toc")
};

declare function toc-prep:process-children($col as xs:string, $partId as xs:string, $div as element(), 
$level as xs:int, $maxLevels as xs:int?, $children as element()+) as element()* {
    if ($level eq 2) then
        for $div at $pos in $children
        return
            toc-prep:process-div($col, $partId, $div, $pos, $level, $maxLevels)
    else
        for $div in $children
        return
            toc-prep:process-div($col, $partId, $div, 1, $level, $maxLevels)
};

declare function toc-prep:expand-xincludes($col as xs:string, $div as element()) as element()* {
    for $xi in $div/xi:include
    return
        doc(concat($col, "/", $xi/@href))/*
};

declare function toc-prep:process-div($col as xs:string, $partId as xs:string, $div as element(), 
$pos as xs:int, $level as xs:int, $maxLevel as xs:int?) as element()+ {
    let $children := $div/div2 | $div/div3 | $div/div4 | $div/div5 | toc-prep:expand-xincludes($col, $div)
    let $id := $div/@xml:id
    return
        if ($children) then (
            <section id="{$id}">
                {
                    if ($level gt 1) then
                        attribute ref { concat("load.xql?id=", $id, "&amp;c=", $col) }
                    else (
                        attribute part { $partId },
                        attribute ref { concat("load.xql?part=", $partId, "&amp;c=", $col) }
                    ),
                    let $head0 := $div/head[@type = 'toc']
                    let $head :=
                            if ($head0) then
                                $head0
                            else
                                ($div//head)[1]
                    return
                        if ($head) then
                            attribute title {utils:process-head($head)}
                        else
                            attribute title { "..."}
                }
                {
                    if (empty($maxLevel) or $maxLevel eq $level + 1) then
                        toc-prep:process-children($col, $partId, $div, $level + 1, $maxLevel, $children)
                    else
                        ()
                }
            </section>
        ) else
            <section id="{$id}" ref="load.xql?id={$id}&amp;c={$col}#{$id}">
            {
                if ($level eq 1) then
                    attribute part { $partId }
                else ()
            }
            {
                let $head0 := $div/head[@type = 'toc']
                let $head :=
                         if ($head0) then
                            $head0
                        else
                            ($div//head)[1]
                return
                    attribute title {utils:process-head($head)}
            }
            </section>
};

declare function toc-prep:table-of-contents($col as xs:string, $id as xs:string, $section as element()+,
    $levels as xs:int?) as element()+ {
            for $div in $section return
                toc-prep:process-div($col, $id, $div, 0, 1, $levels)
};

declare function toc-prep:fix-xpath($col as xs:string, $xpath as xs:string) {
	if (starts-with($xpath, "collection(")) then
		$xpath
	else
		concat("collection('", $col, "')/", $xpath)
};

declare function toc-prep:prepare($col as xs:string) {
    toc-prep:init($col),
    for $section in collection($col)/configuration/structure//section[@xpath]
    let $id := $section/@ref
    let $part := util:eval(toc-prep:fix-xpath($col, $section/@xpath))[1]
	let $log := util:log("DEBUG", ("Processing: ", string($section/@xpath), count($part)))
	let $log2 := util:log-system-err(("TOC Processing: ", string($section/@xpath), count($part)))
    let $toc := toc-prep:table-of-contents($col, $id, $part, ())
    return
        xdb:store(concat($col, "/toc"), concat($id, ".xml"), $toc, "text/xml")
};

