#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Sets True for the Hyperlink property of a form decoration.
// 
// Parameters:
// 	Label - Label - a form decoration.
Procedure SetHyperlinkAttribute(Label) Export
	
	Label.Hyperlink = True;
	
EndProcedure

// Adds current application information to the message text from the user.
//
// Parameters:
//  HTMLText - String - User message text.
//  HTMLAttachments - Structure - Images embedded in the user message.
//
Procedure AddAppInformation(HTMLText, HTMLAttachments) Export
    
    SystemInfo = New SystemInfo();
    
    HTMLText = HTMLText + Chars.LF + StringFunctionsClientServer.SubstituteParametersToString( 
        "<!-- @AddInfo 
        |{
        |   ""base_id"": ""%1"",
        |   ""platformVersion"": ""%2"",
        |   ""configVersion"": ""%3"",
        |   ""configName"": ""%4"",
		|	""descriptionImages"": %5
        |} 
        |-->", 
		Constants.InfoBaseID.Get(), 
        SystemInfo.AppVersion,
        Metadata.Version,
        Metadata.Name,
		SaaSOperationsCTL.StringFromJSONStructure(HTMLAttachments));
	
EndProcedure

Procedure AddValueToXDTOList(Object, ListBox, Val Value) Export

	List = Object[ListBox]; // XDTOList
	List.Add(Value);
	
EndProcedure

#EndRegion

#EndIf