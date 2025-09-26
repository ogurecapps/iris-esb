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

Parameter SETTINGS = "MessageHandler:Reader Settings:selector?context={Ens.ContextSearch/SubclassOf?class=Broker.Process.MessageHandler},MessageType:Reader Settings:selector?context={Ens.ContextSearch/SubclassOf?class=Inbox.Message.Inbound},MessageLifetime:Reader Settings";

Method OnTask() As %Status
{
    Quit:..NeedSetup(.sc) sc
    Set sc = ..HandleUnprocessedMessages()

    Set ..BusinessHost.%WaitForNextCallInterval = 1    
	Quit sc
}

Method HandleUnprocessedMessages()
{
    Set stmt = ##class(%SQL.Statement).%New()
    Set sc = stmt.%PrepareClassQuery(##class(Broker.Storage.Inbox).%ClassName(1), "UnprocessedMessages")
    Quit:$$$ISERR(sc) sc

    Set rset = stmt.%Execute(..MessageHandler, ..MessageType, $SYSTEM.SQL.Functions.DATEADD("ss", -..MessageLifetime, $HOROLOG))
    Quit:rset.%SQLCODE'=0 $$$ERROR($$$GeneralError, $$$FormatText("Execute failed. SQLCODE = %1: %2", rset.%SQLCODE, rset.%Message))

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
    Quit:$$$ISERR(sc) sc
    Quit:rset.%SQLCODE<0 $$$ERROR($$$GeneralError, $$$FormatText("Next failed. SQLCODE = %1: %2", rset.%SQLCODE, rset.%Message))

    Quit sc
}

Method NeedSetup(ByRef sc As %Status) As %Boolean
{
    If ..MessageHandler = "" {
        Set sc = $$$ERROR($$$GeneralError, "MessageHandler is not defined")
        Quit 1
    }
    If ..MessageType = "" {
        Set sc = $$$ERROR($$$GeneralError, "MessageType is not defined")
        Quit 1
    }

    Quit 0
}

}
