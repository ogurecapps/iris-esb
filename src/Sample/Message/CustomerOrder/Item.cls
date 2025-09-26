Class Sample.Message.CustomerOrder.Item Extends (%SerialObject, %JSON.Adaptor, %XML.Adaptor)
{

Property ProductId As %Integer [ Required ];

Property ProductName As %String(MAXLEN = "");

Property Quantity As %Integer;

Storage Default
{
<Data name="ItemState">
<Value name="1">
<Value>ProductId</Value>
</Value>
<Value name="2">
<Value>ProductName</Value>
</Value>
<Value name="3">
<Value>Quantity</Value>
</Value>
</Data>
<State>ItemState</State>
<StreamLocation>^Sample.Message.Custome315.ItemS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
