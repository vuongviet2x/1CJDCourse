#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	CurrentUser = Users.AuthorizedUser(); 
	Email = UsersInternal.UserDetails(CurrentUser).Email;

	If Not ValueIsFilled(Email) Then
		Items.DecorationUserEmailNotFilledIn.Visible = True;
		Items.EnterCode.Enabled = False;
		Items.RequestCode.Enabled = False;
	EndIf;

	UserName = UsersInternal.UserDetails(CurrentUser).Description;
	
	Items.LabelEnterCode.Title = NStr("ru = 'Введите код пользователя для работы с обращениями.
		|Этот код мог быть отправлен на ваш e-mail [email].';
		|en = 'Enter your user code for request management.
		|We have sent you a code to [email].';");
	
	Items.LabelEnterCode.Title = StrReplace(Items.LabelEnterCode.Title, "[email]", Email);
	
	USPAddress = InformationCenterServer.AddressOfExternalAnonymousInterface();
	
	InformationAboutInformationSecurity = InformationCenterServer.InformationAboutInformationSecurityForIntegration();
	ConfigurationName = InformationAboutInformationSecurity.ConfigurationName;
	ConfigurationVersion = InformationAboutInformationSecurity.ConfigurationVersion;
	PlatformVersion = InformationAboutInformationSecurity.PlatformVersion;
	ClientID = InformationAboutInformationSecurity.ClientID;
	InformationSecurityID = InformationAboutInformationSecurity.InformationSecurityID;
	
	DataForSuspIntegrationSettings = InformationCenterServer.DataForSuspIntegrationSettings();
	WUSPRegistrationCode = DataForSuspIntegrationSettings.WUSPRegistrationCode;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure RequestCode(Command)
	
	PageAddressTemplate = 
		"%1/v1/RequestUserCode?email=%2&appname=%3&appversion=%4&platf=%5&ibid=%6&clid=%7&code=%8&username=%9";
	LinkToPage = StrTemplate(PageAddressTemplate, 
		USPAddress, Email, ConfigurationName, ConfigurationVersion, 
		PlatformVersion, InformationSecurityID, ClientID, WUSPRegistrationCode, UserName);
		
	#If WebClient Then
		GotoURL(LinkToPage);
	#Else
		RunApp(LinkToPage);
	#EndIf
	
EndProcedure

&AtClient
Procedure EnterCode(Command)
	
	CheckResult = EnterCodeOnServer();
	
	If CheckResult.CodeIsCorrect Then
		InformationCenterClient.SaveUserCodeOnComputer(UserCode);
		InformationCenterClient.OpenListOfWUSPRequests(UserCode);
		Close();
	Else
		CommonClient.MessageToUser(CheckResult.MessageText);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function EnterCodeOnServer()
	
	CheckResult = InformationCenterServer.CheckUserCode(UserCode, Email);
	
	If Not CheckResult.CodeIsCorrect Then
		RecordError(CheckResult.MessageText);
	EndIf;
	
	Return CheckResult;
	
EndFunction

&AtServerNoContext
Function EventLogEventName()
	
	Return InformationCenterServer.GetEventNameForLog();
	
EndFunction

&AtServerNoContext
Procedure RecordError(ErrorText)
	
	WriteLogEvent(
		StrTemplate("%1.%2", EventLogEventName(), 
			NStr("ru = 'Ввод кода пользователя';
				|en = 'Enter user code';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			ErrorText);
	
EndProcedure

#EndRegion
