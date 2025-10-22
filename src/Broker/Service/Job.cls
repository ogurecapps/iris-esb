/// Async call targets by interval
Class Broker.Service.Job Extends Ens.BusinessService
{

Property TargetConfigNames As Ens.DataType.ConfigName;

Property Adapter As Ens.InboundAdapter;

Parameter ADAPTER = "Ens.InboundAdapter";

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
    Set tSC = $$$OK
    Set targets = $LISTFROMSTRING(..TargetConfigNames)

    Quit:$LISTLENGTH(targets)=0 $$$ERROR($$$GeneralError, "TargetConfigNames are not defined")

	For i=1:1:$LISTLENGTH(targets) {
		Set target = $LISTGET(targets, i)
		Set tSC = ..SendRequestAsync(target, ##class(Ens.Request).%New())
        Quit:$$$ISERR(tSC)
    }

    Quit tSC
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
	If pItem.GetModifiedSetting("TargetConfigNames", .tValue) {
		Set targets = $LISTFROMSTRING(tValue)
		For i=1:1:$LISTLENGTH(targets) Set pArray($LISTGET(targets, i)) = ""
	}
}

}
