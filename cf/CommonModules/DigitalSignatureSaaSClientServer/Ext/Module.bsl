////////////////////////////////////////////////////////////////////////////////
// "Digital signature in SaaS" subsystem.
//  
////////////////////////////////////////////////////////////////////////////////
//


#Region Public

// Parameters:
// 	Phone - String
// 	
// Returns:
// 	String
//
Function GetPhonePresentation(Phone) Export
		
	Presentation = "";
	TextToProcess = TrimAll(Phone); 
	NumbersOnly = "";
	For IndexOf = 1 To StrLen(TextToProcess) Do
		CurrentChar = Mid(TextToProcess, IndexOf, 1);
		If StrFind("0123456789", CurrentChar) Then
			NumbersOnly = NumbersOnly + CurrentChar;
		EndIf;
	EndDo;
	If StrLen(NumbersOnly) = 11 Then
		NumbersOnly = Mid(NumbersOnly, 2);
	EndIf;

	If StrLen(NumbersOnly) = 10 Then
		Presentation = StrTemplate(
			"+7 %1 %2-%3-%4", 
			Mid(NumbersOnly, 1, 3), 
			Mid(NumbersOnly, 4, 3),
			Mid(NumbersOnly, 7, 2),
			Mid(NumbersOnly, 9));		
	EndIf;
	
	Return Presentation;	

EndFunction

// Returns:
// 	String
//
Function GetDescriptionOfWaysToConfirmCryptoOperations() Export
	
	Result = NStr(
	"ru = 'Признак подтверждения операций с ключом пользователя, хранящимся в приложении.
	|Подтверждение предполагает ввод временного пароля, высылаемого в SMS или на эл. почту.';
	|en = 'Indicates whether the user must confirm operations with the key stored in the app.
	|To confirm an operation, the app will send an OTP in a text or email message.';");
	
	Return Result;
	
EndFunction

#Region ObsoleteProceduresAndFunctions

// Deprecated.
// See DigitalSignatureSaaSClient.UsageAllowed.
// See DigitalSignatureSaaS.UsageAllowed.
//
// Returns:
// 	Boolean
//
Function UsageAllowed() Export
	
	#If Client Then
		Return StandardSubsystemsClient.ClientRunParameters()["UsingElectronicSignatureInServiceModelIsPossible"];
	#Else
		Return DigitalSignatureSaaS.UsageAllowed();		
	#EndIf
	
EndFunction

#EndRegion

#EndRegion	