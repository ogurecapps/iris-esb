/// Reglament cleaning of the Inbox, Processed, Performance and FlowResult tables.
/// Common for all namespaces
Class Broker.Process.Purge Extends Ens.BusinessProcess [ ClassType = persistent ]
{

/// What namespaces must be cleaned? The list with a comma separator
Property Namespaces As %String [ InitialExpression = {$NAMESPACE} ];

/// Message age limit in hours (one month by default). Inbox, Processed and Performance records older than this value will be deleted
Property MessageAgeLimit As %Integer [ InitialExpression = {24 * 7 * 4} ];

/// FlowResult age limit in hours (one day by default). FlowResult records older than this value will be deleted
Property FlowResultAgeLimit As %Integer [ InitialExpression = 24 ];

Parameter SETTINGS = "Namespaces:Basic,MessageAgeLimit:Basic,FlowResultAgeLimit:Basic";

Method OnRequest(request As Ens.Request, Output response As Ens.Response) As %Status
{
    Set tSC = $$$OK
    Set list = $LISTFROMSTRING(..Namespaces)
    Set ptr = 0

    While $LISTNEXT(list,ptr,value) {
		Set tSC = ..CleanNamespace(value, ..MessageAgeLimit, ..FlowResultAgeLimit, .inboxCleared, .processedCleared, .performanceCleared, .flowResultCleared)

        If $$$ISERR(tSC) {
            $$$LOGWARNING($$$FormatText("Purge failed for namespace '%1'. %2", value, $SYSTEM.Status.GetErrorText(tSC)))
        } Else {
            $$$LOGINFO($$$FormatText("Purge completed for namespace '%1'. Inbox cleared: %2, Processed cleared: %3, Performance cleared: %4, FlowResult cleared: %5", value, inboxCleared, processedCleared, performanceCleared, flowResultCleared))
        }
	}

    Return $$$OK
}

Method CleanNamespace(target As %String, limit As %Integer, flowResultLimit As %Integer, Output inboxCleared As %Integer, Output processedCleared As %Integer, Output performanceCleared As %Integer, Output flowResultCleared As %Integer) As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = target

    Return:'##class(%Dictionary.ClassDefinition).%Exists($LISTBUILD("Broker.Storage.Inbox")) $$$ERROR($$$GeneralError, "Class Broker.Storage.Inbox does not exist")
    Return:'##class(%Dictionary.ClassDefinition).%Exists($LISTBUILD("Broker.Storage.Processed")) $$$ERROR($$$GeneralError, "Class Broker.Storage.Processed does not exist")
    Return:'##class(%Dictionary.ClassDefinition).%Exists($LISTBUILD("Broker.Storage.Performance")) $$$ERROR($$$GeneralError, "Class Broker.Storage.Performance does not exist")
    Return:'##class(%Dictionary.ClassDefinition).%Exists($LISTBUILD("Broker.Storage.FlowResult")) $$$ERROR($$$GeneralError, "Class Broker.Storage.FlowResult does not exist")

    Set tSC = ..PurgeInbox(limit, .inboxCleared)
    Return:$$$ISERR(tSC) tSC
    Set tSC = ..PurgeProcessed(limit, .processedCleared)
    Return:$$$ISERR(tSC) tSC
    Set tSC = ..PurgePerformance(limit, .performanceCleared)
    Return:$$$ISERR(tSC) tSC
    Set tSC = ..PurgeFlowResult(flowResultLimit, .flowResultCleared)
    Return:$$$ISERR(tSC) tSC

    Return $$$OK
}

Method PurgeInbox(limit As %Integer, Output cleared As %Integer) As %Status
{
    Set SQLCODE = 0
    New %ROWCOUNT, %msg
    &sql(delete Broker_Storage.Inbox where CreatedAt < {fn TIMESTAMPADD(SQL_TSI_HOUR,-:limit,CURRENT_TIMESTAMP)})
    Return:(SQLCODE<0) $$$ERROR($$$GeneralError, $$$FormatText("PurgeInbox failed (SQLCODE = %1): %2", SQLCODE, %msg))
    
    Set cleared = %ROWCOUNT
    Return $$$OK
}

Method PurgeProcessed(limit As %Integer, Output cleared As %Integer) As %Status
{
    Set SQLCODE = 0
    New %ROWCOUNT, %msg
    &sql(delete Broker_Storage.Processed where UpdatedAt < {fn TIMESTAMPADD(SQL_TSI_HOUR,-:limit,CURRENT_TIMESTAMP)})
    Return:(SQLCODE<0) $$$ERROR($$$GeneralError, $$$FormatText("PurgeProcessed failed (SQLCODE = %1): %2", SQLCODE, %msg))

    Set cleared = %ROWCOUNT
    Return $$$OK
}

Method PurgePerformance(limit As %Integer, Output cleared As %Integer) As %Status
{
    Set SQLCODE = 0
    New %ROWCOUNT, %msg
    &sql(delete Broker_Storage.Performance where CreatedAt < {fn TIMESTAMPADD(SQL_TSI_HOUR,-:limit,CURRENT_TIMESTAMP)})
    Return:(SQLCODE<0) $$$ERROR($$$GeneralError, $$$FormatText("PurgePerformance failed (SQLCODE = %1): %2", SQLCODE, %msg))

    Set cleared = %ROWCOUNT
    Return $$$OK
}

Method PurgeFlowResult(limit As %Integer, Output cleared As %Integer) As %Status
{
    Set SQLCODE = 0
    New %ROWCOUNT, %msg
    &sql(delete Broker_Storage.FlowResult where UpdatedAt < {fn TIMESTAMPADD(SQL_TSI_HOUR,-:limit,CURRENT_TIMESTAMP)})
    Return:(SQLCODE<0) $$$ERROR($$$GeneralError, $$$FormatText("PurgeFlowResult failed (SQLCODE = %1): %2", SQLCODE, %msg))
    
    Set cleared = %ROWCOUNT
    Return $$$OK
}

Storage Default
{
<Data name="PurgeDefaultData">
<Subscript>"Purge"</Subscript>
<Value name="1">
<Value>Namespaces</Value>
</Value>
<Value name="2">
<Value>MessageAgeLimit</Value>
</Value>
<Value name="3">
<Value>FlowResultAgeLimit</Value>
</Value>
</Data>
<DefaultData>PurgeDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
