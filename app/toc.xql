xquery version "1.0";

import module namespace req="http://exist-db.org/xquery/request";
import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";

declare option exist:serialize "media-type=text/html";
declare option exist:profiling "enabled=no verbosity=5";

declare namespace ed="http://exist-db.org/xquery/jgoethe";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare function ed:process-children($col as xs:string, $partId as xs:string, $div as element(), 
$level as xs:int, $children as element()+) as element()* {
    if ($level eq 2) then
        for $div at $pos in $children
        return
            ed:process-div($col, $partId, $div, $pos, $level)
    else
        for $div in $children
        return
            ed:process-div($col, $partId, $div, 1, $level)
};

declare function ed:expand-xincludes($div as element()) as element()* {
    for $xi in $div/xi:include
    return
        doc(concat("/db/jgoethe/", $xi/@href))/*
};

declare function ed:process-div($col as xs:string, $partId as xs:string, $div as element(), 
$pos as xs:int, $level as xs:int) as element()+ {
    let $children := $div/div2 | $div/div3 | $div/div4 | $div/div5 | ed:expand-xincludes($div)
    let $id := $div/@xml:id
    return
        <div class="toc_section" id="TOC_{$partId}">
        {
        if ($children) then (
            <table class="expandable">
                <tr>
                    <td class="icon">
                    {
                        if ($level gt 1) then
                            <a class="expand" onclick="tocExpand('{$id}', this)"><img src="images/expand.gif"/></a>
                        else
                            ()
                    }
                    </td>
                    <td>
                        <a id="{$id}" class="level{$level}" target="content" 
                            onclick="loadIndicator(true)">
                        {
                            if ($level gt 1) then
                                attribute href { concat("load.xql?id=", $id, "&amp;c=", $col) }
                            else
                                attribute href { concat("load.xql?part=", $partId, "&amp;c=", $col) },
                            let $head0 := $div/head[@type = 'toc']
                            let $head :=
                                    if ($head0) then
                                        $head0
                                    else
                                        $div//head[1]
                            return
                                if ($head) then
                                    utils:process-head($head)
                                else
                                    "..."
                        }
                        </a>
                    </td>
                </tr>
            </table>,
            <div id="D_{$id}" class="entries" style="display: { if ($level gt 1) then 'none' else 'block'};">
                {ed:process-children($col, $partId, $div, $level + 1, $children)}
            </div>
        ) else
            <table class="expandable">
                <tr>
                    <td class="icon"></td>
                    <td>
                        <a id="{$id}" class="entry" target="content" href="load.xql?id={$id}&amp;c={$col}#{$id}">
                        {
                            let $head0 := $div/head[@type = 'toc']
                            let $head :=
                                     if ($head0) then
                                        $head0
                                    else
                                        $div//head[1]
                            return
                                utils:process-head($head)
                        }
                        </a>
                    </td>
                </tr>
            </table>
    }
    </div>
};

declare function ed:table-of-contents($col as xs:string, $id as xs:string, $section as element()+) as element()+ {
    (: <html>
        <head>
            <title>Table of contents</title>
            <link href="styles/toc.css" type="text/css" rel="stylesheet"/>
        </head>
        <body onload="top.tocLoaded()">
        { :)
            for $div in $section return
                ed:process-div($col, $id, $div, 0, 1)
        (: }</body>
    </html> :)
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
            ed:table-of-contents($col, $section/@ref, $sect)
};

declare function ed:toc-by-part($col as xs:string, $parts as xs:string+) {
    for $id in $parts
    let $section := collection($col)/configuration/structure//section[@ref=$id]
    let $log := util:log("DEBUG", ("ref:", $id))
    let $part := util:eval-inline(xcollection($col), $section/@xpath)
    return
        ed:table-of-contents($col, $id, $part)
};

let $parts := req:get-parameter("part", ())
let $id := req:get-parameter("id", ())
let $col := req:get-parameter("c", ())
return
    if ($id) then
        ed:toc-by-id($col, $id)
    else
        ed:toc-by-part($col, $parts)
