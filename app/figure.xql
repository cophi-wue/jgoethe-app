xquery version "3.1";

import module namespace config="http://digital-humanities.de/jgoethe/config" at "config.xqm";
import module namespace response="http://exist-db.org/xquery/response";
import module namespace util="http://exist-db.org/xquery/util";

let $id := request:get-parameter("id", ())
return
    if (empty($id)) then
        ()
    else
        let $url := doc($config:col || "/graphics.xml")/id($id),
            $path := $config:col || "/" || data($url/@url),
            $data := util:binary-doc($path)
        return if (empty($data))
            then (
                    response:set-status-code(404),
                    <html xmlns="http://www.w3.org/1999/xhtml">
                        <head><title>404 Not found</title>
                            <style>strong {{ background: lightgray; padding: 2px; }}</style>
                        </head>
                        <body>
                            <h1>Image not found</h1>
                            <p>
                                ID <strong>{$id}</strong> in {$config:col || "/graphics.xml"}
                            => URL <strong>{data($url/@url)}</strong>
                            => Path <strong>{$path}</strong>
                            </p>
                        </body>
                    </html>
                )
            else response:stream-binary($data, "image/gif")

