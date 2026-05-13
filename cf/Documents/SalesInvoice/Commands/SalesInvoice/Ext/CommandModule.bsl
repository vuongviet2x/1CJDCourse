
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	SpreadsheetDocument = PrintFormSalesInvoice(CommandParameter);
	
	SpreadsheetDocument.Show("Sales invoice");
	
EndProcedure

&AtServer
Function PrintFormSalesInvoice(PrintingObjects)
	Return Documents.SalesInvoice.PrintFormSalesInvoice(PrintingObjects);
EndFunction

