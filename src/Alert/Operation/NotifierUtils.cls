Class Alert.Operation.NotifierUtils Extends Ens.BusinessOperation
{

Property Server As %String [ InitialExpression = "localhost" ];

Property Port As %Integer [ InitialExpression = 52773 ];

Property SSL As %Boolean;

Parameter SETTINGS = "Server:Trace,Port:Trace,SSL:Trace";

Method GetTraceLink() As %String
{
    Quit "http"_$SELECT(..SSL:"s",1:"")_"://"_..Server_":"_..Port_"/csp/"_$ZCONVERT($NAMESPACE,"l")_"/EnsPortal.VisualTrace.zen?SESSIONID="_..%SessionId
}

}
