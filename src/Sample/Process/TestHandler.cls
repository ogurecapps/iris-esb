/// Processing of customer orders (sample)
Class Sample.Process.TestHandler Extends Broker.Process.MessageHandler
{

Property ThrowError As %Boolean;

Parameter SETTINGS = "ThrowError:Basic";

/// Handle a 'Request'
Method OnRequest(request As %Library.Persistent, Output response As %Library.Persistent) As %Status
{
	Set response = ##class(Ens.Response).%New()	// Required step
	Hang $RANDOM(6)
	Quit $SELECT(..ThrowError:$$$ERROR($$$GeneralError,"Something went wrong"),1:$$$OK)
}

Storage Default
{
<Data name="TestHandlerDefaultData">
<Subscript>"TestHandler"</Subscript>
<Value name="1">
<Value>ThrowError</Value>
</Value>
</Data>
<DefaultData>TestHandlerDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
