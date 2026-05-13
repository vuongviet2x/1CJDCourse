#Region Internal

// Information about the connection between the local infobase and the support.
// 
// Returns:
//  Structure - Contains the following fields:
//  	* AddressOfExternalAnonymousInterface - String - ext_sd web support service address.
//  	* AddressOfAnonymousIntegrationServiceWithUSPInformationCenter - String - Support web service address.
//  	* ConfirmedCodeForIntegrationOfSUSPS - Boolean - If True, the infobase is connected to 1C:Support Management.
//  	* SubscriberSEmailAddressForSuspIntegration - String - Email of the infobase user who addresses the support. 
//			
//  	* WUSPRegistrationCode - String - Code by which the infobase is registered in the support service.
//
Function DataForSuspIntegrationSettings() Export
	
	Return InformationCenterServer.DataForSuspIntegrationSettings();
	
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
	
	Return InformationCenterServer.CheckUserCode(UserCode, Email);
	
EndFunction


// User's email to reply to their tickets.
// 
// Returns:
//  String - e-mail
//
Function UserEmail() Export
	
	Return UsersInternal.UserDetails(Users.AuthorizedUser()).Email;
	
EndFunction

Procedure SaveUserCode(Val ComputerName = Undefined, 
	Val PartOfIBCode = "", Val TemporaryFileOfPieceOfCode) Export
	
	If ComputerName = Undefined Then // Web client
		Return;
	EndIf;
	
	ComputerNameHash = CRC32HashSum(ComputerName);
	
	ComputerCode = New Structure;
	ComputerCode.Insert("PartOfVIBCode", PartOfIBCode);
	ComputerCode.Insert("TemporaryFileOfPieceOfCode", TemporaryFileOfPieceOfCode);
	
	CodesOnComputers = New Map;
	CodesOnComputers.Insert(ComputerNameHash, ComputerCode);
	
	SetPrivilegedMode(True);
	
	Common.WriteDataToSecureStorage(
		Users.CurrentUser(), CodesOnComputers, "AuthorizationDataInSupportService");
	
EndProcedure

// Read user code.
// 
// Parameters:
//  ComputerName - String - Computer name.
// 
// Returns:
//  String - User code.
Function ReadUserCode(Val ComputerName) Export
	
	SetPrivilegedMode(True);
	
	CodesOnComputers = Common.ReadDataFromSecureStorage(
		Users.CurrentUser(), "AuthorizationDataInSupportService");
		
	If CodesOnComputers = Undefined Then
		Return "";
	EndIf;
		
	ComputerNameHash = CRC32HashSum(ComputerName);
	
	ComputerCode = CodesOnComputers.Get(ComputerNameHash);
	
	If ComputerCode = Undefined Then
		Return "";
	EndIf;
	
	If Type(ComputerCode) <> Type("Structure") Then
		Return "";
	EndIf;
	
	If Not ComputerCode.Property("PartOfVIBCode") 
		Or Not ValueIsFilled(ComputerCode.PartOfVIBCode) Then
		Return "";
	EndIf;
	
	If Not ComputerCode.Property("TemporaryFileOfPieceOfCode") 
		Or Not ValueIsFilled(ComputerCode.TemporaryFileOfPieceOfCode) Then
		Return "";
	EndIf;
	
	Return ComputerCode;
	
EndFunction

// Writes the warning to the Event log.
//
Procedure WriteWarning(WarningText) Export
	
	WriteLogEvent(
		InformationCenterServer.GetEventNameForLog(), 
		EventLogLevel.Warning,,,
		WarningText);
		
EndProcedure

#EndRegion

#Region Private

// Returns the CRC32 checksum.
//
// Parameters:
//   Data - String, BinaryData - Data required for calculation.
//
// Returns:
//   Number - CRC32 checksum.
//
Function CRC32HashSum(Data)

	DataHashing = New DataHashing(HashFunction.CRC32);
	DataHashing.Append(Data);
	
	Return DataHashing.HashSum;

EndFunction

#EndRegion