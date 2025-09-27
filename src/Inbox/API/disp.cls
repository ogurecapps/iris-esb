/// With this API, you can send (and deserialize) any messages to your IRIS ESB
/// Dispatch class defined by RESTSpec in Inbox.API.spec
Class Inbox.API.disp Extends Inbox.Core.RestUtils [ GeneratedBy = Inbox.API.spec.cls, ProcedureBlock ]
{

/// The class containing the RESTSpec which generated this class
Parameter SpecificationClass = "Inbox.API.spec";

/// Ignore any writes done directly by the REST method.
Parameter IgnoreWrites = 1;

/// Default the Content-Type for this application.
Parameter CONTENTTYPE = "application/json";

/// By default convert the input stream to Unicode
Parameter CONVERTINPUTSTREAM = 1;

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <!-- Import of any JSON to the ESB message (the type of message should be specified in the parameter) -->
  <Route Url="/v1/inbox" Method="post" Call="OnMessage" />
  <Route Url="/swagger" Method="get" Call="GetOpenAPISpec" />
  <Route Url="/healthcheck" Method="get" Call="Ping" /> 
</Routes>
}

/// Import of any JSON to the ESB message (the type of message should be specified in the parameter)
ClassMethod OnMessage() As %Status
{
    Try {
        If $CASE(%request.ContentType,"application/json":0,:1) {
            Try {
                Do ##class(Inbox.API.impl).%ReportRESTError(..#HTTP415UNSUPPORTEDMEDIATYPE,$$$ERROR($$$RESTContentType,%request.ContentType))
            } Catch {
                Do ##class(%REST.Impl).%ReportRESTError(..#HTTP415UNSUPPORTEDMEDIATYPE,$$$ERROR($$$RESTContentType,%request.ContentType))
            }
            Quit
        }
        Do ##class(%REST.Impl).%SetContentType("application/json")
        If '##class(%REST.Impl).%CheckAccepts("application/json") {
            Try {
                Do ##class(Inbox.API.impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts))
            } Catch {
                Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts))
            }
            Quit
        }
        If '$DATA(%request.Data("import_to",1)) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,"import_to")) Quit
        If $DATA(%request.Data("import_to",2)) {
            Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTDuplicate,"import_to")) Quit
        }
        Set pimportto=%request.Data("import_to",1)
        If '$ISOBJECT(%request.Content) || (%request.Content.Size=0) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,"payload")) Quit
        Set ppayload=##class(%DynamicAbstractObject).%FromJSON(%request.Content)
        Set response=##class(Inbox.API.impl).OnMessage(pimportto,ppayload)
        Do ##class(Inbox.API.impl).%WriteResponse(response)
    } Catch (ex) {
        Try {
            Do ##class(Inbox.API.impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$PARAMETER("Inbox.API.impl","ExposeServerExceptions"))
        } Catch {
            Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$PARAMETER("Inbox.API.impl","ExposeServerExceptions"))
        }
    }
    Quit $$$OK
}

}
