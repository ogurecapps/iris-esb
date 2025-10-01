/// With this API, you can send (and deserialize) any messages to your IRIS ESB
/// Dispatch class defined by RESTSpec in Inbox.API.spec
Class Inbox.API.disp Extends %CSP.REST [ GeneratedBy = Inbox.API.spec.cls, ProcedureBlock ]
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
  <!-- Simple health check -->
  <Route Url="/healthcheck" Method="get" Call="Ping" />
</Routes>
}

/// Import of any JSON to the ESB message (the type of message should be specified in the parameter)
ClassMethod OnMessage() As %Status
{
    Try {
        If $case(%request.ContentType,"application/json":0,:1) {
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
        If '$data(%request.Data("import_to",1)) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,"import_to")) Quit
        If $data(%request.Data("import_to",2)) {
            Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTDuplicate,"import_to")) Quit
        }
        Set pimportto=%request.Data("import_to",1)
        If '$isobject(%request.Content) || (%request.Content.Size=0) Do ##class(%REST.Impl).%ReportRESTError(..#HTTP400BADREQUEST,$$$ERROR($$$RESTRequired,"payload")) Quit
        Set ppayload=##class(%DynamicAbstractObject).%FromJSON(%request.Content)
        Set response=##class(Inbox.API.impl).OnMessage(pimportto,ppayload)
        Do ##class(Inbox.API.impl).%WriteResponse(response)
    } Catch (ex) {
        Try {
            Do ##class(Inbox.API.impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("Inbox.API.impl","ExposeServerExceptions"))
        } Catch {
            Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("Inbox.API.impl","ExposeServerExceptions"))
        }
    }
    Quit $$$OK
}

/// Simple health check
ClassMethod Ping() As %Status
{
    Try {
        Do ##class(%REST.Impl).%SetContentType("application/json")
        If '##class(%REST.Impl).%CheckAccepts("application/json") {
            Try {
                Do ##class(Inbox.API.impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts))
            } Catch {
                Do ##class(%REST.Impl).%ReportRESTError(..#HTTP406NOTACCEPTABLE,$$$ERROR($$$RESTBadAccepts))
            }
            Quit
        }
        Set response=##class(Inbox.API.impl).Ping()
        Do ##class(Inbox.API.impl).%WriteResponse(response)
    } Catch (ex) {
        Try {
            Do ##class(Inbox.API.impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("Inbox.API.impl","ExposeServerExceptions"))
        } Catch {
            Do ##class(%REST.Impl).%ReportRESTError(..#HTTP500INTERNALSERVERERROR,ex.AsStatus(),$parameter("Inbox.API.impl","ExposeServerExceptions"))
        }
    }
    Quit $$$OK
}

}
