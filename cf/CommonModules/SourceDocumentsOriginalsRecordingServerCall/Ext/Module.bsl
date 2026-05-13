///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// Called to record original states of print forms to the register after printing the form.
//
//	Parameters:
//  PrintObjects - ValueList - a list of references to print objects.
//  PrintList - ValueList - a list with template names and print form presentations.
//   Written1 - Boolean - indicates that the document state is written to the register.
//
Procedure WriteOriginalsStatesAfterPrint(PrintObjects, PrintList, Written1 = False) Export

	If GetFunctionalOption("UseSourceDocumentsOriginalsRecording") And Not Users.IsExternalUserSession() Then
		SourceDocumentsOriginalsRecording.WhenDeterminingTheListOfPrintedForms(PrintObjects, PrintList);
		If PrintList.Count() = 0 Then
			Return;
		EndIf;
		InformationRegisters.SourceDocumentsOriginalsStates.WriteDocumentOriginalsStatesAfterPrintForm(PrintObjects, PrintList, Written1);
	EndIf;

EndProcedure

#EndRegion

#Region Private

// Saves the new state of a source document.
//	
// Parameters:
//  RecordData - Array of Structure - Information on the current document state:
//                 * OverallState 						- Boolean - True if the current state is overall;
//                 * Ref 								- DocumentRef - A reference to the document whose source document's state should be changed.
//                 * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates -
//                                                           a current state of the source document original.
//                 * SourceDocument 					- String - a source document ID. It is specified if this state is not overall;
//                 * FromOutside 								- Boolean - True if the source document was added by the user manually. Specified if this state is not overall. 
//               - DocumentRef - A reference to the document whose source document's state should be changed.
//  StateName - String - The state to be applied.
// 
// Returns:
//  String - "IsChanged" is the source document state is not repeated and was saved.
//           "NotIsChanged" 
//           "NotCarriedOut" 
//
Function SetNewOriginalState(Val RecordData, Val StateName) Export

	Return SourceDocumentsOriginalsRecording.SetNewOriginalState(RecordData, StateName);

EndFunction

// Returns a reference to the document by the spreadsheet document barcode
//
// Parameters:
//  Barcode - String - the scanned document barcode.
//
Procedure ProcessBarcode(Barcode) Export
	
	SourceDocumentsOriginalsRecording.ProcessBarcode(Barcode);

EndProcedure

// Returns a structure with data on the current overall state of the document original by reference.
//
//	Parameters:
//  DocumentRef - DocumentRef - a reference to the document whose overall state details must be received. 
//
//  Returns:
//    Structure - General information about the source document state:
//    * Ref - DocumentRef - document reference;
//    * SourceDocumentOriginalState - CatalogRef.SourceDocumentsOriginalsStates - the current
//        state of a document original.
//
Function OriginalStateInfoByRef(DocumentRef) Export

	Return SourceDocumentsOriginalsRecording.OriginalStateInfoByRef(DocumentRef);
	
EndFunction

// Fills in the drop-down choice list of states on the form.
// 
//	Parameters:
//  OriginalStatesChoiceList - ValueList - original states available to users and used when
//                                                    changing the original state.
//
Procedure FillOriginalStatesChoiceList(OriginalStatesChoiceList) Export
	
	OriginalStatesChoiceList.Clear();
	OriginalsStates = SourceDocumentsOriginalsRecording.UsedStates();
	
	For Each State In OriginalsStates Do

		If State.Ref = Catalogs.SourceDocumentsOriginalsStates.OriginalReceived Then 
			OriginalStatesChoiceList.Add(State.Description,,,PictureLib.SourceDocumentOriginalStateOriginalReceived);
		ElsIf State.Ref = Catalogs.SourceDocumentsOriginalsStates.FormPrinted Then
			OriginalStatesChoiceList.Add(State.Description,,,PictureLib.SourceDocumentOriginalStateOriginalNotReceived);
		Else
			OriginalStatesChoiceList.Add(State.Description);
		EndIf;

	EndDo;
EndProcedure

// Checks and returns a flag indicating whether the document by reference is a document with originals recording.
//
//	Parameters:
//  ObjectRef - DocumentRef - a reference to the document to be checked.
//
//	Returns:
//  Boolean - True if the document is an object with originals recording.
//
Function IsAccountingObject(ObjectRef) Export
	
	Return SourceDocumentsOriginalsRecording.IsAccountingObject(ObjectRef);

EndFunction

// Returns a record key of the register of overall document original state by reference.
//
//	Parameters:
//  DocumentRef - DocumentRef - a reference to the document for which a record key of overall state must be received.
//
//	Returns:
//  InformationRegisterRecordKey.SourceDocumentsOriginalsStates - a record key of the register of overall document original state.
//
Function OverallStateRecordKey(DocumentRef) Export

	Return SourceDocumentsOriginalsRecording.OverallStateRecordKey(DocumentRef);

EndFunction

#EndRegion
