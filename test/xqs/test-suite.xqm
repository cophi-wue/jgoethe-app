xquery version "3.1";

(:~ This library module contains XQSuite tests for the jgoethe app.
 :
 : @author Thorsten Vitt
 : @version 0.1.0
 : @see https://thorstenvitt.de/
 :)

module namespace tests = "http://digital-humanities.de/jgoethe/apps/jgoethe/tests";

declare namespace test="http://exist-db.org/xquery/xqsuite";



declare
    %test:name('one-is-one')
    %test:assertTrue
    function tests:tautology() {
        1 = 1
};
