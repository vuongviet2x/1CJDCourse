///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	DataProcessorObject 			= DataProcessorObject2();
	Object.AvailableDataTypes	= DataProcessorObject.Metadata().Attributes.AvailableDataTypes.Type;
	Object.PathToForms 			= DataProcessorObject.Metadata().FullName() + ".Form";
	
	Items.BoundaryType.ChoiceList.Add("Including");
	Items.BoundaryType.ChoiceList.Add("Excluding");
	FormBorderKind = Items.BoundaryType.ChoiceList.Get(0).Value;
	
	// Get a list of types and filter it.
	TypesList = DataProcessorObject2().GenerateListOfTypes();
	DataProcessorObject2().TypesListFiltering(TypesList, "Boundary");
	
	// Read transfer parameters.
	TransferParameters 	= GetFromTempStorage(Parameters.StorageAddress); // See DataProcessorObject.QueryConsole.PutQueriesInTempStorage
	Object.Queries.Load(TransferParameters.Queries);	
	Object.Parameters.Load(TransferParameters.Parameters);
	Object.FileName 	= TransferParameters.FileName;
	CurrentQueryID 	= TransferParameters.CurrentQueryID;
	CurrentParameterID	= TransferParameters.CurrentParameterID;
	
	FillValues();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	If EventName = "GetPointInTime" Then 
		GetPointInTime(Parameter);
	EndIf;	
EndProcedure

///////////////////////////////////////////////////////////////////////////
// FORM ITEM EVENT HANDLERS

&AtClient
Procedure TypeStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	NotifyDescription = New NotifyDescription("TypeSelectionCompletion", ThisObject);
	TypesList.ShowChooseItem(NotifyDescription, NStr("ru = 'Выбрать тип';
																|en = 'Choose type';"));
	
EndProcedure

&AtClient
Procedure TypeSelectionCompletion(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement <> Undefined Then
		
		Current_Type = SelectedElement;
		TypeName    = Current_Type.Value;
		Type        = Current_Type.Presentation;
		
		If TypeName = "PointInTime" Then 
			
			Value       = Type;
			ValueInForm = Type;
			
		Else
			
			Array = New Array;
			Array.Add(Type(TypeName));
			LongDesc = New TypeDescription(Array);
			
			ValueInForm = LongDesc.AdjustValue(TypeName);
			Value       = LongDesc.AdjustValue(TypeName);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueInFormStartChoice(Item, ChoiceData, StandardProcessing)

	QueriesToPass = QueriesPassing();
	QueriesToPass.Insert("Value",Value);
	
	If TypeName = "PointInTime"  Then
		Path = Object.PathToForms + "." + "PointInTime";
		OpenForm(Path, QueriesToPass, ThisObject);
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueInFormOnChange(Item)
	ChangeValueInForm();
EndProcedure

///////////////////////////////////////////////////////////////////////////
// COMMANDS

&AtClient
Procedure WriteBorder(Command)
	ExportBorderServer();
EndProcedure

///////////////////////////////////////////////////////////////////////////
// AUXILIARY PROCEDURES AND FUNCTIONS

&AtServer
Function DataProcessorObject2()
	Return FormAttributeToValue("Object");
EndFunction

// Pass tables "Queries" and "Parameters" as a structure.
//
&AtServer
Function QueriesPassing()
	StorageAddress		= DataProcessorObject2().PutQueriesInTempStorage(Object, CurrentQueryID,CurrentParameterID);
	AddressParameter		= New Structure;
	AddressParameter.Insert("StorageAddress", StorageAddress);
	Return AddressParameter;
EndFunction

&AtServer
Procedure GetPointInTime(StructureOfPassing)
	Value  		= StructureOfPassing.InternalTimeMoment;
	ValueInForm	= StructureOfPassing.PointInTimePresentation;
EndProcedure	

&AtClient
Procedure ExportBorderServer()
	
	TransferParameters = PutQueriesInStructure(CurrentQueryID, CurrentParameterID);
	Notify("GettingBorder", TransferParameters);
	Close(TransferParameters);
	 
	Owner 					= FormOwner;
	Owner.Modified = True;
	
EndProcedure	

&AtServer
Function BorderObjectInnerValue()
	TypeOfGran	= DataProcessorObject2().BorderKindDefinition(FormBorderKind);
	FormBorder 	= New Boundary(ValueFromStringInternal(Value),TypeOfGran);
	
	Return ValueToStringInternal(FormBorder);
EndFunction

&AtServer
Function PutQueriesInStructure(QueryID, ParameterId)
	FormParameters 	= Object.Parameters;
	
	BorderPresentation = GenerateBorder();
	
	For Each Page1 In FormParameters Do
		If Page1.Id = CurrentParameterID Then
			Page1.Type		 		= "Boundary";
			Page1.Value 		= BorderObjectInnerValue();
			Page1.TypeInForm		= NStr("ru = 'Граница';
										|en = 'Border';");
			Page1.ValueInForm	= BorderPresentation;
		EndIf;
	EndDo;
	
	TransferParameters = New Structure;
	TransferParameters.Insert("StorageAddress", DataProcessorObject2().PutQueriesInTempStorage(Object,QueryID,ParameterId));
	Return TransferParameters;
EndFunction	

&AtServer
Procedure FillValues()
	FormParameters = Object.Parameters;
	For Each CurrentParameter In FormParameters Do
		If CurrentParameter.Id = CurrentParameterID Then
			Value = CurrentParameter.Value;
			If IsBlankString(Value) Then
				Return;
			Else
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Boundary = ValueFromStringInternal(Value);
	If TypeOf(Boundary) <> Type("Boundary") Then
		Return;
	EndIf;
	
	ImportedValue = Boundary.Value;
	TypeName = DataProcessorObject2().TypeNameFromValue(ImportedValue);
	Type = TypesList.FindByValue(TypeName).Presentation;
	If StrCompare(TypeName, "PointInTime") <> 0 Then
		ValueInForm = ImportedValue;
	Else
		ValueInForm = DataProcessorObject2().GenerateValuePresentation(ImportedValue);
	EndIf;
	Value = ValueToStringInternal(ImportedValue);
	
	If Boundary.BoundaryType = BoundaryType.Including Then
		FormBorderKind = Items.BoundaryType.ChoiceList.Get(0).Value;
	Else
		FormBorderKind = Items.BoundaryType.ChoiceList.Get(1).Value;
	EndIf;
EndProcedure

&AtServer
Function GenerateBorder()
	TypeOfGran	= DataProcessorObject2().BorderKindDefinition(FormBorderKind);
	FormBorder 	= New Boundary(ValueFromStringInternal(Value),TypeOfGran);
	
	Presentation = DataProcessorObject2().GenerateValuePresentation(FormBorder);
	
	Return Presentation;
EndFunction	

&AtServer
Procedure ChangeValueInForm()
	Value = ValueToStringInternal(ValueInForm);
EndProcedure	

#EndRegion
