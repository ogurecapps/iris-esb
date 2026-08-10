Class Broker.Storage.FlowResult Extends (%Persistent, Broker.Util.Other)
{

/// Business Process making a call
Property Source As %String(MAXLEN = 200) [ Required ];

/// Target of the call, usually a Business Operation
Property Target As %String(MAXLEN = 200) [ Required ];

/// Link to trace
Property SessionId As %String;

/// Status of the call
Property Success As %Boolean [ Required ];

/// Contains additional data for $$$ERROR status
Property FailDetails As %String(MAXLEN = "");

/// For scheduled cleanup
Property UpdatedAt As %TimeStamp [ SqlComputeCode = { Set {*} = $ZDATETIME($NOW(), 3) }, SqlComputed, SqlComputeOnChange = (%%INSERT, %%UPDATE) ];

/// For performance sensors
Property DurationMs As %Integer [ Required ];

Index UpdatedAtIdx On UpdatedAt;

Index SourceSuccessIdx On (Source, Success);

Index SourceTargetDurationIdx On (Source, Target, DurationMs);
 
ClassMethod Hit(source As %String, target As %String, sessionId As %String, status As %Status, startMs As %Integer = 0) As %Status
{
    Set success = $$$ISOK(status)
    Set failDetails = $SYSTEM.Status.GetErrorText(status)
    Set durationMs = $SELECT(startMs = 0:0, 1:..NowMs() - startMs)

    &sql(insert Broker_Storage.FlowResult set 
    	Source = :source, 
        Target = :target, 
        SessionId = :sessionId,
        Success = :success,
        FailDetails = :failDetails,
        DurationMs = :durationMs)

	Return:($GET(SQLCODE,0)'=0) $$$ERROR($$$GeneralError, $$$FormatText("Broker.Storage.FlowResult.Hit() failed. SQLCODE = %1: %2", SQLCODE, $SYSTEM.SQL.Functions.SQLCODE(SQLCODE)))
    Return $$$OK
}

Storage Default
{
<Data name="FlowResultDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Source</Value>
</Value>
<Value name="3">
<Value>Target</Value>
</Value>
<Value name="4">
<Value>SessionId</Value>
</Value>
<Value name="5">
<Value>Success</Value>
</Value>
<Value name="6">
<Value>FailDetails</Value>
</Value>
<Value name="7">
<Value>UpdatedAt</Value>
</Value>
<Value name="8">
<Value>DurationMs</Value>
</Value>
</Data>
<DataLocation>^Broker.Storage.FlowResultD</DataLocation>
<DefaultData>FlowResultDefaultData</DefaultData>
<IdLocation>^Broker.Storage.FlowResultD</IdLocation>
<IndexLocation>^Broker.Storage.FlowResultI</IndexLocation>
<StreamLocation>^Broker.Storage.FlowResultS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
