/// Collecting OpenMetrics sensors from custom business processes that use sync calls. 
/// This class counts the success and failure statuses received by a process when sending requests to related operations (or other processes). 
/// You must override your SendRequestSync() calls by SendRequestSyncDecorator()
Class Broker.Process.MetricsCollectorSync Extends (Ens.BusinessProcess, Broker.Util.Other)
{

Method SendRequestSyncDecorator(pTargetDispatchName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pTimeout As %Numeric = -1, pDescription As %String = "") As %Status
{
    Set startMs = ..NowMs()
    Set tSC = ..SendRequestSync(pTargetDispatchName, pRequest, .pResponse, pTimeout, pDescription)
    
    Set sc = ##class(Broker.Storage.FlowResult).Hit(..%ConfigName, pTargetDispatchName, ..%SessionId, tSC, startMs)
    If $$$ISERR(sc) {
        $$$LOGWARNING($SYSTEM.Status.GetErrorText(sc))
    }

    Return tSC
}

/// For manually increasing the metric
/// For example, you got an $$$OK status, but the response message contains an error
/// startMs = 0 - performance data is not collected 
Method MetricHit(target As %String, status As %Status, startMs As %Integer = 0)
{
    Set tSC = ##class(Broker.Storage.FlowResult).Hit(..%ConfigName, target, ..%SessionId, status, startMs)
    If $$$ISERR(tSC) {
        $$$LOGWARNING($SYSTEM.Status.GetErrorText(tSC))
    }
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
