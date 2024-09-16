xquery version "3.1";

import module namespace config="http://digital-humanities.de/jgoethe/config" at "config.xqm";
import module namespace console="http://exist-db.org/xquery/console";

declare namespace ed="http://exist-db.org/xquery/jgoethe";
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization";
declare option output:method "html";
declare option output:indent "yes";
declare option output:media-type "text/html";

(:declare option exist:serialize "method=xhtml indent=yes:)
(:	omit-xml-declaration=no:)
(:	doctype-public=-//W3C//DTD#160;HTML#160;4.01//EN:)
(:	doctype-system=http://www.w3.org/TR/html4/strict.dtd";:)

declare function ed:display-part-headings($col as xs:string) as element() {
    <tr>
    {
        for $part in collection($col)/configuration/structure/part
        return (
            <th id="{$part/@id}" class="selectAll">
                <input type="checkbox" onclick="selectAll(this, '{$part/@id}');"/>
                <div class="tooltip for_{$part/@id}" style="visibility: hidden">
                    Selektiert alle Werke der Abteilung
                </div>
            </th>,
            <th>{$part/head/text()}</th>
        )
    }
    </tr>
};

declare function ed:display-parts($col as xs:string) as element()+ {
    <tr>
    {
        for $part in collection($col)/configuration/structure/part
        return
            <td colspan="2" class="section">
            	<table cellspacing="0" cellpadding="0">
                {
                    for $s in ($part/section | $part/sep) return
                        if ($s instance of element(section)) then
                            <tr>
                                <td>{
                                    if ($s/@ref) then
                                        <input class="{$part/@id}" type="checkbox" name="part" value="{$s/@ref}"/>
                                    else
                                        ()
                                }
                                </td>
                                <td class="label">{$s/text()}</td>
                            </tr>
                        else
                            <tr><td colspan="2" class="sep"></td></tr>
                }
                </table>
            </td>
    }
    </tr>
};

declare function ed:display-structure($col as xs:string) {
    ed:display-part-headings($col),
    ed:display-parts($col)
};

declare function ed:help-link($category as xs:string) as element()+ {
    <span class="help"><a href="#" onclick="top.displayHelp('{$category}')">[?]</a></span>
};

declare function ed:javascript-warning($col as xs:string) {
    collection($col)/configuration/messages/javascript-warning/node()
};

let $col0 := request:get-parameter("c", ())
let $col := (:  :if ($col0) then $col0 else :) $config:col
return (
    util:log("DEBUG", ("Collection: ", $col)),
    console:log("Collection: " || $col),
    <html>
        <head>
            <title>{collection($col)/configuration/title/text()}</title>
            <link href="styles/tree.css" type="text/css" rel="stylesheet"/>
            <link href="styles/logger.css" type="text/css" rel="stylesheet"/>
            <link href="styles/container.css" type="text/css" rel="stylesheet"/>
            <link href="styles/default-style.css" type="text/css" rel="stylesheet"/>
            <script language="Javascript" type="text/javascript" src="scripts/yahoo.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/event.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/dom.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/container.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/dragdrop.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/animation.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/logger.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/treeview.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/connection.js"/>
            <script language="Javascript" type="text/javascript" src="scripts/edition.js"/>
        </head>
        <body>
            <div id="head">
                <ul id="menu">
                    <li><a href="{collection($col)/configuration/about/@url}" target="content">{collection($col)/configuration/about/text()}</a></li>
                    <li><a href="index.html">Startseite</a></li>
                    <li class="last"><a href="hide_sections" id="hide_sections">&lt;&lt; Ausblenden</a></li>
                </ul>
                <h1 xmlns="">{collection($col)/configuration/title/text()}</h1>
            </div>
            <form action="." method="POST" name="main" onsubmit="return process(this);">
                <div id="container">
                    <input type="hidden" name="c" value="{$col}" id="collection"/>
                    <table id="structure" cellpadding="0" cellspacing="1">
                        { ed:display-structure($col) }
                    </table>
                    <div id="modeselect">
                        <img id="loading" src="images/loading.gif"/>
                        <input type="checkbox" id="toc_check" name="toc_check" checked="checked"/>
                        <label for="toc_check">Weiterführendes Inhaltsverzeichnis {ed:help-link("toc")}</label>
                        <input type="radio" name="mode" value="read" 
                            id="btn_read" checked="yes"
                            onClick="showQueryBox()"/>
                        <label for="btn_read">Lesemodus {ed:help-link("lesemodus")}</label>
                        <input type="radio" name="mode" value="query" id="btn_query"
                            onClick="showQueryBox()"/>
                        <label for="btn_query">Suchemodus {ed:help-link("suchemodus")}</label>
                        <input type="submit" name="action" value="go"/>
                    </div>
                    <div id="querybox" style="display: none;">
                        <label for="i_simple">Suche:</label>
                        <input name="i_simple" id="i_simple" type="text" size="20"/>
                        {ed:help-link("query")}
                        <label for="s_context">Spezifische Suchbereiche:</label>
                        <select id="s_context" name="ctx" size="1">
                            <option></option>
                        </select>
                    </div>
                    <div id="rbox" class="hidden">
                        <div id="dispopt">
                            Fundstellenausgabe:
                            <ul>
                                <li><input type="radio" name="display" value="single" checked="true"/> Einzeilig</li>
                                <li><input type="radio" name="display" value="multi"/> Mehrzeilig</li>
                                <li><input type="radio" name="display" value="work"/> Werk und Trefferanzahl pro Werk</li>
                            </ul>
                        </div>
						<iframe id="hits" name="hits" frameborder="0" marginheight="0" marginwidth="0"></iframe>
                    </div>
                </div>
                <div id="javascript-warning">{ed:javascript-warning($col)}</div>
                <div id="toc">
                    <div id="toc_links">Alle <a id="toc-select-all" href="#">Auswählen</a> 
                    | <a id="toc-deselect-all" href="#">Abwählen</a></div>
                    <div id="toc_tree"></div>
                </div> 
                <div id="content-container">
                	<div id="navbar">
                        <h4>navbar</h4>
                    </div>
                    <iframe id="content" name="content" frameborder="0">
                    </iframe>
                </div>
            </form>
        </body>
    </html>
)
