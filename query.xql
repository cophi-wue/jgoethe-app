xquery version "1.0";

import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";
import module namespace simpleql="http://exist-db.org/xquery/simple-ql"
at "java:org.exist.xquery.modules.simpleql.SimpleQLModule";


declare namespace ed="http://exist-db.org/xquery/jgoethe";
declare namespace xi="http://www.w3.org/2001/XInclude";

declare option exist:serialize "media-type=text/html";

declare function ed:load-section($col as xs:string, $id as xs:string) as node()+ {
    let $section := collection($col)/configuration/structure//section[@ref=$id]
    let $part := util:eval-inline(collection($col), $section/@xpath)
    return
        $part
};

declare function ed:highlight($term as xs:string, $node as text(), 
$args as item()+, $info as item()+) as element() {
    let $id0 := ($node/ancestor::l/@xml:id|$node/ancestor::lg/@xml:id|$node/ancestor::sp/@xml:id|$node/ancestor::p/@xml:id)
    let $id := 
		if ($id0) then $id0[1] 
		else 
			$node/ancestor::*/@xml:id[last()]
	let $query := $args[1] (: Need to escape & before adding it to the html output :)
    return
        <a href="javascript:void(0)" class="{$id}"
            onclick="return top.displayQueryResult(event, 'single', '{$query}', '{$id}', '{util:node-id($node)}', {$info[1]});">
            {$term}
        </a>
};

declare function ed:output-lines($nodes as element()*) as node()* {
    for $node in $nodes return ($node//text(), <br/>)
};

declare function ed:finish-callback($nodes as node()*, $width as xs:integer, $args as item()+) as node()* {
    if ($args[2] eq "multi" and $width lt 300) then
        let $node := $args[3]
        let $preceding := $node/preceding-sibling::l
        let $following := $node/following-sibling::l
        let $prec := if ($following) then $preceding[1] else subsequence($preceding, 1, 2)
        let $follow := if ($preceding) then $following[1] else subsequence($following, 1, 2)
        return (
            ed:output-lines($prec), $nodes, <br/>, ed:output-lines($follow)
        )
    else
        $nodes
};
                                
declare function ed:display($sections as element()*, $count as xs:integer, $matches as node()*, 
$query as xs:string, $mode as xs:string, $col as xs:string) as node()* {
    let $cb := util:function("ed:highlight", 4)
    let $finishCb := util:function("ed:finish-callback", 3)
    let $log := util:log("DEBUG", ("Found: ", $count))
    let $width := if ($mode eq "multi") then 300 else 100
    let $howmany := if ($count gt 100) then 100 else $count
    let $offset as xs:int := request:get-parameter("start", 1)
    let $nodes := subsequence($matches, $offset, $howmany)
    for $hit at $pos in $nodes
    return
        <li>
            { if ($pos mod 2 eq 0) then attribute class { 'hi' } else () }
            {
                text:kwic-display(
                    ($hit/text()|$hit/hi/text()|$hit/title/text()|$hit/stage/text()|$hit/ref/text()), 
                    $width, $cb, $finishCb, ($query, $mode, $hit, $col)
                )
            }
        </li>
};

declare function ed:display-overview($col as xs:string, $sections as element()*, $matches as node()*, $query as xs:string) as node()* {
    <ul>
    {
        for $sect in $sections
        for $div at $pos in utils:get-divs($col, $sect)
        let $hits := $div//$matches
        let $count := count($hits)
        where $count gt 0
        return
            let $first := $hits[1]
            let $id := ($first/ancestor-or-self::*/@xml:id)[last()]
            return
                <li>
                    <a class="overview" href="#" 
                        onclick="return top.displayQueryResult('overview', '{$query}', '{$id}', '{$div/@xml:id}')">
                        <b>{utils:process-head($sect/head)}</b> /
                        { utils:process-head($div/head)} / { $count }
                    </a>
                </li>
    }
    </ul>
};

declare function ed:follow-xinclude($col as xs:string, $sections as element()+) as element()+ {
    let $includes := $sections/xi:include
    return
        ($sections, for $xi in $includes return doc(concat($col, $xi/@href))/*)
};

declare function ed:build-query($query as xs:string) as xs:string {
    concat("//(p|l|head|cell)[", simpleql:parse-simpleql($query), "]")
};

declare function ed:navlink() {
    let $parts := request:get-parameter("part", ())
    let $sections := request:get-parameter("section", ())
    let $col := request:get-parameter("c", ())
    let $simple := request:get-parameter("simple", ())
    let $display := request:get-parameter("display", "work")
    let $offset as xs:int := request:get-parameter("start", 1)
    return
        concat("simple=", $simple, "&amp;display=", $display,
            string-join(for $p in $parts return concat("&amp;part=", $p), ""),
            string-join(for $s in $sections return concat("&amp;section=", $s), ""),
            "&amp;c=", $col)
};

declare function ed:query($col as xs:string, $sections as element()*) as element() {
    let $simple := request:get-parameter("simple", ())
    let $display := request:get-parameter("display", "work")
    let $query := ed:build-query($simple)
    let $log := util:log("DEBUG", ("Query: ", $query))
    let $allSections := ed:follow-xinclude($col, $sections)
    let $offset as xs:int := request:get-parameter("start", 1)
    let $hits := util:eval-inline($allSections, $query)
    let $count := count($hits)
    let $howmany := if ($count gt 100) then 100 else $count
    return
        <ul>
        {
            if ($display eq "work") then
                ed:display-overview($col, $sections, $hits, $query)
            else (
                <li class="info-top">
                {
                    if ($count gt 100) then
                        <a class="nav-right"
                            href="query.xql?start={$offset + $howmany}&amp;{ed:navlink()}">
                            Weitere &gt;&gt;
                        </a>
                    else
                        ()
                }
                {
                    if ($offset gt 1) then
                        <a class="nav-left"
                            href="query.xql?start={$offset - $howmany}&amp;{ed:navlink()}">
                            &lt;&lt; Vorherige
                        </a>
                    else
                        ()
                }
                    <div class="message">{$count} Treffer gefunden. Zeige Treffer {$offset} bis 
                    {$offset + $howmany - 1}.</div>
                </li>,
                ed:display($allSections, $count, $hits, $query, $display, $col),
                <li class="info-bottom">
                {
                    if ($count gt 100) then
                        <a class="nav-right"
                            href="query.xql?start={$offset + $howmany}&amp;{ed:navlink()}">
                            Weitere &gt;&gt;
                        </a>
                    else
                        ()
                }
                {
                    if ($offset gt 1) then
                        <a class="nav-left"
                            href="query.xql?start={$offset - $howmany}&amp;{ed:navlink()}">
                            &lt;&lt; Vorherige
                        </a>
                    else
                        ()
                }
                    <div class="message">{$count} Treffer gefunden. Zeige Treffer {$offset} bis 
                    {$offset + $howmany - 1}.</div>
                </li>
            )
        }
        </ul>
};

let $parts := request:get-parameter("part", ())
let $sections := request:get-parameter("section", ())
let $col := request:get-parameter("c", ())
let $divs :=
	if (exists($sections)) then
		for $s in $sections return collection($col)/id($s)
    else if (exists($parts)) then
        for $p in $parts return ed:load-section($col, $p)
    else
        ()
return
    <html>
        <head>
            <title>Search Results</title>
            <link href="styles/query.css" type="text/css" rel="stylesheet"/>
        </head>
        <body onload="top.searchCompleted()">
            {ed:query($col, $divs)}
        </body>
    </html>
    
