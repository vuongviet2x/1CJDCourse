///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.AdditionalReportsAndDataProcessors

// Returns info about an external data processor.
//
// Returns:
//   See AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo
//
Function ExternalDataProcessorInfo() Export
	RegistrationParameters = AdditionalReportsAndDataProcessors.ExternalDataProcessorInfo("2.2.3.1");
	RegistrationParameters.Information = NStr("ru = 'Загрузка юридических лиц (с контактной информацией) в справочник ""Демо: Контрагенты"".';
											|en = 'Importing legal entities (with contact information) to the ""Demo: Counterparties"" catalog.';");
	RegistrationParameters.Kind = AdditionalReportsAndDataProcessorsClientServer.DataProcessorKindAdditionalDataProcessor();
	RegistrationParameters.Version = "3.0.2.2";
	
	Command = RegistrationParameters.Commands.Add();
	Command.Presentation = NStr("ru = 'Демо: Контрагенты (Юридические лица с контактной информацией)';
								|en = 'Demo: Counterparties (Legal entities with contact information)';");
	Command.Use = AdditionalReportsAndDataProcessorsClientServer.CommandTypeDataImportFromFile();
	Command.Modifier   = Metadata.Catalogs._DemoCounterparties.FullName();
	Command.Id = "CounterpartyLegalEntities";
	
	Return RegistrationParameters;
EndFunction

// End StandardSubsystems.AdditionalReportsAndDataProcessors

#EndRegion

// Determines parameters of data import from file.
//
// Parameters:
//   CommandID - String - Command name given in function ExternalDataProcessorInfo().
//   ImportParameters - Structure - Data import settings:
//       * DataStructureTemplateName - String - Name of the data import template.
//           Default template is ImportingFromFile.
//       * RequiredTemplateColumns - Array - List of required column names.
//
Procedure DefineParametersForLoadingDataFromFile(CommandID, ImportParameters) Export
	If CommandID = "CounterpartyLegalEntities" Then
		ImportParameters.DataStructureTemplateName = "ImportFromCounterpartiesFile";
	EndIf;
EndProcedure

// Maps data being imported and infobase data.
// List and type of table columns repeat the "ImportingFromFile" template.
//
// Parameters:
//  CommandID - String - Command name given in function ExternalDataProcessorInfo().
//  DataToImport - See ImportDataFromFile.MappingTable
//
Procedure MatchUploadedDataFromFile(CommandID, DataToImport) Export
	
	If CommandID = "CounterpartyLegalEntities" Then
		MapCounterparties(DataToImport);
	EndIf;
	
EndProcedure

// Imports mapped data into the infobase.
//
// Parameters:
//  CommandID - String - Command name given in function ExternalDataProcessorInfo(). 
//  DataToImport - See ImportDataFromFile.DescriptionOfTheUploadedDataForReferenceBooks
//  ImportParameters - See ImportDataFromFile.DataLoadingSettings
//  Cancel - Boolean    - Abort import. For example, if some data is invalid.
//
Procedure LoadFromFile(CommandID, DataToImport, ImportParameters, Cancel) Export
	If CommandID = "CounterpartyLegalEntities" Then
		WriteCounterpartiesFromFile(DataToImport, ImportParameters, Cancel);
	EndIf;
EndProcedure

#EndRegion

#Region Private

// Parameters:
//  DataToImport - ValueTable:
//    * MappedObject - CatalogRef
//    * RowMappingResult - String
//    * ErrorDescription - String
//    * Id - Number
//    * Description - String
//
Procedure MapCounterparties(DataToImport)
	
	For Each String In DataToImport Do
		String.MappingObject = Catalogs._DemoCounterparties.FindByAttribute("TIN", TrimAll(String.TIN));
		If String.MappingObject = Undefined Then
			String.MappingObject = Catalogs._DemoCounterparties.FindByDescription(String.Description, True);
		EndIf;
	EndDo;
	
EndProcedure

// Parameters:
//  DataToImport - ValueTable:
//    * MappedObject - CatalogRef
//    * RowMappingResult - String
//    * ErrorDescription - String
//    * Id - Number
//    * Description - String
//  ImportParameters - Structure
//  Cancel - Boolean
//
Procedure WriteCounterpartiesFromFile(DataToImport, ImportParameters, Cancel)
	
	For Each TableRow In DataToImport Do
		If ValueIsFilled(TableRow.MappingObject) Then
			If Not ImportParameters.UpdateExistingItems Then
				TableRow.RowMappingResult = "Skipped";
				Continue;
			EndIf;
		Else
			If Not ImportParameters.CreateNewItems Then
				TableRow.RowMappingResult = "Skipped";
				Continue;
			EndIf;
		EndIf;
		
		BeginTransaction();
		Try
			RecordCounterparty(TableRow);
			CommitTransaction();
		Except
			RollbackTransaction();
			TableRow.RowMappingResult = "Skipped";
			TableRow.ErrorDescription = ErrorProcessing.DetailErrorDescription(ErrorInfo());
		EndTry;
	EndDo;
	
EndProcedure

Procedure RecordCounterparty(TableRow)
	If Not ValueIsFilled(TableRow.MappingObject) Then
		CatalogItem = Catalogs._DemoCounterparties.CreateItem();
		TableRow.MappingObject = CatalogItem;
		TableRow.RowMappingResult = "Created";
	Else
		Block = New DataLock;
		LockItem = Block.Add("Catalog._DemoCounterparties");
		LockItem.SetValue("Ref", TableRow.MappingObject);
		ErrorInfo = Undefined;
		Try
			Block.Lock();
		Except
			ErrorInfo = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		EndTry;
		If ErrorInfo <> Undefined Then
			TableRow.RowMappingResult = "Skipped";
			TableRow.ErrorDescription =
				NStr("ru = 'Не удалось заблокировать объект.
					|Возможно он открыт в другом окне.
					|
					|Техническая информация:';
					|en = 'Failed to lock the object.
					|Probably it is open in other window.
					|
					|Technical information:';")
				+ Chars.LF
				+ ErrorProcessing.BriefErrorDescription(ErrorInfo);
			Return;
		EndIf;
		CatalogItem = TableRow.MappingObject.GetObject();
		If CatalogItem = Undefined Then
			TableRow.RowMappingResult = "Skipped";
			TableRow.ErrorDescription = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Объект ""%1"" не существует.';
					|en = 'The %1 object does not exist.';"),
				TableRow.Description);
			Return;
		EndIf;
		TableRow.RowMappingResult = "Updated";
	EndIf;
	
	CatalogItem.Description = TableRow.Description;
	CatalogItem.DescriptionFull = TableRow.Description;
	CatalogItem.CounterpartyKind = Enums._DemoBusinessEntityIndividual.BusinessEntity;
	CatalogItem.TIN = TableRow.TIN;
	CatalogItem.CRTR = TableRow.CRTR;
	
	ContactInformation = CatalogItem.ContactInformation.Add();
	ContactInformation.EMAddress = TableRow.Mail;
	ContactInformation.Presentation = TableRow.Mail;
	ContactInformation.Kind = ContactsManager.ContactInformationKindByName("_DemoCounterpartyEmail");
	ContactInformation.Type = Enums.ContactInformationTypes.Email;
	
	ContactInformation = CatalogItem.ContactInformation.Add();
	ContactInformation.Presentation = TableRow.Address;
	ContactInformation.Type = Enums.ContactInformationTypes.Address;
	ContactInformation.Kind = ContactsManager.ContactInformationKindByName("_DemoCounterpartyAddress");
	
	If Not CatalogItem.CheckFilling() Then
		TableRow.RowMappingResult = "Skipped";
		UserMessages = GetUserMessages(True);
		If UserMessages.Count() > 0 Then
			
			ErrorDescription = New Array;
			For Each UserMessage In UserMessages Do
				ErrorDescription.Add(UserMessage.Text);
			EndDo;
			TableRow.ErrorDescription = StrConcat(ErrorDescription, Chars.LF + Chars.LF);
			
		EndIf;
		Return;
	EndIf;
	
	CatalogItem.Write();
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf