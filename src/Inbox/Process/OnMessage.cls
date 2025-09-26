/// Deserialize a message and put it in the message broker
Class Inbox.Process.OnMessage Extends Broker.Process.Put2Inbox
{

Method OnRequest(request As Ens.StreamContainer, Output response As Ens.StreamContainer) As %Status
{
    Set tSC = $$$OK
    
    Set stream = request.StreamGet()
    Quit:('$ISOBJECT(stream))||(stream.Size=0) $$$ERROR($$$GeneralError, "Input stream is empty")
    Set className = request.Attributes.GetAt("SourceClass")
    Quit:className="" $$$ERROR($$$GeneralError, "You must specify the import_to parameter")
    Quit:'##class(%Dictionary.ClassDefinition).%Exists($LISTBUILD(className)) $$$ERROR($$$GeneralError, $$$FormatText("Class '%1' does not exist", className))

    // You must create a class (import schema) for deserializing messages before the ESB can accept messages of this type. 
    // This class must extend Inbox.Message.Inbound and be transferred via the import_to parameter of the Inbox API
    Set msg = $CLASSMETHOD(className, "%New")
	   		
	// If you need to receive %DynamicArray, add a property with the name 'UnnamedArray' in your root class
    If ##class(%Dictionary.CompiledProperty).%ExistsId(className_"||UnnamedArray") {    
		Set tSC = msg.%JSONImport("{""UnnamedArray"":"_stream.Read(stream.Size)_"}")
	} Else {
		Set tSC = msg.%JSONImport(stream)	
	}
    Quit:$$$ISERR(tSC) tSC

    Set tSC = ..Put2Inbox(msg, .resp)
    Quit:$$$ISERR(tSC) tSC

    Set response = ..BuildResponse(className)
    Quit tSC
}

Method BuildResponse(className As %String) As Ens.StreamContainer
{
    Set response = ##class(Ens.StreamContainer).%New()
    Set response.Stream = ##class(%Stream.GlobalCharacter).%New()
    Set json = 
    {
        "success": true,
        "import_to": (className),
        "error_text": "",
        "session_id": (..%SessionId)
    }
    Do json.%ToJSON(response.Stream)
    Do response.Attributes.SetAt(##class(%CSP.REST).#HTTP201CREATED, "Status")
    
    Quit response
}

Storage Default
{
<Type>%Storage.Persistent</Type>
}

}
