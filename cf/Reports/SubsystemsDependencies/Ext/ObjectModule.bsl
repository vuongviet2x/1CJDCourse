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

#Region Variables

Var PropertiesKinds;
Var LinksBetweenSubsystemsObjects; // See ExecuteTableCreation
Var SubsystemsDependencies;
Var PicturesCollection;
Var SearchByFullName;
Var ExceptionsTable;
Var ObjectsToCheckStandaloneStatus;
Var EnglishAndNationalNamesMap;

#EndRegion

#Region Public

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.ReportsOptions

// Specify the report form settings.
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
EndProcedure

// End StandardSubsystems.ReportsOptions

#EndRegion

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	If Not Common.FileInfobase() Then
		Raise NStr("ru = 'Отчет предназначен для работы в файловом режиме работы.';
								|en = 'The report is intended to run in file mode only.';");
	EndIf;
	
	ReportOnDependencies();
	
	// Output dependencies into the report.
	StandardProcessing = False;
	DCSettings = SettingsComposer.GetSettings();
	ExternalDataSets = New Structure("LinksBetweenSubsystemsObjects", LinksBetweenSubsystemsObjects);
	
	DCTemplateComposer = New DataCompositionTemplateComposer;
	DCTemplate = DCTemplateComposer.Execute(DataCompositionSchema, DCSettings);
	
	DCProcessor = New DataCompositionProcessor;
	DCProcessor.Initialize(DCTemplate, ExternalDataSets);
	
	DCResultOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	DCResultOutputProcessor.SetDocument(ResultDocument);
	DCResultOutputProcessor.Output(DCProcessor);
	
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", LinksBetweenSubsystemsObjects.Count() = 0);
EndProcedure

#EndRegion

#Region Private

// For internal use only.
//
// Returns:
//   ValueTable
//
Function ReportOnDependencies(PassedModulesExportDirectory = "") Export
	
	ClearDumpDirectory = False;
	ModulesExportDirectory = PassedModulesExportDirectory;
	EnglishAndNationalNamesMap = EnglishAndNationalNamesMap();
	// Preliminary operations.
	ExecutePreparatoryActions();
	If PassedModulesExportDirectory = "" Then
		UploadConfigurationToXML();
		ClearDumpDirectory = True;
	EndIf;
	FillPicturesCollection();
	ObjectBelongingToSubsystem = ObjectsAndSubsystemsMap1();
	MetadataObjectsPropertiesToCheck = MetadataObjectsPropertiesToCheck();
	
	// Search for calls in configuration modules.
	SearchForCallsInFormDynamicListsAndModules(ObjectBelongingToSubsystem);
	
	// Search for calls in configuration metadata.
	
	SearchConfigurationMetadataForCalls(MetadataObjectsPropertiesToCheck, ObjectBelongingToSubsystem);
	LinksBetweenSubsystemsObjects.Sort("CallingSubsystem, SubsystemToCall");
	
	ApplyExceptionsList();
	
	If ClearDumpDirectory Then
		ClearDirectoryForExport();
	EndIf;
	
	Return LinksBetweenSubsystemsObjects;
	
EndFunction

// Preliminary operations.

Procedure ExecutePreparatoryActions()
	
	If ModulesExportDirectory = "" Then
		FillStartupParameters();
	EndIf;
	FillObjectsToCheckStandaloneStatus();
	ExecuteTableCreation();
	SubsystemsDependencies = DataProcessors.FirstSSLDeployment.Create().SubsystemsDependencies();
	FillExceptions();
	
EndProcedure

Function ObjectsAndSubsystemsMap1()
	
	ObjectBelongingToSubsystem = New ValueTable;
	ObjectBelongingToSubsystem.Columns.Add("FullMetadataObjectName2");
	ObjectBelongingToSubsystem.Columns.Add("MDOName");
	ObjectBelongingToSubsystem.Columns.Add("Subsystem");
	ObjectBelongingToSubsystem.Columns.Add("StringForCallFromCode");
	ObjectBelongingToSubsystem.Columns.Add("CanCallByFullName");
	ObjectBelongingToSubsystem.Columns.Add("MetadataCallString");
	ObjectBelongingToSubsystem.Columns.Add("AlternativeMetadataCallString");
	ObjectBelongingToSubsystem.Columns.Add("SearchByType");
	
	For Each StandardSubsystem In Metadata.Subsystems.StandardSubsystems.Subsystems Do
		
		If StandardSubsystem.Name = "SaaSOperations" Then
			// Loop through all SaaS subsystems.
			For Each SaaSSubsystem In StandardSubsystem.Subsystems Do
				SubsystemComposition = SaaSSubsystem.Content;
				For Each MetadataObject In SubsystemComposition Do
					FullMetadataObjectName2 = MetadataObject.FullName();
					Subsystem   = StandardSubsystem.Name + "." + SaaSSubsystem.Name;
					FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem);
				EndDo;
			EndDo;
			
			Continue;
		EndIf;
		
		If StandardSubsystem.Name = "NationalLanguageSupport" Then
			// Loop through all multilanguage subsystem.
			For Each MultilingualSubsystem In StandardSubsystem.Subsystems Do
				SubsystemComposition = MultilingualSubsystem.Content;
				For Each MetadataObject In SubsystemComposition Do
					FullMetadataObjectName2 = MetadataObject.FullName();
					Subsystem   = StandardSubsystem.Name + "." + MultilingualSubsystem.Name;
					FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem);
				EndDo;
			EndDo;
			
			Continue;
		EndIf;
				
		SubsystemComposition = StandardSubsystem.Content;
		For Each MetadataObject In SubsystemComposition Do
			FullMetadataObjectName2 = MetadataObject.FullName();
			Subsystem   = StandardSubsystem.Name;
			FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem);
		EndDo;
		
	EndDo;
	
	FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, "Report.SSLImplementationCheck", "DeveloperTools");
	FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, "Subsystem.Administration", "Administration");
	
	// Development tools.
	For Each StandardSubsystem In Metadata.Subsystems._DemoDeveloperTools.Subsystems Do
		SubsystemComposition = StandardSubsystem.Content;
		For Each MetadataObject In SubsystemComposition Do
			FullMetadataObjectName2 = MetadataObject.FullName();
			If StrFind(FullMetadataObjectName2, "DataProcessor") = 0 Then
				Continue;
			EndIf;
			Subsystem   = StandardSubsystem.Name;
			If Subsystem = "MigrationToNewVersions" Then
				Continue;
			EndIf;
			FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem);
		EndDo;
	EndDo;
	
	// Cloud Technology.
	For Each SaaSTechnologiesSubsystem In Metadata.Subsystems.CloudTechnology.Subsystems Do
		
		RootSubsystem = "CloudTechnology";
		If SaaSTechnologiesSubsystem.Subsystems.Count() > 0 Then
			For Each ChildSubsystem In SaaSTechnologiesSubsystem.Subsystems Do
				SubsystemComposition = ChildSubsystem.Content;
				For Each MetadataObject In SubsystemComposition Do
					FullMetadataObjectName2 = MetadataObject.FullName();
					Subsystem = RootSubsystem + "." + SaaSTechnologiesSubsystem.Name + "." + ChildSubsystem.Name;
					FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem);
				EndDo;
			EndDo;
			
			Continue;
		EndIf;
		
		SubsystemComposition = SaaSTechnologiesSubsystem.Content;
		For Each MetadataObject In SubsystemComposition Do
			FullMetadataObjectName2 = MetadataObject.FullName();
			Subsystem = RootSubsystem + "." + SaaSTechnologiesSubsystem.Name;
			FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem);
		EndDo;
	EndDo;
	
	// Online Support Library.
	For Each OSLSubsystem In Metadata.Subsystems.OnlineUserSupport.Subsystems Do
		
		RootSubsystem = "OnlineUserSupport";
		If OSLSubsystem.Subsystems.Count() > 0 Then
			For Each ChildSubsystem In OSLSubsystem.Subsystems Do
				SubsystemComposition = ChildSubsystem.Content;
				For Each MetadataObject In SubsystemComposition Do
					FullMetadataObjectName2 = MetadataObject.FullName();
					Subsystem = RootSubsystem + "." + OSLSubsystem.Name + "." + ChildSubsystem.Name;
					FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem);
				EndDo;
			EndDo;
			
			Continue;
		EndIf;
		
		SubsystemComposition = OSLSubsystem.Content;
		For Each MetadataObject In SubsystemComposition Do
			FullMetadataObjectName2 = MetadataObject.FullName();
			Subsystem = RootSubsystem + "." + OSLSubsystem.Name;
			FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem);
		EndDo;
	EndDo;
	
	ObjectBelongingToSubsystem.Sort("FullMetadataObjectName2");
	Return ObjectBelongingToSubsystem;
	
EndFunction

Procedure FillObjectBelongingToSubsystem(ObjectBelongingToSubsystem, FullMetadataObjectName2, Subsystem)
	
	IsCommonModuleOrPicture                = False;
	IsFunctionalOption                   = False;
	IsStyleItem                          = False;
	MetadataCallString               = "";
	AlternativeMetadataCallString = "";
	SearchByType = New Array;
	
	If StrFind(FullMetadataObjectName2, "Subsystem.StandardSubsystems.") > 0 Then
		
		Return;
		
	ElsIf StrFind(FullMetadataObjectName2, "CommonModule.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "CommonModule.", "");
		ObjectType                  = "";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = True;
		IsCommonModuleOrPicture   = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "SessionParameter.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "SessionParameter.", "");
		ObjectType                  = "SessionParameters";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "Role.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "Role.", "");
		ObjectType                  = "Roles";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "CommonAttribute.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "CommonAttribute.", "");
		ObjectType                  = "CommonAttributes";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "ExchangePlan.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "ExchangePlan.", "");
		ObjectType                  = "ExchangePlans";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "FilterCriterion.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "FilterCriterion.", "");
		ObjectType                  = "FilterCriteria";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "EventSubscription.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "EventSubscription.", "");
		ObjectType                  = "EventSubscriptions";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "ScheduledJob.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "ScheduledJob.", "");
		ObjectType                  = "ScheduledJobs";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "FunctionalOption.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "FunctionalOption.", "");
		ObjectType                  = "FunctionalOptions";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = True;
		IsFunctionalOption      = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "FunctionalOptionsParameter.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "FunctionalOptionsParameter.", "");
		ObjectType                  = "FunctionalOptionsParameters";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "DefinedType.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "DefinedType.", "");
		ObjectType                  = "DefinedTypes";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "SettingsStorage.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "SettingsStorage.", "");
		ObjectType                  = "SettingsStorages";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "CommonForm.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "CommonForm.", "");
		ObjectType                  = "CommonForms";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "CommonCommand.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "CommonCommand.", "");
		ObjectType                  = "CommonCommands";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "CommandGroup.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "CommandGroup.", "");
		ObjectType                  = "CommandGroups";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "CommonTemplate.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "CommonTemplate.", "");
		ObjectType                  = "CommonTemplates";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "CommonPicture.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "CommonPicture.", "");
		ObjectType                  = "PictureLib";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = True;
		IsCommonModuleOrPicture   = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "XDTOPackage.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "XDTOPackage.", "");
		ObjectType                  = "XDTOPackages";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "WebService.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "WebService.", "");
		ObjectType                  = "WebServices";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "WSReference.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "WSReference.", "");
		ObjectType                  = "WSReferences";
		CanCallByFullName = False;
		CanCallDirectlyFromCode  = False;
		
	ElsIf StrFind(FullMetadataObjectName2, "StyleItem.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "StyleItem.", "");
		ObjectType                  = "StyleItems";
		
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		IsStyleItem             = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "Constant.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "Constant.", "");
		ObjectType                  = "Constants";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "Catalog.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "Catalog.", "");
		ObjectType                  = "Catalogs";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "Catalog.", "CatalogRef."));
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "Catalog.", "CatalogObject."));
		
	ElsIf StrFind(FullMetadataObjectName2, "Document.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "Document.", "");
		ObjectType                  = "Documents";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "Document.", "DocumentRef."));
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "Document.", "DocumentObject."));
		
	ElsIf StrFind(FullMetadataObjectName2, "DocumentJournal.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "DocumentJournal.", "");
		ObjectType                  = "DocumentJournals";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "Enum.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "Enum.", "");
		ObjectType                  = "Enums";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "Enum.", "EnumRef."));
		
	ElsIf StrFind(FullMetadataObjectName2, "Report.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "Report.", "");
		ObjectType                  = "Reports";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "DataProcessor.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "DataProcessor.", "");
		ObjectType                  = "DataProcessors";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "ChartOfCharacteristicTypes.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "ChartOfCharacteristicTypes.", "");
		ObjectType                  = "ChartsOfCharacteristicTypes";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "ChartOfCharacteristicTypes.", "ChartOfCharacteristicTypesRef."));
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "ChartOfCharacteristicTypes.", "ChartOfCharacteristicTypesObject."));
		
	ElsIf StrFind(FullMetadataObjectName2, "ChartOfAccounts.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "ChartOfAccounts.", "");
		ObjectType                  = "ChartsOfAccounts";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "ChartOfCalculationTypes.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "ChartOfCalculationTypes.", "");
		ObjectType                  = "ChartsOfCalculationTypes";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "InformationRegister.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "InformationRegister.", "");
		ObjectType                  = "InformationRegisters";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "AccumulationRegister.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "AccumulationRegister.", "");
		ObjectType                  = "AccumulationRegisters";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "AccountingRegister.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "AccountingRegister.", "");
		ObjectType                  = "AccountingRegisters";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "CalculationRegister.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "CalculationRegister.", "");
		ObjectType                  = "CalculationRegisters";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "BusinessProcess.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "BusinessProcess.", "");
		ObjectType                  = "BusinessProcesses";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "BusinessProcess.", "BusinessProcessRef."));
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "BusinessProcess.", "BusinessProcessObject."));
		
	ElsIf StrFind(FullMetadataObjectName2, "Task.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "Task.", "");
		ObjectType                  = "Tasks";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "Task.", "TaskRef."));
		SearchByType.Add(StrReplace(FullMetadataObjectName2, "Task.", "TaskObject."));
		
	ElsIf StrFind(FullMetadataObjectName2, "Subsystem.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "Subsystem.", "");
		ObjectType                  = "Subsystems";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = True;
		
	ElsIf StrFind(FullMetadataObjectName2, "HTTPService.") > 0 Then
		
		ObjectName                  = StrReplace(FullMetadataObjectName2, "HTTPService.", "");
		ObjectType                  = "HTTPServices";
		CanCallByFullName = True;
		CanCallDirectlyFromCode  = False;
		
	EndIf;
	
	// Prepare parameters.
	If CanCallDirectlyFromCode And Not IsStyleItem And Not IsFunctionalOption Then
		StringForCallFromCode = ?(ObjectType <> "", ObjectType + ".","") + ObjectName;
	ElsIf IsStyleItem Then
		IsColor = (Metadata.StyleItems[ObjectName].Type = Metadata.ObjectProperties.StyleElementType.Color);
		StringForCallFromCode = ?(IsColor, "StyleColors.", "StyleFonts.") + ObjectName;
	ElsIf IsFunctionalOption Then
		StringForCallFromCode = "GetFunctionalOption" + "(""" + ObjectName + """)";
	Else
		StringForCallFromCode = "";
	EndIf;
	
	If Not IsCommonModuleOrPicture Then
		MetadataCallString               = "Metadata." + ObjectType + "." + ObjectName;
		AlternativeMetadataCallString = "Metadata." + ObjectType + "[""" + ObjectName + """]";
	EndIf;
	
	// Populate a table.
	TableRow                                          = ObjectBelongingToSubsystem.Add();
	TableRow.FullMetadataObjectName2                             = FullMetadataObjectName2;
	TableRow.MDOName                                   = ObjectName;
	TableRow.Subsystem                               = Subsystem;
	TableRow.StringForCallFromCode                    = StringForCallFromCode;
	TableRow.CanCallByFullName              = CanCallByFullName;
	TableRow.MetadataCallString               = MetadataCallString;
	TableRow.AlternativeMetadataCallString = AlternativeMetadataCallString;
	TableRow.SearchByType                              = SearchByType;
	
EndProcedure

Function InfobaseDirectory(ConnectionString)
	
	FileInforbaseFind = StrFind(ConnectionString, "File=");
	FirstPathChar = FileInforbaseFind + 6;
	ConnectionString = Mid(ConnectionString, FirstPathChar);
	LastPathChar = StrFind(ConnectionString, ";");
	ConnectionString = Left(ConnectionString, LastPathChar - 2);
	
	Return ConnectionString;
	
EndFunction

Function MetadataObjectsPropertiesToCheck()
	
	FillPropertiesKinds();
	
	MetadataObjectsPropertiesTree = New ValueTree;
	MetadataObjectsPropertiesTree.Columns.Add("MetadataObject");
	MetadataObjectsPropertiesTree.Columns.Add("PropertyKind1");
	MetadataObjectsPropertiesTree.Columns.Add("Property");
	MetadataObjectsPropertiesTree.Columns.Add("Type" );
	
	SpreadsheetDocument = Reports.SubsystemsDependencies.GetTemplate("PropertiesToCheck");
	StringText = Undefined;
	LineNumber   = 2;
	
	PropertyTypeRow = Undefined; // ValueTreeRow
	While StringText <> "TableEnd" Do
		
		Area = SpreadsheetDocument.Area(LineNumber, 1);
		AreaName = Area.Name;
		StringText = Area.Text;
		
		If IsBlankString(StringText) Then
			LineNumber = LineNumber + 1;
			Continue;
		EndIf;
		
		If NewBlockBeginning(StringText) Then
			
			If StrFind(StringText, "MetadataObject: ") > 0 Then
				MetadataObject = StrReplace(StringText, "MetadataObject: ", "");
				MetadataObjectsRow = MetadataObjectsPropertiesTree.Rows.Add();
				MetadataObjectsRow.MetadataObject = MetadataObject;
				PropertyTypeRow = Undefined;
			Else
				PropertyKind1 = StrReplace(StringText, ":", "");
				PropertyTypeRow = MetadataObjectsRow.Rows.Add();
				PropertyTypeRow.PropertyKind1 = PropertyKind1;
			EndIf;
			
			LineNumber = LineNumber+1;
			Continue;
			
		EndIf;
		
		If PropertyTypeRow <> Undefined Then
			ObjectProperty1         = StrReplace(StringText, ":", "");
			RowProperty          = PropertyTypeRow.Rows.Add();
			RowProperty.Property = ObjectProperty1;
			RowProperty.Type      = SpreadsheetDocument.Area(LineNumber, 2).Text;
		EndIf;
		
		LineNumber = LineNumber+1;
	EndDo;
	
	Return MetadataObjectsPropertiesTree;
	
EndFunction

Procedure FillPicturesCollection()
	PicturesCollection = New Map;
	
	// Configuration images.
	For Each Picture In Metadata.CommonPictures Do
		IconName = Picture.Name;
		PicturesCollection.Insert(XMLString(PictureLib[IconName].GetBinaryData()), Picture.FullName());
	EndDo;
	
EndProcedure

Procedure FillExceptions()
	
	ExceptionsTable = New ValueTable;
	ExceptionsTable.Columns.Add("ObjectToExclude");
	ExceptionsTable.Columns.Add("CallingSubsystem");
	ExceptionsTable.Columns.Add("SubsystemToCall");
	ExceptionsTable.Columns.Add("CallingObject");
	
	SpreadsheetDocument = Reports.SubsystemsDependencies.GetTemplate("ExceptionObjects");
	StringText = Undefined;
	AreaName = Undefined;
	LineNumber   = 1;
	
	ExampleFinished = False;
	
	While AreaName <> "DocumentEnd" Do
		Area = SpreadsheetDocument.Area(LineNumber, 0);
		AreaName = Area.Name;
		StringText = Area.Text;
		
		If Not ExampleFinished Then
			ExampleFinished = (AreaName = "ExceptionsList");
			LineNumber = LineNumber + 1;
			Continue;
		EndIf;
		
		If IsBlankString(StringText) Or AreaName = "DocumentEnd" Then
			LineNumber = LineNumber + 1;
			Continue;
		EndIf;
		
		If AreaName = "ObjectsToExclude" Then
			CurrentExceptionsBlock = "ObjectsToExclude";
			LineNumber = LineNumber + 1;
			Continue;
		ElsIf AreaName = "LinksToExclude" Then
			CurrentExceptionsBlock = "LinksToExclude";
			LineNumber = LineNumber + 1;
			Continue;
		EndIf;
		
		ExceptionString_ = ExceptionsTable.Add();
		If CurrentExceptionsBlock = "ObjectsToExclude" Then
			ExceptionString_.ObjectToExclude = StringText;
		Else
			ExceptionArray = StrSplit(StringText, "-", False);
			ExceptionString_.CallingSubsystem = ExceptionArray[0];
			ExceptionString_.SubsystemToCall = ExceptionArray[1];
			ExceptionString_.CallingObject     = ExceptionArray[2];
		EndIf;
		
		LineNumber = LineNumber + 1;
	EndDo;
	
EndProcedure

// Checks.

Procedure SearchForCallsInFormDynamicListsAndModules(ObjectBelongingToSubsystem)
	
	FilesArray = FindFiles(ModulesExportDirectory, "*.bsl", True);
	FormsFilesArray = FindFiles(ModulesExportDirectory, "Form.xml", True); 
	
	CommonClientServer.SupplementArray(FilesArray, FormsFilesArray);
	
	For Each File In FilesArray Do
		
		FullName_Structure = FullNameByModuleName(File.FullName, File.Name);
		
		// Skip demo objects.
		If StrFind(FullName_Structure.FullModuleName, "_Demo") <> 0 Then
			Continue;
		EndIf;
		
		// Get the calling subsystem.
		CallingObject = FullName_Structure.FullObjectName;
		FoundRow = ObjectBelongingToSubsystem.Find(CallingObject, "FullMetadataObjectName2");
		FullCallingObjectName = FullName_Structure.FullModuleName;
		
		StandaloneObjectCheck = (ObjectsToCheckStandaloneStatus.Find(CallingObject) <> Undefined);
		
		If FoundRow = Undefined And Not StandaloneObjectCheck Then
			Continue;
		EndIf;
		
		If StandaloneObjectCheck Then
			CallingSubsystemRow = Undefined;
			CallingSubsystem = "UniversalDataProcessors";
		Else
			CallingSubsystem = FoundRow.Subsystem;
			// Data of the calling subsystem object.
			CallingSubsystemRow = SubsystemsDependencies.Find(CallingSubsystem, "Name");
		EndIf;
		
		If StrStartsWith(CallingSubsystem, "CloudTechnology.")
			Or StrStartsWith(CallingSubsystem, "OnlineUserSupport.")
			Or StrFind(CallingSubsystem, "DataExchange") > 0
			Or StrFind(CallingSubsystem, "DataExchangeSaaS") > 0 Then
			Continue;
		EndIf;
		
		If File.Extension = ".bsl" Then
			
			FileText = New TextReader(File.FullName);
			TextString = FileText.Read(); 
			
			CallsSearchStructure = GetCallSearchStructure(TextString, CallingSubsystem, CallingSubsystemRow,
				ObjectBelongingToSubsystem, StandaloneObjectCheck, FullCallingObjectName);
			SearchForCallInFormDynamicListsAndModules(CallsSearchStructure);
			
			FileText.Close();
			
		ElsIf File.Extension = ".xml" Then
			
			TableOfRequests = GetTableWithQueriesFromDynamicLists(File.FullName);
			For Each QueryTableRow In TableOfRequests Do
				
				TextString = QueryTableRow.QueryText;
				AttributeName = QueryTableRow.Attribute;
				
				CallsSearchStructure = GetCallSearchStructure(TextString, CallingSubsystem, CallingSubsystemRow,
					ObjectBelongingToSubsystem, StandaloneObjectCheck, FullCallingObjectName, AttributeName);
				
				SearchForCallInFormDynamicListsAndModules(CallsSearchStructure);
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
EndProcedure 

Procedure SearchForCallInFormDynamicListsAndModules(CallsSearchStructure)
	
	// Demo code blocks are not analyzed.
	CutOutDemoExamplesFromCode(CallsSearchStructure.TextString);
	
	For Each MapItem In CallsSearchStructure.ObjectBelongingToSubsystem Do
		
		SubsystemToCall = MapItem.Subsystem;
		If CallsSearchStructure.CallingSubsystem = SubsystemToCall Then
			Continue; // Intra-subsystem call.
		EndIf;
		
		SubsystemToCallRow = SubsystemsDependencies.Find(SubsystemToCall, "Name");
		If SubsystemToCallRow <> Undefined
			And Not CallsSearchStructure.StandaloneObjectCheck And SubsystemToCallRow.Required Then
			Continue; // The subsystem is required.
		EndIf;
		
		If CallsSearchStructure.CallingSubsystemRow <> Undefined
			And CallsSearchStructure.CallingSubsystemRow.ConditionallyDependsOnSubsystems.Find("*") <> Undefined Then
			Break; // Don't check subsystem dependencies.
		EndIf;
		
		If CallsSearchStructure.CallingSubsystemRow <> Undefined
			And CallsSearchStructure.CallingSubsystemRow.DependsOnSubsystems.Find(SubsystemToCall) <> Undefined Then
			Continue; // Dependency between these subsystems is documented.
		EndIf;
		
		CallSearchStructure = New Structure;
		CallSearchStructure.Insert("TextString", 					CallsSearchStructure.TextString);
		CallSearchStructure.Insert("CallingSubsystem", 			CallsSearchStructure.CallingSubsystem);
		CallSearchStructure.Insert("FullCallingObjectName", 	CallsSearchStructure.FullCallingObjectName);
		CallSearchStructure.Insert("SubsystemToCall", 			SubsystemToCall);
		CallSearchStructure.Insert("MapItem", 			MapItem);
		CallSearchStructure.Insert("AttributeName", 					CallsSearchStructure.AttributeName);
		
		ExecuteSearchForCallsInOtherSubsystems(CallSearchStructure);
		If Not CallsSearchStructure.StandaloneObjectCheck Then
			FindCallToMetadataInModulesCode(CallSearchStructure);
			If CallsSearchStructure.CallingSubsystem <> "DeveloperTools" Then
				ExecuteSearchByFullObjectName(CallSearchStructure);
			EndIf;
		EndIf;
		
	EndDo;
	
	ProcessCallsViaNotifications(CallsSearchStructure.CallingSubsystem, CallsSearchStructure.FullCallingObjectName,
		CallsSearchStructure.TextString, CallsSearchStructure.ObjectBelongingToSubsystem);
	
EndProcedure

Procedure ExecuteSearchForCallsInOtherSubsystems(CallSearchStructure)
	
	TextString      = CallSearchStructure.TextString;
	CallStart      = 0;
	CallEnd       = 0;
	NewTextString = "";
	KeyChar     = " ";
	LineNumber       = 0;
	StringForCallFromCode = CallSearchStructure.MapItem.StringForCallFromCode;
		
	If StringForCallFromCode = "" Then
		Return;
	EndIf;
	
	SearchBars = New Array;
	If StrFind(StringForCallFromCode, "PictureLib") > 0
		Or StrFind(StringForCallFromCode, "StyleColors") > 0
		Or StrFind(StringForCallFromCode, "StyleFonts") > 0
		Or StrFind(StringForCallFromCode, "SessionParameters") > 0
		Or StrFind(StringForCallFromCode, "GetFunctionalOption") > 0 Then
		SearchBars.Add(StringForCallFromCode);
	Else
		SearchBars.Add(StringForCallFromCode + ".");
		SearchBars.Add(StringForCallFromCode + "[");
	EndIf;
	
	FormAttributeName = String(CallSearchStructure.AttributeName);
	If Not IsBlankString(FormAttributeName) Then
		FormAttributeName = "Attribute: " + FormAttributeName + Chars.LF;
	EndIf;
	
	For Each SearchString In SearchBars Do
		
		GetCallBeginningAndEnd(TextString, SearchString, NewTextString, CallStart, CallEnd, KeyChar);
		
		If CallStart = 0 Or CallEnd = 0 Then
			Continue;
		EndIf;
		
		While True Do
			
			CallText = Left(NewTextString, CallEnd);
			
			If LineNumber = 0 Then
				LineNumber = LineNumber(CallSearchStructure.TextString, CallStart, LineNumber);
			Else
				LineNumber = LineNumber(TextString, CallStart, LineNumber);
			EndIf;
			
			If Not IsComment(TextString, CallStart)
				And Not IsString(TextString, CallStart)
				And StrFind(CallText, Chars.LF) = 0
				And StrFind(Mid(NewTextString, 0, CallEnd), " ") = 0
				And (TrimAll(KeyChar) <> KeyChar
					Or KeyChar = "("
					Or KeyChar = ",") Then
				
				LinksBetweenSubsystemsObjectsRow = LinksBetweenSubsystemsObjects.Add();
				LinksBetweenSubsystemsObjectsRow.Call_Position = FormAttributeName + "string " + LineNumber + ": " + CallText;
				LinksBetweenSubsystemsObjectsRow.SubsystemToCall = CallSearchStructure.SubsystemToCall;
				LinksBetweenSubsystemsObjectsRow.CallingSubsystem = CallSearchStructure.CallingSubsystem;
				LinksBetweenSubsystemsObjectsRow.CallingObject     = CallSearchStructure.FullCallingObjectName;
			EndIf;
			
			TextString = Mid(NewTextString, CallEnd);
			NewTextString = "";
			GetCallBeginningAndEnd(TextString, SearchString, NewTextString, CallStart, CallEnd, KeyChar);
			If CallStart = 0 Or CallEnd = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure ProcessCallsViaNotifications(CallingSubsystem, FullCallingObjectName, TextString, ObjectBelongingToSubsystem)
	
	FoundCalls = SearchTextForNotifications(TextString);
	For Each CurrentCall In FoundCalls Do
		RecordIncorrectCalls(CurrentCall, CallingSubsystem, FullCallingObjectName, ObjectBelongingToSubsystem);
	EndDo;
	
EndProcedure

// Parameters:
//   ModuleText - String
// Returns:
//   Array of Structure:
//   * LineNumber - Number
//   * Call - String
//
Function SearchTextForNotifications(Val ModuleText)
	
	RowsWithNotifications   = New Array;
	CurrentOccurrenceNumber = StrFind(ModuleText, "New NotifyDescription(");
	
	LineNumber = 0;
	Offset    = 0;
	
	While CurrentOccurrenceNumber > 0 Do
		
		LineNumber = LineNumber(ModuleText, CurrentOccurrenceNumber, LineNumber) + Offset;
		
		ModuleText        = Mid(ModuleText, CurrentOccurrenceNumber);
		IterationCount = StrLen(ModuleText);
		
		For IndexOf = 24 To IterationCount Do
			
			CurrentChar   = Mid(ModuleText, IndexOf, 1);
			NextChar = Mid(ModuleText, IndexOf + 1, 1);
			
			If CurrentChar = ")" And (NextChar = ";" Or NextChar = ",") Then
				
				CurrentNotificationRow = Left(ModuleText, IndexOf + 1);
				ModuleText             = Mid(ModuleText, IndexOf + 1);
				CurrentOccurrenceNumber   = StrFind(ModuleText, "New NotifyDescription(");
				
				Offset = StrLineCount(CurrentNotificationRow) - 1;
				
				StructureOfResults_ = New Structure;
				StructureOfResults_.Insert("LineNumber", LineNumber);
				StructureOfResults_.Insert("Call",       ExcludeAnonymousStructures(CurrentNotificationRow));
				
				RowsWithNotifications.Add(StructureOfResults_);
				Break;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	Return RowsWithNotifications;
	
EndFunction

Function ExcludeAnonymousStructures(Val RowWithNotification)
	
	AnonymousStructureOccurrence = StrFind(RowWithNotification, "New Structure(");
	If AnonymousStructureOccurrence > 0 Then
		
		RowWithStructure = Mid(RowWithNotification, AnonymousStructureOccurrence);
		
		OpenParenthesesCounter = 0;
		CloseParenthesesCounter = 0;
		
		IterationCount = StrLen(RowWithStructure);
		
		For IndexOf = 15 To IterationCount Do
			
			If OpenParenthesesCounter <> 0 And CloseParenthesesCounter <> 0
				And OpenParenthesesCounter = CloseParenthesesCounter Then
				
				AnonymousStructureCall = Mid(RowWithStructure, 1, IndexOf - 1);
				RowWithNotification = StrReplace(RowWithNotification, AnonymousStructureCall, "AdditionalParameters");
				Break;
				
			Else
				
				CurrentChar   = Mid(RowWithStructure, IndexOf, 1);
				If CurrentChar = "(" Then
					OpenParenthesesCounter = OpenParenthesesCounter + 1;
				ElsIf CurrentChar = ")" Then
					CloseParenthesesCounter = CloseParenthesesCounter + 1;
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return RowWithNotification;
	
EndFunction

Procedure RecordIncorrectCalls(CurrentCall, CallingSubsystem, FullCallingObjectName, ObjectBelongingToSubsystem)
	
	DetailsParametersAsArray = StrSplit(CurrentCall.Call, ",");
	
	If DetailsParametersAsArray.Count() >= 2 Then
		
		TargetCall       = DetailsParametersAsArray.Get(1);
		IsCorrectCall = IsCorrectCall(CallingSubsystem, TargetCall, ObjectBelongingToSubsystem);
		
		SubsystemToCallRow = SubsystemsDependencies.Find(IsCorrectCall.SubsystemToCall, "Name");
		If SubsystemToCallRow <> Undefined And SubsystemToCallRow.Required Then
			Return; // The subsystem is required.
		EndIf;
		
		If ValueIsFilled(TargetCall) Then
			If Not IsCorrectCall.ObjectBelongsToCurrentSubsystem Then
				RecordLinksError(CurrentCall, IsCorrectCall.SubsystemToCall, CallingSubsystem, FullCallingObjectName);
			EndIf;
		EndIf;
		
		If DetailsParametersAsArray.Count() = 5 Then
			
			TargetCall       = DetailsParametersAsArray.Get(4);
			IsCorrectCall = IsCorrectCall(CallingSubsystem, TargetCall, ObjectBelongingToSubsystem);
			
			If ValueIsFilled(TargetCall) Then
				If Not IsCorrectCall.ObjectBelongsToCurrentSubsystem Then
					RecordLinksError(CurrentCall, IsCorrectCall.SubsystemToCall, CallingSubsystem, FullCallingObjectName);
				EndIf;
			EndIf;
				
		EndIf;
		
	EndIf;
	
EndProcedure

Function IsCorrectCall(CallingSubsystem, TargetCall, ObjectBelongingToSubsystem)
	
	OutgoingCall = TrimAll(StrReplace(StrReplace(StrReplace(TargetCall,"""", ""), ")", ""), ";", ""));
	
	If OutgoingCall = "ThisObject" Or StrStartsWith(OutgoingCall, "Module") Then
		Return New Structure("ObjectBelongsToCurrentSubsystem, SubsystemToCall", True, "");
	Else
		StringOfBelonging = ObjectBelongingToSubsystem.Find(OutgoingCall, "MDOName");
		If StringOfBelonging <> Undefined And StringOfBelonging.Subsystem <> CallingSubsystem Then
			Return New Structure("ObjectBelongsToCurrentSubsystem, SubsystemToCall", False, StringOfBelonging.Subsystem);
		Else
			Return New Structure("ObjectBelongsToCurrentSubsystem, SubsystemToCall", True, "");
		EndIf;
	EndIf;
	
EndFunction

// Parameters:
//   CurrentCall - Structure:
//   * LineNumber - Number
//   * Call - String
//   SubsystemToCall - String
//   CallingSubsystem - String
//   FullCallingObjectName - String
//
Procedure RecordLinksError(CurrentCall, SubsystemToCall, CallingSubsystem, FullCallingObjectName)
	
	LinksBetweenSubsystemsObjectsRow = LinksBetweenSubsystemsObjects.Add();
	LinksBetweenSubsystemsObjectsRow.Call_Position          = "string " + CurrentCall.LineNumber + ": " + CurrentCall.Call;
	LinksBetweenSubsystemsObjectsRow.SubsystemToCall = SubsystemToCall;
	LinksBetweenSubsystemsObjectsRow.CallingSubsystem = CallingSubsystem;
	LinksBetweenSubsystemsObjectsRow.CallingObject     = FullCallingObjectName;
	
EndProcedure

Procedure ExecuteSearchByFullObjectName(CallSearchStructure)
	
	TextString = CallSearchStructure.TextString;
	If Not CallSearchStructure.MapItem.CanCallByFullName Then
		Return;
	EndIf;
	
	SearchString = CallSearchStructure.MapItem.FullMetadataObjectName2;
	
	CallStart = 0;
	CallEnd = 0;
	NewTextString = "";
	KeyChar = " ";
	LineNumber = 0; 
	ArrayOfAnchorChars = New Array;
	ArrayOfAnchorChars.Add(" ");
	ArrayOfAnchorChars.Add(".");
	ArrayOfAnchorChars.Add("""");
	ArrayOfAnchorChars.Add(")");
	
	If SearchString = "" Then
		Return;
	EndIf;
	
	SearchByFullName = True;
	GetCallBeginningAndEnd(TextString, SearchString, NewTextString, CallStart, CallEnd, KeyChar);
	
	If CallStart = 0 Or CallEnd = 0 Then
		Return;
	EndIf;
	
	FormAttributeName = String(CallSearchStructure.AttributeName);
	If Not IsBlankString(FormAttributeName) Then
		FormAttributeName = "Attribute: " + FormAttributeName + Chars.LF;
	EndIf;
	
	While True Do
		
		CallText = Left(NewTextString, CallEnd);
		
		If Not IsComment(TextString, CallStart, True)
			And (ArrayOfAnchorChars.Find(KeyChar) <> Undefined) Then
			
			If LineNumber = 0 Then
				LineNumber = LineNumber(CallSearchStructure.TextString, CallStart, LineNumber);
			Else
				LineNumber = LineNumber(TextString, CallStart, LineNumber);
			EndIf;
			
			LinksBetweenSubsystemsObjectsRow = LinksBetweenSubsystemsObjects.Add();
			LinksBetweenSubsystemsObjectsRow.Call_Position = FormAttributeName + "string " + LineNumber + ": " + CallText;
			LinksBetweenSubsystemsObjectsRow.SubsystemToCall = CallSearchStructure.SubsystemToCall;
			LinksBetweenSubsystemsObjectsRow.CallingSubsystem = CallSearchStructure.CallingSubsystem;
			LinksBetweenSubsystemsObjectsRow.CallingObject     = CallSearchStructure.FullCallingObjectName;
			
		EndIf;
		
		TextString = Mid(NewTextString, CallEnd);
		NewTextString = "";
		SearchByFullName = True;
		GetCallBeginningAndEnd(TextString, SearchString, NewTextString, CallStart, CallEnd, KeyChar);
		If CallStart = 0 Or CallEnd = 0 Then
			Break;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure FindCallToMetadataInModulesCode(CallSearchStructure)
	
	SearchStringArray = New Array;
	SearchStringArray.Add(CallSearchStructure.MapItem.MetadataCallString);
	If CallSearchStructure.CallingSubsystem <> "DeveloperTools" Then
		For Each TypeName In CallSearchStructure.MapItem.SearchByType Do
			Template = "Type(""%1"")";
			SearchStringArray.Add(StringFunctionsClientServer.SubstituteParametersToString(Template, TypeName));
		EndDo;
	EndIf;
	
	FormAttributeName = String(CallSearchStructure.AttributeName);
	If Not IsBlankString(FormAttributeName) Then
		FormAttributeName = "Attribute: " + FormAttributeName + Chars.LF;
	EndIf;
	
	For Each SearchString In SearchStringArray Do
		
		TextString = CallSearchStructure.TextString;
		CallStart = 0;
		CallEnd = 0;
		NewTextString = "";
		KeyChar = " ";
		LineNumber = 0;
		
		If SearchString = "" Then
			Return;
		EndIf;
		
		GetCallBeginningAndEnd(TextString, SearchString, NewTextString, CallStart, CallEnd, KeyChar);
		
		If CallStart = 0 Or CallEnd = 0 Then
			Continue;
		EndIf;
		
		While True Do
			
			CallText = Left(NewTextString, CallEnd);
			NextChar = Mid(NewTextString, CallEnd + 1, 1);
			Validation = Undefined;
			// ACC:280-off - The check is performed by the structure constructor. An exception is the expected behavior.
			Try
				Validation = New Structure(NextChar);
			Except
				// Do not handle exceptions.
				// Errors mean the correct call was found.
			EndTry;
			// ACC:280-on
			
			If (Validation = Undefined Or Validation.Count() = 0)
				And Not IsComment(TextString, CallStart) Then
				
				If LineNumber = 0 Then
					LineNumber = LineNumber(CallSearchStructure.TextString, CallStart, LineNumber);
				Else
					LineNumber = LineNumber(TextString, CallStart, LineNumber);
				EndIf;
				
				TextBeforeCall = Left(CallSearchStructure.TextString, CallStart);
				ConditionalCall = "If Common.SubsystemExists(""StandardSubsystems.%1"")";
				ConditionalCall = StringFunctionsClientServer.SubstituteParametersToString(ConditionalCall, CallSearchStructure.SubsystemToCall);
				ConditionalCallClient = "If CommonClient.SubsystemExists(""StandardSubsystems.%1"")";
				ConditionalCallClient = StringFunctionsClientServer.SubstituteParametersToString(ConditionalCallClient, CallSearchStructure.SubsystemToCall);
				EndOfCondition = "EndIf;";
				StartOfFunction = "Function ";
				BeginningOfProcedure = "Procedure ";
				
				FunctionPosition = StrFind(TextBeforeCall, StartOfFunction, SearchDirection.FromEnd);
				ProcedurePosition = StrFind(TextBeforeCall, BeginningOfProcedure, SearchDirection.FromEnd);
				ConditionEndPosition = StrFind(TextBeforeCall, EndOfCondition, SearchDirection.FromEnd);
				ConditionalCallPosition = StrFind(TextBeforeCall, ConditionalCall, SearchDirection.FromEnd);
				If ConditionalCallPosition = 0 Then
					ConditionalCallPosition = StrFind(TextBeforeCall, ConditionalCallClient, SearchDirection.FromEnd);
				EndIf;
				
				If ConditionalCallPosition < FunctionPosition
					Or ConditionalCallPosition < ProcedurePosition
					Or ConditionalCallPosition < ConditionEndPosition Then
					LinksBetweenSubsystemsObjectsRow = LinksBetweenSubsystemsObjects.Add();
					LinksBetweenSubsystemsObjectsRow.Call_Position = FormAttributeName + "string " + LineNumber + ": " + CallText;
					LinksBetweenSubsystemsObjectsRow.SubsystemToCall = CallSearchStructure.SubsystemToCall;
					LinksBetweenSubsystemsObjectsRow.CallingSubsystem = CallSearchStructure.CallingSubsystem;
					LinksBetweenSubsystemsObjectsRow.CallingObject     = CallSearchStructure.FullCallingObjectName;
				EndIf;
				
			EndIf;
			
			TextString = Mid(NewTextString, CallEnd);
			NewTextString = "";
			GetCallBeginningAndEnd(TextString, SearchString, NewTextString, CallStart, CallEnd, KeyChar);
			If CallStart = 0 Or CallEnd = 0 Then
				Break;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure SearchConfigurationMetadataForCalls(MetadataObjectsPropertiesToCheck, ObjectBelongingToSubsystem)
	
	For Each StringMetadataObject In MetadataObjectsPropertiesToCheck.Rows Do
		
		For Each PropertyKind1 In StringMetadataObject.Rows Do
			
			For Each ObjectProperty1 In PropertyKind1.Rows Do
				
				PropertyKindToCheck = PropertyKind1.PropertyKind1;
				PropertyToCheck = ObjectProperty1.Property;
				PropertyType1 = ObjectProperty1.Type;
				
				For Each MetadataObject In Metadata[StringMetadataObject.MetadataObject] Do
					
					CallingObject = MetadataObject.FullName();
					If StrFind(CallingObject, "_Demo") > 0 Then
						Continue;
					EndIf;
					
					FoundRow = ObjectBelongingToSubsystem.Find(CallingObject);
					
					If FoundRow = Undefined Then
						Continue;
					EndIf;
					
					CallingSubsystem = FoundRow.Subsystem;
					If StrStartsWith(CallingSubsystem, "CloudTechnology.")
						Or StrStartsWith(CallingSubsystem, "OnlineUserSupport.")
						Or StrFind(CallingSubsystem, "DataExchange") > 0
						Or StrFind(CallingSubsystem, "DataExchangeSaaS") > 0 Then
						Continue;
					EndIf;
					
					SubsystemsToCall = SearchForSubsystemsToCall(ObjectBelongingToSubsystem, MetadataObject, PropertyKindToCheck, PropertyToCheck, PropertyType1);
					
					If SubsystemsToCall = Undefined Then
						Continue;
					EndIf;
					
					For Each TableRow In SubsystemsToCall Do
						
						SubsystemToCallRow = TableRow.SubsystemData;
						SubsystemToCall = SubsystemToCallRow.Subsystem;
						If CallingSubsystem = SubsystemToCall Then
							Continue; // Intra-subsystem call.
						EndIf;
						
						FoundSubsystem = SubsystemsDependencies.Find(SubsystemToCall, "Name");
						If FoundSubsystem <> Undefined And FoundSubsystem.Required Then
							Continue; // The subsystem is required.
						EndIf;
						
						CallingSubsystemRow = SubsystemsDependencies.Find(CallingSubsystem, "Name");
						If CallingSubsystemRow <> Undefined
							And CallingSubsystemRow.ConditionallyDependsOnSubsystems.Find("*") <> Undefined Then
							Break; // Don't check subsystem dependencies.
						EndIf;
						
						If CallingSubsystemRow <> Undefined
							And (CallingSubsystemRow.DependsOnSubsystems.Find(SubsystemToCall) <> Undefined
							   Or CallingSubsystemRow.ConditionallyDependsOnSubsystems.Find(SubsystemToCall) <> Undefined) Then
							Continue; // Dependency between these subsystems is documented.
						EndIf;
						
						LinksBetweenSubsystemsObjectsRow = LinksBetweenSubsystemsObjects.Add();
						LinksBetweenSubsystemsObjectsRow.Call_Position = PropertyKindToCheck + "."
							+ ?(IsBlankString(TableRow.AttributeName), PropertyToCheck, TableRow.AttributeName);
						LinksBetweenSubsystemsObjectsRow.SubsystemToCall = SubsystemToCall;
						LinksBetweenSubsystemsObjectsRow.CallingSubsystem = CallingSubsystem;
						LinksBetweenSubsystemsObjectsRow.CallingObject     = CallingObject;
						LinksBetweenSubsystemsObjectsRow.ObjectToCall     = TableRow.ObjectToCall;
						
					EndDo;
					
				EndDo;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Auxiliary actions.

Function SearchForSubsystemsToCall(ObjectBelongingToSubsystem, MetadataObject, PropertyKindToCheck, PropertyToCheck, PropertyType1)
	
	SubsystemsToCall = Undefined;
	If PropertyKindToCheck = "Properties" Then
		FieldToCheck = MetadataObject[PropertyToCheck];
		SubsystemsToCall = SearchObjectPropertyForCalls(ObjectBelongingToSubsystem, SubsystemsToCall, FieldToCheck, PropertyType1);
	ElsIf PropertyKindToCheck = "Attributes"
		Or PropertyKindToCheck = "AddressingAttributes"
		Or PropertyKindToCheck = "Commands"
		Or PropertyKindToCheck = "Dimensions"
		Or PropertyKindToCheck = "Resources" Then
		
		For Each AttributeToCheck In MetadataObject[PropertyKindToCheck] Do
			FieldToCheck = AttributeToCheck[PropertyToCheck];
			AttributeName = AttributeToCheck.Name + "." + PropertyToCheck;
			SubsystemsToCall = SearchObjectPropertyForCalls(ObjectBelongingToSubsystem, SubsystemsToCall, FieldToCheck, PropertyType1, AttributeName);
		EndDo;
		
	ElsIf PropertyKindToCheck = "TabularSections" Then
		
		PropertiesToCheck = StrSplit(PropertyToCheck, ".", False);
		For Each TabularSectionToCheck In MetadataObject[PropertyKindToCheck] Do
			For Each AttributeToCheck In TabularSectionToCheck[PropertiesToCheck[0]] Do
				FieldToCheck = AttributeToCheck[PropertiesToCheck[1]];
				AttributeName    = TabularSectionToCheck.Name + "." + AttributeToCheck.Name + "." + PropertiesToCheck[1];
				SubsystemsToCall = SearchObjectPropertyForCalls(ObjectBelongingToSubsystem, SubsystemsToCall, FieldToCheck, PropertyType1, AttributeName);
			EndDo;
		EndDo;
		
	ElsIf PropertyToCheck = "Characteristics" Then
		Return Undefined;
	EndIf;
	
	Return SubsystemsToCall;
	
EndFunction

Function SearchObjectPropertyForCalls(ObjectBelongingToSubsystem, SubsystemsToCall, FieldToCheck, PropertyType1, AttributeName = Undefined)
	
	AnyRefAttribute = Metadata.Reports.SubsystemsDependencies.Attributes.AnyRef.Type;
	
	If SubsystemsToCall = Undefined Then
		SubsystemsToCall = New ValueTable;
		SubsystemsToCall.Columns.Add("SubsystemData");
		SubsystemsToCall.Columns.Add("ObjectToCall");
		SubsystemsToCall.Columns.Add("AttributeName");
	EndIf;
	
	If FieldToCheck = Undefined Then
		Return SubsystemsToCall;
	EndIf;
	
	If PropertyType1 = "TypeDescription" Then
		
		If AnyRefAttribute = FieldToCheck Then
			Return SubsystemsToCall;
		EndIf;
		
		For Each DefinedType In Metadata.DefinedTypes Do
			If FieldToCheck = DefinedType.Type Then
				Return SubsystemsToCall;
			EndIf;
		EndDo;
		
		ObjectTypesArray = FieldToCheck.Types();
		If GroupTypesSelection(ObjectTypesArray) Then
			Return SubsystemsToCall;
		EndIf;
		
		For Each ObjectType In ObjectTypesArray Do
			
			MOToCall = Metadata.FindByType(ObjectType);
			If MOToCall <> Undefined Then
				FullMONameToCall = MOToCall.FullName();
				FillSubsystemsToCallInMetadata(SubsystemsToCall, ObjectBelongingToSubsystem, FullMONameToCall, AttributeName);
			EndIf;
			
		EndDo;
		
	ElsIf PropertyType1 = "MetadataObjectPropertyValueCollection" Then
		
		For Each MetadataObject In FieldToCheck Do
			FullMONameToCall = MetadataObject.FullName();
			FillSubsystemsToCallInMetadata(SubsystemsToCall, ObjectBelongingToSubsystem, FullMONameToCall, AttributeName);
		EndDo;
		
	ElsIf PropertyType1 = "String"
		Or PropertyType1 = "MetadataObject" Then
		
		If PropertyType1 = "MetadataObject" Then
			FullMONameToCall = FieldToCheck.FullName();
		Else
			MetadataObjectName = StrSplit(FieldToCheck, ".", False)[0];
			FullMONameToCall = "CommonModule." + MetadataObjectName;
		EndIf;
		FillSubsystemsToCallInMetadata(SubsystemsToCall, ObjectBelongingToSubsystem, FullMONameToCall, AttributeName);
		
	ElsIf PropertyType1 = "FunctionalOptionContent" Then
		
		For Each FOCompositionItem In FieldToCheck Do
			
			If FOCompositionItem.Object = Undefined Then
				Continue;
			EndIf;
			
			FullMONameToCall = FOCompositionItem.Object.FullName();
			FillSubsystemsToCallInMetadata(SubsystemsToCall, ObjectBelongingToSubsystem, FullMONameToCall, AttributeName);
			
		EndDo;
		
	ElsIf PropertyType1 = "Picture" Then
		
		If FieldToCheck.Kind <> PictureType.Empty Then
			FullMONameToCall = PicturesCollection[XMLString(FieldToCheck.GetBinaryData())];
			If FullMONameToCall <> Undefined Then
				FillSubsystemsToCallInMetadata(SubsystemsToCall, ObjectBelongingToSubsystem, FullMONameToCall, AttributeName);
			EndIf;
		EndIf;
		
	EndIf;
	
	Return SubsystemsToCall;
	
EndFunction

Procedure FillSubsystemsToCallInMetadata(SubsystemsToCall, ObjectBelongingToSubsystem, FullMONameToCall, AttributeName)
	
	FullNameInPieces = StrSplit(FullMONameToCall, ".", False);
	If FullNameInPieces.Count() > 2 Then
		FullMONameToCall = FullNameInPieces[0] + "." + FullNameInPieces[1];
	EndIf;
	
	SubsystemToCallRow = ObjectBelongingToSubsystem.Find(FullMONameToCall, "FullMetadataObjectName2");
	If SubsystemToCallRow <> Undefined Then
		SubsystemsToCallRow = SubsystemsToCall.Add();
		SubsystemsToCallRow.SubsystemData = SubsystemToCallRow;
		SubsystemsToCallRow.ObjectToCall = FullMONameToCall;
		SubsystemsToCallRow.AttributeName = AttributeName;
	EndIf;
	
EndProcedure

Function GroupTypesSelection(ObjectTypesArray)
	
	SelectedObjectsCount = New Map;
	
	For Each ArrayElement In ObjectTypesArray Do
		
		If ArrayElement = Type("ConstantsSet") Then
			Return True;
		EndIf;
		MetadataObject = Metadata.FindByType(ArrayElement);
		If MetadataObject = Undefined Then
			Continue;
		EndIf;
		
		MetadataObjectFullName = MetadataObject.FullName();
		ObjectKind = StrSplit(MetadataObjectFullName, ".", False)[0];
		If ObjectKind = "Catalog" Then
			ObjectKind = "Catalogs";
		ElsIf ObjectKind = "Document" Then
			ObjectKind = "Documents";
		ElsIf ObjectKind = "Enum" Then
			ObjectKind = "Enums";
		ElsIf ObjectKind = "ChartOfCharacteristicTypes" Then
			ObjectKind = "ChartsOfCharacteristicTypes";
		ElsIf ObjectKind = "ChartOfAccounts" Then
			ObjectKind = "ChartsOfAccounts";
		ElsIf ObjectKind = "ChartOfCalculationTypes" Then
			ObjectKind = "ChartsOfCalculationTypes";
		ElsIf ObjectKind = "BusinessProcess" Then
			ObjectKind = "BusinessProcesses";
		ElsIf ObjectKind = "Task" Then
			ObjectKind = "Tasks";
		ElsIf ObjectKind = "ExchangePlan" Then
			ObjectKind = "ExchangePlans";
		EndIf;
		
		Count = SelectedObjectsCount[ObjectKind];
		If Count = Undefined Then
			SelectedObjectsCount.Insert(ObjectKind, 1);
		Else
			SelectedObjectsCount.Insert(ObjectKind, Count+1);
		EndIf;
		
	EndDo;
	
	For Each MapRow In SelectedObjectsCount Do
		
		If MapRow.Value = ClassManagerByName(MapRow.Key).AllRefsType().Types().Count() Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

Function ClassManagerByName(MOClass)
	
	If      Upper(MOClass) = "EXCHANGEPLANS" Then
		Manager = ExchangePlans;
		
	ElsIf Upper(MOClass) = "CATALOGS" Then
		Manager = Catalogs;
		
	ElsIf Upper(MOClass) = "DOCUMENTS" Then
		Manager = Documents;
		
	ElsIf Upper(MOClass) = "DOCUMENTJOURNALS" Then
		Manager = DocumentJournals;
		
	ElsIf Upper(MOClass) = "ENUMS" Then
		Manager = Enums;
		
	ElsIf Upper(MOClass) = "CHARTSOFCHARACTERISTICTYPES" Then
		Manager = ChartsOfCharacteristicTypes;
		
	ElsIf Upper(MOClass) = "CHARTSOFACCOUNTS" Then
		Manager = ChartsOfAccounts;
		
	ElsIf Upper(MOClass) = "CHARTSOFCALCULATIONTYPES" Then
		Manager = ChartsOfCalculationTypes;
		
	ElsIf Upper(MOClass) = "BUSINESSPROCESSES" Then
		Manager = BusinessProcesses;
		
	ElsIf Upper(MOClass) = "TASKS" Then
		Manager = Tasks;
		
	EndIf;
	
	Return Manager;
	
EndFunction

Procedure UploadConfigurationToXML()
	
	If InfoBaseUsers.CurrentUser().PasswordIsSet Then
		Raise NStr("ru = 'Проверка возможна только для пользователя без пароля.';
								|en = 'Can check only for users without password.';");
	EndIf;
	
	DumpDirectory = GetTempFileName("CheckBeforeAssembly"); // ACC:441 - Temporary files are deleted by "ClearDirectoryForExport"
	BinDir = StandardSubsystemsServer.ClientParametersAtServer().Get("BinDir");
	CreateDirectory(DumpDirectory);
	
	ConnectionString = InfoBaseConnectionString();
	If DesignerIsOpen() Then
		If Common.FileInfobase() Then
			InfobaseDirectory = StringFunctionsClientServer.ParametersFromString(ConnectionString).file;
			FileCopy(InfobaseDirectory + "\1Cv8.1CD", DumpDirectory + "\1Cv8.1CD");
			ConnectionString = StringFunctionsClientServer.SubstituteParametersToString("File=""%1"";", DumpDirectory);
		Else
			Raise NStr("ru = 'Для проверки закройте конфигуратор.';
									|en = 'To check, close Designer.';");
		EndIf;
	EndIf;
	
	MessagesFileName = DumpDirectory + "\UploadConfigurationToFilesMessages.txt";
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(ConnectionString);
	StartupCommand.Add("/N");
	StartupCommand.Add(UserName());
	StartupCommand.Add("/P");
	StartupCommand.Add();
	StartupCommand.Add("/DumpConfigToFiles");
	StartupCommand.Add(DumpDirectory);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	If Result.ReturnCode <> 0 Then
		Try
			Text = New TextDocument;
			Text.Read(MessagesFileName);
			Messages = Text.GetText();
		Except
			Messages = "";
		EndTry;
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось выполнить выгрузку конфигурации в файлы по причине:
			           |%1';
						|en = 'Failed to import configuration to files due to:
						|%1';"), Messages);
	EndIf;
	
	ModulesExportDirectory = DumpDirectory;
	
EndProcedure

Procedure ClearDirectoryForExport()
	FilesArray = FindFiles(ModulesExportDirectory, "*", True);
	For Each File In FilesArray Do
		DeleteFiles(File.FullName);
	EndDo;
EndProcedure

Procedure GetCallBeginningAndEnd(TextString, SearchString, NewTextString, CallStart, CallEnd, KeyChar)
	
	CallStart = StrFind(TextString, SearchString);
	If CallStart = 0 Then
		SearchByFullName = False;
		Return;
	EndIf;
	
	KeyChar = Mid(TextString, CallStart-1,1);
	
	NewTextString = Right(TextString, StrLen(TextString) - CallStart + 1);
	If StrFind(SearchString, "Metadata.") > 0
		Or StrFind(SearchString, "PictureLib.") > 0
		Or StrFind(SearchString, "StyleColors.") > 0
		Or StrFind(SearchString, "StyleFonts.") > 0
		Or StrFind(SearchString, "SessionParameters.") > 0
		Or StrFind(SearchString, "Enums.") > 0
		Or SearchByFullName Then
		CallEnd = StrLen(SearchString);
	Else
		If StrEndsWith(SearchString, "[") Then
			CallEnd = StrFind(NewTextString, "]");
		Else
			CallEnd = StrFind(NewTextString, "(");
			CallEnd2 = StrFind(NewTextString, ".", , StrLen(SearchString) + 1);
			CallEnd3 = StrFind(NewTextString, Chars.LF, , StrLen(SearchString) + 1);
			CallEnd = Min(CallEnd, CallEnd2, CallEnd3);
		EndIf;
	EndIf;
	
	If SearchByFullName Then
		KeyChar = Mid(NewTextString, StrLen(SearchString)+1,1);
		SearchByFullName = False;
	EndIf;
	
	CharCode = CharCode(Mid(NewTextString, StrLen(SearchString)+1,1));
	If StrFind(SearchString, "PictureLib.") > 0
		And (CharCode >= 1040 And CharCode <= 1103
			Or CharCode >= 48 And CharCode <= 57) Then
		CallEnd = 0;
	EndIf;
	
EndProcedure

Function IsComment(TextString, CallStart, SearchByFullName = False)
	
	Indent = 1;
	While StrFind(Mid(TextString, CallStart-Indent, Indent), Chars.LF) = 0 Do
		Indent = Indent + 1;
	EndDo;
	
	If StrFind(Mid(TextString, CallStart-Indent, Indent), "//") > 0
		Or (Not SearchByFullName And StrFind(Mid(TextString, CallStart-Indent, Indent), "|") > 0) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function IsString(TextString, CallStart)
	
	Indent = 1;
	While StrFind(Mid(TextString, CallStart-Indent, Indent), Chars.LF) = 0 Do
		Indent = Indent + 1;
	EndDo;
	
	If StrFind(Mid(TextString, CallStart-Indent, Indent), "NStr") > 0
		And StrOccurrenceCount(Mid(TextString, CallStart-Indent, Indent), "'") <> 2 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Procedure CutOutDemoExamplesFromCode(TextString)
	
	EditingFlag = StrFind(TextString, "// _Demo begin example");
	While EditingFlag > 0 Do
		
		LastExampleCharPosition = StrFind(TextString, "// _Demo end example") + StrLen("// _Demo end example");
		TextString = Left(TextString,EditingFlag-1) + Mid(TextString,LastExampleCharPosition);
		EditingFlag = StrFind(TextString, "// _Demo begin example");
		
	EndDo;
	
EndProcedure

Procedure FillPropertiesKinds()
	
	PropertiesKinds = New Array;
	PropertiesKinds.Add("MetadataObject:");
	PropertiesKinds.Add("Properties:");
	PropertiesKinds.Add("Attributes:");
	PropertiesKinds.Add("AddressingAttributes:");
	PropertiesKinds.Add("TabularSections:");
	PropertiesKinds.Add("Commands:");
	PropertiesKinds.Add("Characteristics:");
	PropertiesKinds.Add("AccountingFlags:");
	PropertiesKinds.Add("ChartOfAccountsExtDimensionAccountingFlag:");
	PropertiesKinds.Add("Dimensions:");
	PropertiesKinds.Add("Resources:");
	
EndProcedure

Function NewBlockBeginning(StringText)
	
	If StrFind(StringText, "MetadataObject: ") > 0 Then
		Return True;
	Else
		Return PropertiesKinds.Find(StringText) <> Undefined;
	EndIf;
	
EndFunction

Procedure FillStartupParameters()
	
	IBAdministratorName = InfoBaseUsers.CurrentUser().Name;
	ConnectionString = InfoBaseConnectionString();
	IBDirectory = InfobaseDirectory(InfoBaseConnectionString());
	
	FileInforbaseFind = StrFind(ConnectionString, "File=");
	
	If FileInforbaseFind = 0 Then
		Common.MessageToUser(NStr("ru = 'Данный отчет предназначен для использования с файловой базой';
													|en = 'The report is intended to run in file infobases only';"));
	EndIf;
	
EndProcedure

Procedure ApplyExceptionsList()
	
	For Each ExceptionString In ExceptionsTable Do
		FilterParameters = New Structure();
		
		If ExceptionString.ObjectToExclude <> Undefined Then
			FilterParameters.Insert("CallingObject", ExceptionString.ObjectToExclude);
			FoundRows = LinksBetweenSubsystemsObjects.FindRows(FilterParameters);
		Else
			FilterParameters.Insert("CallingSubsystem", ExceptionString.CallingSubsystem);
			FilterParameters.Insert("SubsystemToCall", ExceptionString.SubsystemToCall);
			FilterParameters.Insert("CallingObject", ExceptionString.CallingObject);
			FoundRows = LinksBetweenSubsystemsObjects.FindRows(FilterParameters);
		EndIf;
		
		For Each FoundRow In FoundRows Do
			LinksBetweenSubsystemsObjects.Delete(FoundRow);
		EndDo;
		
	EndDo;
	
EndProcedure

Function LineNumber(TextString, CallStart, LineNumber)
	
	LineNumber = LineNumber + StrOccurrenceCount(Left(TextString, CallStart), Chars.LF) + ?(LineNumber = 0, 1, 0);
	
	Return LineNumber;
	
EndFunction

Procedure FillObjectsToCheckStandaloneStatus()
	
	ObjectsToCheckStandaloneStatus = New Array;
	
	SpreadsheetDocument = Reports.SubsystemsDependencies.GetTemplate("StandaloneDataProcessors");
	
	AreaName = Undefined;
	LineNumber   = 1;
	
	While AreaName <> "DocumentEnd" Do
		
		Area = SpreadsheetDocument.Area(LineNumber, 0);
		AreaName = Area.Name;
		StringText = Area.Text;
		If IsBlankString(StringText)
			Or AreaName = "Header"
			Or AreaName = "DocumentEnd" Then
			LineNumber = LineNumber + 1;
			Continue;
		EndIf;
		
		ObjectsToCheckStandaloneStatus.Add(StringText);
		
		LineNumber = LineNumber + 1;
		
	EndDo;
	
EndProcedure

// Check whether the report can be generated.

Function DesignerIsOpen()
	Sessions = GetInfoBaseSessions();
	For Each Session In Sessions Do
		If Upper(Session.ApplicationName) = "DESIGNER" Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

Function FullNameByModuleName(FullPathWithName, FileNameWithExtension)
	FormPath = StrReplace(FullPathWithName, ModulesExportDirectory + GetPathSeparator(), "");
	ModuleNameByParts = StrSplit(FormPath, GetPathSeparator(), False);
	
	FullObjectName = "";
	FullModuleName  = "";
	Step = 0;
	For Each PathPart In ModuleNameByParts Do
		Step = Step + 1;
		If Upper(PathPart) = "EXT" Then
			Continue;
		EndIf;
		
		If PathPart = FileNameWithExtension Then
			PathPart = StrSplit(PathPart, ".")[0];
		EndIf;
		
		TransformedPathPart = EnglishAndNationalNamesMap()[PathPart];
		If TransformedPathPart = Undefined Then
			TransformedPathPart = PathPart;
		EndIf;
		
		If Step < 3 Then
			FullObjectName = ?(FullObjectName = "",
				                 TransformedPathPart,
				                 FullObjectName + "." + TransformedPathPart);
		EndIf;
		
		FullModuleName = ?(FullModuleName = "",
			                 TransformedPathPart,
			                 FullModuleName + "." + TransformedPathPart);
	EndDo;
	
	Result = New Structure;
	Result.Insert("FullObjectName", FullObjectName);
	Result.Insert("FullModuleName", FullModuleName);
	
	Return Result;
EndFunction

Function EnglishAndNationalNamesMap()
	Result = New Map;
	
	// Metadata object kinds.
	Result.Insert("AccountingRegister", "AccountingRegister");
	Result.Insert("AccumulationRegister", "AccumulationRegister");
	Result.Insert("BusinessProcess", "BusinessProcess");
	Result.Insert("CalculationRegister", "CalculationRegister");
	Result.Insert("Catalog", "Catalog");
	Result.Insert("ChartOfAccounts", "ChartOfAccounts");
	Result.Insert("ChartOfCalculationTypes", "ChartOfCalculationTypes");
	Result.Insert("ChartOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	Result.Insert("CommandGroup", "CommandGroup");
	Result.Insert("CommonAttribute", "CommonAttribute");
	Result.Insert("CommonCommand", "CommonCommand");
	Result.Insert("CommonForm", "CommonForm");
	Result.Insert("CommonModule", "CommonModule");
	Result.Insert("CommonPicture", "CommonPicture");
	Result.Insert("CommonTemplate", "CommonTemplate");
	Result.Insert("Configuration", "Configuration");
	Result.Insert("Constant", "Constant");
	Result.Insert("DataProcessor", "DataProcessor");
	Result.Insert("DefinedType", "DefinedType");
	Result.Insert("Document", "Document");
	Result.Insert("DocumentJournal", "DocumentJournal");
	Result.Insert("DocumentNumerator", "DocumentNumerator");
	Result.Insert("Enum", "Enum");
	Result.Insert("EventSubscription", "EventSubscription");
	Result.Insert("ExchangePlan", "ExchangePlan");
	Result.Insert("FilterCriterion", "FilterCriterion");
	Result.Insert("FunctionalOption", "FunctionalOption");
	Result.Insert("FunctionalOptionsParameter", "FunctionalOptionsParameter");
	Result.Insert("InformationRegister", "InformationRegister");
	Result.Insert("Language", "Language");
	Result.Insert("Report", "Report");
	Result.Insert("Role", "Role");
	Result.Insert("ScheduledJob", "ScheduledJob");
	Result.Insert("Sequence", "Sequence");
	Result.Insert("SessionParameter", "SessionParameter");
	Result.Insert("SettingsStorage", "SettingsStorage");
	Result.Insert("Style", "Style");
	Result.Insert("StyleItem", "StyleItem");
	Result.Insert("Subsystem", "Subsystem");
	Result.Insert("Task", "Task");
	Result.Insert("WebService", "WebService");
	Result.Insert("WSReference", "WSReference");
	Result.Insert("XDTOPackage", "XDTOPackage");
	
	// Metadata object kinds (plural form).
	Result.Insert("AccountingRegisters", "AccountingRegister");
	Result.Insert("AccumulationRegisters", "AccumulationRegister");
	Result.Insert("BusinessProcesses", "BusinessProcess");
	Result.Insert("CalculationRegisters", "CalculationRegister");
	Result.Insert("Catalogs", "Catalog");
	Result.Insert("ChartsOfAccounts", "ChartOfAccounts");
	Result.Insert("ChartsOfCalculationTypes", "ChartOfCalculationTypes");
	Result.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	Result.Insert("CommandGroups", "CommandGroup");
	Result.Insert("CommonAttributes", "CommonAttribute");
	Result.Insert("CommonCommands", "CommonCommand");
	Result.Insert("CommonForms", "CommonForm");
	Result.Insert("CommonModules", "CommonModule");
	Result.Insert("CommonPictures", "CommonPicture");
	Result.Insert("CommonTemplates", "CommonTemplate");
	Result.Insert("Configurations", "Configuration"); // Obsolete.
	Result.Insert("Constants", "Constant");
	Result.Insert("DataProcessors", "DataProcessor");
	Result.Insert("DefinedTypes", "DefinedType");
	Result.Insert("Documents", "Document");
	Result.Insert("DocumentJournals", "DocumentJournal");
	Result.Insert("DocumentNumerator", "DocumentNumerator");
	Result.Insert("Enums", "Enum");
	Result.Insert("EventSubscriptions", "EventSubscription");
	Result.Insert("ExchangePlans", "ExchangePlan");
	Result.Insert("FilterCriteria", "FilterCriterion");
	Result.Insert("FunctionalOptions", "FunctionalOption");
	Result.Insert("FunctionalOptionsParameters", "FunctionalOptionsParameter");
	Result.Insert("InformationRegisters", "InformationRegister");
	Result.Insert("Languages", "Language");
	Result.Insert("Reports", "Report");
	Result.Insert("Roles", "Role");
	Result.Insert("ScheduledJobs", "ScheduledJob");
	Result.Insert("Sequences", "Sequence");
	Result.Insert("SessionParameters", "SessionParameter");
	Result.Insert("SettingsStorages", "SettingsStorage");
	Result.Insert("Style", "Style");
	Result.Insert("StyleItems", "StyleItem");
	Result.Insert("Subsystems", "Subsystem");
	Result.Insert("Tasks", "Task");
	Result.Insert("WebServices", "WebService");
	Result.Insert("WSReference", "WSReference");
	Result.Insert("XDTOPackages", "XDTOPackage");
	
	// Types of nested metadata objects.
	Result.Insert("Module", "Module");
	Result.Insert("ManagerModule", "ManagerModule");
	Result.Insert("ObjectModule", "ObjectModule");
	Result.Insert("CommandModule", "CommandModule");
	Result.Insert("RecordSetModule", "RecordSetModule");
	Result.Insert("ValueManagerModule", "ValueManagerModule");
	
	Result.Insert("ExternalConnectionModule", "ExternalConnectionModule");
	Result.Insert("ManagedApplicationModule", "ManagedApplicationModule");
	Result.Insert("OrdinaryApplicationModule", "OrdinaryApplicationModule");
	Result.Insert("SessionModule", "SessionModule");
	
	Result.Insert("Help", "Help");
	Result.Insert("Form", "Form");
	Result.Insert("Flowchart", "Flowchart");
	Result.Insert("Picture", "Picture");
	Result.Insert("CommandInterface", "CommandInterface");
	
	Result.Insert("Template", "Template");
	Result.Insert("Command", "Command");
	Result.Insert("Aggregates", "Aggregates");
	Result.Insert("Recalculation", "Recalculation");
	Result.Insert("Predefined", "Predefined");
	Result.Insert("Content", "Content");
	Result.Insert("Rights", "Rights");
	Result.Insert("Schedule", "Schedule");
	
	// Types of nested metadata objects (plural form).
	Result.Insert("Module", "Module");
	Result.Insert("ManagerModule", "ManagerModule");
	Result.Insert("ObjectModule", "ObjectModule");
	Result.Insert("CommandModule", "CommandModule");
	Result.Insert("RecordSetModule", "RecordSetModule");
	Result.Insert("ValueManagerModule", "ValueManagerModule");
	
	Result.Insert("ExternalConnectionModule", "ExternalConnectionModule");
	Result.Insert("ManagedApplicationModule", "ManagedApplicationModule");
	Result.Insert("OrdinaryApplicationModule", "OrdinaryApplicationModule");
	Result.Insert("SessionModule", "SessionModule");
	
	Result.Insert("Help", "Help");
	Result.Insert("Forms", "Form");
	Result.Insert("Flowchart", "Flowchart");
	Result.Insert("Picture", "Picture");
	Result.Insert("CommandInterface", "CommandInterface");
	
	Result.Insert("Templates", "Template");
	Result.Insert("Commands", "Command");
	Result.Insert("Aggregates", "Aggregates");
	Result.Insert("Recalculations", "Recalculation");
	Result.Insert("Predefined", "Predefined");
	Result.Insert("Content", "Content");
	Result.Insert("Rights", "Rights");
	Result.Insert("Schedule", "Schedule");
	
	Return Result;
EndFunction

// Returns:
//   ValueTable:
//   * CallingSubsystem 
//   * CallingObject 
//   * SubsystemToCall 
//   * ObjectToCall 
//   * Call_Position 
//
Function ExecuteTableCreation()
	
	LinksBetweenSubsystemsObjects = New ValueTable;
	LinksBetweenSubsystemsObjects.Columns.Add("CallingSubsystem");
	LinksBetweenSubsystemsObjects.Columns.Add("CallingObject");
	LinksBetweenSubsystemsObjects.Columns.Add("SubsystemToCall");
	LinksBetweenSubsystemsObjects.Columns.Add("ObjectToCall");
	LinksBetweenSubsystemsObjects.Columns.Add("Call_Position");
	Return LinksBetweenSubsystemsObjects;
	
EndFunction

Function GetCallSearchStructure(TextString, CallingSubsystem, CallingSubsystemRow, ObjectBelongingToSubsystem,
	StandaloneObjectCheck, FullCallingObjectName, AttributeName = Undefined)
	
	CallsSearchStructure = New Structure;
	CallsSearchStructure.Insert("TextString",						TextString);
	CallsSearchStructure.Insert("CallingSubsystem",				CallingSubsystem);
	CallsSearchStructure.Insert("CallingSubsystemRow",		CallingSubsystemRow);
	CallsSearchStructure.Insert("ObjectBelongingToSubsystem",	ObjectBelongingToSubsystem);
	CallsSearchStructure.Insert("StandaloneObjectCheck",		StandaloneObjectCheck);
	CallsSearchStructure.Insert("FullCallingObjectName",		FullCallingObjectName);
	CallsSearchStructure.Insert("AttributeName",						AttributeName);
	
	Return CallsSearchStructure;
	
EndFunction

#Region DOMManagement

Function GetTableWithQueriesFromDynamicLists(FullFileName)
	
	QueryTextsTable = New ValueTable;
	QueryTextsTable.Columns.Add("Attribute");
	QueryTextsTable.Columns.Add("QueryText");
	
	SearchExpressionsArray = New Array;
	SearchExpressionsArray.Add("//xmlns:Attributes/xmlns:Attribute/xmlns:Settings/xmlns:QueryText");
	
	DOMDocument = DOMDocument(FullFileName);
	
	For Each ExpressionForSearch In SearchExpressionsArray Do
		
		XPathResult = EvaluateXPathExpression(ExpressionForSearch, DOMDocument);
		While True Do
			
			DOMElementQueryText = XPathResult.IterateNext();
			If DOMElementQueryText = Undefined Then
				Break;
			EndIf;
			
			QueryText = DOMElementQueryText.TextContent;
			If IsBlankString(QueryText) Then
				Continue;
			EndIf;
			
			QueryTableNewRow = QueryTextsTable.Add();
			QueryTableNewRow.Attribute = "";
			QueryTableNewRow.QueryText = QueryText;
			
			DOMElementSettings = DOMElementQueryText.ParentNode;
			If DOMElementSettings = Undefined Then
				Continue;
			EndIf;
			
			DOMElementAttribute = DOMElementSettings.ParentNode;
			If DOMElementAttribute = Undefined Then
				Continue;
			EndIf;
			
			QueryTableNewRow.Attribute = GetElementName(DOMDocument, DOMElementAttribute);
			
		EndDo;
		
	EndDo;
	
	Return QueryTextsTable;
	
EndFunction

Function DOMDocument(PathToFile)
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(PathToFile);
	
	DOMBuilder = New DOMBuilder;
	DOMDocument = DOMBuilder.Read(XMLReader);
	
	XMLReader.Close();
	
	Return DOMDocument;
	
EndFunction

Function EvaluateXPathExpression(Expression, DOMDocument, DOMElement = Undefined)
	
	Dereferencer = DOMDocument.CreateNSResolver();
	ContextNode = ?(DOMElement = Undefined, DOMDocument, DOMElement);
	Try
		XPathResult = DOMDocument.EvaluateXPathExpression(Expression, ContextNode, Dereferencer);
	Except
		XPathResult = Undefined;
	EndTry;
	
	Return XPathResult;
	
EndFunction

Function GetDOMElementByXPathExpression(Expression, DOMDocument, DOMElement = Undefined)
	
	XPathResult = EvaluateXPathExpression(Expression, DOMDocument, DOMElement);
	Return XPathResult.IterateNext();
	
EndFunction

Function GetDOMElementValueByXPathExpression(Expression, DOMDocument, DOMElement = Undefined, DefaultValue = "")
	
	DOMElementResult = GetDOMElementByXPathExpression(Expression, DOMDocument, DOMElement);
	
	// If there's no such expression, return the default value.
	If DOMElementResult = Undefined Then
		Return DefaultValue;
	EndIf;
	
	Return DOMElementResult.TextContent;
	
EndFunction

Function GetElementName(DOMDocument, DOMElement, Prefix = "xmlns", GetNameFrom = "Attribute")
	
	Name = "";
	If GetNameFrom = "Attribute" Then
		Name = DOMElement.GetAttribute("name");
	ElsIf GetNameFrom = "Node" Then
		Name = GetDOMElementValueByXPathExpression(Prefix + ":Name", DOMDocument, DOMElement);
	EndIf;
	
	Return String(Name);
	
EndFunction

#EndRegion

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf