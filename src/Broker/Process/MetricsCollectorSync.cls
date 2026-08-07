/// Collecting OpenMetrics sensors from custom business processes that use sync calls. 
/// This class counts the success and failure statuses received by a process when sending requests to related operations (or other processes). 
/// You must override your SendRequestSync() calls by SendRequestSyncDecorator()
Class Broker.Process.MetricsCollectorSync Extends (Ens.BusinessProcess, Broker.Util.Other)
{

Method SendRequestSyncDecorator(pTargetDispatchName As %String, pRequest As %Library.Persistent, ByRef pResponse As %Library.Persistent, pTimeout As %Numeric = -1, pDescription As %String = "") As %Status
{
    Set startMs = ..NowMs()
    Set tSC = ..SendRequestSync(pTargetDispatchName, pRequest, .pResponse, pTimeout, pDescription)
    
    Set sc = ##class(Broker.Storage.FlowResult).Hit($CLASSNAME(), pTargetDispatchName, ..%SessionId, tSC, startMs)
    If $$$ISERR(sc) {
        $$$LOGWARNING($SYSTEM.Status.GetErrorText(sc))
    }

    Return tSC
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
