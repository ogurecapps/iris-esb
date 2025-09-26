Class Sample.Message.CustomerOrder.Order Extends Inbox.Message.Inbound
{

Property CreatedAt As %TimeStamp [ Required ];

Property OrderId As %Integer [ Required ];

Property OrderStatus As %String(VALUELIST = ",NEW,IN_PROGRESS,DELIVERED,CANCELED");

Property Customer As Sample.Message.CustomerOrder.Customer;

Property Items As list Of Sample.Message.CustomerOrder.Item;

Storage Default
{
<Data name="OrderDefaultData">
<Subscript>"Order"</Subscript>
<Value name="1">
<Value>CreatedAt</Value>
</Value>
<Value name="2">
<Value>OrderId</Value>
</Value>
<Value name="3">
<Value>OrderStatus</Value>
</Value>
<Value name="4">
<Value>Customer</Value>
</Value>
<Value name="5">
<Value>Items</Value>
</Value>
</Data>
<DefaultData>OrderDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
