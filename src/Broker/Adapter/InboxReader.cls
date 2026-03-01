/// Get Id's unprocessed messages from the Inbox by message handler & message type
Class Broker.Adapter.InboxReader Extends Ens.InboundAdapter
{

/// Production item, handler of messages
Property MessageHandler As Ens.DataType.ConfigName;

/// Will be consume messages only this type
Property MessageType As %String(MAXLEN = 100);

/// Message lifetime (aka depth of messages reading) may be different 
/// for each consumer. Default is 86400 seconds (1 day)
Property MessageLifetime As %Integer [ InitialExpression = 86400 ];

/// - 'NewOnly' means 'At-most once' guarantee type, so the broker will not try to re-deliver messages after error </br> 
/// - 'ErrorOnly' means reading only messages with errors, use it to set up a separate error message thread. 
///    You can limit the number of message delivery retries by the formula: RetryCount = MessageLifetime / CallInterval </br>
/// - 'AllMessages' (by default) means 'At-least once' guarantee type, the broker will attempt to deliver the message 
///    until it receives a successful response, or until the message expires.
Property Read As %String(VALUELIST = ",AllMessages,NewOnly,ErrorOnly") [ InitialExpression = "AllMessages" ];

Parameter SETTINGS = "Read:Reader Settings,MessageHandler:Reader Settings:selector?context={Ens.ContextSearch/SubclassOf?class=Broker.Process.MessageHandler},MessageType:Reader Settings:selector?context={Ens.ContextSearch/SubclassOf?class=Inbox.Message.Inbound},MessageLifetime:Reader Settings";

Method OnTask() As %Status
{
    Return:..NeedSetup(.sc) sc
    Set sc = ..HandleUnprocessedMessages()

    Set ..BusinessHost.%WaitForNextCallInterval = 1    
	Return sc
}

Method HandleUnprocessedMessages() As %Status
{
    Set stmt = ##class(%SQL.Statement).%New()
    Set sc = stmt.%PrepareClassQuery(##class(Broker.Storage.Inbox).%ClassName(1), ..Read)
    Return:$$$ISERR(sc) sc

    Set rset = stmt.%Execute(..MessageHandler, ..MessageType, $SYSTEM.SQL.Functions.DATEADD("ss", -..MessageLifetime, $HOROLOG))
    Return:rset.%SQLCODE'=0 $$$ERROR($$$GeneralError, $$$FormatText("Execute failed. SQLCODE = %1: %2", rset.%SQLCODE, rset.%Message))

    While rset.%Next() {
        Set id = rset.%Get("ID")
        Set msg = ##class(Broker.Storage.Inbox).%OpenId(id)
        If '$ISOBJECT(msg) {
            Set sc = $$$ERROR($$$GeneralError, $$$FormatText("Failed to open message with ID = %1", id))
            Quit
        }

        Set sc = ..BusinessHost.ProcessInput(msg)
		Quit:$$$ISERR(sc)   
    }
    Return:$$$ISERR(sc) sc
    Return:rset.%SQLCODE<0 $$$ERROR($$$GeneralError, $$$FormatText("Next failed. SQLCODE = %1: %2", rset.%SQLCODE, rset.%Message))

    Return sc
}

Method NeedSetup(ByRef sc As %Status) As %Boolean
{
    If ..MessageHandler = "" {
        Set sc = $$$ERROR($$$GeneralError, "MessageHandler is not defined")
        Return 1
    }
    If ..MessageType = "" {
        Set sc = $$$ERROR($$$GeneralError, "MessageType is not defined")
        Return 1
    }

    Return 0
}

}
