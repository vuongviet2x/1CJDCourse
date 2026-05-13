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

#Region Variables

Var PreviousValue2, NewValue;

#EndRegion

#Region EventHandlers

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PreviousValue2 = Constants.LimitAccessAtRecordLevelUniversally.Get();
	
	If Not AccessManagementInternal.ScriptVariantRussian() Then
		Value = True;
	EndIf;
	
	NewValue = Value;
	
	If Value And Not PreviousValue2 Then // Enabled.
		InformationRegisters.AccessRestrictionParameters.UpdateRegisterData();
	EndIf;
	
	If Value = PreviousValue2 Then
		Return;
	EndIf;
	
	If Common.IsStandaloneWorkplace() Then
		ErrorText =
			NStr("ru = 'Изменение варианта работы Стандартный/Производительный следует выполнить в приложении в сервисе.';
				|en = 'To change the app mode (Standard or High-performance), go to the app in the service.';");
		Raise ErrorText;
	ElsIf Common.IsSubordinateDIBNode() Then
		ErrorText =
			NStr("ru = 'Изменение варианта работы Стандартный/Производительный следует выполнить в главном узле информационной базы.';
				|en = 'The operation mode (standard or high-performance) can only be changed in the master node.';");
		Raise ErrorText;
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If NewValue <> Value Then
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Нельзя изменять значение константы %1 в обработчиках подписок на событие %2.';
				|en = 'Cannot change the %1 constant value in the %2 event subscription handlers.';"),
			"LimitAccessAtRecordLevelUniversally", "BeforeWrite");
		Raise ErrorText;
	EndIf;
	
	If Value And Not PreviousValue2 Then // Enabled.
		AccessManagementInternal.ClearLastAccessUpdate();
		PlanningParameters = AccessManagementInternal.AccessUpdatePlanningParameters();
		PlanningParameters.LongDesc = "EnabledRestrictAccessAtTheRecordLevelUniversally";
		AccessManagementInternal.ScheduleAccessUpdate(Undefined, PlanningParameters);
	EndIf;
	
	If Not Value And PreviousValue2 Then // Disabled.
		ValueManager = Constants.FirstAccessUpdateCompleted.CreateValueManager();
		ValueManager.Value = False;
		InfobaseUpdate.WriteData(ValueManager);
		AccessManagementInternal.EnableDataFillingForAccessRestriction();
	EndIf;
	
	If Value <> PreviousValue2 Then // Modified.
		AccessManagementInternal.UpdateSessionParameters();
	EndIf;
	
EndProcedure

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf