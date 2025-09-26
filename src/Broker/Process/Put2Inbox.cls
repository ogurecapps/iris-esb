/// You can inherit from this process if you need to save message to Broker
Class Broker.Process.Put2Inbox Extends Ens.BusinessProcess [ ClassType = persistent ]
{

/// Put to Inbox operation
Property Operation As Ens.DataType.ConfigName [ InitialExpression = "Broker.Operation.Put2Inbox" ];

Parameter SETTINGS = "Operation:Basic:selector?context={Ens.ContextSearch/ProductionItems?className=Broker.Operation.Put2Inbox&productionName=@productionId}";

Method Put2Inbox(request As Ens.Request, Output response As Ens.Response) As %Status
{
    Quit:..Operation="" $$$ERROR($$$GeneralError, "You need to set Operation setting")
    Quit ..SendRequestSync(..Operation, request, .response)
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Set:pItem.GetModifiedSetting("Operation", .tValue) pArray(tValue) = ""
}

Storage Default
{
<Data name="Put2InboxDefaultData">
<Subscript>"Put2Inbox"</Subscript>
<Value name="1">
<Value>Operation</Value>
</Value>
</Data>
<DefaultData>Put2InboxDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
