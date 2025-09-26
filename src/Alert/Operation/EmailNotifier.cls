Class Alert.Operation.EmailNotifier Extends Alert.Operation.NotifierUtils
{

Parameter INVOCATION = "Queue";

Parameter ADAPTER = "EnsLib.EMail.OutboundAdapter";

Property Adapter As EnsLib.EMail.OutboundAdapter;

Method OnMessage(request As Ens.AlertRequest, Output response As Ens.Response) As %Status
{
    Set msg = ##class(%Net.MailMessage).%New()
    Set msg.Subject = $$$FormatText("[IRIS Alert] An error occurred while executing %1", request.SourceConfigName)
    Set msg.IsHTML = 1

    // Recipient can be a list of email addresses
    Set to = $PIECE(request.AlertDestination, ":", 2)
    Set total = $LENGTH(to, ";")
	If total '= 0 {
		For i=1:1:total {
			Set email = $ZSTRIP($PIECE(to, ";", i),"<>WC")
			Do:email'="" msg.To.Insert(email)
		}
	} Else {
		Do msg.To.Insert(to)
	}

    Do msg.TextData.Write("<html>")
 	Do msg.TextData.Write("<body>")
 	Do msg.TextData.Write(request.AlertText)
 	Do msg.TextData.Write("<br><br>")
 	Do msg.TextData.Write(..GetTraceLink())
 	Do msg.TextData.Write("<br><br>")
 	Do msg.TextData.Write("<span style='color:DimGray'>This message was generated automatically and does not require an answer.<br>")
 	Do msg.TextData.Write("For questions about this mailing, please contact support.<br>")
 	Do msg.TextData.Write("<br>")
 	Do msg.TextData.Write($$$FormatText("e-mail: <a href='mailto:%1'>%1</a></span>", ..Adapter.From))
 	Do msg.TextData.Write("</body>")
 	Do msg.TextData.Write("</html>")
 	
 	Set ..Adapter.SMTP.IgnoreFailedAuth = 1
	Quit ..Adapter.SendMail(msg)

    Quit $$$OK
}

}
