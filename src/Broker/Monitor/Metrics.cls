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
        Set consumer = rset.%Get("consumer")
        Set minMs = rset.%Get("minMs")
        Set maxMs = rset.%Get("maxMs")
        Set avgMs = rset.%Get("avgMs")

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
        Set source = rset.%Get("source")
        Set ok = rset.%Get("ok")
        Set error = rset.%Get("error")

        Do ..SetSensor("success_sync_calls_consumer", ok, source)
        Do ..SetSensor("failed_sync_calls_consumer", error, source)
    }

    Set rset = ..SyncCallDurationFunc()

    While rset.%Next() {
        Set source = rset.%Get("source")
        Set target = rset.%Get("target")
        Set minMs = rset.%Get("minMs")
        Set maxMs = rset.%Get("maxMs")
        Set avgMs = rset.%Get("avgMs")

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
        Set consumer = rset.%Get("consumer")
        Set ok = rset.%Get("ok")
        Set error = rset.%Get("error")
        Set pending = rset.%Get("pending")

        Do ..SetSensor("success_messages_consumer", ok, consumer)
        Do ..SetSensor("failed_messages_consumer", error, consumer)
        Do ..SetSensor("pending_messages_consumer", pending, consumer)
    }

    Return $$$OK
}

Query SensorsByConsumer() As %SQLQuery(CONTAINID = 0, ROWSPEC = "consumer:%String,ok:%Integer,error:%Integer,pending:%Integer") [ SqlProc ]
{
    select 
        %exact(p.ConsumerName) as consumer, 
        sum(case when p.Status = 'OK' then 1 else 0 end) as ok, 
        sum(case when p.Status = 'ERROR' then 1 else 0 end) as error, 
        sum(case when p.Status = 'PENDING' then 1 else 0 end) as pending
    from 
        Broker_Storage.Processed p
    group by 
        p.ConsumerName
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
        p.ConsumerName
}

Query SyncCallStatus() As %SQLQuery(CONTAINID = 0, ROWSPEC = "source:%String,ok:%Integer,error:%Integer") [ SqlProc ]
{
    select 
        %exact(Source) as source,
        sum(case when Success=1 then 1 else 0 end) as ok, 
        sum(case when Success<>1 then 1 else 0 end) as error   
    from 
        Broker_Storage.FlowResult
    group by 
        Source
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
        Source,
        Target
}

}
