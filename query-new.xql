xquery version "3.1";

import module namespace utils="http://exist-db.org/xquery/jgoethe/utils" at "util.xqm";
import module namespace config="http://digital-humanities.de/jgoethe/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";


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
    let $offset as xs:int := request:get-parameter("start", 1)
    return
        concat("simple=", $simple, "&amp;display=", $display,
            string-join(for $p in $parts return concat("&amp;part=", $p), ""),
            string-join(for $s in $sections return concat("&amp;section=", $s), ""),
            "&amp;c=", $col)
};



declare function ed:query($col as xs:string, $divs as node()*) as node()* {
    let $simple := request:get-parameter("simple", ())
    let $display := request:get-parameter("display", "work")
    let $offset as xs:integer := request:get-parameter("start", 1)
    let $hits := $divs//(p|l|head|cell)[ft:query(., $simple)]
    let $count := count($hits)
    let $howmany := if ($count gt 100) then 100 else $count
    return
        <ul>
        {
            if ($display eq "work") then
                "TODO: display=work"
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
                <pre>
                    {serialize($hits, map { "indent": true() })}
                </pre>
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
