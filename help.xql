xquery version "1.0";

<html>
    <head>
        <title>Hilfe</title>
        { /help/style }
    </head>
    <body>
    {
        let $category := request:get-parameter("category", ())
        return
            /help/category[@id = $category]/*
    }
    </body>
</html>