
#Region Public

// A procedure that handles external link clicks.
//
// Parameters:
//	Form - ClientApplicationForm - Context of a client application form.
//	Item - FormGroup - Form group.
//
Procedure ClickingOnInformationLink(Form, Item) Export
	
	Hyperlink = Form.InformationReferences.FindByValue(Item.Name);
	
	If Hyperlink <> Undefined Then
		
		FileSystemClient.OpenURL(Hyperlink.Presentation);
		
	EndIf;
	
EndProcedure

// A procedure that handles "All" link clicks.
//
// Parameters:
//	FormPath - String - Full path to form.
//
Procedure ClickingOnAllInfoLinksLink(FormPath) Export

	FormParameters = New Structure("FormPath", FormPath);
	OpenForm("DataProcessor.InformationCenter.Form.InformationLinksInContext", FormParameters);
	
EndProcedure

// Opens a form with all support tickets.
//
Procedure OpenSupportRequests() Export
	
	DatabaseIsConnectedByCusp = DatabaseIsConnectedByCusp();
	If DatabaseIsConnectedByCusp Then
		
		UserCode = ReadUserCodeFromComputerForUSP();
		If Not ValueIsFilled(UserCode) Then
			OpenUserCodeEntryForm();
			Return;
		EndIf;
		
		UserEmail = UserEmail();
		If Not ValueIsFilled(UserEmail) Then
			MessageText = NStr("ru = 'Для работы с обращениями нужно заполнить e-mail пользователя.';
									|en = 'To manage requests, fill in user email.';");
			CommonClient.MessageToUser(MessageText);
			Return;
		EndIf;
		
		CodeReviewResult = CheckUserCodeForUSP(UserCode, UserEmail);
			
		If Not CodeReviewResult.CodeIsCorrect Then
			OpenUserCodeEntryForm();
			Return;
		EndIf;
			
		OpenListOfWUSPRequests(UserCode);
		
	Else
		
		OpenCuspActivationForm(DatabaseIsConnectedByCusp);
		
	EndIf;
	
EndProcedure

// Opens a form with forum discussions.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OpenForumDiscussions() Export 
EndProcedure

// Opens a form with Idea Center.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure OpenIdeaCenter() Export 
EndProcedure

// Opens a form to display all news.
// @skip-warning EmptyMethod - Implementation feature.
//
Procedure ShowAllMessages() Export
EndProcedure

// Defines whether the local infobase is connected to the technical support.
// 
// Returns:
//  Boolean - If True, the infobase is connected to 1C:Support Management.
//
Function DatabaseIsConnectedByCusp() Export
	
	SettingsData = InformationCenterServerCall.DataForSuspIntegrationSettings();
	Return SettingsData.ConfirmedCodeForIntegrationOfSUSPS;
	
EndFunction

// Opens the interaction based on the support ticket.
//
// Parameters:
//	SupportRequestID - UUID - Support ticket ID.
//	InteractionID - UUID - Interaction ID.
//	InteractionType - String - Interaction type.
//	Incoming - Boolean - Incoming message flag.
//	Viewed_SSLyf - Boolean - Message read flag.
//
Procedure OpenInteractionWithSupport(SupportRequestID, InteractionID, InteractionType, 
	Incoming, Viewed_SSLyf = True, UserCode = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("SupportRequestID", SupportRequestID);
	FormParameters.Insert("InteractionID", InteractionID);
	FormParameters.Insert("InteractionType", InteractionType);
	FormParameters.Insert("Incoming", Incoming);
	FormParameters.Insert("Viewed_SSLyf", Viewed_SSLyf);
	
	If ValueIsFilled(UserCode) Then
		FormParameters.Insert("UserCode", UserCode);
	EndIf;
	
	OpenForm("DataProcessor.InformationCenter.Form.InteractionOnSupportRequest", FormParameters,,
		New UUID);
	
EndProcedure

// OPens a form to send a message to the recipient.
//
// Parameters:
//	CreateSupportRequest - Boolean - Flag indicating whether to create a support ticket.
//	SupportRequestID - UUID
//	UserCode - String
//	MessageParameters - See MessageParameters
//
Procedure OpenFormForSendingMessageToSupportService(CreateSupportRequest, 
	SupportRequestID = Undefined, UserCode = Undefined, MessageParameters = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("CreateSupportRequest", CreateSupportRequest);
	If SupportRequestID <> Undefined Then 
		FormParameters.Insert("SupportRequestID", SupportRequestID);
	EndIf;
	
	ClosingNotification1 = Undefined;
	If MessageParameters <> Undefined Then
		FormParameters.Insert("Attachments", MessageParameters.Attachments);
		FormParameters.Insert("Subject", MessageParameters.MessageSubject1);
		FormParameters.Insert("Content", MessageParameters.Message);
		ClosingNotification1 = MessageParameters.CompletionHandler;
	EndIf;
		
	If ValueIsFilled(UserCode) Then
		FormParameters.Insert("UserCode", UserCode);
	EndIf;
	
	OpenForm("DataProcessor.InformationCenter.Form.SendingAMessageToTechnicalSupport",
		FormParameters,,,,,ClosingNotification1);
	
EndProcedure

// Message parameters.
// 
// Returns:
//  Structure - Message parameters:
// * MessageSubject1 - String
// * Message - String
// * Attachments - Array of Structure:
//   ** FileName - String
//   ** Data - String - Address in the temporary storage. 
// * CompletionHandler - NotifyDescription - A handler that handles message form closure.
//
Function MessageParameters() Export
	
	MessageParameters = New Structure;
	MessageParameters.Insert("MessageSubject1", "");
	MessageParameters.Insert("Message", "");
	MessageParameters.Insert("Attachments", New Array);
	MessageParameters.Insert("CompletionHandler");
	
	Return MessageParameters;
	
EndFunction

// Opens a form with the support ticket.
//
// Parameters:
//	SupportRequestID - UUID - Support ticket ID.
//
Procedure OpenSupportRequest(SupportRequestID, UserCode = Undefined) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("SupportRequestID", SupportRequestID);
	If ValueIsFilled(UserCode) Then
		FormParameters.Insert("UserCode", UserCode);
	EndIf;
	OpenForm("DataProcessor.InformationCenter.Form.InteractionsOnSupportRequest", FormParameters,, 
		New UUID);
	
EndProcedure

// Opens a form with a ticket list.
//
// Parameters:
//  UserCode	 - String - User code required for support ticket management.
//
Procedure OpenListOfWUSPRequests(UserCode) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("UserCode", UserCode);
	OpenForm("DataProcessor.InformationCenter.Form.TechnicalSupportRequests", FormParameters);
	
EndProcedure

#EndRegion

#Region Internal

// Opens a form containing a single news item.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	Id - UUID - News item ID.
//
Procedure ShowNews(Id) Export
EndProcedure

// Opens a form with the idea content.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	IdeaID - String - an idea UUID.
//
Procedure ShowIdea(Val IdeaID) Export
EndProcedure

Procedure PuttingFile(Notification, 
	Address = Undefined, 
	File = Undefined,
	Interactively = Undefined, 
	FormIdentifier = Undefined,
	NotificationBeforePlacement = Undefined) Export

	//@skip-warning ObsoleteMethod - Implementation feature.
	BeginPutFile(Notification, Address, File, Interactively, FormIdentifier, NotificationBeforePlacement);
	
EndProcedure

Procedure PlacingFiles(CallbackOnCompletion, Files, 
	Interactively = Undefined,
	FormIdentifier = Undefined,
	NotificationBeforePlacement = Undefined) Export
	
	//@skip-warning ObsoleteMethod - Implementation feature.
	BeginPuttingFiles(
		CallbackOnCompletion, Files, Interactively, FormIdentifier, NotificationBeforePlacement)

EndProcedure

// Get file from the storage.
// 
// Parameters:
//  Address - String - Address.
//  FileName - String - file name
//  Interactively - Boolean - Interactive receiving flag.
// 
// Returns:
//  Boolean, Undefined - Flag of receiving a file from the storage.
Function GetFileFromStorage(Address, FileName, Interactively = True) Export
	
	//@skip-warning ObsoleteMethod - Implementation feature.
	Return GetFile(Address, FileName, Interactively);
	
EndFunction

Procedure SaveUserCodeOnComputer(UserCode) Export
	
	#If WebClient Then
		Return;
	#Else
		
		SplitCode = InformationCenterClientServer.SplitUserCode(UserCode);
		TempFileName = GetTempFileName();
		
		// When accessing a Windows remote desktop, the temporary file directory might be a temporary subdirectory
		// created for the duration of the session. If this is the case, create the file in the user's general directory.
		SharedFolderPosition = StrFind(Upper(TempFileName), "\TEMP\", SearchDirection.FromEnd);
		If SharedFolderPosition <> 0 Then
			PositionOfPenultimateSeparator = SharedFolderPosition + StrLen("\TEMP");
			PositionOfLastSeparator = StrFind(TempFileName, "\", SearchDirection.FromEnd);
			If PositionOfLastSeparator > PositionOfPenultimateSeparator Then
				TempFileName = Left(TempFileName, PositionOfPenultimateSeparator - 1)
				+ Mid(TempFileName, PositionOfLastSeparator);
			EndIf;
		EndIf;
		
		TextDocument = New TextDocument;
		TextDocument.AddLine(SplitCode[1]);
		TextDocument.Write(TempFileName);
		File = New File(TempFileName);
		File.SetReadOnly(True);
		
		InformationCenterServerCall.SaveUserCode(ComputerName(), SplitCode[0], TempFileName);
		
	#EndIf
	
EndProcedure

// Opens unread interactions.
//
// Parameters:
//	SupportRequestID - UUID - Support ticket ID.
//	ListOfUnseenInteractions - ValueList - List of unread interactions.
//
Procedure OpenUnseenInteractions(SupportRequestID, ListOfUnseenInteractions, UserCode) Export 
	
	If ListOfUnseenInteractions.Count() = 1 Then 
		FirstInteraction = ListOfUnseenInteractions.Get(0).Value;
		OpenInteractionWithSupport(SupportRequestID, FirstInteraction.Id, 
			FirstInteraction.Type, FirstInteraction.Incoming, False, UserCode);
	Else
		Parameters = New Structure;
		Parameters.Insert("ListOfUnseenInteractions", ListOfUnseenInteractions);
		Parameters.Insert("SupportRequestID", SupportRequestID);
		
		If ValueIsFilled(UserCode) Then
			Parameters.Insert("UserCode", UserCode);
		EndIf;
		
		OpenForm("DataProcessor.InformationCenter.Form.UnreadInteractions", Parameters,,
			New UUID);
	EndIf;
	
EndProcedure

Procedure OpenLink(Href, Element, HTMLDocument = Undefined) Export
	
	SelectedLink = Undefined;
	
	If Href <> Undefined Then
		// If the event has a value in Href property, assume that the user will follow this link.
		SelectedLink = Href;
	Else
		Try
			// If an event item has a value in "Href" property and the "AREA" element, 
			// assume that the user will follow this link.
			If Upper(Element.tagName) = "AREA" Then
				SelectedLink = Element.Href;
			EndIf;
		Except
		EndTry;
	EndIf;
	
	If IsBlankString(SelectedLink) Then
		Return;
	EndIf;
	
	#If WebClient Then
		If Find(SelectedLink, "javascript:_1c") = 1 Then
			
			// For Firefox, uses the javascript:
			NavigationLinkPosition = Find(SelectedLink, "e1cib/");
			
			If NavigationLinkPosition <> 0 Then
				SelectedLink = 
				"v8doc:" 
				+ Mid(
				SelectedLink, 
				NavigationLinkPosition, 
				StrLen(SelectedLink) - NavigationLinkPosition - 2);
			Else
				Return;
			EndIf;
			
		EndIf;
		
		SeparatorPosition = Find(SelectedLink, "#");
		PositionOfInternalNavigationLink = Find(SelectedLink, "#e1cib/");
		
		If SeparatorPosition = 1  Then
			
			// For Safari, passes a relative link.
			Return;
			
		EndIf;
		
		If Find(SelectedLink, GetInfoBaseURL()) = 1 Then
			
			// For Google Chrome and Microsoft Internet Explorer, passes an absolute link.
			If SeparatorPosition <> 0 And PositionOfInternalNavigationLink = 0 Then
				
				Return;
				
			EndIf;
			
		EndIf;
		
	#Else
		If Find(SelectedLink, GetInfoBaseURL()) = 1 Then
			
			ElementID = Mid(SelectedLink, Find(SelectedLink, "#") + 1);
			ElementByID = HTMLDocument.getElementById(ElementID);
			
			If ElementByID <> Undefined Then
				ElementByID.scrollIntoView(True);
				Return;
			EndIf;
			
		EndIf;
	#EndIf
	
	LinkDiagram = DefineLinkScheme(SelectedLink);
	
	If LinkDiagram = "e1c://" Then
		
		GotoURL(SelectedLink);
	
	ElsIf (LinkDiagram = "http://" And Find(SelectedLink, "e1cib") > 0)
		Or (LinkDiagram = "https://" And Find(SelectedLink, "e1cib") > 0) Then
		
		If Not FollowInternalNavigationLink(SelectedLink) Then
			GotoURL(SelectedLink);
		EndIf;
		
	ElsIf LinkDiagram = "http://"
		Or LinkDiagram = "https://"
		Or LinkDiagram = "ftp://"
		Or LinkDiagram = "file://" Then
		
		#If WebClient Then
			GotoURL(SelectedLink);
		#Else
			RunApp(SelectedLink);
		#EndIf
		
	Else
		
		GotoURL(SelectedLink);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private
	
Function ReadUserCodeFromComputerForUSP()
	
	#If WebClient Then
		
		Return "";
		
	#Else
		
		ComputerName = ComputerName();
		ComputerCode = InformationCenterServerCall.ReadUserCode(ComputerName);
		
		If Not ValueIsFilled(ComputerCode) Then
			Return "";
		EndIf;
		
		TextDocument = New TextDocument;
		Try
			TextDocument.Read(ComputerCode.TemporaryFileOfPieceOfCode);
			SplitCode = New Array;
			SplitCode.Add(ComputerCode.PartOfVIBCode);
			SplitCode.Add(TextDocument.GetText());
			UserCode = InformationCenterClientServer.CollectUserCode(SplitCode);
			Return UserCode;
		Except // File is deleted or corrupted.
			InformationCenterServerCall.WriteWarning(
			NStr("ru = 'Не найдены сохраненные учетные данные пользователя службы поддержки';
				|en = 'Saved credentials of the technical support user are not found';"));
			Return "";
		EndTry;
		
	#EndIf
	
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
Function CheckUserCodeForUSP(UserCode, Email)
	
	Return InformationCenterServerCall.CheckUserCode(UserCode, Email);
	
EndFunction

// Opens a form where you can enter a user code to manage support tickets.
//
Procedure OpenUserCodeEntryForm()
	
	OpenForm("DataProcessor.InformationCenter.Form.UserCodeEntryForm");
	
EndProcedure

// Opens the form that connects the local infobase to the support service.
//
Procedure OpenCuspActivationForm(Val DatabaseEnabled = Undefined) Export
	
	If DatabaseEnabled = Undefined Then
		DatabaseEnabled = DatabaseIsConnectedByCusp();
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("DatabaseEnabled", DatabaseEnabled);
	OpenForm("DataProcessor.InformationCenter.Form.SupportConnectionForm", FormParameters);
	
EndProcedure

// User's email for support tickets.
// 
// Returns:
//  String - e-mail
//
Function UserEmail()
	
	Return InformationCenterServerCall.UserEmail();
	
EndFunction

Function FollowInternalNavigationLink(URL)
	
	PositionOfInternalNavigationLink = Find(URL, "#e1cib/");
	If PositionOfInternalNavigationLink = 0 Then
		Return False;
	EndIf;
	
	InternalNavigationLink = Mid(URL, PositionOfInternalNavigationLink + 1);
	Try
		GotoURL(InternalNavigationLink);
	Except
		// The infobase might be missing an internal URL.
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

Function DefineLinkScheme(Href)
	
	Schemes = New Array;
	Schemes.Add("v8doc:");
	Schemes.Add("http://");
	Schemes.Add("https://");
	Schemes.Add("ftp://");
	Schemes.Add("e1c://");
	Schemes.Add("file://");
	Schemes.Add("mailto:");
	
	For Each Schema In Schemes Do
		If StrStartsWith(Href, Schema) Then
			Return Schema;
		EndIf;
	EndDo;
	
	Return "";
	
EndFunction

#EndRegion