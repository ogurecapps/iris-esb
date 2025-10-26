/// Table for store ID's processed messages for all consumers
Class Broker.Storage.Processed Extends %Persistent
{

/// Id of record in Broker.Storage.Inbox
Property InboxId As %String [ Required ];

/// Name of Production host (is used like a GroupId in the Kafka)
Property ConsumerName As %String(MAXLEN = 100) [ Required ];

/// For scheduled cleanup
Property UpdatedAt As %TimeStamp [ InitialExpression = {$ZDATETIME($HOROLOG, 3)}, Required ];

/// Current status of message
Property Status As %String(VALUELIST = ",OK,ERROR,PENDING") [ Required ];

/// Status details - contains additional data for ERROR status
Property StatusDetails As %String(MAXLEN = "");

/// Link to trace
Property SessionId As %String;

Index ConsumerNameInboxKey On (ConsumerName, InboxId) [ Unique ];

Index ConsumerNameInboxIdx On (ConsumerName, InboxId) [ Type = bitmap ];

Index UpdatedAtIdx On UpdatedAt;

Index StatusIdx On Status;

/// Mark the message as processed
ClassMethod SetMessageStatus(inboxId As %String, consumerName As %String, sessionId As %String, status As %String, statusDetails As %String = "") As %Status
{
    &sql(insert or update 
    	Broker_Storage.Processed set 
    		InboxId = :inboxId, 
            ConsumerName = :consumerName, 
            Status = :status,
            StatusDetails = :statusDetails,
            SessionId = :sessionId)
	Quit:($GET(SQLCODE,0)'=0) $$$ERROR($$$GeneralError, $$$FormatText("SetMessageStatus failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))
    
    Quit $$$OK
}

ClassMethod ClearPending(Output cleared As %Integer) As %Status
{
    New %ROWCOUNT
    &sql(delete from Broker_Storage.Processed where Status = 'PENDING')
    Quit:($GET(SQLCODE,0)<0) $$$ERROR($$$GeneralError, $$$FormatText("ClearPending failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))
    
    Set cleared = %ROWCOUNT
    Quit $$$OK
}

Storage Default
{
<Data name="ProcessedDefaultData">
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
<Value>UpdatedAt</Value>
</Value>
<Value name="5">
<Value>Status</Value>
</Value>
<Value name="6">
<Value>StatusDetails</Value>
</Value>
<Value name="7">
<Value>SessionId</Value>
</Value>
</Data>
<DataLocation>^Broker.Storage.ProcessedD</DataLocation>
<DefaultData>ProcessedDefaultData</DefaultData>
<IdLocation>^Broker.Storage.ProcessedD</IdLocation>
<IndexLocation>^Broker.Storage.ProcessedI</IndexLocation>
<StreamLocation>^Broker.Storage.ProcessedS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
