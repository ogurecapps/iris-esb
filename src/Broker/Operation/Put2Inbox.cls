/// Separate operation if we need to see what we save in the Broker
Class Broker.Operation.Put2Inbox Extends Ens.BusinessOperation
{

Parameter INVOCATION = "Queue";

Method OnMessage(pRequest As %Library.Persistent, Output pResponse As %Library.Persistent) As %Status
{
	Quit ##class(Broker.Storage.Inbox).Put2Inbox(pRequest)
}

}
