/// Monitoring via REST
Class Broker.Monitor.Metrics Extends %SYS.Monitor.SAM.Abstract
{

Parameter PRODUCT = "esb";

/// 24 hours
Parameter PerformanceDeepInSec = 86400;

/// If you have many namespaces
Parameter Namespaces = "ESB";

Method GetSensors() As %Status
{
	Set list = $LISTFROMSTRING(..#Namespaces)
    Set ptr = 0

    While $LISTNEXT(list,ptr,value) {
        Set tSC = ..GetNamespaceSensors(value, ..#PerformanceDeepInSec)
        Return:$$$ISERR(tSC) tSC
    }

    Return $$$OK
}

Method GetNamespaceSensors(target As %String, perfDeep As %Integer) As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = target

    Set sc = ..PerformanceSensors(perfDeep)
    Return:$$$ISERR(sc) sc

    Set sc = ..SensorsByConsumer()
    Return:$$$ISERR(sc) sc

    Set sc = ..SyncCallSensors()
    Return:$$$ISERR(sc) sc

    Return $$$OK
}

Method PerformanceSensors(perfDeep As %Integer) As %Status
{
    Set rset = ..PerformanceSensorsFunc(-perfDeep)

    While rset.%Next() {
        Set consumer = rset.consumer
        Set minMs = rset.minMs
        Set maxMs = rset.maxMs
        Set avgMs = rset.avgMs

        Set labels("source") = consumer
        Set labels("type") = "min"
        Do ..SetSensorLabels("messages_performance", $NUMBER(minMs/1000,3), .labels)

        Set labels("type") = "max"
        Do ..SetSensorLabels("messages_performance", $NUMBER(maxMs/1000,3), .labels)

        Set labels("type") = "avg"
        Do ..SetSensorLabels("messages_performance", $NUMBER(avgMs/1000,3), .labels)
    }

    Return $$$OK
}

Method SyncCallSensors() As %Status
{
    Set rset = ..SyncCallStatusFunc()

    While rset.%Next() {
        Set source = rset.source
        Set type = $SELECT(rset.success=1:"ok", 1:"error")
        Set counts(source, type) = $GET(counts(source, type)) + rset.cnt
    }

    Set source = ""
    For {
        Set source = $ORDER(counts(source))
        Quit:source=""

        Do ..SetSensor("success_sync_calls_consumer", $GET(counts(source, "ok"), 0), source)
        Do ..SetSensor("failed_sync_calls_consumer", $GET(counts(source, "error"), 0), source)
    }

    Set rset = ..SyncCallDurationFunc()

    While rset.%Next() {
        Set source = rset.source
        Set target = rset.target
        Set minMs = rset.minMs
        Set maxMs = rset.maxMs
        Set avgMs = rset.avgMs

        Set labels("source") = source
        Set labels("target") = target
        Set labels("type") = "min"
        Do ..SetSensorLabels("sync_calls_performance", $NUMBER(minMs/1000,3), .labels)

        Set labels("type") = "max"
        Do ..SetSensorLabels("sync_calls_performance", $NUMBER(maxMs/1000,3), .labels)

        Set labels("type") = "avg"
        Do ..SetSensorLabels("sync_calls_performance", $NUMBER(avgMs/1000,3), .labels)
    }

    Return $$$OK
}

Method SensorsByConsumer() As %Status
{
    Set rset = ..SensorsByConsumerFunc()

    While rset.%Next() {
        Set counts(rset.consumer, rset.status) = rset.cnt
    }

    Set consumer = ""
    For {
        Set consumer = $ORDER(counts(consumer))
        Quit:consumer=""

        Do ..SetSensor("success_messages_consumer", $GET(counts(consumer, "OK"), 0), consumer)
        Do ..SetSensor("failed_messages_consumer", $GET(counts(consumer, "ERROR"), 0), consumer)
        Do ..SetSensor("pending_messages_consumer", $GET(counts(consumer, "PENDING"), 0), consumer)
    }

    Return $$$OK
}

Query SensorsByConsumer() As %SQLQuery(CONTAINID = 0, ROWSPEC = "consumer:%String,status:%String,cnt:%Integer") [ SqlProc ]
{
    select
        %exact(p.ConsumerName) as consumer,
        %exact(p.Status) as status,
        count(*) as cnt
    from
        Broker_Storage.Processed p
    group by
        %exact(p.ConsumerName),
        %exact(p.Status)
}

Query PerformanceSensors(deepInSec As %Integer) As %SQLQuery(CONTAINID = 0, ROWSPEC = "consumer:%String,minMs:%Integer,maxMs:%Integer,avgMs:%Integer") [ SqlProc ]
{
    select 
        %exact(p.ConsumerName) as consumer,
        min(p.ProcessedMs-p.CreatedMs) as minMs,
        max(p.ProcessedMs-p.CreatedMs) as maxMs,
        avg(p.ProcessedMs-p.CreatedMs) as avgMs
    from 
        Broker_Storage.Performance p
    where 
        not p.ProcessedMs is null and
        p.CreatedAt >= {fn TIMESTAMPADD(SQL_TSI_SECOND, :deepInSec, CURRENT_TIMESTAMP)}
    group by
        %exact(p.ConsumerName)
}

Query SyncCallStatus() As %SQLQuery(CONTAINID = 0, ROWSPEC = "source:%String,success:%Boolean,cnt:%Integer") [ SqlProc ]
{
    select
        %exact(Source) as source,
        Success as success,
        count(*) as cnt
    from
        Broker_Storage.FlowResult
    group by
        %exact(Source),
        Success
}

Query SyncCallDuration() As %SQLQuery(CONTAINID = 0, ROWSPEC = "source:%String,target:%String,minMs:%Integer,maxMs:%Integer,avgMs:%Integer") [ SqlProc ]
{
    select 
        %exact(Source) as source,
        %exact(Target) as target,
        min(DurationMs) as minMs,
        max(DurationMs) as maxMs,
        avg(DurationMs) as avgMs    
    from 
        Broker_Storage.FlowResult
    group by
        %exact(Source),
        %exact(Target)
}

ClassMethod RebuildIndices()
{
    Set tSC = $$$OK
    Try {
        $$$ThrowOnError(##class(Broker.Storage.FlowResult).%BuildIndices($LISTBUILD("SourceSuccessBmp","SourceTargetDurationIdx")))
        $$$ThrowOnError(##class(Broker.Storage.Processed).%BuildIndices($LISTBUILD("ConsumerStatusBmp")))
        $$$ThrowOnError(##class(Broker.Storage.Performance).%BuildIndices($LISTBUILD("CreatedAtIdx")))
    } Catch ex {
        Set tSC = ex.AsStatus()
    }

    Write $SELECT($$$ISERR(tSC):$SYSTEM.Status.GetErrorText(tSC), 1:"Success"),!
}

}
