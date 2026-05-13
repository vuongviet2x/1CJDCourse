#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	Use = True;
	Schedule = New ValueStorage(Catalogs.JobsQueueHandlers.DefaultSchedule());
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Auto = False;
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	CheckForChanges();
	
	Validation = Methods.Unload(, "Method");
	Validation.GroupBy("Method");
	If Validation.Count() <> Methods.Count() Then
		Common.MessageToUser(NStr("ru = 'Обнаружены дубли методов';
													|en = 'Method duplicates are found';"), , "Methods", , Cancel);
	EndIf;
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CheckForChanges();
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
EndProcedure

Procedure BeforeDelete(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CheckForChanges();
	
EndProcedure

#EndRegion

#Region Private

Procedure CheckForChanges()
	
	If Auto Then
		Raise NStr("ru = 'Редактирование этой настройки выполняется только в Менеджере сервиса';
								|en = 'This setting is edited in the Service Manager only';");
	EndIf;
	
EndProcedure

#EndRegion

#EndIf

