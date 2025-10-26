/// Reglament cleaning of the Inbox and Processed tables. 
/// Common for all namespaces
Class Broker.Process.Purge Extends Ens.BusinessProcess [ ClassType = persistent ]
{

/// What namespaces must be cleaned? The list with a comma separator
Property Namespaces As %String [ InitialExpression = {$NAMESPACE} ];

/// Message age limit in hours (one month by default). Records older than this value will be deleted
Property MessageAgeLimit As %Integer [ InitialExpression = {24 * 7 * 4} ];

Parameter SETTINGS = "Namespaces:Basic,MessageAgeLimit:Basic";

Method OnRequest(request As Ens.Request, Output response As Ens.Response) As %Status
{
    Set tSC = $$$OK
    Set list = $LISTFROMSTRING(..Namespaces)
    Set ptr = 0

    While $LISTNEXT(list,ptr,value) {
		Set tSC = ..CleanNamespace(value, ..MessageAgeLimit, .inboxCleared, .processedCleared)
        
        If $$$ISERR(tSC) {
            $$$LOGWARNING($$$FormatText("Purge failed for namespace '%1'. %2", value, $SYSTEM.Status.GetErrorText(tSC)))
        } Else {
            $$$LOGINFO($$$FormatText("Purge completed for namespace '%1'. Inbox cleared: %2, Processed cleared: %3", value, inboxCleared, processedCleared))
        }	
	}

    Quit $$$OK
}

Method CleanNamespace(target As %String, limit As %Integer, Output inboxCleared As %Integer, Output processedCleared As %Integer) As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = target

    Quit:'##class(%Dictionary.ClassDefinition).%Exists($LISTBUILD("Broker.Storage.Inbox")) $$$ERROR($$$GeneralError, "Class Broker.Storage.Inbox does not exist")
    Quit:'##class(%Dictionary.ClassDefinition).%Exists($LISTBUILD("Broker.Storage.Processed")) $$$ERROR($$$GeneralError, "Class Broker.Storage.Processed does not exist")

    Set tSC = ..PurgeInbox(limit, .inboxCleared)
    Quit:$$$ISERR(tSC) tSC
    Set tSC = ..PurgeProcessed(limit, .processedCleared)

    Quit tSC
}

Method PurgeInbox(limit As %Integer, Output cleared As %Integer) As %Status
{
    Set SQLCODE = 0
    New %ROWCOUNT, %msg
    &sql(delete Broker_Storage.Inbox where CreatedAt < {fn TIMESTAMPADD(SQL_TSI_HOUR,-:limit,CURRENT_TIMESTAMP)})
    Quit:(SQLCODE<0) $$$ERROR($$$GeneralError, $$$FormatText("PurgeInbox failed (SQLCODE = %1): %2", SQLCODE, %msg))
    
    Set cleared = %ROWCOUNT
    Quit $$$OK
}

Method PurgeProcessed(limit As %Integer, Output cleared As %Integer) As %Status
{
    Set SQLCODE = 0
    New %ROWCOUNT, %msg
    &sql(delete Broker_Storage.Processed where UpdatedAt < {fn TIMESTAMPADD(SQL_TSI_HOUR,-:limit,CURRENT_TIMESTAMP)})
    Quit:(SQLCODE<0) $$$ERROR($$$GeneralError, $$$FormatText("PurgeProcessed failed (SQLCODE = %1): %2", SQLCODE, %msg))
    
    Set cleared = %ROWCOUNT
    Quit $$$OK
}

Storage Default
{
<Data name="PurgeDefaultData">
<Subscript>"Purge"</Subscript>
<Value name="1">
<Value>Namespaces</Value>
</Value>
<Value name="2">
<Value>AgeLimit</Value>
</Value>
<Value name="3">
<Value>MessageAgeLimit</Value>
</Value>
</Data>
<DefaultData>PurgeDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
