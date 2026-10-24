Class Util.Common [ Abstract ]
{

/// Set checkpoint: ^global(dim1,dim2,...) = $LB(payloadJSON, setAt)
/// setAt - time the checkpoint was set, in UTC seconds; setting it again updates it
ClassMethod SetCheckpoint(global As %String, payload As %DynamicObject, dim... As %String) As %Status
{
	Set @..CheckpointRef(global, dim...) = $LISTBUILD($SELECT($ISOBJECT(payload): payload.%ToJSON(), 1: ""), ..CheckpointNow())
	Return $$$OK
}

/// Checks whether the checkpoint is set.
/// If a TTL in seconds is set in ^Common.Checkpoint.Config(global), a checkpoint older than the TTL is treated as unknown.
/// Without a TTL in the config, checkpoints never expire.
ClassMethod IsKnownCheckpoint(global As %String, Output payload As %String, dim... As %String) As %Boolean
{
	Set payload = ""
	Set value = $GET(@..CheckpointRef(global, dim...))
	Return:value="" 0

	Set ttl = +$GET(^Common.Checkpoint.Config(global))
	Return:(ttl > 0)&&((..CheckpointNow() - $LISTGET(value, 2)) >= ttl) 0

	Set payload = $LISTGET(value, 1)
	Return 1
}

ClassMethod CheckpointNow() As %Integer [ Private ]
{
	Set stamp = $ZTIMESTAMP
	Return ($PIECE(stamp, ",") * 86400) + ($PIECE(stamp, ",", 2) \ 1)
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
