/// Common inbox for all IRIS messages with garantee delivery
Class Broker.Storage.Inbox Extends %Persistent [ CompileAfter = Broker.Storage.Processed ]
{

/// Any content we want to keep in this queue must extend Ens.Request
Property PayloadId As %String [ Required ];

/// Property for determining messages with different types of payload (like a topic in the Kafka)
/// We will be use the classnames ($classname() of Payload property)
Property PayloadType As %String(MAXLEN = 100) [ Required ];

/// For reglament cleanup and lifetime check
Property CreatedAt As %TimeStamp [ Required ];

Index PayloadTypePayloadIdKey On (PayloadType, PayloadId) [ Unique ];

Index PayloadTypeCreatedAtIdx On (PayloadType, CreatedAt);

/// Get messages which do not exist in Processed i.e. new messages
Query UnprocessedMessages(consumer As %String, payloadType As %String, notBefore As %TimeStamp) As %SQLQuery(CONTAINID = 1, ROWSPEC = "ID:%Integer") [ SqlProc ]
{
    select m.ID 
    from Broker_Storage.Inbox m 
    where m.PayloadType = :payloadType 
        and m.CreatedAt >= :notBefore
        and (
            not exists (
                select 1 
                from Broker_Storage.Processed p
                where p.ConsumerName = :consumer and p.InboxId = m.ID
                    and p.Status <> 'ERROR'
            )
        )
}

/// Get inbox record by message
ClassMethod GetFromInbox(payloadId As %String, payloadType As %String, ByRef record As Broker.Storage.Inbox) As %Status
{
    Set SQLCODE = 0
	Set id = ""
	
	&sql(select id into :id from Broker_Storage.Inbox where PayloadId = :payloadId and PayloadType = :payloadType)
    Quit:(SQLCODE<0) $$$ERROR($$$GeneralError, $$$FormatText("GetFromInbox failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))
    Quit:id="" $$$ERROR($$$GeneralError, $$$FormatText("Record not found. PayloadId = '%1', PayloadType = '%2'", payloadId, payloadType))

    Set record = ##class(Broker.Storage.Inbox).%OpenId(id)
    Quit $$$OK
}

/// Use this method to quickly add something to the Inbox.
/// Also, you can extend a business process Broker.Process.Put2Inbox and call the same method in this class
/// if you need to trace message content (don't forget to add operation Broker.Operation.Put2Inbox to your Production)
ClassMethod Put2Inbox(request As Ens.Request) As %Status
{
    Set payloadId = request.%Id()
    Set payloadType = $CLASSNAME(request)
    Set SQLCODE = 0
	
    &sql(insert or update 
    		Broker_Storage.Inbox set 
    			PayloadId = :payloadId, 
    			PayloadType = :payloadType, 
    			createdAt = CURRENT_TIMESTAMP)
    Quit:(SQLCODE'=0) $$$ERROR($$$GeneralError, $$$FormatText("SaveToInbox failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))
    
    Quit $$$OK
}

Storage Default
{
<Data name="InboxDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PayloadId</Value>
</Value>
<Value name="3">
<Value>PayloadType</Value>
</Value>
<Value name="4">
<Value>CreatedAt</Value>
</Value>
</Data>
<DataLocation>^Broker.Storage.InboxD</DataLocation>
<DefaultData>InboxDefaultData</DefaultData>
<ExtentSize>3</ExtentSize>
<IdLocation>^Broker.Storage.InboxD</IdLocation>
<IndexLocation>^Broker.Storage.InboxI</IndexLocation>
<Property name="%%CLASSNAME">
<AverageFieldSize>2</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<Property name="%%ID">
<AverageFieldSize>3</AverageFieldSize>
<Selectivity>1</Selectivity>
</Property>
<Property name="CreatedAt">
<AverageFieldSize>21</AverageFieldSize>
<Selectivity>33.3333%</Selectivity>
</Property>
<Property name="PayloadId">
<AverageFieldSize>3</AverageFieldSize>
<Selectivity>33.3333%</Selectivity>
</Property>
<Property name="PayloadType">
<AverageFieldSize>19</AverageFieldSize>
<Selectivity>100.0000%</Selectivity>
</Property>
<SQLMap name="IDKEY">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="PayloadTypeCreatedAtIdx">
<BlockCount>-4</BlockCount>
</SQLMap>
<SQLMap name="PayloadTypePayloadIdKey">
<BlockCount>-4</BlockCount>
</SQLMap>
<StreamLocation>^Broker.Storage.InboxS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
