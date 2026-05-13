///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.ClassifiersOperations" subsystem.
// CommonModule.ClassifiersOperationsOverridable.
//
// Server overridable procedures for importing classifiers:
//  - Determine the IDs of autoupdated classifiers
//  - Determine classifier file processing algorithms
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// The list and settings of classifiers whose updates need
// to be imported from the classifier service, are overridden. To get an ID,
// translate
// into English a description of the metadata object whose data is planned to be updated. When translating, it is recommended that you use professional
// text translation applications or make use of translator services, since
// if semantic errors in the ID are detected, it is required to create a new classifier
// and change the configuration code.
//
// Parameters:
//  Classifiers  - Array of Structure - contains classifier import settings.
//                    For the composition of settings, see the ClassifiersOperations.ClassifierDetails function.
//
// Example:
//	Specifier = ClassifiersOperations.ClassifierDetails();
//	Specifier.Description = NStr("en = 'Refinancing rates'");
//	Specifier.ID = "CentralBankRefinancingRate";
//	Specifier.AutoUpdate = True;
//	Specifier.SharedData = True;
//	Specifier.SaveFileToCache = False;
//	Specifier.SharedDataProcessing = False;
//	Classifiers.Add(Specifier);
//
//@skip-warning
Procedure OnAddClassifiers(Classifiers) Export
	
	
EndProcedure

// Classifier version number, which was imported to the infobase, is overridden.
// When you start using the ClassifiersOperations subsystem or when connecting a new
// classifier to the service, it is unknown which classifier version number is imported to the infobase.
// That is why upon data update iteration, the data will be reimported from the service.
// To avoid reimport, specify the initial version number.
// The method will be called upon an attempt to import a version of the classifier whose
// version equals to 0.
//
// Parameters:
//  Id        - String - FileAddress - String - a file address in a temporary storage.
//                         It is defined in the OnAddClassifiers procedure.
//  InitialVersionNumber - Number - version number of an imported classifier.
//
// Example:
//	If ID = "CentralBankRefinancingRate" Then
//		InitialVersionNumber = InformationRegisters.RefinancingRates.ImportedVersionNumber();
//	EndIf;
//
//@skip-warning
Procedure OnDefineInitialClassifierVersionNumber(Id, InitialVersionNumber) Export
	
	
EndProcedure

// Algorithms of processing the file imported
// from the classifier service are overridden. You cannot delete temporary storage
// after processing the file, because it will be saved to
// cache for the subsequent use if it is necessary.
//
// Parameters:
//  Id           - String - FileAddress - String - a file address in a temporary storage.
//                            It is defined in the OnAddClassifiers procedure.
//  Version                  - Number - a number of the imported version.
//  Address                   - String - binary data address of an update file in
//                            a temporary storage.
//  Processed               - Boolean - if False, errors occurred when processing the update file
//                            and it needs to be imported again.
//  AdditionalParameters - Structure - contains additional processing parameters.
//                            Use it to pass values to the
//                            ClassifiersOperationsSaaSOverridable.OnProcessDataArea overridable method
//                            and the OSLSubsystemsIntegration.OnProcessDataArea method.
// Example:
//	If ID = "CentralBankRefinancingRate" Then
//		Processed = InformationRegisters.RefinancingRates.UpdateRegisterDataFromFile(Address, AdditionalParameters);
//	EndIf;
//
//@skip-warning
Procedure OnImportClassifier(Id, Version, Address, Processed, AdditionalParameters) Export
	
	
EndProcedure

// Overrides custom classifier update settings.
//
// Parameters:
//  Settings - Structure:
//    * DisableNotifications - Boolean - If True, the notification on enabling auto-download of classifiers will be disabled in the ToDoList subsystem
//        and the user will not be notified if the ToDoList subsystem is not integrated in the configuration on startup.
//        @skip-warning
//
//
Procedure OnDefineUserSettings(Settings) Export
	
EndProcedure

#EndRegion
