#Region Internal

// Returns: 
//  String - Right to start.
Function RightToStart() Export
	
	Return NStr("ru = 'Запуск';
				|en = 'Start';");
	
EndFunction

// Returns: 
//  String - Right to start and administer.
Function LaunchAndAdministrationRights() Export
	
	Return NStr("ru = 'Запуск и администрирование';
				|en = 'Launch and administration';");
	
EndFunction

// Returns: 
//  String - Owner role.
Function OwnerRole() Export
	
	Return NStr("ru = 'Владелец';
				|en = 'Owner';");
	
EndFunction

// Returns: 
//  String - Administrator role.
Function RoleAdministrator() Export
	
	Return NStr("ru = 'Администратор';
				|en = 'Administrator';");
	
EndFunction

// Returns: 
//  String -  User role.
Function UserRole_() Export
	
	Return NStr("ru = 'Пользователь';
				|en = 'User';");
	
EndFunction

// Parameters: 
//  Id - String
// 
// Returns: 
//  String
Function RolePresentation(Id) Export
	
	If Id = "owner" Then
		Return OwnerRole();
	ElsIf Id = "administrator" Then
		Return RoleAdministrator();
	ElsIf Id = "user" Then  
		Return UserRole_();
	ElsIf Id = "operator" Then
		Return OperatorRole();
	EndIf;
	
EndFunction

// Parameters: 
//  Presentation - String
// 
// Returns: 
//  String - Role API ID.
Function APIIDForRole(Presentation) Export
	
	If Presentation = OwnerRole() Then
		Return "owner";
	ElsIf Presentation = RoleAdministrator() Then
		Return "administrator";
	ElsIf Presentation = UserRole_() Then
		Return "user";
	ElsIf Presentation = OperatorRole() Then
		Return "operator";
	EndIf;
	
EndFunction

// Parameters: 
//  Presentation - String
// 
// Returns: 
//  String
Function APIID(Presentation) Export
	
	If Presentation = RightToStart() Then
		Return "user";
	ElsIf Presentation = LaunchAndAdministrationRights() Then
		Return "administrator";
	EndIf;
	
EndFunction

#EndRegion

#Region Private

Function OperatorRole()
	
	Return NStr("ru = 'Оператор';
				|en = 'Operator';");
	
EndFunction

#EndRegion
