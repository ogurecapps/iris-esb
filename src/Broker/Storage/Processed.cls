/// Table for store ID's processed messages for all consumers
Class Broker.Storage.Processed Extends %Persistent
{

/// Id of record in Broker.Storage.Inbox
Property InboxId As %String [ Required ];

/// Name of Production host (is used like a GroupId in the Kafka)
Property ConsumerName As %String(MAXLEN = 100) [ Required ];

/// For scheduled cleanup
Property UpdatedAt As %TimeStamp [ Required, SqlComputeCode = { Set {*} = $ZDATETIME($NOW(), 3) }, SqlComputed, SqlComputeOnChange = (%%INSERT, %%UPDATE) ];

/// Current status of message
Property Status As %String(VALUELIST = ",OK,ERROR,PENDING") [ Required ];

/// Status details - contains additional data for ERROR status
Property StatusDetails As %String(MAXLEN = "");

/// Link to trace
Property SessionId As %String;

Index ConsumerNameInboxKey On (ConsumerName, InboxId) [ Unique ];

Index UpdatedAtIdx On UpdatedAt;

Index StatusIdx On Status [ Type = bitmap ];

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
	Return:($GET(SQLCODE,0)'=0) $$$ERROR($$$GeneralError, $$$FormatText("SetMessageStatus failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))
    
    Return $$$OK
}

/// Drop PENDING marks OnStart() the Production.
/// Marks of messages whose Interoperability session still has Queued messages are kept:
/// the Production redelivers them after restart, finishes the session itself and sets OK/ERROR,
/// so re-reading them from the Inbox would produce duplicates in the consumer system
ClassMethod ClearPending(Output cleared As %Integer, Output kept As %Integer) As %Status
{
    New %ROWCOUNT
    Set cleared = 0, kept = 0

    &sql(select count(*) into :pending from Broker_Storage.Processed where Status = 'PENDING')
    Return:($GET(SQLCODE,0)<0) $$$ERROR($$$GeneralError, $$$FormatText("ClearPending failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))

    &sql(delete from Broker_Storage.Processed p where p.Status = 'PENDING'
        and not exists (
            select 1 from Ens.MessageHeader h
                where h.SessionId = p.SessionId and h.Status = 2 /* Queued */))
    Return:($GET(SQLCODE,0)<0) $$$ERROR($$$GeneralError, $$$FormatText("ClearPending failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))

    Set cleared = %ROWCOUNT
    Set kept = $GET(pending, 0) - cleared
    
    Return $$$OK
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
