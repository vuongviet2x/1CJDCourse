#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("DatabaseEnabled") Then
		DatabaseEnabled = Parameters.DatabaseEnabled;
	EndIf;
	
	If DatabaseEnabled Then
		
		DataForSuspIntegrationSettings = InformationCenterServer.DataForSuspIntegrationSettings();
		USPAddress = DataForSuspIntegrationSettings.AddressOfExternalAnonymousInterface;
		Email = DataForSuspIntegrationSettings.SubscriberSEmailAddressForSuspIntegration;
		
		If Not ValueIsFilled(Email) Then
			Items.DecorationUserEmailNotFilledIn.Visible = True;
			Items.EnterRegistrationCode_SSLyf.Enabled = False;
			Items.EnterTokenForRegistration.Enabled = False;
		EndIf;

		Items.InformationDecoration.Title = NStr("ru = 'Информационная база подключена к службе поддержки со следующими параметрами:';
														|en = 'The infobase is connected to the technical support with the following parameters:';");
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		
		JobParameters = TimeConsumingOperations.ExecuteInBackground(
			"InformationCenterServer.DetermineConnectionStateInBackground", , ExecutionParameters);
		
		Items.ConnectionStateIcon.Picture = PictureLib.TimeConsumingOperation16;
		
		RegistrationCode = InformationCenterServer.WUSPRegistrationCode();
		InformationAboutInformationSecurity = InformationCenterServer.InformationAboutInformationSecurityForIntegration();
		InformationSecurityID = InformationAboutInformationSecurity.InformationSecurityID;
		
	Else
		
		Items.InformationDecoration.Title = NStr("ru = 'Информационная база не подключена к службе поддержки. Подключить базу можно сейчас.';
														|en = 'The infobase is not connected to the technical support. You can connect the infobase now.';");
		
		Email = UsersInternal.UserDetails(Users.AuthorizedUser()).Email;
		InformationAboutInformationSecurity = InformationCenterServer.InformationAboutInformationSecurityForIntegration();
		ConfigurationName = InformationAboutInformationSecurity.ConfigurationName;
		ConfigurationVersion = InformationAboutInformationSecurity.ConfigurationVersion;
		PlatformVersion = InformationAboutInformationSecurity.PlatformVersion;
		ClientID = InformationAboutInformationSecurity.ClientID;
		InformationSecurityID = InformationAboutInformationSecurity.InformationSecurityID;
		
	EndIf;
	
	Items.RegistrationCode.Visible = Not DatabaseEnabled;
	Items.EnterRegistrationCode_SSLyf.Visible = Not DatabaseEnabled;
	Items.GoToRegistrationPage.Visible = Not DatabaseEnabled;
	Items.CancelConnection.Visible = DatabaseEnabled;
	Items.CancelConnection.Enabled = False;
	
	Items.USPAddress.ReadOnly = DatabaseEnabled;
	Items.Email.ReadOnly = DatabaseEnabled;
	Items.ConnectionStatusGroup.Visible = DatabaseEnabled;
	
	Items.GroupEnteringTokenForActivation.Visible = Not DatabaseEnabled;
	
	Items.GoToPageRequestingUserCodes.Visible = DatabaseEnabled;
	Items.GoToPageRequestingUserCodes.Enabled = False;
	
	Items.DecorationInscriptionConnectDatabase.Visible = Not DatabaseEnabled;
	Items.DecorationInscriptionWithHelpOfCode.Visible = Not DatabaseEnabled;
	Items.SeparatorGroup.Visible = Not DatabaseEnabled;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)

	If DatabaseEnabled Then
		AttachIdleHandler("DetermineConnectionStateInPendingBackground", 1, True);
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure GoToRegistrationPage(Command)
	
	If Not ValueIsFilled(USPAddress) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Необходимо указать адрес службы поддержки';
				|en = 'Specify the technical support address';"), , "USPAddress");
		Return;
	EndIf;
	
	If Not ValueIsFilled(Email) Then
		CommonClient.MessageToUser(
			NStr("ru = 'Необходимо указать e-mail пользователя';
				|en = 'Specify user email';"), , "Email");
		Return;
	EndIf;
	
	PageAddressTemplate = "%1/v1/StartLocalRegistration?email=%2&appname=%3&appversion=%4&platf=%5&ibid=%6&clid=%7";
	LinkToPage = StrTemplate(PageAddressTemplate, 
		USPAddress, Email, ConfigurationName, ConfigurationVersion, PlatformVersion, InformationSecurityID, ClientID);
	
	#If WebClient Then
		GotoURL(LinkToPage);
	#Else
		RunApp(LinkToPage);
	#EndIf
	
EndProcedure

&AtClient
Procedure EnterRegistrationCode_SSLyf(Command)
	Result = EnterRegistrationCodeOnServer();
	If Not Result.Success Then
		CommonClient.MessageToUser(Result.MessageText);
	EndIf;
EndProcedure

&AtClient
Procedure GoToRequests(Command)
	
	Close();
	InformationCenterClient.OpenSupportRequests();
	
EndProcedure

&AtClient
Procedure CancelConnection(Command)

	Notification = New NotifyDescription("CancelConnectionWhenCheckingResponse", ThisForm);
	
	QueryText = NStr("ru = 'После отмены подключения работа с обращениями в службу поддержки будет невозможна. Продолжить?';
						|en = 'After the connection is canceled, operations with requests to the technical support will be unavailable. Continue?';");
	
	ShowQueryBox(Notification, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure RequestUserCodes(Command)
	
	If Not CheckingBeforeSendingCodeRequests() Then
		Return;
	EndIf;

	QueryResult = RequestUserCodesOnServer();
	
	If Not QueryResult.RequestSent Then
		CommonClient.MessageToUser(QueryResult.MessageText);
		Return;
	EndIf;
	
	If QueryResult.Property("QueryID")
		And ValueIsFilled(QueryResult.QueryID)
		And QueryResult.Property("ThereIsPageWithProtection")
		And QueryResult.ThereIsPageWithProtection Then
		OpenPageForReceivingUserCodesWithProtection(QueryResult.QueryID);
		Return;
	EndIf;
	
	If QueryResult.Property("ThereIsPageWithProtection")
		And Not QueryResult.ThereIsPageWithProtection Then
		
		MessageText = StrTemplate(
			NStr("ru = 'Отправлено писем: %1.';
				|en = 'Sent emails: %1.';"),
			QueryResult.SentEmailsCount);
			
		MessageText = MessageText 
			+ Chars.LF 
			+ NStr("ru = 'Код, отправленный в письме, пользователи могут использовать для работы с обращениями.';
					|en = 'Users can use the code sent in the email to manage tickets.';");
		
		If QueryResult.Property("SubscriberHasNoUserAddress") Then
			CheckAndDisplayErrorsInSendingEmails(QueryResult.SubscriberHasNoUserAddress);
		EndIf;

		If ValueIsFilled(QueryResult.MessageText) Then
			MessageText = MessageText + Chars.LF + QueryResult.MessageText;
		EndIf;
		
		CommonClient.MessageToUser(MessageText);
		
		Return;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToPageRequestingUserCodes(Command)
	GoToPageRequestingUserCodesOnServer();
EndProcedure

&AtClient
Procedure EnterTokenForRegistration(Command)
	
	TextInvalidToken = NStr("ru = 'Неверный токен для регистрации.';
								|en = 'Incorrect token for registration.';");
	
	If Not ValueIsFilled(TokenForRegistration) Then
		CommonClient.MessageToUser(
			TextInvalidToken,
			,
			"TokenForRegistration");
		Return;
	EndIf;
	
	TokenDecryptionData = TokenDecryptionData(TokenForRegistration);
	
	If Not TokenDecryptionData.Deciphered Then
		CommonClient.MessageToUser(
			TextInvalidToken,
			,
			"TokenForRegistration");
		Return;
	EndIf;
	
	If Not TokenDecryptionData.Data.Property("email") Then
		CommonClient.MessageToUser(
			TextInvalidToken,
			,
			"TokenForRegistration");
		Return;
	EndIf;
	
	If TokenDecryptionData.Data.email <> Email Then
		CommonClient.MessageToUser(
			NStr("ru = 'Токен предназначен для пользователя с другим адресом электронной почты.';
				|en = 'The token is generated for a user with a different email address.';"),
			,
			"TokenForRegistration");
		Return;
	EndIf;

	USPAddress = TokenDecryptionData.Data.url;
	Email = TokenDecryptionData.Data.email;
	RegistrationCode = TokenDecryptionData.Data.code;
	
	Result = EnterRegistrationCodeOnServer();
	If Not Result.Success Then
		CommonClient.MessageToUser(Result.MessageText);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function EnterRegistrationCodeOnServer()
	
	Result = New Structure;
	Result.Insert("MessageText", "");
	Result.Insert("Success", False);
	
	ServiceAddress = USPAddress + "/v1/FinishLocalRegistration";
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ServiceAddress);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		
		If Lower(URIStructure.Schema) = Lower("https") Then
			SecureConnection = 
				CommonClientServer.NewSecureConnection(, New OSCertificationAuthorityCertificates);
		Else
			SecureConnection = Undefined;
		EndIf;
		
		Join = New HTTPConnection(
			Host,
			Port,
			,
			,
			GetFilesFromInternet.GetProxy(URIStructure.Schema),
			,
			SecureConnection);
		
		QueryData = New Structure;
		QueryData.Insert("email", Email);
		QueryData.Insert("appname", ConfigurationName);
		QueryData.Insert("appversion", ConfigurationVersion);
		QueryData.Insert("platf", PlatformVersion);
		QueryData.Insert("ibid", InformationSecurityID);
		QueryData.Insert("clid", ClientID);
		QueryData.Insert("code", RegistrationCode);
		QueryData.Insert("method_name", "FinishLocalRegistration");
		
		JSONWriter = New JSONWriter;
		JSONWriter.SetString();
		WriteJSON(JSONWriter, QueryData);
		
		QueryString = JSONWriter.Close();
		
		Headers = New Map;
		Headers.Insert("Content-Type", "application/json; charset=utf-8");
		Headers.Insert("Accept", "application/json");
		
		Query = New HTTPRequest(PathAtServer, Headers);
		Query.SetBodyFromString(QueryString);
		
		Response = Join.Post(Query);
		
		If Response.StatusCode <> 200 Then
			
			ErrorText = StrTemplate(NStr("ru = 'Ошибка %1';
										|en = 'Error %1';", Common.DefaultLanguageCode()), String(Response.StatusCode));
			RecordError(Result, ErrorText);
			Return Result;
			
		EndIf;
		
		JSONReader = New JSONReader;
		
		ResponseBodyString = Response.GetBodyAsString();
		JSONReader.SetString(ResponseBodyString);
		
		Try
			ResponseData = ReadJSON(JSONReader, False);	
		Except
			RecordError(Result, ResponseBodyString);
			Return Result;
		EndTry;
		
		If Not ResponseData.success Then
			RecordError(Result, ResponseData.response_text);
			Return Result;
		EndIf;
		
		AddressOfInformationCenter = ResponseData.info_center_address;
		
		WhenRegistrationCodeIsSuccessfullyEntered();
		
		Result.Success = True;
		Return Result;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		RecordError(Result, 
			InformationCenterInternal.DetailedErrorText(ErrorInfo), 
			InformationCenterInternal.ShortErrorText(ErrorInfo));
			
		Return Result;
		
	EndTry;
	
EndFunction

&AtServer
Procedure RecordError(Result, DetailedErrorText, Val ShortErrorText = "")
	
	If Not ValueIsFilled(ShortErrorText) Then
		ShortErrorText = DetailedErrorText;
	EndIf;
	
	Result.Success = False;
	Result.MessageText = ShortErrorText;
	
	WriteLogEvent(
		StrTemplate("%1.%2", EventLogEventName(), 
			NStr("ru = 'Ввод кода регистрации';
				|en = 'Enter registration code';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			DetailedErrorText);
				
	Result.Success = False;
	Result.MessageText = ShortErrorText;
	
EndProcedure

&AtServer
Procedure WhenRegistrationCodeIsSuccessfullyEntered()
	
	Items.DecorationSuccessfulConnection.Title = StrReplace(
		Items.DecorationSuccessfulConnection.Title,
		"[Email]",
		Email);
	
	InformationCenterServer.RecordDataForSuspIntegrationSettings(
		USPAddress,
		True,
		Email,
		RegistrationCode,
		AddressOfInformationCenter);
	
	Items.GroupPages.CurrentPage = Items.SuccessfulConnectionPage;
	
EndProcedure

&AtServer
Function EventLogEventName()
	
	Return InformationCenterServer.GetEventNameForLog();
	
EndFunction

&AtClient
Procedure DefineSupportedBasesInBackgroundEnd(Operation, AdditionalParameters) Export
	
	If Operation.Status = "Completed2" Then
		
		Result = GetFromTempStorage(Operation.ResultAddress);
		
		If Result.Success Then
			Items.ConnectionStateLabel.Title = NStr("ru = 'Подключено';
																	|en = 'Connected';");
			Items.ConnectionStateIcon.Picture = PictureLib.AppearanceCheckIcon;
			Items.CancelConnection.Enabled = True;
			Items.GoToPageRequestingUserCodes.Enabled = True;
		Else
			Items.ConnectionStateLabel.Title = NStr("ru = 'Ошибка подключения: ';
																	|en = 'Connection error: ';") + Result.MessageText;
			Items.ConnectionStateIcon.Picture = PictureLib.AppearanceExclamationMarkIcon;
			Items.GoToPageRequestingUserCodes.Enabled = False;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure DetermineConnectionStateInPendingBackground()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.OutputIdleWindow = False;
	
	Handler = New NotifyDescription("DefineSupportedBasesInBackgroundEnd", ThisObject);
	TimeConsumingOperationsClient.WaitCompletion(JobParameters, Handler, IdleParameters);
	
EndProcedure

&AtServer
Procedure CancelConnectionOnServer()
	
	InformationCenterServer.ClearDataForSuspIntegrationSettings();
	
EndProcedure

&AtClient
Procedure CancelConnectionWhenCheckingResponse(Response, AdditionalParameters) Export
	
	If Response = DialogReturnCode.Yes Then
		CancelConnectionOnServer();
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TokenDecryptionData(Token)
	
	Return InformationCenterServer.DecryptTokenForRegistrationInSupportService(Token);
	
EndFunction

&AtServer
Procedure GoToPageRequestingUserCodesOnServer()
	
	FillInListOfInformationSecurityUsers();
	Title = NStr("ru = 'Запросить коды пользователей';
					|en = 'Request user codes';");
	Items.GroupPages.CurrentPage = Items.RequestUserCodePage;
	
EndProcedure

&AtServer
Procedure FillInListOfInformationSecurityUsers()
	
	Query = New Query;
	Query.Text = "SELECT
	|	UsersContactInformation.Ref AS User,
	|	MIN(UsersContactInformation.LineNumber) AS LineNumber
	|INTO UsersWithKILineNumbers
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|WHERE
	|	NOT UsersContactInformation.Ref.Invalid
	|	AND NOT UsersContactInformation.Ref.IsInternal
	|	AND UsersContactInformation.EMAddress <> """"
	|
	|GROUP BY
	|	UsersContactInformation.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UsersWithKILineNumbers.User AS User,
	|	UsersContactInformation.EMAddress AS Email,
	|	TRUE AS RequestCode
	|FROM
	|	Catalog.Users.ContactInformation AS UsersContactInformation
	|		INNER JOIN UsersWithKILineNumbers AS UsersWithKILineNumbers
	|		ON UsersContactInformation.Ref = UsersWithKILineNumbers.User
	|			AND (UsersWithKILineNumbers.LineNumber = UsersContactInformation.LineNumber)";
	
	UsersToRequestCodes.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure OpenPageForReceivingUserCodesWithProtection(QueryID)
	
	PageAddressTemplate = 
		"%1/v1/RequestLocalUserCodesContinue?rid=%2&register_code=%3&ibid=%4";
	LinkToPage = StrTemplate(PageAddressTemplate, 
		USPAddress, QueryID, RegistrationCode, InformationSecurityID);
		
	#If WebClient Then
		GotoURL(LinkToPage);
	#Else
		RunApp(LinkToPage);
	#EndIf
	
EndProcedure

&AtServer
Function RequestUserCodesOnServer()
	
	UserData_ = New Array;
	For Each UserRow1 In UsersToRequestCodes Do
		If Not UserRow1.RequestCode Then
			Continue;
		EndIf;
		UserData_.Add(
			New Structure(
				"username, email",
				String(UserRow1.User),
				UserRow1.Email));
	EndDo;
	
	QueryResult = InformationCenterServer.RequestUserCodes(UserData_);
	
	Return QueryResult;
	
EndFunction

&AtServer
Function CheckingBeforeSendingCodeRequests()
	
	For IndexOf = 0 To UsersToRequestCodes.Count() - 1 Do
		UserRow1 = UsersToRequestCodes[IndexOf];
		If Not CommonClientServer.EmailAddressMeetsRequirements(UserRow1.Email) Then
			Common.MessageToUser(
			NStr("ru = 'Адрес электронной почты содержит ошибки';
				|en = 'The email address contains errors';"),
			,
			"UsersToRequestCodes["+String(IndexOf)+"].Email");
			Return False;
		EndIf;
	EndDo;
	
	Return True;
	
EndFunction

&AtServer
Procedure CheckAndDisplayErrorsInSendingEmails(SubscriberHasNoUserAddress)
	
	If SubscriberHasNoUserAddress = Undefined Then
		Return;
	EndIf;
	
	MessageTemplate = 
		NStr("ru = 'Пользователя с адресом %1 нет в базе службы поддержки, поэтому ему не отправлено письмо.';
			|en = 'A user with the %1 address is not found in the technical support database, so no email was sent to them.';");
	
	For Each Address In SubscriberHasNoUserAddress Do
		
		UserStrings = UsersToRequestCodes.FindRows(New Structure("Email", Address));
		If UserStrings.Count() = 0 Then
			Continue;
		EndIf;
		
		UserRow1 = UserStrings[0];
		RowIndex = UsersToRequestCodes.IndexOf(UserRow1);
		
		MessageText = StrTemplate(MessageTemplate, Address);
		
		Common.MessageToUser(
			MessageText, 
			, 
			"UsersToRequestCodes["+String(RowIndex)+"].Email");
		
	EndDo;
	
EndProcedure

#EndRegion
