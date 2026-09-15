Class Broker.Production.Util Extends Ens.Production
{

/// Override this in your Production class to do setup before the Production starts
ClassMethod OnStart(pTimeStarted As %String) As %Status
{
	Set tSC = ##class(Broker.Storage.Processed).ClearPending(.cleared, .kept)

    If $$$ISERR(tSC) {
        $$$LOGWARNING($SYSTEM.Status.GetErrorText(tSC))
    } Else {
        $$$LOGINFO($$$FormatText("Cleared %1 PENDING messages, kept %2 (will be finished by the Production)", cleared, kept))
    }

    Return ##super(pTimeStarted)
}

XData ProductionDefinition
{
<Production></Production>
}

}
