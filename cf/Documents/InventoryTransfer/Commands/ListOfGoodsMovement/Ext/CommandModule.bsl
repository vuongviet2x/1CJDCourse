
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//{{_PRINT_WIZARD(ListOfGoodsMovement)
	Spreadsheet = ListOfGoodsMovement(CommandParameter);

	Spreadsheet.Show("List of goods movement");
	//}}
EndProcedure

&AtServer
Function ListOfGoodsMovement(CommandParameter)
	Return Documents.InventoryTransfer.ListOfGoodsMovement(CommandParameter);
EndFunction
