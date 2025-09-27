/// Alerts routing by subscribers and notifier types. 
/// How it works: you should create a process in the Production based on this class and call it Ens.Alert. 
/// The process, with this name, will automatically collect all alerts from Production items for which raised flag "Alert on Error". 
/// Next, you should fill Lookup Tables named by notifier types. 
/// For example: Alert.Operation.EmailNotifier, Alert.Operation.SMSNotifier and so on (you can add your own notifier implementations to the Alert.Operation package). 
/// For each of these tables, Key means the source of the exception (name of Production business host), 
/// Value means contact ID (e-mail address for EmailNotifier, for example), can be empty.
Class Alert.Process.Router Extends Ens.BusinessProcess [ ClassType = persistent ]
{

Method OnRequest(request As Ens.AlertRequest, Output response As Ens.Response) As %Status
{
    Set notifierType = ""
    For {
        Set notifierType = $ORDER(^Ens.LookupTable(notifierType))  Quit:notifierType=""
        Continue:'(notifierType["Alert.Operation.")
        Set source = ""
        For {
            Set source = $ORDER(^Ens.LookupTable(notifierType, source))  Quit:source=""
            Continue:source'=request.SourceConfigName
            Set contactId = $GET(^Ens.LookupTable(notifierType, source))

            Set request.AlertDestination = $SELECT(contactId="":notifierType, 1:notifierType_":"_contactId)
            Quit
        }
        Quit:request.AlertDestination'=""   // Alert will be forwarded to the first suitable for conditions subscriber 
    }

    If request.AlertDestination'="" {
        Quit ..SendRequestAsync($PIECE(request.AlertDestination, ":", 1), request)
    } Else {
        $$$LOGWARNING($$$FormatText("Alert destination not found for source '%1'", request.SourceConfigName))
    }

    Quit $$$OK
}

Method OnResponse(request As %Library.Persistent, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, callresponse As %Library.Persistent, pCompletionKey As %String) As %Status
{
	Quit $$$OK
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Set prod = ##class(Ens.Config.Production).%OpenId(##class(Ens.Director).GetActiveProductionName())
	Quit:'$iso(prod)
	
    Set className = ##class(Broker.Process.MessageHandler).%ClassName(1)
	For i=1:1:prod.Items.Count() {
		#dim item As Ens.Config.Item = prod.Items.GetAt(i)
		Set:(item.Name["Alert.Operation.") pArray(item.Name) = ""
	}
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
