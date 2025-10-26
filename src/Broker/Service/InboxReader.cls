/// This class is a main worker for all services that consume
/// messages from the Inbox. Once message of a type specified in
/// adapter settings comes in it's being sent to the message router.
Class Broker.Service.InboxReader Extends (Ens.BusinessService, Broker.Message.Status)
{

Property Adapter As Broker.Adapter.InboxReader;

Property MessageRouter As Ens.DataType.ConfigName [ InitialExpression = "Broker.Process.MessageRouter" ];

Parameter ADAPTER = "Broker.Adapter.InboxReader";

Parameter SETTINGS = "MessageRouter:Basic:selector?context={Ens.ContextSearch/ProductionItems?className=Broker.Process.MessageRouter&productionName=@productionId}";

Method OnProcessInput(pInput As Broker.Storage.Inbox, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
    Quit:..MessageRouter="" $$$ERROR($$$GeneralError, "MessageRouter setting is required")
    
    Set request = ##class(Broker.Message.InboxRequest).%New()
    Set request.InboxId = pInput.%Id()
    Set request.PayloadId = pInput.PayloadId
    Set request.PayloadType = pInput.PayloadType
    Set request.MessageHandler = ..Adapter.MessageHandler
    
    Set tSC = ##class(Broker.Storage.Processed).SetMessageStatus(request.InboxId, request.MessageHandler, ..%SessionId, ..#PENDING)
    Quit:$$$ISERR(tSC) tSC

    Quit ..SendRequestAsync(..MessageRouter, request)
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Set:pItem.GetModifiedSetting("MessageRouter", .tValue) pArray(tValue) = ""
}

}
