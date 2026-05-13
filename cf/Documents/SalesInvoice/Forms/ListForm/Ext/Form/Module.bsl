
&AtServer
Procedure CopyAndPostAtServer()
	
	DocumentRef = Items.List.CurrentRow;
	If ValueIsFilled(DocumentRef) Then
		NewDocument = DocumentRef.Copy();
		// NewDocument variable contains a value of type DocumentObject
		NewDocument.Write(DocumentWriteMode.Posting, DocumentPostingMode.RealTime);
		
		Items.List.Refresh();
	Else
		Message("No document selected for copying");
	EndIf;
	
EndProcedure

&AtClient
Procedure CopyAndPost(Command)
	CopyAndPostAtServer();
EndProcedure



