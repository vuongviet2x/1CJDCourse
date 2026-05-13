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
	
	DataProcessorObject    = DataProcessorObject2();
	Object.PathToForms = DataProcessorObject.Metadata().FullName() + ".Form";
	
	// Read transfer parameters.
	TransferParameters = GetFromTempStorage(Parameters.StorageAddress); // See DataProcessorObject.QueryConsole.PutQueriesInTempStorage
	Object.Queries.Load(TransferParameters.Queries);	
	Object.Parameters.Load(TransferParameters.Parameters);
	Object.FileName = TransferParameters.FileName;
	CurrentQueryID = TransferParameters.CurrentQueryID;
	CurrentParameterID = TransferParameters.CurrentParameterID;
	
	Try   // In case a form is opened not from the main form.
		PointInTime = ValueFromStringInternal(Parameters.Value);
		Date          = PointInTime.Date;
		Ref        = PointInTime.Ref;
	Except
		FillValues();
	EndTry;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteAndClose(Command)
	ExportPointInTimeServer();
EndProcedure

#EndRegion

#Region Private

&AtServer
Function DataProcessorObject2()
	Return FormAttributeToValue("Object");
EndFunction

&AtClient
Procedure ExportPointInTimeServer()
	Owner			= FormOwner;
	OwnerFormName 	= Owner.FormName;
	MainFormName 	= Object.PathToForms + ".Form";
	
	If  OwnerFormName = MainFormName Then 
		TransferParameters = PutQueriesInStructure(CurrentQueryID, CurrentParameterID);
		Close(); 
		Owner.Modified = True;
		Notify("ExportQueriesToAttributes", TransferParameters);
	Else
		PointInTimePresentation = "";
		InternalTimeMoment = InternalValueOfPointInTime(PointInTimePresentation);
		Close();
		TransferParameters = New Structure("InternalTimeMoment, PointInTimePresentation",
			InternalTimeMoment, PointInTimePresentation);
		Notify("GetPointInTime", TransferParameters);
	EndIf;	
EndProcedure	

&AtServer
Function PutQueriesInStructure(QueryID, ParameterId)
	FormParameters = Object.Parameters;
	
	PointInTimePresentation = "";
	For Each Page1 In FormParameters Do
		If Page1.Id = CurrentParameterID Then
			Page1.Type		 		= "PointInTime";
			Page1.Value 		= InternalValueOfPointInTime(PointInTimePresentation);
			Page1.TypeInForm		= NStr("ru = 'Момент времени';
										|en = 'Point in time';");
			Page1.ValueInForm	= PointInTimePresentation;
		EndIf;
	EndDo;
		
	TransferParameters = New Structure;
	TransferParameters.Insert("StorageAddress", DataProcessorObject2().PutQueriesInTempStorage(Object,QueryID,ParameterId));
	Return TransferParameters;
EndFunction	

&AtServer
Function InternalValueOfPointInTime(Presentation)
	PointInTime = New PointInTime(Date, Ref);	
	Presentation = DataProcessorObject2().GenerateValuePresentation(PointInTime);
	
	Return ValueToStringInternal(PointInTime);
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
	
	PointInTime = ValueFromStringInternal(Value);
	If TypeOf(PointInTime) <> Type("PointInTime") Then 
		Return;
	EndIf;
	
	Date 	= PointInTime.Date;
	Ref 	= PointInTime.Ref;
EndProcedure	

#EndRegion
