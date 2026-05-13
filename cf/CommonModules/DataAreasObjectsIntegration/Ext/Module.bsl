// @strict-types

#Region Public

// See JobsQueueOverridable.OnDefineHandlerAliases
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
// 	NamesAndAliasesMap - See JobsQueueOverridable.OnDefineHandlerAliases.NamesAndAliasesMap
//
Procedure OnDefineHandlerAliases(NamesAndAliasesMap) Export
EndProcedure

// See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport
//
// Parameters:
//	Types - See ExportImportDataOverridable.OnFillTypesExcludedFromExportImport.Types
//
Procedure OnFillTypesExcludedFromExportImport(Types) Export
	
	Types.Add(Metadata.InformationRegisters.ObjectsToSend);
	Types.Add(Metadata.InformationRegisters.AccountingSystemsSettings);
	Types.Add(Metadata.InformationRegisters.ObjectsIntegrationStates);
	
EndProcedure

// Adds an object to be sent to the external accounting system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - accounting system.
//  ObjectID - String - Object ID. Must comply with the OS naming convention. 
//						 The length is 50 characters.  
//  Handler - String - Object handler ID. The length is 50 characters.
//  ObjectData - BinaryData - object data to send. If it is not specified, data will be requested before sending.
//
Procedure AddPlaceToSend(AccountingSystem, ObjectID,
		Handler, ObjectData = Undefined) Export
EndProcedure

// Deletes an object from objects to be sent to the accounting system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - accounting system.
//  ObjectID - String - Object ID. The length is 50 characters.
//  Handler - String - Object handler ID. The length is 50 characters.
//
Procedure DeleteItemToSend(AccountingSystem,
		ObjectID = Undefined, Handler = Undefined) Export
EndProcedure

// Notifies an external accounting system according to notification settings.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems, CatalogRef - accounting system.
//  ObjectID - String - Object ID. The length is 50 characters.
//  RaiseException1 - Boolean - indicates if an exception was raised upon unsuccessful notification sending.
//
Procedure NotifyObjectChanged(AccountingSystem, ObjectID,
		RaiseException1 = False) Export
EndProcedure

// Returns settings of an external accounting system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems, CatalogRef - accounting system.
//  SettingsKeys - String, Array of String - setting keys, by which you need to return values.
//
// Returns:
//  Structure - Accounting system settings:
//	* NotifyAboutChanges - Boolean - indicates that notifications are used when creating or editing application data.
//	* ServiceAddress - String - an address of the service for getting notifications about changes.
//	* AuthenticationMethod - EnumRef.AuthenticationMethods - a method of authentication in the service for getting notifications.
//	* Login - String - an authentication username in the service for getting notifications (used upon basic authentication).
//	* Password - String - an authentication password in the service for getting notifications (used upon basic authentication).
//	* UseCertificate - Boolean - indicates the certificate use when establishing connection with the service for getting notifications.
//	* CertificateName - String - a certificate file name.
//	* CertificatePassword - String -  a certificate password. It is used if the UseCertificate property is specified.
//	* CertificateData - BinaryData - a certificate binary data in base64. It is used if the UseCertificate property is specified.
//	* SignData - Boolean - indicates the use of using data signature when sending it to the service of getting notifications.
//	* SignatureKey - String - a secret word to sign the data to be sent. Data is signed using the HMACSHA256 algorithm.
//
Function Settings(AccountingSystem, Val SettingsKeys = Undefined) Export
EndFunction

// Returns a template for placing command execution results
// @skip-warning EmptyMethod - Implementation feature.
// 
// Returns:
//  ValueTable - Template for executing the command to return results:
//	* ObjectID - String - object ID.
//	* Handler - String - a handler ID.
//
Function NewCommandExecutionResults() Export
EndFunction

#Region JobsQueueHandlers

// Executes the command received from the accounting system.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//	AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - accounting system.
//	ParameterId_ - String - ID of the file that contains command runtime parameters. The length is 36 characters.
//
Procedure ExecuteCommand(AccountingSystem, ParameterId_) Export
EndProcedure

// Generates a data package to be received by the accounting system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - an accounting system
//				   by which data is prepared.
//
Procedure PrepareData(AccountingSystem) Export
EndProcedure

// Processes the data package received from the accounting system.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//	AccountingSystem - DefinedType.DataAreasIntegrationAccountingSystems - an accounting system
//				   by which data is prepared.
//  FileID - String - ID of the file to be processed. The length is 36 characters.
//
Procedure ProcessData__(AccountingSystem, FileID) Export
EndProcedure

#EndRegion

#EndRegion
