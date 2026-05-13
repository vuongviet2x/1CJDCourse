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
	
	Task_Subject = NStr("ru = 'Новая задача';
						|en = 'New task';");
	TaskDueDate = CurrentSessionDate();
	Task = Tasks.PerformerTask.EmptyRef();
	SetAddressingObjectTypes();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	SetItemsState();
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RoleOnChange(Item)
	
	MainAddressingObject = Undefined;
	AdditionalAddressingObject = Undefined;
	SetAddressingObjectTypes();
	SetItemsState();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateTaskExecute(Command)
	
	CreateTask();
	RepresentDataChange(TaskRef, DataChangeType.Create);
		
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetAddressingObjectTypes()
	
	MainAddressingObjectTypes = Undefined;
	AdditionalAddressingObjectTypes = Undefined;
	UsedByAddressingObjects = False;
	If Not Role.IsEmpty() Then
		InfoAboutRole = Common.ObjectAttributesValues(Role, 
			"MainAddressingObjectTypes,AdditionalAddressingObjectTypes,UsedByAddressingObjects");
		UsedByAddressingObjects = InfoAboutRole.UsedByAddressingObjects;
		If UsedByAddressingObjects Then
			MainAddressingObjectTypes = Common.ObjectAttributeValue(InfoAboutRole.MainAddressingObjectTypes, "ValueType");
			AdditionalAddressingObjectTypes = Common.ObjectAttributeValue(InfoAboutRole.AdditionalAddressingObjectTypes, "ValueType");
		EndIf;
	EndIf;
EndProcedure

&AtClient
Procedure SetItemsState()

	RoleIsSet = Not Role.IsEmpty();
	MainAddressingObjectTypesAreSet = RoleIsSet And UsedByAddressingObjects
		And ValueIsFilled(MainAddressingObjectTypes);
	AddlAddressingObjectTypesSet = RoleIsSet And UsedByAddressingObjects 
		And ValueIsFilled(AdditionalAddressingObjectTypes);
	Items.MainAddressingObject.Enabled = MainAddressingObjectTypesAreSet;
	Items.AdditionalAddressingObject.Enabled = AddlAddressingObjectTypesSet;
	
	Items.MainAddressingObject.AutoMarkIncomplete = MainAddressingObjectTypesAreSet;
	Items.AdditionalAddressingObject.AutoMarkIncomplete = AddlAddressingObjectTypesSet;
	Items.MainAddressingObject.TypeRestriction = MainAddressingObjectTypes;
	Items.AdditionalAddressingObject.TypeRestriction = AdditionalAddressingObjectTypes;
	
EndProcedure

&AtServer
Procedure CreateTask()
	
	SetPrivilegedMode(True);
	
	TaskObject = Tasks.PerformerTask.CreateTask();
	TaskObject.Date = CurrentSessionDate();
	TaskObject.Author = Users.CurrentUser();
	TaskObject.PerformerRole = Role;
	TaskObject.MainAddressingObject = MainAddressingObject;
	TaskObject.AdditionalAddressingObject = AdditionalAddressingObject;
	TaskObject.LongDesc = NStr("ru = 'Задача сгенерирована автоматически.';
								|en = 'The task is generated automatically.';");
	TaskObject.Description = Task_Subject;
	TaskObject.TaskDueDate = TaskDueDate;
	TaskObject.Write();
	
	Task = String(TaskObject);
	TaskRef = TaskObject.Ref;
	
EndProcedure

#EndRegion
