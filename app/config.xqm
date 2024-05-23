xquery version "3.1";

module namespace config="http://digital-humanities.de/jgoethe/config";
import module namespace console="http://exist-db.org/xquery/console";

declare variable $config:app-root := 
    let $rawPath := system:get-module-load-path()
    let $modulePath :=
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    return substring($modulePath, 1, string-length($modulePath) - 4); (: "/app" :)
    
declare variable $config:data := $config:app-root || "/data";
declare variable $config:col := $config:data || "/jgoethe";
declare variable $config:tei2html := $config:col || "/tei2html.xsl";