/// Processing of messages
Class Sample.Process.TestHandler Extends (Broker.Process.MessageHandler, Util.Common)
{

Property ThrowError As %Boolean;

Parameter SETTINGS = "ThrowError:Basic";

Parameter CPS = "^Checkpoint.TestHandler";

/// Handle a 'Request'
Method OnRequest(request As %Library.Persistent, Output response As %Library.Persistent) As %Status
{
	If request.%IsA(##class(Sample.Message.CustomerOrder.Order).%ClassName(1)) {
		If ..IsKnownCheckpoint(..#CPS, .payload, request.OrderId, request.OrderStatus) {
        	$$$LOGWARNING($$$FormatText("Status '%1' for customer order ID '%2' has already been processed. Last time details: %3", request.OrderStatus, request.OrderId, payload))
        	Return $$$OK   
    	}
		/// ... Do something ...
		/// Saving a checkpoint after successful processing
		Set tSC = ..SetCheckpoint(..#CPS, {"processed_at": ($ZDATETIME($HOROLOG, 3)), "session_id": (..%SessionId), 
			"customer_name": (request.Customer.FirstName_" "_request.Customer.LastName)}, request.OrderId, request.OrderStatus)
		Return:$$$ISERR(tSC) tSC
	}

	Set response = ##class(Ens.Response).%New()	// Required step
	Hang $RANDOM(6)
	Return $SELECT(..ThrowError:$$$ERROR($$$GeneralError,"Something went wrong"),1:$$$OK)
}

Storage Default
{
<Data name="TestHandlerDefaultData">
<Subscript>"TestHandler"</Subscript>
<Value name="1">
<Value>ThrowError</Value>
</Value>
</Data>
<DefaultData>TestHandlerDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
