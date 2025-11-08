/// Call targets by interval
Class Util.Service.IntervalCall Extends Ens.BusinessService
{

/// List of targets to call
Property TargetConfigNames As Ens.DataType.ConfigName;

/// If true, calls are made asynchronously (SendRequestAsync)
Property AsyncCall As %Boolean;

/// If true, and the target list contains more than one target, the process will stop after the first error
Property BreakOnError As %Boolean [ InitialExpression = 1 ];

Property Adapter As Ens.InboundAdapter;

Parameter ADAPTER = "Ens.InboundAdapter";

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId},AsyncCall,BreakOnError";

Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
    Set tSC = $$$OK
    Set targets = $LISTFROMSTRING(..TargetConfigNames)

    Quit:$LISTLENGTH(targets)=0 $$$ERROR($$$GeneralError, "TargetConfigNames are not defined")

	For i=1:1:$LISTLENGTH(targets) {
		Set target = $LISTGET(targets, i)
		Set pRequest = ##class(Ens.Request).%New()

		If ..AsyncCall {
			Set tSC = ..SendRequestAsync(target, pRequest)
		} Else  {
			Set tSC = ..SendRequestSync(target, pRequest, .pResponse)
		}
        Quit:($$$ISERR(tSC)&&..BreakOnError)
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
