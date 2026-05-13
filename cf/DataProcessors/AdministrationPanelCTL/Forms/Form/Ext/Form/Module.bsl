#Region FormEventHandlers

&AtClient
Procedure OnOpen(Cancel)
	Cancel = True;
	ShowMessageBox(, NStr("ru = 'Обработка не предназначена для непосредственного использования.';
									|en = 'The data processor cannot be opened manually.';"));
EndProcedure

#EndRegion