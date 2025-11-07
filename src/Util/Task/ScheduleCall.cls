/// Launch selected business service on schedule
Class Util.Task.ScheduleCall Extends %SYS.Task.Definition
{

Parameter TaskName = "Launch On Schedule";

/// Business Service to launch
Property ServiceName As Ens.DataType.ConfigName;

Method OnTask() As %Status
{
	#dim tService As Ens.BusinessService
	Set tSC = ##class(Ens.Director).CreateBusinessService(..ServiceName, .tService)
	Quit:$$$ISERR(tSC) tSC
	
	Set pRequest = ##class(Ens.Request).%New()
	Quit tService.ProcessInput(pRequest, .pResponse)
}

}
