Class App.Installer
{

XData Install [ XMLNamespace = INSTALLER ]
{
<Manifest>
	<Default Name="NAMESPACE" Value="ESB"/>
	<Default Name="DBNAME" Value="${NAMESPACE}"/>
	<Default Name="SOURCESPATH" Dir="#{$system.Process.CurrentDirectory()}src"/>
	<Default Name="RESOURCE" Value="%DB_%DEFAULT"/>
    <Default Name="PROD" Value="Production.Main"/>

	<Namespace Name="${NAMESPACE}" Code="${DBNAME}" Data="${DBNAME}" Create="yes" Ensemble="1">
		<Configuration>
			<Database Name="${DBNAME}" Dir="${MGRDIR}${DBNAME}" Create="yes" Resource="${RESOURCE}"/>
		</Configuration>

		<Import File="${SOURCESPATH}" Flags="ck" Recurse="1"/>
        <Production Name="${PROD}" AutoStart="1"/>
	</Namespace>

    <Invoke Class="App.Installer" Method="BuildWebApp" CheckStatus="true"/>
    <Invoke Class="App.Installer" Method="EscalateMonitoringPriv" CheckStatus="true"/>
    <Invoke Class="App.Installer" Method="EnableSensors" CheckStatus="true"/>
    <Invoke Class="App.Installer" Method="PutNotifierDefaults" CheckStatus="true"/>
</Manifest>
}

ClassMethod Setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
    Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "Install")
}

ClassMethod BuildWebApp() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    
    Set webProperties("DispatchClass") = "Inbox.API.disp"
    Set webProperties("NameSpace") = "ESB"
    Set webProperties("Enabled") = 1
    Set webProperties("AutheEnabled") = 64
    Set webProperties("MatchRoles") = ":%All"

    Quit ##class(Security.Applications).Create("/csp/rest", .webProperties)
}

/// Somehow, custom sensors don't wanna add to the metrics API without %All privileges
ClassMethod EscalateMonitoringPriv() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"

    Set tSC = $$$OK
    Set appName = "/api/monitor"

    If ##class(Security.Applications).Exists(appName) {
        Set webProperties("MatchRoles") = ":%All"
        Set tSC = ##class(Security.Applications).Modify(appName, .webProperties)
    }

    Quit tSC
}

ClassMethod EnableSensors() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"

    Quit ##class(SYS.Monitor.SAM.Config).AddApplicationClass("Broker.Monitor.Metrics", "ESB")
}

ClassMethod PutNotifierDefaults() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "ESB"

    Do ##class(Ens.Util.LookupTable).%UpdateValue("Alert.Operation.LogFileNotifier", "Sample.Process.CustomerOrderHandler")
    Do ##class(Ens.Util.LookupTable).%UpdateValue("Alert.Operation.LogFileNotifier", "Sample.Process.StringArrayHandler")

    Quit $$$OK
}

}
