Class Broker.Storage.Performance Extends %Persistent
{

Property InboxId As %String [ Required ];

Property ConsumerName As %String(MAXLEN = 200) [ Required ];

Property CreatedAt As %TimeStamp [ Required ];

Property CreatedMs As %Integer [ Required ];

Property ProcessedMs As %Integer;

Index InboxIdConsumerNameKey On (InboxId, ConsumerName) [ Unique ];

Index CreatedAtIdx On CreatedAt;

ClassMethod DropMeasurement(inboxId As %String, consumerName As %String) As %Status
{
   If ..InboxIdConsumerNameKeyOpen(inboxId, consumerName) {
       Quit ..InboxIdConsumerNameKeyDelete(inboxId, consumerName)    
   }

   Quit $$$OK
}

ClassMethod OnRequest(inboxId As %String, consumerName As %String) As %Status
{
    Set sc = ..DropMeasurement(inboxId, consumerName) // For resend message case
    Quit:$$$ISERR(sc) sc

    Set h = $NOW()
    Set ts = ($PIECE(h,",",1)*86400 + $PIECE(h,",",2)) * 1000

    &sql(insert Broker_Storage.Performance 
        set 
            InboxId = :inboxId, 
            ConsumerName = :consumerName,
            CreatedMs = :ts,
            CreatedAt = CURRENT_TIMESTAMP)
	Quit:($GET(SQLCODE,0)'=0) $$$ERROR($$$GeneralError, $$$FormatText("OnRequest failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))
    
    Quit $$$OK
}

ClassMethod OnResponse(inboxId As %String, consumerName As %String) As %Status
{
    Set h = $NOW()
    Set ts = ($PIECE(h,",",1)*86400 + $PIECE(h,",",2)) * 1000

    &sql(update Broker_Storage.Performance 
        set 
            ProcessedMs = :ts
        where
            InboxId = :inboxId and 
            ConsumerName = :consumerName)
	Quit:($GET(SQLCODE,0)'=0) $$$ERROR($$$GeneralError, $$$FormatText("OnResponse failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))
    
    Quit $$$OK
}

Storage Default
{
<Data name="PerformanceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>InboxId</Value>
</Value>
<Value name="3">
<Value>ConsumerName</Value>
</Value>
<Value name="4">
<Value>CreatedAt</Value>
</Value>
<Value name="5">
<Value>CreatedMs</Value>
</Value>
<Value name="6">
<Value>ProcessedMs</Value>
</Value>
</Data>
<DataLocation>^Broker.Storage.PerformanceD</DataLocation>
<DefaultData>PerformanceDefaultData</DefaultData>
<IdLocation>^Broker.Storage.PerformanceD</IdLocation>
<IndexLocation>^Broker.Storage.PerformanceI</IndexLocation>
<StreamLocation>^Broker.Storage.PerformanceS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
