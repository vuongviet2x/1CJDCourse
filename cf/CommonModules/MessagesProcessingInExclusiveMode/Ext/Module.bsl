
#Region Public

// See MessagesExchangeOverridable.GetMessagesChannelsHandlers.
//
Procedure OnDefineMessagesChannelsHandlers(Handlers) Export
	
	AddMessageChannelHandler("ExclusiveMode\SetIBTimeZone", MessagesProcessingInExclusiveMode, Handlers);
	
EndProcedure // GetMessagesChannelsHandlers()

// Processes a message body from the channel according to the algorithm of the current message channel.
//
// Parameters:
//  MessagesChannel - String - an ID of a message channel used to receive the message.
//  Body  - Arbitrary - a Body of the message received from the channel to be processed.
//  Sender    - ExchangePlanRef.MessagesExchange - an endpoint that is the sender of the message.
//
Procedure ProcessMessage(MessagesChannel, Body, Sender) Export
	
	If MessagesChannel = "ExclusiveMode\SetIBTimeZone" Then
		SetIBTimeZone(Body);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Sets a new time zone for the infobase.
//
// Parameters:
//  Message - Structure,
//
Procedure SetIBTimeZone(Message) Export
	
	TimeZone = Message.TimeZone;
	DataArea = Message.DataArea;
	
	If SaaSOperationsCached.IsSeparatedConfiguration() Then
		SaaSOperations.SignInToDataArea(DataArea);
	EndIf;
	
	If GetInfoBaseTimeZone() <> TimeZone Then
		
		ExternalMonopolyMode = ExclusiveMode();
		
		If ExternalMonopolyMode Then
			
			AreaBlocked = True;
			
		Else
			
			Try
				
				SetExclusiveMode(True);
				AreaBlocked = True;
				
			Except
				
				AreaBlocked = False;
				
				MessageTemplate = NStr("ru = 'Не удалось заблокировать область данных для установки часового пояса ""%1""';
										|en = 'Cannot lock the data area to set time zone ""%1""';");
				MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TimeZone);
				WriteLogEvent(RemoteAdministrationMessagesImplementation.LogEventRemoteAdministrationSetParameters(),
					EventLogLevel.Error, , , MessageText);
				
			EndTry;
			
		EndIf;
		
		If AreaBlocked Then
			
			If ValueIsFilled(TimeZone) Then
				
				SetInfoBaseTimeZone(TimeZone);
				
			Else
				
				SetInfoBaseTimeZone();
				
			EndIf;
			
			If Not ExternalMonopolyMode Then
				
				SetExclusiveMode(False);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If SaaSOperationsCached.IsSeparatedConfiguration() Then
		SaaSOperations.SignOutOfDataArea();
	EndIf;
	
EndProcedure

Procedure AddMessageChannelHandler(Canal, ChannelHandler, Handlers)
	
	Handler = Handlers.Add();
	Handler.Canal = Canal;
	Handler.Handler = ChannelHandler;
	
EndProcedure

#EndRegion