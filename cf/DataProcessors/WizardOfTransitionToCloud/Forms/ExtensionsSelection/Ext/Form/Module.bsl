
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	ExtensionsListing.Load(GetFromTempStorage(Parameters.ExtensionsStorageURL));
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersExtensionsListing

&AtClient
Procedure ExtensionsListingSelection(Item, RowSelected, Field, StandardProcessing)
	ChoiceData = Items.ExtensionsListing.CurrentData;
	Close(ChoiceData.Name);
EndProcedure

#EndRegion
