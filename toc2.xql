xquery version "1.0";

import module namespace req="http://exist-db.org/xquery/request";
import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";

declare option exist:serialize "media-type=text/xml omit-xml-declaration=no";
declare option exist:profiling "enabled=no verbosity=5";

declare namespace ed="http://exist-db.org/xquery/jgoethe";
declare namespace xi="http://www.w3.org/2001/XInclude";

import module namespace xdb="http://exist-db.org/xquery/xmldb";

declare function ed:init($baseCollection as xs:string) as empty() {
    if (collection(concat($baseCollection, "/toc"))) then
        xdb:remove(concat($baseCollection, "/toc"))
    else (),
    let $collection := xdb:create-collection($baseCollection, "toc")
    return ()
};

declare function ed:process-children($col as xs:string, $partId as xs:string, $div as element(), 
$level as xs:int, $maxLevels as xs:int?, $children as element()+) as element()* {
    if ($level eq 2) then
        for $div at $pos in $children
        return
            ed:process-div($col, $partId, $div, $pos, $level, $maxLevels)
    else
        for $div in $children
        return
            ed:process-div($col, $partId, $div, 1, $level, $maxLevels)
};

declare function ed:expand-xincludes($div as element()) as element()* {
    for $xi in $div/xi:include
    return
        doc(concat("/db/jgoethe/", $xi/@href))/*
};

declare function ed:process-div($col as xs:string, $partId as xs:string, $div as element(), 
$pos as xs:int, $level as xs:int, $maxLevel as xs:int?) as element()+ {
    let $children := $div/div2 | $div/div3 | $div/div4 | $div/div5 | ed:expand-xincludes($div)
    let $id := $div/@xml:id
    return
        if ($children) then (
            <section id="{$id}">
                {
                    if ($level gt 1) then
                        attribute ref { concat("load.xql?id=", $id, "&amp;c=", $col) }
                    else
                        attribute ref { concat("load.xql?part=", $partId, "&amp;c=", $col) },
                    let $head0 := $div/head[@type = 'toc']
                    let $head :=
                            if ($head0) then
                                $head0
                            else
                                $div//head[1]
                    return
                        if ($head) then
                            attribute title {utils:process-head($head)}
                        else
                            attribute title { "..."}
                }
                {
                    if (empty($maxLevel) or $maxLevel eq $level + 1) then
                        ed:process-children($col, $partId, $div, $level + 1, $maxLevel, $children)
                    else
                        ()
                }
            </section>
        ) else
            <section id="{$id}" ref="load.xql?id={$id}&amp;c={$col}#{$id}">
            {
                let $head0 := $div/head[@type = 'toc']
                let $head :=
                         if ($head0) then
                            $head0
                        else
                            $div//head[1]
                return
                    attribute title {utils:process-head($head)}
            }
            </section>
};

declare function ed:table-of-contents($col as xs:string, $id as xs:string, $section as element()+,
    $levels as xs:int?) as element()+ {
            for $div in $section return
                ed:process-div($col, $id, $div, 0, 1, $levels)
};

declare function ed:toc-by-id($col as xs:string, $id as xs:string) {
    util:declare-option("exist:serialize", "media-type=text/xml omit-xml-declaration=no"),
    let $anchor := collection($col)/id($id)
    let $log := util:log("DEBUG", ("Anchor: ", $anchor, "; ID: ", $id))
    let $sections := collection($col)/configuration/structure//section[@xpath]
    return
        for $section in $sections
        let $sect := 
                util:eval-inline(xcollection($col), $section/@xpath)
        where $sect//$anchor
        return
            ed:table-of-contents($col, $section/@ref, $sect, ())
};

declare function ed:toc-by-part($col as xs:string, $parts as xs:string+, $levels as xs:int?) {
    for $id in $parts
    let $section := collection($col)/configuration/structure//section[@ref=$id]
    let $log := util:log("DEBUG", ("ref:", $id))
    let $part := util:eval-inline(xcollection($col), $section/@xpath)
    return
        ed:table-of-contents($col, $id, $part, $levels)
};

declare function ed:preprocess($col as xs:string) {
    for $section in collection($col)/configuration/structure//section
    let $id := $section/@ref
    let $part := util:eval-inline(xcollection($col), $section/@xpath)
    let $toc := ed:table-of-contents($col, $id, $part, ())
    return
        xdb:store(concat($col, "/toc"), concat($id, ".xml"), $toc, "text/xml")
};

let $parts := req:get-parameter("part", ())
let $levels := req:get-parameter("levels", ())
let $id := req:get-parameter("id", ())
let $col := req:get-parameter("c", ())
return
    if ($id) then
        ed:toc-by-id($col, $id)
    else if ($parts) then
        ed:toc-by-part($col, $parts, $levels)
    else
        ed:preprocess($col)
