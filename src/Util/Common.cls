Class Util.Common [ Abstract ]
{

ClassMethod SetCheckpoint(global As %String, payload As %DynamicObject, dim... As %String) As %Status
{
	Set @..CheckpointRef(global, dim...) = payload.%ToJSON()
	Return $$$OK
}

ClassMethod IsKnownCheckpoint(global As %String, Output payload As %String, dim... As %String) As %Boolean
{
	Set payload = $GET(@..CheckpointRef(global, dim...))
	Return payload '= ""
}

ClassMethod CheckpointRef(global As %String, dim... As %String) As %String [ Private ]
{
	Set ref = global
	For i=1:1:$GET(dim) {
		Set ref = $NAME(@ref@(dim(i)))
	}
	Return ref
}

}
