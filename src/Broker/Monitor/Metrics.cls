/// Monitoring via REST
Class Broker.Monitor.Metrics Extends %SYS.Monitor.SAM.Abstract
{

Parameter PRODUCT = "esb_broker";

/// 24 hours
Parameter PerformanceDeepInSec = 86400;

Method GetSensors() As %Status
{
	Set sc = ..PerformanceSensors()
    Quit:$$$ISERR(sc) sc

    Set sc = ..SensorsByConsumer()
    Quit sc
}

Method PerformanceSensors() As %Status
{
    Set rset = ..PerformanceSensorsFunc(-..#PerformanceDeepInSec)

    While rset.%Next() {
        Set consumer = rset.%Get("consumer")
        Set minMs = rset.%Get("minMs")
        Set maxMs = rset.%Get("maxMs")
        Set avgMs = rset.%Get("avgMs")

        Set labels("id") = consumer
        Set labels("type") = "min"
        Do ..SetSensorLabels("request_response_performance", $NUMBER(minMs/1000,3), .labels)

        Set labels("type") = "max"
        Do ..SetSensorLabels("request_response_performance", $NUMBER(maxMs/1000,3), .labels)

        Set labels("type") = "avg"
        Do ..SetSensorLabels("request_response_performance", $NUMBER(avgMs/1000,3), .labels)
    }

    Quit $$$OK
}

Method SensorsByConsumer() As %Status
{
    Set rset = ..SensorsByConsumerFunc()

    While rset.%Next() {
        Set consumer = rset.%Get("consumer")
        Set ok = rset.%Get("ok")
        Set error = rset.%Get("error")
        Set pending = rset.%Get("pending")
        Set retries = rset.%Get("retries")

        Do ..SetSensor("success_messages_consumer", ok, consumer)
        Do ..SetSensor("failed_messages_consumer", error, consumer)
        Do ..SetSensor("pending_messages_consumer", pending, consumer)
        Do ..SetSensor("retries_messages_consumer", retries, consumer)
    }

    Quit $$$OK
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

}
