#Region Private

// Runs data exchange with the given time interval.
//
Procedure LaunchSync() Export

#If MobileClient Then
	If MainServerAvailable() = True Then
		_DemoExchangeMobileClientOfflineClient.StartSync();
	EndIf;
#EndIf

EndProcedure

#If MobileClient Then

// Checks whether the synchronization between the main server and the standalone server is finished.
//
Procedure WaitSyncEnd() Export
	
	ErrorText = "";
	BackgroundJobIdentifier = _DemoExchangeMobileClientClient.BackgroundJobIdentifier();
	If Not _DemoExchangeMobileClientOfflineServerCall.DataExchangeIsOver(BackgroundJobIdentifier, ErrorText) Then
		Return;
	EndIf;
	
	DetachIdleHandler("WaitSyncEnd");
	If ErrorText <> "" Then
		Message = New UserMessage();
		Message.Text = ErrorText;
		Message.Message();
		Return;
	EndIf;
	
	If MainServerAvailable() = True Then
		_DemoExchangeMobileClientClient.NotifyAboutEnd();
	EndIf;
	
EndProcedure
#EndIf

#EndRegion