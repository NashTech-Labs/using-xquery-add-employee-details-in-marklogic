xquery version "1.0-ml";

declare option xdmp:output "method = html";

declare function local:saveEmployeeDetails(
    $name as xs:string,
    $address as xs:string?,
    $doj as xs:string?,
    $salary as xs:string?,
    $jobtitle as xs:string?
) as xs:string {
    let $id as xs:string := local:generateID()
    let $book as element(employeedetails) :=
        element employeedetails {
            attribute category { $category },
            attribute id { $id },
            element name { $name },
            element address { $address },
            element doj { $doj },
            element salary { $salary }
        }

    let $uri := '/EmployeeDetails/employeedetails-' || $id || '.xml'
    let $save := xdmp:document-insert($uri, $employeedetails)
    return
        $id
};

declare function local:generateID(
) as xs:string {
    let $hash :=
        xs:string(
            xdmp:hash64(
                fn:concat(
                    xs:string(xdmp:host()),
                    xs:string(fn:current-dateTime()),
                    xs:string(xdmp:random())
                )
            )
        )
    return
        local:padString($hash, 20, fn:false())
};

declare function local:padString(
    $string as xs:string,
    $length as xs:integer,
    $padLeft as xs:boolean
) as xs:string {
    if (fn:string-length($string) = $length) then (
        $string
    ) else if (fn:string-length($string) < $length) then (
        if ($padLeft) then (
            local:padString(fn:concat("0", $string), $length, $padLeft)
        ) else (
            local:padString(fn:concat($string, "0"), $length, $padLeft)
        )
    ) else (
        fn:substring($string, 1, $length)
    )
};

declare function local:sanitizeInput($chars as xs:string?) {
    fn:replace($chars,"[\]\[<>{}\\();%\+]","")
};

declare variable $id as xs:string? :=
    if (xdmp:get-request-method() eq "POST") then (
        let $name as xs:string? := local:sanitizeInput(xdmp:get-request-field("name"))
        let $address as xs:string? := local:sanitizeInput(xdmp:get-request-field("address"))
        let $doj as xs:string? := local:sanitizeInput(xdmp:get-request-field("doj"))
        let $salary as xs:string? := local:sanitizeInput(xdmp:get-request-field("salary"))
        let $jobtitle as xs:string? := local:sanitizeInput(xdmp:get-request-field("jobtitle"))
        return
            local:saveEmployeeDetails($name, $address, $doj, $salary, $jobtitle)
    ) else ();

(: build the html :)
xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html>
    <head>
        <title>Add Employee Details</title>
    </head>
    <body>
        {
        if (fn:exists($id) and $id ne '') then (
            <div class="message">Employee Details Saved! ({$id})</div>
        ) else ()
        }
        <form name="add-employeedetails" action="add-employee.xqy" method="post">
            <fieldset>
                <legend>Add Book</legend>
                <label for="name">Name</label> <input type="text" id="name" name="name"/>
                <label for="address">Address</label> <input type="text" id="address" name="address"/>
                <label for="doj">DOJ</label> <input type="text" id="doj" name="doj"/>
                <label for="salary">Salary</label> <input type="text" id="salary" name="salary"/>
                <label for="jobtitile">Jobtitle</label>
                <select name="category" id="category">
                    <option/>
                    {
                    for $c in ('HR','FINANCE','IT')
                    return
                        <option value="{$c}">{$c}</option>
                    }
                </select>
                <input type="submit" value="Save"/>
            </fieldset>
        </form>
    </body>
    </html>