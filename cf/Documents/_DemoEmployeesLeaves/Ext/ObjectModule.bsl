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

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	For Each EmployeeString In Employees_ Do
		
		If Not ValueIsFilled(EmployeeString.StartDate)
				Or Not ValueIsFilled(EmployeeString.EndDate) Then
			
			If Not ValueIsFilled(EmployeeString.StartDate)
				And Not ValueIsFilled(EmployeeString.EndDate) Then
			
				MessageText= NStr("ru = 'По сотруднику %1 не задан период отпуска';
									|en = 'Leave period is not specified for the %1 employee';");
				AttributeName = "StartDate";
				
			Else
				
				MessageText = NStr("ru = 'По сотруднику %1 неверно задан период отпуска';
										|en = 'Leave period is incorrect for the %1 employee';");
				If Not ValueIsFilled(EmployeeString.StartDate) Then
					AttributeName = "StartDate";
				Else
					AttributeName = "EndDate";
				EndIf;
					
			EndIf;
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, EmployeeString.Employee);
			
			Common.MessageToUser(
				MessageText,
				,
				"Employees_[" + (EmployeeString.LineNumber - 1) + "]." + AttributeName,
				"Object",
				Cancel);
	
		EndIf; 
		
	EndDo;
	     	
			
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If FillingData = Undefined Then // Create a new item.
		_DemoStandardSubsystems.OnEnterNewItemFillCompany(ThisObject);
	EndIf;
	
	If TypeOf(FillingData) = Type("DocumentRef._DemoEmployeesLeaves") Then
		AttributesValues = Common.ObjectAttributesValues(FillingData, "Organization, Employees_");
		Organization = AttributesValues.Organization; 
		TSEmployees_ = AttributesValues.Employees_;
		EmployeeResponsible = Users.CurrentUser();
		For Each StringEmployees In TSEmployees_ Do
			NewRow = Employees_.Add();
			FillPropertyValues(NewRow, StringEmployees);
		EndDo;
	EndIf;
		
EndProcedure

Procedure Posting(Cancel, PostingMode)
		
	GenerateRegisterRecordsToDocumentsRegistry();
	
EndProcedure

#EndRegion

#Region Private

Procedure GenerateRegisterRecordsToDocumentsRegistry()
	
	Movement = InformationRegisters._DemoDocumentsRegistry.CreateRecordManager();
	Movement.RefType = Common.MetadataObjectID(Ref.Metadata());
	Movement.Organization = Organization;
	Movement.IBDocumentDate = Date;
	Movement.Ref = Ref;
	Movement.IBDocumentNumber = Number;
	Movement.EmployeeResponsible = EmployeeResponsible;
	Movement.Comment = Comment;
	Movement.Posted = True;
	Movement.DeletionMark = False;
	Movement.SourceDocumentDate = Date;
	Movement.SourceDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Number, True, True) ;
	Movement.RecordingInAccountingDate = Date;
	Movement.Write();
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf