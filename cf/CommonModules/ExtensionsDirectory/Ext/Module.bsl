
#Region Public

// Returns a flag indicating that the extension directory is used.
//
// Returns:
//  Boolean
Function Used() Export
	
	Return False;
	
EndFunction

// Returns the name of the link to go to the extension store.
//
// Returns:
//  String
Function NameOfExtensionCatalogLink() Export
	
	Return NStr("ru = 'Каталог расширений';
				|en = 'Extension Store';");
	
EndFunction

// Returns the actual extension status.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  PublicId - String - Public ID of an extension from the Service Manager.
// 
// Returns:
//  EnumRef.ExtensionStates
Function ExtensionState(PublicId) Export
EndFunction


// User rating info.
// 
// Parameters:
//  PublicId - String - Public ID of an extension from the Service Manager.
// 
// Returns:
//  Structure - User rating info.:
// * RatingIsSet - Boolean - Indicates that the user rated.
// * NameOfExtension - String - Extension name.
// * Evaluation - Number - Numeric rating presentation.
// * CreationDate - Date - Date of creating the first rating.
// * LastChangeDate - Date - Last rating change date.
// * Version - String - Version of the extension that was installed when the rating was last edited.
// * DeveloperResponse - String - Text of the developer's response to the rating.
// * DateOfDeveloperResponse - Date - Date of the developer's response to the rating.
// * ReceivingDataError - Structure - If an error occurred while receiving the data, this property exists.:
// ** ErrorText - String - Error report text.
Function UserRatingInformation(PublicId) Export
	
	DataOfError = New Structure();
	DataOfError.Insert("ErrorText", NStr("ru = 'Расширение fresh не подключено.';
												|en = 'The ""fresh"" extension is not attached.';"));
	
	ResponseData = New Structure();
	ResponseData.Insert("RatingIsSet", False);
	ResponseData.Insert("NameOfExtension", "");
	ResponseData.Insert("Evaluation", 0);
	ResponseData.Insert("CreationDate", Date(1, 1, 1));
	ResponseData.Insert("LastChangeDate", Date(1, 1, 1));
	ResponseData.Insert("Version", "");
	ResponseData.Insert("DeveloperResponse", "");
	ResponseData.Insert("DateOfDeveloperResponse", Date(1, 1, 1));
	ResponseData.Insert("ReceivingDataError", DataOfError);
	
	Return ResponseData;
	
EndFunction

#EndRegion

#Region Internal

// Parameters:
//	InstalledExtensions_ - Array of Structure - Structure with the following properties:
//		* Id - UUID - Extension ID in the service.
//		* Presentation - String - Extension presentation. 
//		* Installation - UUID - New installation ID.
//		
// Returns:
// 	Boolean - True if it is successful, otherwise, False.
//
Function RestoreExtensionsToNewArea(Val InstalledExtensions_, 
	Val ServiceUserID = Undefined) Export
	
	Return False;
	
EndFunction

// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  DataAreaCode - Number - 
//  
// Returns:
//	Structure - Structure with the following properties:
//	 * DataAreaKey - String - 
//	 * RecoveryExtensions - See RestoreExtensionsToNewArea.InstalledExtensions_
//
Function GetExtensionsForNewArea(Val DataAreaCode) Export
EndFunction

// Returns: 
//  Array of Type - Reference types added by extensions.
Function ReferenceTypesAddedByExtensions() Export
	
	ReferenceTypes = New Array;
	TypesOfMetadataObjectsOfReferenceType = TypesOfMetadataObjectsOfReferenceType();
	
	IsSeparatedSession = SaaSOperations.SessionSeparatorUsage();
	
	SetPrivilegedMode(True);
	SessionExtensions = ConfigurationExtensions.Get(,
		ConfigurationExtensionsSource.SessionApplied);
	
	ScopeSeparation = ConfigurationExtensionScope.DataSeparation;	
	For Each Extension In SessionExtensions Do
		
		If IsSeparatedSession And
			Extension.Scope <> ScopeSeparation Then
			Continue;
		EndIf;
		
		If Not Extension.ModifiesDataStructure() Then
			Continue;
		EndIf;
		
		OMDExtensions = New ConfigurationMetadataObject(Extension.GetData());
		
		For Each OMDType In TypesOfMetadataObjectsOfReferenceType Do
			AddTypes_(ReferenceTypes, OMDType, OMDExtensions);
		EndDo;
		
	EndDo;
	
	Return ReferenceTypes;
	
EndFunction

Procedure RecordDataOfRecoverableAreaExtensions(RecoveryExtensions) Export 
	
	Common.WriteDataToSecureStorage(
		"ExtensionData_", 
		RecoveryExtensions, 
		"RecoveryExtensions");
	
EndProcedure

Procedure ReadDataOfRecoverableAreaExtensions(ExtensionData_) Export 

	If TypeOf(ExtensionData_) <> Type("Structure") Then
		Return;
	EndIf;
	
	If ExtensionData_.Property("RecoveryExtensions") Then
		Return;
	EndIf;	
	
	StorageData = ReadDataOfRecoverableExtensions();
		
	If StorageData <> Undefined Then
		ExtensionData_.Insert("RecoveryExtensions", StorageData);	
	EndIf;
	
EndProcedure

Function ReadDataOfRecoverableExtensions() Export
	
	Return Common.ReadDataFromSecureStorage(
		"ExtensionData_",
		"RecoveryExtensions");
	
EndFunction

#EndRegion

#Region Private

Procedure AddTypes_(ReferenceTypes, OMDType, OMDExtensions)
	
	ObjectBelonging = Metadata.ObjectProperties.ObjectBelonging.Native; 
	
	For Each OMD In OMDExtensions[OMDType] Do
		
		If OMD.ObjectBelonging <> ObjectBelonging Then
			Continue;
		EndIf;
		
		ReferenceForTypeDefinition = PredefinedValue(OMD.FullName() 
			+ ".EmptyRef");
		ReferenceTypes.Add(TypeOf(ReferenceForTypeDefinition));
		
	EndDo;
	
EndProcedure

Function TypesOfMetadataObjectsOfReferenceType()
	
	TypesOfMetadataObjectsOfReferenceType = New Array;
	TypesOfMetadataObjectsOfReferenceType.Add("Catalogs");
	TypesOfMetadataObjectsOfReferenceType.Add("Documents");
	TypesOfMetadataObjectsOfReferenceType.Add("BusinessProcesses");
	TypesOfMetadataObjectsOfReferenceType.Add("Tasks");
	TypesOfMetadataObjectsOfReferenceType.Add("ChartsOfAccounts");
	TypesOfMetadataObjectsOfReferenceType.Add("ExchangePlans");
	TypesOfMetadataObjectsOfReferenceType.Add("ChartsOfCharacteristicTypes");
	TypesOfMetadataObjectsOfReferenceType.Add("ChartsOfCalculationTypes");
	
	Return TypesOfMetadataObjectsOfReferenceType;
	
EndFunction

#EndRegion