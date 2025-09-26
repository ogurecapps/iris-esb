Class Sample.Message.CustomerOrder.Customer Extends (%SerialObject, %JSON.Adaptor, %XML.Adaptor)
{

Property FirstName As %String(MAXLEN = "");

Property LastName As %String(MAXLEN = "");

Storage Default
{
<Data name="CustomerState">
<Value name="1">
<Value>FirstName</Value>
</Value>
<Value name="2">
<Value>LastName</Value>
</Value>
</Data>
<State>CustomerState</State>
<StreamLocation>^Sample.Message.Cus315.CustomerS</StreamLocation>
<Type>%Storage.Serial</Type>
}

}
