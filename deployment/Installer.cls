Class App.Installer
{

XData Install [ XMLNamespace = INSTALLER ]
{
<Manifest>
	<Default Name="NAMESPACE" Value="ESB"/>
	<Default Name="DBNAME" Value="${NAMESPACE}"/>
	<Default Name="SOURCESPATH" Dir="#{$system.Process.CurrentDirectory()}src"/>
	<Default Name="RESOURCE" Value="%DB_%DEFAULT"/>
    <Default Name="INBOXAPI" Value="/csp/rest"/>
    <Default Name="PROD" Value="Production.Main"/>
    <Default Name="APIROLE" Value="%All"/>
    <Default Name="APIDISP" Value="Inbox.API.disp"/>

	<Namespace Name="${NAMESPACE}" Code="${DBNAME}" Data="${DBNAME}" Create="yes" Ensemble="1">
		<Configuration>
			<Database Name="${DBNAME}" Dir="${MGRDIR}${DBNAME}" Create="yes" Resource="${RESOURCE}"/>
		</Configuration>
        <CSPApplication 
            Url="${INBOXAPI}"
            Recurse="1"
            Directory="${INBOXAPI}" 
            Grant="${APIROLE}"
            AuthenticationMethods="64"
        />
		<Import File="${SOURCESPATH}" Flags="ck" Recurse="1"/>
        <Production Name="${PROD}" AutoStart="1"/>
	</Namespace>

    <Invoke Class="App.Installer" Method="SetDispatchClass" CheckStatus="true">
        <Arg Value="${INBOXAPI}"/>
        <Arg Value="${APIDISP}"/>
    </Invoke>
    
    <Invoke Class="App.Installer" Method="EnableSensors" CheckStatus="true"/>
</Manifest>
}

ClassMethod Setup(ByRef pVars, pLogLevel As %Integer = 3, pInstaller As %Installer.Installer, pLogger As %Installer.AbstractLogger) As %Status [ CodeMode = objectgenerator, Internal ]
{
    Quit ##class(%Installer.Manifest).%Generate(%compiledclass, %code, "Install")
}

ClassMethod SetDispatchClass(pApp As %String, pClass As %String) As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"
    
    Set tSC = ##class(Security.Applications).Get(pApp, .webProperties)
    Quit:$$$ISERR(tSC) tSC
  
    Set webProperties("DispatchClass") = pClass
    Quit ##class(Security.Applications).Modify(pApp, .webProperties)
}

ClassMethod EnableSensors() As %Status
{
    New $NAMESPACE
    Set $NAMESPACE = "%SYS"

    Quit ##class(SYS.Monitor.SAM.Config).AddApplicationClass("Broker.Monitor.Metrics", "ESB")
}

}
