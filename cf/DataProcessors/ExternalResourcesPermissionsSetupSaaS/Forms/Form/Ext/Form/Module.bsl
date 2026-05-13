#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Raise NStr("ru = 'Обработка не предназначена для интерактивного использования';
							|en = 'Data processor is not for interactive use';");
	
EndProcedure

#EndRegion