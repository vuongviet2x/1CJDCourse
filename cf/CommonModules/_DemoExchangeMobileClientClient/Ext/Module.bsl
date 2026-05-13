#Region Private

// On app startup, runs an exchange with the master server.
//
Procedure OnStart() Export
	ApplicationParameters.Insert("BackgroundJobIdentifier", Undefined);
#If MobileClient Then
	If _DemoExchangeMobileClientServerCall.RequiresDataExchangeWithStandaloneApplication() Then
		If MainServerAvailable() = True Then
			_DemoExchangeMobileClientOfflineClient.StartSync();
		EndIf;
		AttachIdleHandler("LaunchSync", 10);
	EndIf;
#EndIf
EndProcedure 

// Notifies the user that the synchronization between the main server and a standalone server is over.
//
Procedure NotifyAboutEnd() Export
	
	NewEntries = _DemoExchangeMobileClientOfflineServerCall.NewEntriesAcceptedSent();
	If NewEntries.Accepted = 0 And NewEntries.Sent = 0 Then
		Return;
	EndIf;

	RefreshInterface();
	NotificationText1 = NStr("ru = 'Принято объектов: %1 Отправлено объектов: %2';
							|en = 'Objects received: %1 Objects sent: %2';");
	ShowUserNotification(NStr("ru = 'Выполнена синхронизация';
										|en = 'Synchronization is completed';"), , 
		StringFunctionsClientServer.SubstituteParametersToString(NotificationText1, NewEntries.Accepted, NewEntries.Sent));

EndProcedure

// Returns the id of the background job that syncs data with a standalone node.
//
// Returns:
//  String
//
Function BackgroundJobIdentifier() Export

	Return ApplicationParameters.Get("BackgroundJobIdentifier");
	
EndFunction

#EndRegion