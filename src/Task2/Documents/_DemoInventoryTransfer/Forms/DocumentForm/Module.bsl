&AtServer
Procedure Ext1_OnCreateAtServerAfter(Cancel, StandardProcessing)
    // Field ReleasedBy
    FieldReleasedBy = Items.Add("ReleasedByField", Type("FormField"), Items.ResponsibleGroup);
	FieldReleasedBy.Type = FormFieldType.InputField;
    FieldReleasedBy.DataPath = "Object.ReleasedBy"; 
	FieldReleasedBy.Title    = "Released by";

    // Field ReceivedBy
    FieldReceivedBy = Items.Add("ReceivedByField", Type("FormField"), Items.ResponsibleGroup); 
	FieldReceivedBy.Type = FormFieldType.InputField;
    FieldReceivedBy.DataPath = "Object.ReceivedBy";
    FieldReceivedBy.Title    = "Received by";
EndProcedure

&AtServer
Procedure Ext1_StorageSourceOnChangeAfterAtServer()
	Object.ReleasedBy = Object.StorageSource.FinanciallyLiablePerson;
EndProcedure

&AtClient
Procedure Ext1_StorageSourceOnChangeAfter(Item)
	Ext1_StorageSourceOnChangeAfterAtServer();
EndProcedure

&AtServer
Procedure Ext1_StorageLocationDestinationOnChangeAfterAtServer()
	Object.ReceivedBy = Object.StorageLocationDestination.FinanciallyLiablePerson;
EndProcedure

&AtClient
Procedure Ext1_StorageLocationDestinationOnChangeAfter(Item)
	Ext1_StorageLocationDestinationOnChangeAfterAtServer();
EndProcedure
