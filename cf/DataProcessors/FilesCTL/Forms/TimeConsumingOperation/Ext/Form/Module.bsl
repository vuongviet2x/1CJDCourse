//@strict-types

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	Parameters.Property("AbortAllowed", AbortAllowed);

	DialogTitle = "";
	If Parameters.Property("DialogTitle", DialogTitle) And ValueIsFilled(DialogTitle) Then
		ThisObject.Title = DialogTitle;
		ThisObject.AutoTitle = False;
	EndIf;

	If Not AbortAllowed Then
		Items.TimeConsumingOperationNoteTextDecoration.ToolTip = NStr(
			"ru = 'Операцию нельзя прервать до окончания выполнения';
			|en = 'Operation cannot be aborted until it is completed';");
		Items.TimeConsumingOperationNoteTextDecoration.ToolTipRepresentation = ToolTipRepresentation.ShowBottom;
	EndIf;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)

	If Exit Then
		Return;
	EndIf;

	OperationAborted = True;

	Cancel = Not AbortAllowed;

EndProcedure

#EndRegion