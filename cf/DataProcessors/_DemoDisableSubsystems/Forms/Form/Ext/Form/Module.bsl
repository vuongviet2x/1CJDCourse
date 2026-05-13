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
	
	SavedSettings = Common.CommonSettingsStorageLoad(
		"Core", "DisabledSubsystems", New Map);
	
	// Populate the subsystem tree.
	For Each Subsystem In Metadata.Subsystems Do
		
		If StrStartsWith(Subsystem.Name, "_Demo") Then
			Continue;
		EndIf;
		
		TreeItems = DisabledSubsystems.GetItems();
		NewRow = TreeItems.Add();
		NewRow.Subsystem = Subsystem.Name;
		NewRow.Presentation = Subsystem.Synonym;
		NewRow.isDisabled = SavedSettings.Get(Subsystem.Name) = True;
		
		SubordinateTreeItems = NewRow.GetItems();
		For Each SubordinateSubsystem In Subsystem.Subsystems Do
			
			SubsystemName = Subsystem.Name + "." + SubordinateSubsystem.Name;
			
			NewRow = SubordinateTreeItems.Add();
			NewRow.Subsystem = SubsystemName;
			NewRow.Presentation = SubordinateSubsystem.Synonym;
			NewRow.isDisabled = SavedSettings.Get(SubsystemName) = True;
		EndDo;
		
	EndDo;
	
	If Common.IsMobileClient() Then
		Items.FormWrite.Representation = ButtonRepresentation.Picture;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Write(Command)
	WriteAtServer();
	ApplicationParameters["StandardSubsystems.ConfigurationSubsystems"] = Undefined; // Restore client cache.
	
	StandardSubsystemsClient.ClientParametersOnStart();
	StandardSubsystemsClient.ClientRunParameters();
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure WriteAtServer()
	SettingValue = New Map;
	For Each TreeRow In DisabledSubsystems.GetItems() Do
		If TreeRow.isDisabled Then
			SettingValue.Insert(TreeRow.Subsystem, True);
		EndIf;
		For Each SubordinateRow In TreeRow.GetItems() Do
			If SubordinateRow.isDisabled Then
				SettingValue.Insert(SubordinateRow.Subsystem, True);
			EndIf;
		EndDo;
	EndDo;
	Common.CommonSettingsStorageSave("Core", "DisabledSubsystems", SettingValue);
	RefreshReusableValues();
EndProcedure

&AtClient
Procedure DisabledSubsystemsisDisabledOnChange(Item)
	
	CurrentRow = DisabledSubsystems.FindByID(Items.DisabledSubsystems.CurrentRow);
	For Each TreeRow In CurrentRow.GetItems() Do
		TreeRow.isDisabled = CurrentRow.isDisabled;
	EndDo;
	
EndProcedure

#EndRegion