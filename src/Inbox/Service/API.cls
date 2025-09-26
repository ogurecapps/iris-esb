/// Entry point in Interoperability for Inbox API
/// (use the class name for the Production item name)
Class Inbox.Service.API Extends (Ens.BusinessService, %REST.Impl)
{

/// Deserialization process
Property OnMessageProcess As Ens.DataType.ConfigName [ InitialExpression = "Inbox.Process.OnMessage" ];

Parameter SETTINGS = "OnMessageProcess:Basic:selector?context={Ens.ContextSearch/ProductionItems?className=Inbox.Process.OnMessage&productionName=@productionId}";

ClassMethod Call(pClassName As %String, pRequest As %DynamicObject) As %DynamicObject
{
    Do ..%SetContentType("application/json")
    
    Set input = ##class(Ens.StreamContainer).%New()
    Set input.Stream = ##class(%Stream.GlobalCharacter).%New()
    Do input.Attributes.SetAt(pClassName, "SourceClass")
    
    Do pRequest.%ToJSON(input.Stream)
    
    Quit:$CLASSNAME()'=$GET($$$ConfigClassName($CLASSNAME())) ..Error($$$ERROR($$$EnsErrBusinessDispatchNameNotRegistered, $CLASSNAME()))
	
	Set tSC = ##class(Ens.Director).CreateBusinessService($CLASSNAME(), .service)
	Quit:$$$ISERR(tSC) ..Error(tSC)
	
	Set tSC = service.ProcessInput(input, .output)
	Quit:$$$ISERR(tSC) ..Error(tSC)

    Quit ..Success(output)
}

ClassMethod Success(pOutput As Ens.StreamContainer) As %DynamicObject
{
    Do ..%SetStatusCode(##class(%CSP.REST).#HTTP200OK)

    If (pOutput '= $$$NULLOREF) {
        // HTTP status can be set during the processing of the call in the Business Process
        If pOutput.Attributes.GetAt("Status") '= "" {
            Do ..%SetStatusCode(pOutput.Attributes.GetAt("Status"))
        }
        Set stream = pOutput.StreamGet()
		Quit $SELECT($iso(stream):{}.%FromJSON(stream),1:"")
	} Else {
        Quit ""
    }
}

ClassMethod Error(pStatus As %Status) As %DynamicObject
{
    Do ..%SetStatusCode(##class(%CSP.REST).#HTTP500INTERNALSERVERERROR)
    Do ##class(%CSP.REST).StatusToJSON(pStatus, .json)
    Quit json
}

Method OnProcessInput(pInput As Ens.StreamContainer, Output pOutput As Ens.StreamContainer) As %Status
{
    Quit ..SendRequestSync(..OnMessageProcess, pInput, .pOutput)
}

ClassMethod OnGetConnections(Output pArray As %String, pItem As Ens.Config.Item)
{
    Set:pItem.GetModifiedSetting("OnMessageProcess", .tValue) pArray(tValue) = ""
}

}
