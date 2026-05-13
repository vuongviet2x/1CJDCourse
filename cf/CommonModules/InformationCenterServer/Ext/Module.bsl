
#Region Public

////////////////////////////////////////////////////////////////////////////////
// External links.

// Adds external links to the form.
//
// Parameters:
//	Form - ClientApplicationForm - Form context.
//	FormGroup - FormGroup - External link group.
//	GroupCount - Number - External link group count for the form.
//	NumberOfLinksInGroup - Number - External link count in the group.
//	DisplayAllLink - Boolean - Show "All" URL flag.
//	FormPath - String - Full path to form.
//
Procedure OutputContextualLinks(Form, FormGroup, GroupCount = 3, NumberOfLinksInGroup = 1, 
	DisplayAllLink = True, FormPath = "") Export
	
	Try
		
		If IsBlankString(FormPath) Then 
			FormPath = Form.FormName;
		EndIf;
		
		HashOfPathToForm = HashOfFullPathToForm(FormPath);
		
		FormReferenceTable = InformationCenterServerCached.InformationReferences(HashOfPathToForm);
		If FormReferenceTable.Count() = 0 Then 
			Return;
		EndIf;
		
		// Modify form parameters.
		FormGroup.ShowTitle = False;
		FormGroup.ToolTip   = "";
		FormGroup.Representation = UsualGroupRepresentation.None;
		FormGroup.Group = ChildFormItemsGroup.Horizontal;
		
		// Add a list of external links.
		AttributeName = "InformationReferences";
		AttributesToBeAdded = New Array;
		AttributesToBeAdded.Add(New FormAttribute(AttributeName, New TypeDescription("ValueList")));
		Form.ChangeAttributes(AttributesToBeAdded);
		
		FormOutputGroups(
			Form, FormReferenceTable, FormGroup, GroupCount, NumberOfLinksInGroup, DisplayAllLink);
		
	Except
		
		EventName = GetEventNameForLog();
		WriteLogEvent(EventName, EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
		
	EndTry;	
		
EndProcedure

// Populates form item with external links.
//
// Parameters:
//  Form - ClientApplicationForm - Form.
//  ItemArray - Array of FormField - Array of form items.
//  AllLinksElement - FormDecoration - Form item.
//  FormPath - String - Form path.
//
Procedure FillInStaticInformationLinks(Form, ItemArray, AllLinksElement = Undefined, 
	FormPath = "") Export
	
	Try
		
		If IsBlankString(FormPath) Then 
			FormPath = Form.FormName;
		EndIf;
		
		HashOfPathToForm = HashOfFullPathToForm(FormPath);
		
		RefsTable = InformationCenterServerCached.InformationReferences(HashOfPathToForm);
		If RefsTable.Count() = 0 Then 
			Return;
		EndIf;
		
		FillInformationLinks(Form, ItemArray, RefsTable, AllLinksElement);
		
		//@skip-warning StringliteralContainsError - Check error.
		If TypeOf(AllLinksElement) = Type("FormDecoration") Then
			DisplayLink = RefsTable.Count() <= ItemArray.Count();
			AllLinksElement.Visible = DisplayLink;
		EndIf;
		
		
	Except
		
		EventName = GetEventNameForLog();
		WriteLogEvent(EventName, EventLogLevel.Error,,, 
			DetailErrorDescription(ErrorInfo()));
			
	EndTry;	
	
EndProcedure

// Returns an external link by ID.
//
// Parameters:
//	Id - String - Link ID.
//
// Returns:
//	Structure - Context link.:
//	* Address - String
//	* Description - String
//
Function ContextualLinkByID(Id) Export
	
	ReturnedStructure = New Structure;
	ReturnedStructure.Insert("Address", "");
	ReturnedStructure.Insert("Description", "");
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	InformationReferencesForForms.Address AS Address,
	|	InformationReferencesForForms.Description AS Description
	|FROM
	|	Catalog.InformationReferencesForForms AS InformationReferencesForForms
	|WHERE
	|	InformationReferencesForForms.Id = &ID
	|	AND NOT InformationReferencesForForms.DeletionMark";
	
	Query.SetParameter("ID", Id);
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		ReturnedStructure.Address = Selection.Address;
		ReturnedStructure.Description = Selection.Description;
		Break;
		
	EndDo;
	
	Return ReturnedStructure;
	
EndFunction

// Returns all external link namespaces.
//
// Returns:
//  Array of String - Array of external link namespaces.
//
Function NamespacesOfInformationalLinks() Export
	
	ArrayOfSpaces = New Array;
	ArrayOfSpaces.Add(NamespaceOfInformationalLinks());
	ArrayOfSpaces.Add(NamespaceOfInformationalLinks_1_0_1_1());
	
	Return ArrayOfSpaces;	
	
EndFunction

// Generates a news list.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	NewsTable - ValueTable - Has the following columns:
//	 * Description - String - News item title.
//	 * Id - UUID - News item ID.
//	 * Severity - Number - News item importance.
//	 * ExternalRef - String - External link address.
//	NumberOfDisplayedNews - Number - Number of news items to display on the desktop.
//
Procedure GenerateListOfNewsOnDesktop(NewsTable, Val NumberOfDisplayedNews = 3) Export
	
EndProcedure

// Returns "True" if the integration with 1C:Support Management succeeded.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//	Boolean - True if the integration with the technical support is established.
Function IntegrationWithSupportEstablished() Export
	
	Return ConfirmedCodeForIntegrationOfSUSPS();
		
EndFunction

#EndRegion

#Region Internal

// Returns a list of external link templates.
//
// Returns:
//  Array of TextDocument - Array of common templates.
//
Function GetCommonTemplatesForInformationalLinks() Export
	
	ArrayOfTemplates = New Array;
	ArrayOfTemplates.Add(GetCommonTemplate("InformationLinksCommon"));
	
	InformationCenterServerOverridable.CommonTemplatesWithInformationLinks(ArrayOfTemplates);
	
	Return ArrayOfTemplates;
	
EndFunction

// Generates hash of the full path to the form when a user saves it.
//
Procedure FullFormPathBeforeWriteBeforeWrite(Source, Cancel) Export
	
	If Source.DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsBlankString(Source.FullFormPath) Then 
		Source.Hash = HashOfFullPathToForm(Source.FullFormPath);
	EndIf;
	
EndProcedure

// Returns hash of the full path to a form.
//
// Parameters:
//	FullFormPath - String - Full path to form.
//
// Returns:
//	String - hash.
//
Function HashOfFullPathToForm(Val FullFormPath) Export
	
	DataHashing = New DataHashing(HashFunction.MD5);
	DataHashing.Append(FullFormPath);
	Return StrReplace(DataHashing.HashSum, " ", "");
	
EndFunction

// Returns an event name for Event Log.
//
// Returns:
//	String - a name of an event in the event log.
//
Function GetEventNameForLog() Export
	
	Return NStr("ru = 'Информационный центр';
				|en = 'Information center';", Common.DefaultLanguageCode());
	
EndFunction

// The procedure of the scheduled SupportNewsReader job.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure SupportNewsReader() Export

EndProcedure

// Returns the proxy of the Manager Service Information Center.
// The calling code must set the privileged mode.
// @skip-warning EmptyMethod - Implementation feature.
//
// Returns:
//	WSProxy - an information center proxy.
//
Function GetProxyInformationCenter_1_0_1_1() Export
	
EndFunction

// Address of the support's InformationCenterIntegrationProtected web service.
// 
// Returns:
//  String - Address.
//
Function AddressOfAnonymousIntegrationServiceWithUSPInformationCenter()
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Address = Common.ReadDataFromSecureStorage(
		Owner, "AddressOfAnonymousIntegrationServiceWithUSPInformationCenter");
	SetPrivilegedMode(False);
	
	If Address = Undefined Then
		Return "";
	EndIf;
	
	Return Address;
	
EndFunction

// Address of the ExternalAnonymousAPI (ext_sd) HTTP service of the support service.
// 
// Returns:
//  String - Address. 
//
Function AddressOfExternalAnonymousInterface() Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	AddressOfExternalAnonymousInterface = Common.ReadDataFromSecureStorage(
		Owner, "AddressOfExternalAnonymousInterface");
	SetPrivilegedMode(False);
	
	If AddressOfExternalAnonymousInterface = Undefined Then
		Return "";
	EndIf;
	
	Return AddressOfExternalAnonymousInterface;
	
EndFunction

// Email of the infobase user who addresses the support.
// 
// Returns:
//  String - e-mail
//
Function SubscriberSEmailAddressForSuspIntegration() Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	SubscriberSEmailAddressForSuspIntegration = Common.ReadDataFromSecureStorage(
		Owner, "SubscriberSEmailAddressForSuspIntegration");
	SetPrivilegedMode(False);
	
	If SubscriberSEmailAddressForSuspIntegration = Undefined Then
		Return "";
	EndIf;
	
	Return SubscriberSEmailAddressForSuspIntegration;
	
EndFunction

// Information about the connection between the local infobase and the support.
// 
// Returns:
//  Structure - Contains the following fields:
//  	* AddressOfExternalAnonymousInterface - String - Support ext_sd web service address.
//  	* AddressOfAnonymousIntegrationServiceWithUSPInformationCenter - String - Support web service address.
//  	* ConfirmedCodeForIntegrationOfSUSPS - Boolean - If True, the infobase is connected to 1C:Support Management.
//  	* SubscriberSEmailAddressForSuspIntegration - String - Email of the infobase user who addresses the support. 
//			
//  	* WUSPRegistrationCode - String - Code by which the infobase is registered in the support service.
//
Function DataForSuspIntegrationSettings() Export
	
	Result = New Structure;
	Result.Insert("AddressOfExternalAnonymousInterface", AddressOfExternalAnonymousInterface());
	Result.Insert("AddressOfAnonymousIntegrationServiceWithUSPInformationCenter", 
		AddressOfAnonymousIntegrationServiceWithUSPInformationCenter());
	Result.Insert("ConfirmedCodeForIntegrationOfSUSPS", ConfirmedCodeForIntegrationOfSUSPS());
	Result.Insert("SubscriberSEmailAddressForSuspIntegration", SubscriberSEmailAddressForSuspIntegration());
	Result.Insert("WUSPRegistrationCode", WUSPRegistrationCode());
	
	Return Result;
	
EndFunction

// Determines whether the registration code is entered.
// 
// Returns:
//  Boolean - If True, the code is entered.
//
Function ConfirmedCodeForIntegrationOfSUSPS() Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	ConfirmedCodeForIntegrationOfSUSPS = Common.ReadDataFromSecureStorage(
		Owner, "ConfirmedCodeForIntegrationOfSUSPS");
	SetPrivilegedMode(False);
	
	If ConfirmedCodeForIntegrationOfSUSPS = Undefined Then
		Return False;
	EndIf;
	
	Return ConfirmedCodeForIntegrationOfSUSPS;
	
EndFunction

// Code by which the infobase is registered in the support service.
// 
// Returns:
//  String - Code.
//
Function WUSPRegistrationCode() Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	WUSPRegistrationCode = Common.ReadDataFromSecureStorage(
		Owner, "WUSPRegistrationCode");
	SetPrivilegedMode(False);
	
	If WUSPRegistrationCode = Undefined Then
		Return "";
	EndIf;
	
	Return WUSPRegistrationCode;
	
EndFunction

// Saves the information about the connection between the local infobase and the support.
//
// Parameters:
//  ExternalInterfaceAddress		 - String - Support ext_sd web service address.
//  CodeConfirmed_				 - Boolean - If True, the infobase is connected to 1C:Support Management.
//  SubscriberSAddress				 - String - Email of the infobase user who addresses the support.
//  RegistrationCode				 - String - Code by which the infobase is registered in the support service.
//  AddressOfInformationCenter	 - String - Address to the Technical Support web service that manages tickets.
//
Procedure RecordDataForSuspIntegrationSettings(ExternalInterfaceAddress, CodeConfirmed_, 
	SubscriberSAddress, RegistrationCode, AddressOfInformationCenter) Export
	
	WriteAddressOfExternalAnonymousInterface(ExternalInterfaceAddress);
	WriteDownAddressOfAnonymousIntegrationServiceWithUSPInformationCenter(AddressOfInformationCenter);
	RecordCodeConfirmationFlagForIntegrationOfSuspension(CodeConfirmed_);
	RecordSubscriberSEmailAddressForSuspIntegration(SubscriberSAddress);
	WriteVUSPRegistrationCode(RegistrationCode);
	
EndProcedure

// Saves the support's ext_sd HTTP service.
//
// Parameters:
//  Address	 - String
//
Procedure WriteAddressOfExternalAnonymousInterface(Address) Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(Owner, Address, "AddressOfExternalAnonymousInterface");
	SetPrivilegedMode(False);
	
EndProcedure

// Saves the Technical Support web service for ticket management.
//
// Parameters:
//  Address	 - String
//
Procedure WriteDownAddressOfAnonymousIntegrationServiceWithUSPInformationCenter(Address) Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(
		Owner, Address, "AddressOfAnonymousIntegrationServiceWithUSPInformationCenter");
	SetPrivilegedMode(False);
	
EndProcedure

// Saves the code confirmation flag for the integration of the local infobase and 1C:Support Management.
//
// Parameters:
//  CodeConfirmed	 - Boolean
//
Procedure RecordCodeConfirmationFlagForIntegrationOfSuspension(CodeConfirmed) Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(Owner, CodeConfirmed, "ConfirmedCodeForIntegrationOfSUSPS");
	SetPrivilegedMode(False);
	
EndProcedure

// Saves the email of the infobase user who addresses the support.
//
// Parameters:
//  Address	 - String
//
Procedure RecordSubscriberSEmailAddressForSuspIntegration(Address) Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(Owner, Address, "SubscriberSEmailAddressForSuspIntegration");
	SetPrivilegedMode(False);
	
EndProcedure

// Saves the code by which the infobase is registered in the support service. 
//
// Parameters:
//  Code	 - String
//
Procedure WriteVUSPRegistrationCode(Code) Export
	
	SetPrivilegedMode(True);
	Owner = Common.MetadataObjectID("DataProcessor.InformationCenter");
	Common.WriteDataToSecureStorage(Owner, Code, "WUSPRegistrationCode");
	SetPrivilegedMode(False);
	
EndProcedure

// Cleans up the information about the connection between the local infobase and the support.
//
Procedure ClearDataForSuspIntegrationSettings() Export
	
	WriteAddressOfExternalAnonymousInterface("");
	WriteDownAddressOfAnonymousIntegrationServiceWithUSPInformationCenter("");
	RecordCodeConfirmationFlagForIntegrationOfSuspension(False);
	RecordSubscriberSEmailAddressForSuspIntegration("");
	WriteVUSPRegistrationCode("");
	
EndProcedure

// Returns the picture of the support ticket status.
//
// Parameters:
//	State - String - Support ticket status.
//
// Returns:
//	Picture - Picture.
//
Function ImageByStateOfRequest(State) Export
	
	If State = "Closed" Then 
		Return PictureLib.ClosedSupportRequest;
	ElsIf State = "InProgress" Then
		Return PictureLib.SupportRequestIsInProgress;
	ElsIf State = "New" Then
		Return PictureLib.NewSupportRequest;
	ElsIf State = "NeedAnswer" Then
		Return PictureLib.SupportRequestAnswerRequired;
	EndIf;
	
	Return Undefined;
	
EndFunction

// A picture number by interaction type.
//
// Parameters:
//	InteractionType - String - Interaction type.
//	Incoming - Boolean - Flag indicating whether the interaction is incoming.
//
// Returns:
//	Number - Picture index.
//
Function InteractionImageNumber(InteractionType, Incoming) Export
	
	If InteractionType = "Email" Then 
		If Incoming Then 
			Return 2;
		Else
			Return 3;
		EndIf;
	ElsIf InteractionType = "Comment" Then 
		Return 4;
	ElsIf InteractionType = "PhoneCall" Then 
		Return 1;
	EndIf;
	
	Return 0;
	
EndFunction

// Returns the email address of the active user.
//
// Returns:
//	String - Active user's email address.
//
Function DetermineUserSEmailAddress() Export
	
	CurrentUser = Users.CurrentUser();
	
	If Common.SubsystemExists("StandardSubsystems.ContactInformation") Then 
		
		Module = Common.CommonModule("ContactsManager");
		If Module = Undefined Then 
			Return "";
		EndIf;
		
		Return Module.ObjectContactInformation(CurrentUser, 
			PredefinedValue("Catalog.ContactInformationKinds.UserEmail"));
		
	EndIf;
	
	Return "";
	
EndFunction

// Returns attachment size in MB. The size must not exceed 20 MB.
//
// Returns:
//	Number - Attachment size in MB.
//
Function MaximumSizeOfAttachmentsForSendingMessagesToSupport() Export
	
	Return 20;
	
EndFunction

// The text of an exception raised when 1C:Support Management is unavailable.
//
// Returns:
//	String - an exception text.
//
Function TextOfErrorInformationOutputInSupportService() Export
	
	Return NStr("ru = 'Служба поддержки временно не доступна.
                       |Пожалуйста, повторите попытку позже.';
						|en = 'Technical support is temporarily unavailable.
						|Please, try again later.';")
	
EndFunction

// Returns a support ticket template.
// 
// Parameters:
//  MessageText - String
//  
// Returns:
//	String - Support ticket template.
//
Function TextTemplateInTech(MessageText = "") Export
	
	Template = NStr("ru = 'Здравствуйте.
		|<p/>
		|<p/>%1%2
		|<p/>
		|С уважением, %3.';
		|en = 'Hi,
		|<p/>
		|<p/>%1%2
		|<p/>
		|Best regards, %3';");
	Template = StrTemplate(Template, MessageText, "CursorPosition", Users.CurrentUser().FullDescr());
	
	Return Template;
	
EndFunction

// Gets Technical Support WSProxy.
//
// Returns:
//	WSProxy - Technical Support WSProxy.
//
Function GetSupportProxy() Export
	
	SetPrivilegedMode(True);
	ServiceAddress = AddressOfAnonymousIntegrationServiceWithUSPInformationCenter();
	SetPrivilegedMode(False);
	
	ConnectionParameters = Common.WSProxyConnectionParameters();
	ConnectionParameters.WSDLAddress = ServiceAddress;
	ConnectionParameters.NamespaceURI = "http://www.1c.ru/1cFresh/InformationCenter/SupportServiceData/1.0.0.1";
	ConnectionParameters.ServiceName = "InformationCenterIntegrationProtected_1_0_0_1";
	ConnectionParameters.EndpointName = "InformationCenterIntegrationProtected_1_0_0_1Soap";
	ConnectionParameters.Timeout = 20;
	
	Proxy = Common.CreateWSProxy(ConnectionParameters);
	
	Return Proxy;
	
EndFunction

// Checks the user code required for a support ticket.
//
// Parameters:
//  UserCode	 - String - Code being checked.
//  Email			 - String - Email of the user whose code is being checked.
// 
// Returns:
//  Structure - with the following fields::
//  	* CodeIsCorrect - Boolean
//  	* MessageText - String - Populated if the code is invalid.
//
Function CheckUserCode(UserCode, Email) Export
	
	USPAddress = AddressOfExternalAnonymousInterface();
	
	Result = New Structure;
	Result.Insert("CodeIsCorrect", False);
	Result.Insert("MessageText", "");
	
	ServiceAddress = USPAddress + "/v1/CheckUserCode";
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ServiceAddress);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		
		If Lower(URIStructure.Schema) = Lower("https") Then
			SecureConnection = CommonClientServer.NewSecureConnection(
				, New OSCertificationAuthorityCertificates);
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
		QueryData.Insert("method_name", "CheckUserCode");
		QueryData.Insert("user_code", UserCode);
		QueryData.Insert("email", Email);
		
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
			Result.MessageText = ErrorText;
			Return Result;
		EndIf;
		
		JSONReader = New JSONReader;
		
		ResponseBodyString = Response.GetBodyAsString();
		JSONReader.SetString(ResponseBodyString);
		
		Try
			ResponseData = ReadJSON(JSONReader, False);	
		Except
			
			WriteLogEvent(
				StrTemplate(
					"%1.%2", 
					GetEventNameForLog(), 
					NStr("ru = 'Проверка кода пользователя';
						|en = 'Check user code';", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ResponseBodyString);
			
			Result.MessageText = ResponseBodyString;
			
			Return Result;
		EndTry;
		
		If Not ResponseData.success Then
			
			WriteLogEvent(
				StrTemplate(
					"%1.%2", 
					GetEventNameForLog(), 
					NStr("ru = 'Проверка кода пользователя';
						|en = 'Check user code';", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ResponseData.response_text);
			
			Result.MessageText = ResponseData.response_text;
			
			Return Result;
			
		EndIf;
		
		Result.CodeIsCorrect = True;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(
			StrTemplate(
				"%1.%2", 
				GetEventNameForLog(), 
				NStr("ru = 'Проверка кода пользователя';
					|en = 'Check user code';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo));
		
		Result.MessageText = InformationCenterInternal.DetailedErrorText(ErrorInfo);
		
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

// Returns the access code for the Technical Support Information Center web service.
// @skip-warning EmptyMethod - Implementation feature.
// Returns:
//  String - User code.
//
Function UserCodeForAccess() Export
EndFunction

// Returns the structure of form interaction value by XDTO interaction object.
// 
// Parameters:
//	Interaction - XDTODataObject - Interaction object. 
// Returns:
//	Structure:
// * Subject - String - Interaction topic. 
// * Date - Date - Date the interaction was created.
// * LongDesc - String - Details.
// * Id - UUID - ID.
// * Type - String - Type. 
// * Incoming - Boolean - Direction flag. If True, incoming. If False, outgoing.
//
Function StoredInteractionValue(Interaction) Export
		
	StoredValue = New Structure;
	StoredValue.Insert("Subject", Interaction.Name);
	StoredValue.Insert("Date", Interaction.Date);
	StoredValue.Insert("LongDesc", Interaction.Description);
	StoredValue.Insert("Id", New UUID(Interaction.Id));
	StoredValue.Insert("Type", Interaction.Type);
	StoredValue.Insert("Incoming", Interaction.Incoming);
	
	Return StoredValue;
	
EndFunction

// Infobase information used to integrate with the 1C:Support Management.
// 
// Returns:
//  Structure - Infobase information used to integrate with 1C:Support Management.:
//  * ConfigurationName - String
//  * ConfigurationVersion - String
//  * PlatformVersion - String
//  * ClientID - UUID
//  * InformationSecurityID - String
//  
Function InformationAboutInformationSecurityForIntegration()  Export
	
	Si = New SystemInfo;
	
	InformationRecords = New Structure();
	InformationRecords.Insert("ConfigurationName", Metadata.Name);
	InformationRecords.Insert("ConfigurationVersion", Metadata.Version);
	InformationRecords.Insert("PlatformVersion", Si.AppVersion);
	InformationRecords.Insert("ClientID", Si.ClientID);
	InformationRecords.Insert("InformationSecurityID", Constants.InfoBaseID.Get());
	
	Return InformationRecords;
	
EndFunction

Function RequestUserCodes(UserData_) Export
	
	USPAddress = AddressOfExternalAnonymousInterface();
	
	Result = New Structure;
	Result.Insert("RequestSent", False);
	Result.Insert("QueryID", Undefined);
	Result.Insert("SentEmailsCount", 0);
	Result.Insert("SubscriberHasNoUserAddress", Undefined);
	Result.Insert("ThereIsPageWithProtection", False);
	Result.Insert("MessageText", "");
	
	MethodName = "RequestLocalUserCodesStart";
	
	ServiceAddress = USPAddress + "/v1/"+MethodName;
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ServiceAddress);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		
		If Lower(URIStructure.Schema) = Lower("https") Then
			SecureConnection = CommonClientServer.NewSecureConnection(
				, New OSCertificationAuthorityCertificates);
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
			
		InformationAboutInformationSecurityForIntegration = InformationAboutInformationSecurityForIntegration();
		
		QueryData = New Structure;
		QueryData.Insert("method_name", MethodName);
		QueryData.Insert("users_data", UserData_);
		QueryData.Insert("ibid", InformationAboutInformationSecurityForIntegration.InformationSecurityID);
		QueryData.Insert("register_code", WUSPRegistrationCode());
		
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
			Result.MessageText = ErrorText;
			Return Result;
		EndIf;
		
		JSONReader = New JSONReader;
		
		ResponseBodyString = Response.GetBodyAsString();
		JSONReader.SetString(ResponseBodyString);
		
		Try
			ResponseData = ReadJSON(JSONReader, False);	
		Except
			
			WriteLogEvent(
				StrTemplate(
					"%1.%2", 
					GetEventNameForLog(), 
					NStr("ru = 'Проверка кода пользователя';
						|en = 'Check user code';", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ResponseBodyString);
			
			Result.MessageText = ResponseBodyString;
			
			Return Result;
		EndTry;
		
		If Not ResponseData.success Then
			
			WriteLogEvent(
				StrTemplate(
					"%1.%2", 
					GetEventNameForLog(), 
					NStr("ru = 'Проверка кода пользователя';
						|en = 'Check user code';", Common.DefaultLanguageCode())),
				EventLogLevel.Error,
				,
				,
				ResponseData.response_text);
			
			Result.MessageText = ResponseData.response_text;
			
			Return Result;
			
		EndIf;
		
		Result.RequestSent = True;
		
		If ResponseData.Property("request_id") Then
			Result.QueryID = ResponseData.request_id;
		EndIf;
		
		If ResponseData.Property("captcha")
			And ResponseData.captcha Then
			Result.ThereIsPageWithProtection = True;
		Else
			Result.ThereIsPageWithProtection = False;
		EndIf;
		
		If ResponseData.Property("letters_sent_count") Then
			Result.SentEmailsCount = ResponseData.letters_sent_count;
		EndIf;
		
		If ResponseData.Property("no_abonent_users") Then
			Result.SubscriberHasNoUserAddress = ResponseData.no_abonent_users;
		EndIf;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(
			StrTemplate(
				"%1.%2", 
				GetEventNameForLog(), 
				NStr("ru = 'Проверка кода пользователя';
					|en = 'Check user code';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo));
		
		Result.MessageText = InformationCenterInternal.DetailedErrorText(ErrorInfo);
		
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

Function DecryptTokenForRegistrationInSupportService(Token) Export
	
	Result = New Structure;
	Result.Insert("MessageText", "");
	Result.Insert("Deciphered", False);
	Result.Insert("Data", Undefined);
	
	Try
	
		BinaryData = base64UrlDecode(Token);
		
		DataReader = New DataReader(BinaryData);
		ReadingResult = "";
		While Not DataReader.ReadCompleted Do
			ReadLine_ = DataReader.ReadLine();
			ReadingResult = ReadingResult + ReadLine_ + Chars.LF;
		EndDo;
		DataReader.Close();
		
		StructureOfData = StructureFromJSONString(ReadingResult);
		
		Result.Data = StructureOfData;
		Result.Deciphered = True;
	
	Except
		
		ErrorInfo = ErrorInfo();
		Result.MessageText = CloudTechnology.ShortErrorText(ErrorInfo);
		
		Return Result;
		
	EndTry;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Private

// Returns a namespace for the InformationLinks XDTO package.
//
// Returns:
//	String - a namespace.
//
Function NamespaceOfInformationalLinks()
	
	Return "http://www.1c.ru/SaaS/1.0/XMLSchema/ManageInfoCenter/InformationReferences";
	
EndFunction

// Returns a namespace for the InformationLinks_1_0_1_1 XDTO package.
//
// Returns:
//	String - a namespace.
//
Function NamespaceOfInformationalLinks_1_0_1_1()
	
	Return "http://www.1c.ru/1cFresh/InformationCenter/InformationReferences/1.0.1.1";
	
EndFunction

// Generates form items for external links.
//
// Parameters:
//	Form - ClientApplicationForm - Form context:
//  * InformationReferences - ValueList - External link values.
//	RefsTable - See InformationCenterServerCached.InformationReferences
//	FormGroup - FormGroup - External link group.
//	GroupCount - Number - External link group count for the form.
//	NumberOfLinksInGroup - Number - External link count in the group.
//	DisplayAllLink - Boolean - Show "All" URL flag.
//
Procedure FormOutputGroups(Form, RefsTable, FormGroup, GroupCount, NumberOfLinksInGroup, 
	DisplayAllLink)
	
	RefsCount = ?(RefsTable.Count() > GroupCount * NumberOfLinksInGroup, 
		GroupCount * NumberOfLinksInGroup, RefsTable.Count());
	
	GroupCount = ?(RefsCount < GroupCount, RefsCount, GroupCount);
	
	IncompleteGroupName = "InformationReferencesGroup";
	
	For Iteration = 1 To GroupCount Do 
		
		FormItemName = IncompleteGroupName + String(Iteration);
		ParentGroup2 = Form.Items.Add(FormItemName, Type("FormGroup"), FormGroup);
		ParentGroup2.Type = FormGroupType.UsualGroup;
		ParentGroup2.ShowTitle = False;
		ParentGroup2.Group = ChildFormItemsGroup.Vertical;
		ParentGroup2.Representation = UsualGroupRepresentation.None;
		
	EndDo;
	
	For Iteration = 1 To RefsCount Do 
		
		GroupLinks = GetGroupOfLinks(Form, GroupCount, IncompleteGroupName, Iteration);
		
		RefData = RefsTable.Get(Iteration - 1);
		RefName = RefData.Description;
		Address = RefData.Address;
		
		LinkElement = 
			Form.Items.Add("LinkElement" + String(Iteration), Type("FormDecoration"), GroupLinks);
		LinkElement.Type = FormDecorationType.Label;
		LinkElement.Title = RefName;
		LinkElement.AutoMaxWidth = False;
		LinkElement.Height = 1;
		DataProcessors.InformationCenter.SetHyperlinkAttribute(LinkElement);
		LinkElement.SetAction("Click", "Attachable_ClickingOnInformationLink");
		
		Form.InformationReferences.Add(LinkElement.Name, Address);
		
	EndDo;
	
	If DisplayAllLink Then
		Item = Form.Items.Add("LinkAllInformationalLinks", Type("FormDecoration"), FormGroup);
		Item.Type = FormDecorationType.Label;
		Item.Title = NStr("ru = 'Все';
								|en = 'All';");
		Item.Hyperlink = True;
		Item.TextColor = WebColors.Black;
		Item.HorizontalAlign = ItemHorizontalLocation.Right;
		Item.SetAction("Click", "Attachable_ClickingOnAllInfoLinksLink")
	EndIf;
	
EndProcedure

// Populates form items
//
// Parameters:
//  Form - ClientApplicationForm - Form:
//  * InformationReferences - ValueList - External link values.
//  RefsTable - ValueTable - Table of references.
//  ItemArray - Array - Array of form elements.
//  AllLinksElement - FormDecoration -  "All" label.
//
Procedure FillInformationLinks(Form, ItemArray, RefsTable, AllLinksElement)
	
	For Iteration = 0 To ItemArray.Count() -1 Do
		
		RefData = RefsTable.Get(Iteration);
		
		LinkElement = ItemArray.Get(Iteration);
		LinkElement.Title = RefData.Description;
		DataProcessors.InformationCenter.SetHyperlinkAttribute(LinkElement);
		LinkElement.ToolTip = RefData.ToolTip;
		
		Form.InformationReferences.Add(LinkElement.Name, RefData.Address);
		
	EndDo;
	
EndProcedure

// Returns the group to add external links to.
//
// Parameters:
//	Form - ClientApplicationForm - Form context.
//	GroupCount - Number - External link group count for the form.
//	IncompleteGroupName - String - Brief group description.
//	CurrentIteration - Number - Current iteration.
//
// Returns:
//	FormGroup - a group of information references or Undefined.
//
Function GetGroupOfLinks(Form, GroupCount, IncompleteGroupName, CurrentIteration)
	
	GroupName = "";
	
	For IteratingGroups = 1 To GroupCount Do
		
		If CurrentIteration % IteratingGroups  = 0 Then 
			GroupName = IncompleteGroupName + String(IteratingGroups);
		EndIf;
		
	EndDo;
	
	Return Form.Items.Find(GroupName);
	
EndFunction

Procedure DetermineConnectionStateInBackground(Parameters, ResultAddress) Export
	
	USPAddress = AddressOfExternalAnonymousInterface();
	
	Result = New Structure;
	Result.Insert("Success", True);
	Result.Insert("MessageText", "");
	
	ServiceAddress = USPAddress + "/version";
	
	Try
		
		URIStructure = CommonClientServer.URIStructure(ServiceAddress);
		Host = URIStructure.Host;
		PathAtServer = URIStructure.PathAtServer;
		Port = URIStructure.Port;
		
		If Lower(URIStructure.Schema) = Lower("https") Then
			SecureConnection = CommonClientServer.NewSecureConnection(
				, New OSCertificationAuthorityCertificates);
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
		
		Query = New HTTPRequest(PathAtServer);
		Response = Join.Get(Query);
		
		If Response.StatusCode <> 200 Then
			ErrorText = StrTemplate(NStr("ru = 'Ошибка %1';
										|en = 'Error %1';", Common.DefaultLanguageCode()), String(Response.StatusCode));
			Result.MessageText = ErrorText;
			Result.Success = False;
		EndIf;
		
	Except
		
		ErrorInfo = ErrorInfo();
		
		WriteLogEvent(
			StrTemplate(
				"%1.%2", 
				GetEventNameForLog(), 
				NStr("ru = 'Проверка кода пользователя';
					|en = 'Check user code';", Common.DefaultLanguageCode())),
			EventLogLevel.Error,
			,
			,
			DetailErrorDescription(ErrorInfo));
		
		Result.MessageText = InformationCenterInternal.ShortErrorText(ErrorInfo);
		Result.Success = False;
		
	EndTry;
	
	PutToTempStorage(Result, ResultAddress);
	
EndProcedure

Function base64UrlDecode(Val String)
	
	While StrLen(String) % 4 <> 0 Do
		String = String + "=";
	EndDo;
	
	String = StrReplace(String, "-", "+");
	String = StrReplace(String, "_", "/");
	
	Return Base64Value(String);
	
EndFunction

Function StructureFromJSONString(String, DateTypeProperties = Undefined)
    
	JSONReader = New JSONReader;
    JSONReader.SetString(String);
    Response = ReadJSON(JSONReader,, DateTypeProperties, JSONDateFormat.ISO); 
    Return Response
    
EndFunction

#EndRegion
