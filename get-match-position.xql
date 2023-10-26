xquery version "1.0";

declare option exist:serialize "method=xml media-type=text/xml omit-xml-declaration=no";

import module namespace req="http://exist-db.org/xquery/request";

let $id := req:get-parameter("id", ())
let $col := req:get-parameter("c", ())
let $nodeId := req:get-parameter("node", ())
let $query := req:get-parameter("query", ())
let $section := xcollection($col)//id($id)
return
		if ($section) then
			let $node := util:node-by-id($section, $nodeId)
			let $hits := util:eval(concat("$section[.", $query, "]"))
			return
				<result hits="{count($hits)}"/>
		else
			<error>no section found for id: {$id}.</error>