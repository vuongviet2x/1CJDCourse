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
	
	CertificateUsers = Parameters.Users;
	CertificateRecipient = Parameters.User;
	ViewMode = Parameters.ViewMode;
	
	If CertificateUsers = Undefined Then
		CertificateUsers = New Array;
	EndIf;
	
	If CertificateUsers.Count() > 0
		Or CertificateRecipient <> Users.CurrentUser()
		Or Not ValueIsFilled(CertificateRecipient) Then
		ChoiceMode = "UsersList";
	Else
		ChoiceMode = "JustForMe";
	EndIf;
	
	FillInTheFullList(CertificateUsers, CertificateRecipient);
	FormControl(ThisObject);
	ConfigureConditionalFormatting();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ChoiceModeOnChange(Item)
	
	FormControl(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectedUsers

&AtClient
Procedure SelectedUsersBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	PickingParameters = New Structure;
	PickingParameters.Insert("ChoiceMode", True);
	PickingParameters.Insert("CloseOnChoice", False);
	PickingParameters.Insert("MultipleChoice", True);
	PickingParameters.Insert("AdvancedPick", True);
	PickingParameters.Insert("HideUsersWithoutMatchingIBUsers", True);
	
	Selected_ = New Array;
	For Each String In SelectedUsers Do
		Selected_.Add(String.User);
	EndDo;
	
	PickingParameters.Insert("SelectedUsers", Selected_);
	PickingParameters.Insert("PickFormHeader",
		NStr("ru = 'Выберите пользователей, у которых сертификат будет доступен в списке выбора';
			|en = 'Select users who will see the certificate in the choice list';"));
	PickingParameters.Insert("PickingCompletionButtonTitle", NStr("ru = 'Выбрать';
																		|en = 'Select';"));
	
	Handler = New NotifyDescription("Add_Users", ThisObject);
	
	OpenForm("Catalog.Users.ChoiceForm", PickingParameters,,,,, Handler);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OK(Command)
	
	If ViewMode Then
		Result = Undefined;
	Else	
		Result = New Structure;
		Result.Insert("Users", New Array);
		Result.Insert("User", PredefinedValue("Catalog.Users.EmptyRef"));
		
		If ChoiceMode = "UsersList" Then
			If Items.UsersTable.Visible Then
				For Each UserRow1 In UsersTable Do
					If UserRow1.Check Then
						Result.Users.Add(UserRow1.User);
					EndIf;
				EndDo;
			Else
				For Each UserRow1 In SelectedUsers Do
					Result.Users.Add(UserRow1.User);
				EndDo;
			EndIf;
		Else
			Result.User = UsersClient.CurrentUser();	
		EndIf;
		If Result.Users.Count() = 1 Then
			Result.User = Result.Users[0];
			Result.Users.Clear();
		EndIf;
	EndIf;
	
	Close(Result);
	
EndProcedure

&AtClient
Procedure CancelCheck(Command)
	
	ChangeTheListLabels(False);
	
EndProcedure

&AtClient
Procedure SelectAllItems(Command)
	
	ChangeTheListLabels(True);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure Add_Users(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedUsers.Clear();
	For Each User In Result Do
		NewRow = SelectedUsers.Add();
		NewRow.User = User;
		If User = CertificateRecipient Then
			NewRow.Main = True;
		EndIf;
	EndDo;

EndProcedure

&AtClient
Procedure ChangeTheListLabels(CheckMarkValue)
	
	For Each UserRow1 In UsersTable Do
		UserRow1.Check = CheckMarkValue;
	EndDo;
	
EndProcedure

&AtServer
Procedure ConfigureConditionalFormatting()
	
	If Items.UsersTable.Visible Then
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("BackColor");
		AppearanceColorItem.Value = StyleColors.AddedAttributeBackground;
		AppearanceColorItem.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField("UsersTable.Main");
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = True;
		DataFilterItem.Use  = True;
		
		DesignFieldElement = ConditionalAppearanceItem.Fields.Items.Add();
		DesignFieldElement.Field = New DataCompositionField("UsersTable");
		DesignFieldElement.Use = True;
	EndIf;
	
	If Items.UsersTable.Visible Then
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		AppearanceColorItem = ConditionalAppearanceItem.Appearance.Items.Find("BackColor");
		AppearanceColorItem.Value = StyleColors.AddedAttributeBackground;
		AppearanceColorItem.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField("SelectedUsers.Main");
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = True;
		DataFilterItem.Use  = True;
		
		DesignFieldElement = ConditionalAppearanceItem.Fields.Items.Add();
		DesignFieldElement.Field = New DataCompositionField("SelectedUsers");
		DesignFieldElement.Use = True;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInTheFullList(CertificateUsers, CertificateRecipient)
	
	UsersArray = New Array;
	If CertificateUsers <> Undefined Then
		UsersArray = CertificateUsers;
	EndIf;
	
	If ValueIsFilled(CertificateRecipient)
		And ChoiceMode = "UsersList" Then
		UsersArray.Add(CertificateRecipient);
	EndIf;
	
	QueryText = 
	"SELECT ALLOWED
	|	Users.Ref AS User,
	|	CASE
	|		WHEN Users.Ref IN (&Users)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Check,
	|	CASE
	|		WHEN Users.Ref = &CertificateRecipient
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Main
	|FROM
	|	Catalog.Users AS Users
	|WHERE
	|	(NOT Users.DeletionMark
	|				AND NOT Users.Invalid
	|				AND (NOT Users.IsInternal
	|						AND Users.IBUserID <> &EmptyIDOfTheIBUser
	|					OR Users.Ref = &CurrentUser)
	|			OR Users.Ref IN (&Users))
	|
	|ORDER BY
	|	Users.Description";
	
	Query = New Query(QueryText);
	Query.SetParameter("Users", UsersArray);
	Query.SetParameter("CurrentUser", Users.AuthorizedUser());
	Query.SetParameter("EmptyIDOfTheIBUser", New UUID("00000000-0000-0000-0000-000000000000"));
	Query.SetParameter("CertificateRecipient", CertificateRecipient);
	
	Result = Query.Execute().Unload();
	If Result.Count() > 30 Then
		SelectedUsers.Clear();
		For Each User In UsersArray Do
			NewRow = SelectedUsers.Add();
			NewRow.User = User;
			If User = CertificateRecipient Then
				NewRow.Main = True;
			EndIf;
		EndDo;
		Items.UsersTable.Visible = False;
		Items.SelectedUsers.Visible = True;
	Else
		UsersTable.Load(Result);
		Items.UsersTable.Visible = True;
		Items.SelectedUsers.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FormControl(TheFormContext)
	
	FormItems = TheFormContext.Items;
	
	If TheFormContext.ViewMode Then
		FormItems.UsersTable.ReadOnly = True;
		FormItems.SelectedUsers.ReadOnly = True;
		FormItems.ChoiceMode.ReadOnly = True;
		FormItems.SelectionMethodList.ReadOnly = True;
	Else	
		FormItems.UsersTable.ReadOnly = Not TheFormContext.ChoiceMode = "UsersList";
		FormItems.SelectedUsers.ReadOnly = Not TheFormContext.ChoiceMode = "UsersList";
	EndIf;	
	
	FormItems.UsersSelectAll.Enabled = Not FormItems.UsersTable.ReadOnly;
	FormItems.UsersCancelCheck.Enabled = Not FormItems.UsersTable.ReadOnly;
		
EndProcedure

#EndRegion
