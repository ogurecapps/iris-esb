/// Use this pattern if you wanna receive a list of some objects
/// ["1","2","3"]
Class Sample.Message.SomeArray.Root Extends Inbox.Message.Inbound
{

Property UnnamedArray As list Of %String;

Storage Default
{
<Data name="RootDefaultData">
<Subscript>"Root"</Subscript>
<Value name="1">
<Value>UnnamedArray</Value>
</Value>
</Data>
<DefaultData>RootDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
