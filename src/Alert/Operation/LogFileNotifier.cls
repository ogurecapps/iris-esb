/// Simple writing of alerts to the text file (feel free to parse it with some log grabber)
Class Alert.Operation.LogFileNotifier Extends Alert.Operation.NotifierUtils
{

Parameter INVOCATION = "Queue";

Property FileName As %String(MAXLEN = 100) [ InitialExpression = "alerts.log" ];

Property MessageTag As %String(MAXLEN = 100) [ InitialExpression = {"["_$NAMESPACE_"]"} ];

Property Delimiter As %String [ InitialExpression = " | " ];

Property Adapter As EnsLib.File.OutboundAdapter;

Parameter ADAPTER = "EnsLib.File.OutboundAdapter";

Parameter SETTINGS = "FileName:Basic,MessageTag:Log,Delimiter:Log";

Method OnMessage(request As Ens.AlertRequest, Output response As Ens.Response) As %Status
{
    Set entry = request.AlertTime_
                $SELECT(..MessageTag'="":..Delimiter_..MessageTag,1:"")_
                ..Delimiter_request.SourceConfigName_
                ..Delimiter_..GetTraceLink()_
                ..Delimiter_$ZSTRIP(request.AlertText,"*C")

    $$$TRACE(entry)
    Quit ..Adapter.PutLine(..FileName, entry)
}

}
