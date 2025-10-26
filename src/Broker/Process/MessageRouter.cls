/// Receives messages from connected Inbox readers (you can add a few routers in Production)
/// Marks messages as PENDING (moved to the service to prevent double message reading in case we have no free actors in the router)
/// Marks messages as OK/ERROR after processing by MessageHandler 
Class Broker.Process.MessageRouter Extends (Ens.BusinessProcess, Broker.Message.Status) [ ClassType = persistent ]
{

Property CollectPerformance As %Boolean [ InitialExpression = 0 ];

Parameter SETTINGS = "CollectPerformance";

Method OnRequest(request As Broker.Message.InboxRequest, Output response As Ens.Response) As %Status
{
    Set req = $CLASSMETHOD(request.PayloadType, "%OpenId", request.PayloadId)
    Quit:'$ISOBJECT(req) $$$ERROR($$$GeneralError, $$$FormatText("OpenId failed. Classname = '%1', Id = '%2'", request.PayloadType, request.PayloadId))

    If ..CollectPerformance {
        Set sc = ##class(Broker.Storage.Performance).OnRequest(request.InboxId, request.MessageHandler)
        If $$$ISERR(sc) $$$LOGWARNING($$$FormatText("Collecting performance error: %1", $SYSTEM.Status.GetErrorText(sc)))
    }

    Quit ..SendRequestAsync(request.MessageHandler, req)
}

Method OnResponse(request As Broker.Message.InboxRequest, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, callresponse As Ens.Response, pCompletionKey As %String) As %Status
{
    Quit:'$ISOBJECT(callresponse) $$$OK	// You should create any response in your MessageHandler
	
	Set tSC = ##class(Broker.Storage.Processed).SetMessageStatus(request.InboxId, request.MessageHandler, ..%SessionId, ..#OK)
    If $$$ISERR(tSC) {
    	$$$LOGWARNING($$$FormatText("[OnResponse] Error on message confirmation: %1", $SYSTEM.Status.GetErrorText(tSC)))
    	Quit $$$OK
    }

    If ..CollectPerformance {
    	Set sc = ##class(Broker.Storage.Performance).OnResponse(request.InboxId, request.MessageHandler)
        If $$$ISERR(sc) $$$LOGWARNING($$$FormatText("Collecting performance error: %1", $SYSTEM.Status.GetErrorText(sc)))
    }

	Quit tSC
}

Method OnError(request As Broker.Message.InboxRequest, ByRef response As %Library.Persistent, callrequest As %Library.Persistent, pErrorStatus As %Status, pCompletionKey As %String) As %Status
{
    Quit:'$ISOBJECT(request) $$$OK	// It's an error in the current process, not a response
    
    Set tSC = ##class(Broker.Storage.Processed).SetMessageStatus(request.InboxId, request.MessageHandler, ..%SessionId, ..#ERROR, $SYSTEM.Status.GetErrorText(pErrorStatus))
    If $$$ISERR(tSC) $$$LOGWARNING($$$FormatText("[OnError] Error on message confirmation: %1", $SYSTEM.Status.GetErrorText(tSC)))

    If ..CollectPerformance {
        Set tSC = ##class(Broker.Storage.Performance).DropMeasurement(request.InboxId, request.MessageHandler)
        If $$$ISERR(tSC) $$$LOGWARNING($$$FormatText("Collecting performance error: %1", $SYSTEM.Status.GetErrorText(tSC)))
    }      

    // Error returns OK because message has already been
    // routed and processed with error. The status has been
    // set to message so it will not be propagated further.
	Quit $$$OK
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Set prod = ##class(Ens.Config.Production).%OpenId(##class(Ens.Director).GetActiveProductionName())
	Quit:'$iso(prod)
	
    Set className = ##class(Broker.Process.MessageHandler).%ClassName(1)
	For i=1:1:prod.Items.Count() {
		#dim item As Ens.Config.Item = prod.Items.GetAt(i)
		Set:$CLASSMETHOD(item.ClassName, "%IsA", className) pArray(item.Name) = ""
	}
}

Storage Default
{
<Data name="MessageRouterDefaultData">
<Subscript>"MessageRouter"</Subscript>
<Value name="1">
<Value>CollectPerformance</Value>
</Value>
</Data>
<DefaultData>MessageRouterDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
