Class Broker.Production.Util Extends Ens.Production
{

ClassMethod OnStop(pTimeStarted As %String, pForced As %Boolean)
{
	Set tSC = ##class(Broker.Storage.Processed).ClearPending(.cleared)
    
    If $$$ISERR(tSC) {
        $$$LOGWARNING($SYSTEM.Status.GetErrorText(tSC))
    } Else {
        $$$LOGINFO($$$FormatText("Cleared %1 PENDING messages", cleared))
    }
}

XData ProductionDefinition
{
<Production></Production>
}

}
