xquery version "3.1";

import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";
import module namespace config="http://digital-humanities.de/jgoethe/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";
import module namespace kwic="http://exist-db.org/xquery/kwic";


declare namespace ed="http://exist-db.org/xquery/jgoethe";

declare namespace output="http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:media-type "text/html";


declare function ed:load-section($col as xs:string, $id as xs:string) as node()+ {
    let $section := collection($col)/configuration/structure//section[@ref=$id]
    let $part := util:eval("collection('" || $col || "')//" || $section/@xpath)
    return
        $part
};

declare function ed:navlink() {
    let $parts := request:get-parameter("part", ())
    let $sections := request:get-parameter("section", ())
    let $col := request:get-parameter("c", ())
    let $simple := request:get-parameter("simple", ())
    let $display := request:get-parameter("display", "work")
    let $offset as xs:integer := request:get-parameter("start", 1)
    return
        concat("simple=", $simple, "&amp;display=", $display,
            string-join(for $p in $parts return concat("&amp;part=", $p), ""),
            string-join(for $s in $sections return concat("&amp;section=", $s), ""),
            "&amp;c=", $col)
};

declare function ed:display($sections as element()*, $count as xs:integer, $matches as node()*, 
$query as xs:string, $mode as xs:string, $col as xs:string) as node()* {
    let $width := if ($mode eq "multi") then 300 else 100
    let $howmany := if ($count gt 100) then 100 else $count
    let $offset as xs:integer := request:get-parameter("start", 1)
    let $nodes := subsequence($matches, $offset, $howmany)
    for $hit at $pos in $nodes
    let $node := $hit,
        $id0 := ($node/ancestor::l/@xml:id|$node/ancestor::lg/@xml:id|$node/ancestor::sp/@xml:id|$node/ancestor::p/@xml:id),
        $id := (if ($id0) then $id0[1] else $node/ancestor::*/@xml:id[last()])[1],
        $link := "javascript:top.displayQueryResult(null,'single','"|| $query ||"','" || $id || "','" || util:node-id($node)  || "', " || $pos || ")" (: FIXME Leerstellen :),
        $titles := for $a in $hit/ancestor::*
                   let $h := $a/head
                   return if ($h and exists($sections//$h)) then utils:process-head($h[1]) else ()
    return (
        <li class="{if ($pos mod 2 eq 0) then 'hi hierarchy' else 'hierarchy'}">
            {string-join($titles, ' | ')}
        </li>,
        <li>
            {if ($pos mod 2 eq 0) then attribute class { 'hi'} else ()}
            {kwic:summarize($hit, <config width="{$width}" table="no" link="{$link}"/>)}
        </li>
    )
};

declare function ed:display-overview($col as xs:string, $sections as element()*, $matches as node()*, $simple as xs:string) as node()* {
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
                        onclick="return top.displayQueryResult(null, 'overview', '{$simple}', '{$id}', '{$div/@xml:id}')">
                        <b>{utils:process-head($sect/head)}</b> /
                        { utils:process-head($div/head)} / { $count }
                    </a>
                </li>
    }
    </ul>
};


declare function ed:query($col as xs:string, $divs as node()*) as node()* {
    let $simple := request:get-parameter("simple", ())
    let $display := request:get-parameter("display", "work")
    let $offset as xs:integer := request:get-parameter("start", 1)
    let $hits := utils:ftquery($divs, $simple)
    let $count := count($hits)
    let $howmany := if ($count gt 100) then 100 else $count
    return
        <ul>
        {
            if ($display eq "work") then
                ed:display-overview($col, $divs, $hits, $simple)
            else (
                <li class="info-top">
                {
                    if ($count gt 100) then
                        <a class="nav-right" rel="next"
                           href="query-new.xql?start={$offset + $howmany}&amp;{ed:navlink()}">
                           Weitere &gt;&gt;
                        </a>
                    else
                        ()
                }
                {
                    if ($offset gt 1) then
                        <a class="nav-left" rel="prev"
                         href="query-new.xql?start={$offset - $howmany}&amp;{ed:navlink()}">
                         &lt;&lt; Vorherige</a>
                    else
                        ()
                }
                    <div class="message">{$count} Treffer gefunden. Zeige Treffer {$offset} bis 
                    {$offset + $howmany - 1}.</div>
                </li>,
                ed:display($divs, $count, $hits, $simple, $display, $col),
                <li class="info-bottom">
                {
                    if ($count gt 100) then
                        <a class="nav-right"
                            href="query-new.xql?start={$offset + $howmany}&amp;{ed:navlink()}">
                            Weitere &gt;&gt;
                        </a>
                    else
                        ()
                }
                {
                    if ($offset gt 1) then
                        <a class="nav-left"
                            href="query-new.xql?start={$offset - $howmany}&amp;{ed:navlink()}">
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
let $col := $config:col (:  :request:get-parameter("c", ()) FIXME :)
let $divs :=
	if (exists($sections)) then
		for $s in $sections return (collection($col)/id($s), console:log('Section: ' || $s || ', col=' || $col))
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
