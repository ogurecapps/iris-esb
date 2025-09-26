Class Broker.Message.InboxRequest Extends Ens.Request
{

Property InboxId As %String [ Required ];

Property PayloadId As %String [ Required ];

Property PayloadType As %String [ Required ];

Property MessageHandler As %String(MAXLEN = 100) [ Required ];

Storage Default
{
<Data name="InboxRequestDefaultData">
<Subscript>"InboxRequest"</Subscript>
<Value name="1">
<Value>InboxId</Value>
</Value>
<Value name="2">
<Value>PayloadId</Value>
</Value>
<Value name="3">
<Value>PayloadType</Value>
</Value>
<Value name="4">
<Value>MessageHandler</Value>
</Value>
</Data>
<DefaultData>InboxRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
