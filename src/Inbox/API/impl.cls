/// With this API, you can send (and deserialize) any messages to your IRIS ESB<br/>
/// Business logic class defined by OpenAPI in Inbox.API.spec<br/>
/// Updated Oct 1, 2025 11:13:24
Class Inbox.API.impl Extends %REST.Impl [ ProcedureBlock ]
{

/// If ExposeServerExceptions is true, then details of internal errors will be exposed.
Parameter ExposeServerExceptions = 0;

/// Any payload in JSON format can be put in the body of this method. It will be imported into the ESB message and put into the inbox queue. The type of message should be specified through the import_to parameter<br/>
/// The method arguments hold values for:<br/>
///     import_to, Type of message (class name) to import into the inbox queue<br/>
///     payload, Only JSON allowed<br/>
ClassMethod OnMessage(importto As %String, payload As %DynamicObject) As %DynamicObject
{
    Quit ##class(Inbox.Service.API).Call(importto, payload)
}

/// Every well-designed API must have a health check endpoint
ClassMethod Ping() As %DynamicObject
{
    Do ..%SetStatusCode(##class(%CSP.REST).#HTTP200OK)
    Do ..%SetContentType("application/json")
    Do ..%WriteResponse({"message": ($$$FormatText("Server time: %1", $ZDATETIME($HOROLOG,3)))}.%ToJSON())

    Quit $$$OK
}

}
