module namespace utils="http://exist-db.org/xquery/jgoethe/utils";

import module namespace transform="http://exist-db.org/xquery/transform";
import module namespace util="http://exist-db.org/xquery/util";

declare namespace xi="http://www.w3.org/2001/XInclude";

declare function utils:process-head($head as element(head)?) as xs:string {
    translate(
        string-join(
            for $node in $head/node()
            return
                if ($node instance of element(lb)) then
                	" "
                else if ($node instance of element(title) or $node instance of element(ref) or $node instance of element(hi)) then
                	string($node)
                else if ($node instance of text()) then
                	string($node)
                else
                	()
            , " "
        ), "'", ""
    )
};

declare function utils:xsl-params($func, $page as xs:int, $nextPage as xs:int, $id as xs:string, $head as element(),
$subSect as xs:string?, $anchor as xs:string) as element() {
    let $onload := concat(
                    $func, "('", if ($page gt 0) then utils:process-head($head) else (),
                    "', '", $id, "', ", $page, ", ", $nextPage, ", '", $subSect, "')"
                   )
    return
        <parameters>
            <param name="onload" value="{$onload}"/>
            <param name="anchor" value="{$anchor}"/>
        </parameters>
};

declare function utils:transform($sect as element()?) as empty-sequence() {
    utils:transform($sect, ())
};

declare function utils:transform($sect as element()?, $params as element()?) as empty-sequence() {
    transform:stream-transform($sect, doc("/db/jgoethe/tei2html.xsl"), $params)
};

declare function utils:find-pages($col as xs:string, $parts as element()*, $level as xs:int) as element()* {
    for $part in $parts
    let $divs := (
        utils:get-xincluded-divs($col, $part),
        if ($part instance of element(div1)) then
            $part/div2
        else if ($part instance of element(div2)) then
            $part/div3
        else if ($part instance of element(div3)) then
            $part/div4
        else
            $part
    )
    return (
        let $prec := $divs[1]/preceding-sibling::*
        return
            if ($prec) then <page>{$prec}</page> else (),
        if ($level > 1) then
            utils:find-pages($col, $divs, $level - 1)
        else
            if ($divs) then (
                for $div in $divs return <page>{$div}</page>
            ) else
                $part
    )
};

declare function utils:find-pages-with-anchor($col as xs:string, $parts as element()*, $anchor as node(), 
    $level as xs:int) as element()* {
    for $part in $parts
    let $divs := (
        utils:get-xincluded-divs($col, $part),
        if ($part instance of element(div1)) then
            $part/div2
        else if ($part instance of element(div2)) then
            $part/div3
        else if ($part instance of element(div3)) then
            $part/div4
        else
            $part
    )
    return (
        if ($level > 1) then
            utils:find-pages-with-anchor($col, $divs, $anchor, $level - 1)
        else
            let $div := $divs[.//$anchor]
            return
                if ($div) then
                    (index-of($divs, $div), $div)
                else ()
    )
};

declare function utils:get-xincluded-divs($col as xs:string, $part as element()) as element()* {
    for $xi in $part/xi:include
    return
        doc(concat($col, "/", $xi/@href))/*
};

declare function utils:get-divs($col as xs:string, $part as element()) as node()* {
    utils:get-xincluded-divs($col, $part),
    if ($part instance of element(div1)) then
        $part/div2
    else if ($part instance of element(div2)) then
        $part/div3
    else if ($part instance of element(div3)) then
        $part/div4
    else
        $part
};

declare function utils:get-subdivs($col as xs:string, $part as element()) as node()* {
    let $divs := (
        utils:get-xincluded-divs($col, $part),
        if ($part instance of element(div1)) then
            $part/div2
        else if ($part instance of element(div2)) then
            $part/div3
        else if ($part instance of element(div3)) then
            $part/div4
        else
            $part
    )
    return
        if ($divs) then $divs else $part
};

declare function utils:subsection-id($anchor as node()) as xs:string {
    let $section := ($anchor/ancestor-or-self::div5 | $anchor/ancestor-or-self::div4 | 
        $anchor/ancestor-or-self::div3 | $anchor/ancestor-or-self::div2 | $anchor/ancestor-or-self::div1 |
        $anchor/ancestor-or-self::page)/@xml:id
    return $section[last()] cast as xs:string
};
