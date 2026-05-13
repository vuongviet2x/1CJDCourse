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
	
	If Common.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchServer = Common.CommonModule("FullTextSearchServer");
		UseFullTextSearch = ModuleFullTextSearchServer.UseSearchFlagValue();
	Else 
		Items.FullTextSearchManagementGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
		StoreChangeHistory = ModuleObjectsVersioning.StoreHistoryCheckBoxValue();
	Else 
		Items.ObjectVersioningGroup.Visible = False;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") Then
		ModuleMarkedObjectsDeletion = Common.CommonModule("MarkedObjectsDeletion");
		AutomaticallyDeleteMarkedObjects = ModuleMarkedObjectsDeletion.ModeDeleteOnSchedule().Use;
	Else 
		Items.AutoDeleteObjectsGroup.Visible = False;
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.UseSearchFlagChangeNotificationProcessing(
			EventName, 
			UseFullTextSearch);
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.StoreHistoryCheckBoxChangeNotificationProcessing(
			EventName, 
			StoreChangeHistory);
	EndIf;
	
	If CommonClient.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") Then
		ModuleMarkedObjectsDeletionClient = CommonClient.CommonModule("MarkedObjectsDeletionClient");
		ModuleMarkedObjectsDeletionClient.DeleteOnScheduleCheckBoxChangeNotificationProcessing(
			EventName, 
			AutomaticallyDeleteMarkedObjects);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure UseFullTextSearchOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.OnChangeUseSearchFlag(UseFullTextSearch);
	EndIf;
	
EndProcedure

&AtClient
Procedure StoreHistoryOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.OnStoreHistoryCheckBoxChange(StoreChangeHistory);
	EndIf;
	
EndProcedure

&AtClient
Procedure AutomaticallyDeleteMarkedObjectsOnChange(Item)
	
	If CommonClient.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") Then
		ModuleMarkedObjectsDeletionClient = CommonClient.CommonModule("MarkedObjectsDeletionClient");
		ModuleMarkedObjectsDeletionClient.OnChangeCheckBoxDeleteOnSchedule(AutomaticallyDeleteMarkedObjects);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ConfigureFullTextSearch(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.FullTextSearch") Then
		ModuleFullTextSearchClient = CommonClient.CommonModule("FullTextSearchClient");
		ModuleFullTextSearchClient.ShowSetting();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfigureChangesHistoryStorage(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		ModuleObjectsVersioningClient = CommonClient.CommonModule("ObjectsVersioningClient");
		ModuleObjectsVersioningClient.ShowSetting();
	EndIf;
	
EndProcedure

&AtClient
Procedure DeleteMarkedObjects(Command)
	
	If CommonClient.SubsystemExists("StandardSubsystems.MarkedObjectsDeletion") Then
		ModuleMarkedObjectsDeletionClient = CommonClient.CommonModule("MarkedObjectsDeletionClient");
		ModuleMarkedObjectsDeletionClient.GoToMarkedForDeletionItems(ThisObject);
	EndIf;
	
EndProcedure

#EndRegion

