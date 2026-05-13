#Region Private

// Checks whether the synchronization between the main server and the standalone server is finished.
//
// Returns:
//  Boolean - "True" if the synchronization is not finished.
//
Function IsSyncRunning()
	ErrorText = "";
	BackgroundJobIdentifier = ApplicationParameters.Get("BackgroundJobIdentifier");
	Return BackgroundJobIdentifier <> Undefined
		And Not _DemoExchangeMobileClientOfflineServerCall.DataExchangeIsOver(BackgroundJobIdentifier, ErrorText);
EndFunction

// Syncs data by performing the following
// - Prompts the user to enter the password to access the main infobase.
// - Starts a background sync process.
// - If the job start failed, shows the error message to the user.
//
Procedure StartSync() Export
	
#If MobileClient Then
	If IsSyncRunning() Then
		Return;
	EndIf;
	
	If MainServerAvailable() <> True Then
		Message = New UserMessage();
		Message.Text = NStr("ru = 'Синхронизация не выполняется из-за отсутствия связи с сервером и возобновится после восстановления связи.';
								|en = 'Synchronization is not running as there is no connection with the server. It will resume after the connection is restored.';");
		Message.Message();
		Return;
	EndIf;

	BackgroundJobIdentifier = _DemoExchangeMobileClientOfflineServerCall.PerformDataExchangeInBackground();
	ApplicationParameters.Insert("BackgroundJobIdentifier", BackgroundJobIdentifier);
	Notify("SyncStarted");
	AttachIdleHandler("WaitSyncEnd", 2);
#EndIf
	
EndProcedure

#EndRegion