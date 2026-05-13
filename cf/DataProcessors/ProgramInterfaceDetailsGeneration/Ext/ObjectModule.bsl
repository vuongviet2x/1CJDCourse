///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables
Var APIStructure; // See NewAPIStructure
Var MethodStructure; // Structure
Var CommentRead, ReadParameters1, FullObjectName, AreaName,
	ObjectsAndSubsystemsMap1, ReadReturnValues, ReadExample, ReadMethod1,
	MethodRead, ObjectTypeAndManager, MethodAvailability, AvailabilityID, EnglishVersion;
#EndRegion

#Region Private

// Override.

// Prepare source data to later generate API details.

Procedure GenerateAPI() Export
	
	ClearDumpDirectory1 = Not ValueIsFilled(DumpDirectory);
	
	UploadConfigurationToXML();
	
	DefineVersionLanguage();
	
	APIStructure = NewAPIStructure();
	DetailsGenerationLog = NewDetailsGenerationLog();
	
	ModuleFiles = FindFiles(DumpDirectory + GetPathSeparator() + "CommonModules", "*bsl", True);
	
	ObjectsAndSubsystemsMap1 = New Map;
	FillObjectsToSubsystemsMap(ObjectsAndSubsystemsMap1);
	
	DifferentModules = New Map;
	For Each ModuleFile In ModuleFiles Do
		
		FullName_Structure = FullNameByModuleName(ModuleFile.FullName, ModuleFile.Name);
		FullObjectName   = FullName_Structure.FullObjectName;
		
		If ObjectsAndSubsystemsMap1[FullObjectName] = Undefined Then
			// Document only objects that belong to the specified subsystems.
			Continue;
		EndIf;
		
		FileText = New TextReader(ModuleFile.FullName);
		ModuleText = FileText.Read();
		
		Public = ModuleAPI(ModuleText);
		If Not ValueIsFilled(Public) Then
			Continue;
		EndIf;
		
		If StrFind(ModuleFile.FullName, "CommonModules") > 0 Then
			FillMethodAvailability(ModuleFile);
		EndIf;
		NumberUpTo = APIStructure.Count();
		ReadModuleAPI(Public);
		DifferentModules.Insert(FullObjectName, APIStructure.Count() - NumberUpTo);
	EndDo;
	
	If Not FileText = Undefined Then
		FileText.Close();
		FileText = Undefined;
	EndIf;
	APIStructure.Sort("Subsystem, Location, Area, MethodName");
	
	PrepareDetails();
	
	If ClearDumpDirectory1 Then
		DeleteFiles(DumpDirectory);
	EndIf;
	
EndProcedure

Procedure DefineVersionLanguage() Export
	
	If IsBlankString(DumpDirectory) Then
		Return;
	EndIf;
	
	File = New File(DumpDirectory);
	Result = Undefined;
	If File.Exists() Then
		DOMDocument    = DOMDocument(DumpDirectory + GetPathSeparator() + "Configuration.xml");
		XPathExpression = "xmlns:Configuration/xmlns:Properties/xmlns:ScriptVariant";
		Result      = DOMDocument.EvaluateXPathExpression(XPathExpression, DOMDocument, DOMDocument.CreateNSResolver()).IterateNext();
	EndIf;
	VersionLanguage = ?(Result = Undefined, "Russian", Result.TextContent);
	
	EnglishVersion = VersionLanguage = "English";
	
EndProcedure

// Returns:
//   Structure:
//    * InvalidProgramming - Array
//    * LongComment -  Array
//    * HyperlinkInQuotes - Array
//    * HyperlinkNotFound - ValueList
//    * ObsoleteMethods - Array
//
Function NewDetailsGenerationLog()
	
	DetailsLog = New Structure;
	DetailsLog.Insert("InvalidProgramming",  New Array);
	DetailsLog.Insert("LongComment",   New Array);
	DetailsLog.Insert("HyperlinkInQuotes", New Array);
	DetailsLog.Insert("HyperlinkNotFound", New ValueList);
	DetailsLog.Insert("ObsoleteMethods",     New Array);
	
	Return DetailsLog;
	
EndFunction

// Returns:
//   ValueTable:
//   * Subsystem 
//   * FullObjectName 
//   * MethodDesc 
//   * ParametersDetails 
//   * DescriptionOfReturnValue 
//   * ExampleDetails 
//   * MethodSyntax 
//   * Enabled 
//   * AvailabilityID 
//   * Location 
//   * MethodName 
//   * CallSyntax 
//
Function NewAPIStructure()
	
	APIStructure = New ValueTable;
	APIStructure.Columns.Add("Subsystem");
	APIStructure.Columns.Add("FullObjectName");
	APIStructure.Columns.Add("MethodDesc");
	APIStructure.Columns.Add("ParametersDetails");
	APIStructure.Columns.Add("DescriptionOfReturnValue");
	APIStructure.Columns.Add("ExampleDetails");
	APIStructure.Columns.Add("MethodSyntax");
	APIStructure.Columns.Add("Enabled");
	APIStructure.Columns.Add("AvailabilityID");
	APIStructure.Columns.Add("Location");
	APIStructure.Columns.Add("Area");
	APIStructure.Columns.Add("MethodName");
	APIStructure.Columns.Add("CallSyntax");
	Return APIStructure;
	
EndFunction


Function ModuleAPI(ModuleText)
	
	AreaStart = StrFind(ModuleText, APIArea1());
	If AreaStart = 0 Then
		Return "";
	EndIf;
	
	APIAreaStart = AreaStart + StrLen(APIArea1());
	APIAreaEnd  = Undefined;
	
	EntryNumber = 1;
	While APIAreaEnd = Undefined Do
		AreaStart = StrFind(ModuleText, AreaStart(), , APIAreaStart, EntryNumber);
		EndRegion  = StrFind(ModuleText, EndRegion(), , APIAreaStart, EntryNumber);
		
		If AreaStart > 0 And AreaStart < EndRegion Then
			EntryNumber = EntryNumber + 1;
		Else
			APIAreaEnd = EndRegion;
		EndIf;
		
	EndDo;
	
	APIArea = Mid(ModuleText, APIAreaStart, APIAreaEnd - APIAreaStart);
	
	Return APIArea;
	
EndFunction

Procedure ReadModuleAPI(Val Public)
	
	TextDocument = New TextDocument;
	TextDocument.SetText(Public);
	NestingForAreas = 0;
	
	SetVariables();
	For Iterator_SSLy = 1 To TextDocument.LineCount() Do
		String = TextDocument.GetLine(Iterator_SSLy);
		If ReadMethod1 Then
			If StrFind(String, LineEndOfProcedure()) > 0 Or StrFind(String, LineEndOfFunction()) > 0 Then
				// Finish reading the body of the procedure or function.
				SetVariables();
			EndIf;
			Continue;
		EndIf;
		
		If StrFind(String, ScopeStringObsoleteProceduresAndFunctions()) > 0
			Or StrFind(String, StringScopeForCallingFromOtherSubsystems()) > 0 Then
			AreasNesting = 0;
			While True Do
				If StrFind(String, StringArea()) > 0 Then
					AreasNesting = AreasNesting + 1;
				ElsIf StrFind(String, LineEndOfArea()) > 0 Then
					AreasNesting = AreasNesting - 1;
				EndIf;
				
				If StrFind(String, LineEndOfArea()) <> 0 And AreasNesting = 0 Then
					Break;
				EndIf;
				
				Iterator_SSLy = Iterator_SSLy + 1;
				String = TextDocument.GetLine(Iterator_SSLy);
			EndDo;
		EndIf;
		
		If IsBlankString(String) Then
			Continue;
		ElsIf Left(String, 2) = "//" Then
			MethodStructure.Insert("DetailsLength", 0);
			ReadCommentAndMethod(String, TextDocument, Iterator_SSLy);
			MethodStructure.Delete("DetailsLength");
		Else
			AreaStart = StrFind(String, "#Area");
			EndRegion  = StrFind(String, "#EndRegion");
			If AreaStart > 0 Then
				If NestingForAreas = 0 Then
					AreaName = TrimAll(Right(String, StrLen(String) - AreaStart - 8));
				EndIf;
				NestingForAreas = NestingForAreas + 1;
			EndIf;
			If EndRegion > 0 Then
				NestingForAreas = NestingForAreas - 1;
				If NestingForAreas = 0 Then
					AreaName = "";
				EndIf;
			EndIf;
		EndIf;
		If CommentRead And ReadMethod1 Then
			FillPropertyValues(APIStructure.Add(), MethodStructure);
		EndIf;
	EndDo;
	
EndProcedure

Procedure ReadCommentAndMethod(String, TextDocument, Iterator_SSLy, Recursion = False)
	
	If StrFind(String, StringParameters_() + ":") > 0 And StrSplit(String, " ", False).Count() = 2 Then
		ReadParameters1 = True;
		Return;
	ElsIf StrFind(String, StringReturnValue() + ":") > 0 Then
		ReadParameters1           = False;
		ReadReturnValues = True;
		Return;
	ElsIf StrFind(String, StringExample()) > 0 And StrSplit(String, " ", False).Count() = 2 Then
		ReadParameters1           = False;
		ReadReturnValues = False;
		ReadExample = True;
		Return;
	EndIf;
	
	If Left(String, 2) = "//" Then
		String = Right(String, StrLen(String) - 2);
	EndIf;
	
	If IsBlankString(String) Then
		Return;
	EndIf;
	
	String = StrReplace(String, Chars.Tab, " ");
	
	If Not ReadParameters1 And Not ReadReturnValues And Not ReadExample Then
		MethodStructure.MethodDesc =
			?(Not IsBlankString(MethodStructure.MethodDesc),
			MethodStructure.MethodDesc + Chars.LF + String,
			String);
	ElsIf ReadParameters1 Then
		MethodStructure.ParametersDetails = 
			?(Not IsBlankString(MethodStructure.ParametersDetails),
			MethodStructure.ParametersDetails + Chars.LF + String,
			String);
	ElsIf ReadReturnValues Then
		MethodStructure.DescriptionOfReturnValue = 
			?(Not IsBlankString(MethodStructure.DescriptionOfReturnValue),
			MethodStructure.DescriptionOfReturnValue + Chars.LF + String,
			String);
	ElsIf ReadExample Then
		MethodStructure.ExampleDetails = 
			?(Not IsBlankString(MethodStructure.ExampleDetails),
			MethodStructure.ExampleDetails + Chars.LF + String,
			String);
	EndIf;
	
	If Recursion Then
		Return;
	EndIf;
	
	MethodStructure.DetailsLength = MethodStructure.DetailsLength + 1;
	
	Iterator_SSLy = Iterator_SSLy + 1;
	String = TextDocument.GetLine(Iterator_SSLy);
	While Left(String, 2) = "//" Do
		ReadCommentAndMethod(String, TextDocument, Iterator_SSLy, True);
		MethodStructure.DetailsLength = MethodStructure.DetailsLength + 1;
		Iterator_SSLy = Iterator_SSLy + 1;
		String = TextDocument.GetLine(Iterator_SSLy);
	EndDo;
	
	If IsBlankString(String) Then
		SetVariables();
		Return;
	EndIf;
	
	CommentRead = True;
	
	ReadMethod1 = True;
	MethodReadError = False;
	ReadMethod(String, TextDocument, Iterator_SSLy, MethodReadError);
	If MethodReadError Then
		SetVariables();
		Return;
	EndIf;
	
	MethodStructure.FullObjectName = FullObjectName;
	MethodStructure.Subsystem = ObjectsAndSubsystemsMap1[FullObjectName];
	
	If StrFind(MethodStructure.FullObjectName, StringOverridable()) > 0 Then
		MethodStructure.Location = LineOverride();
	Else
		MethodStructure.Location = LineInterface();
		MethodStructure.Area    = AreaName;
	EndIf;
	
	MethodCallSyntax = MethodCallSyntax(MethodStructure.MethodSyntax, MethodStructure.FullObjectName);
	MethodStructure.MethodName       = MethodCallSyntax.MethodName;
	MethodStructure.CallSyntax = MethodCallSyntax.CallSyntax;
	If MethodCallSyntax.IsFunction Then
		MethodStructure.CallSyntax = StringSyntaxOfFunctionCallResult() + MethodStructure.CallSyntax;
	EndIf;
	
	DetailsLog = DetailsGenerationLog; //See NewDetailsGenerationLog
	
	// Logging.
	If StrFind(MethodStructure.MethodDesc, StringIsForInternalUseOnly()) > 0
		Or StrFind(MethodStructure.FullObjectName, StringInternal()) > 0 Then
		DetailsLog.InvalidProgramming.Add(MethodCallSyntax.CallSyntaxWithoutParameters);
	EndIf;
	If StrFind(MethodStructure.MethodDesc, "Obsolete3.") > 0 Then
		DetailsLog.ObsoleteMethods.Add(MethodCallSyntax.CallSyntaxWithoutParameters);
	EndIf;
	If MethodStructure.DetailsLength > 50 Then
		DetailsLog.LongComment.Add(MethodCallSyntax.CallSyntaxWithoutParameters
			+ " (" + NStr("ru = 'всего строк';
							|en = 'total number of lines';") + " - "
			+ MethodStructure.DetailsLength + ")");
	EndIf;
	
EndProcedure

Procedure ReadMethod(String, TextDocument, Iterator_SSLy, MethodReadError, Recursion = False)
	
	If Not CommentRead And Not ReadMethod1 Then
		Return;
	EndIf;
	
	If StrStartsWith(String, LineEndOfProcedure()) > 0 Or StrStartsWith(String, LineEndOfFunction()) > 0 Then
		MethodReadError = True;
	ElsIf ReadMethod1 And StrFind(String, ExportLine()) > 0 Then
		MethodStructure.MethodSyntax = ?(IsBlankString(MethodStructure.MethodSyntax),
			String,
			MethodStructure.MethodSyntax + Chars.LF + String);
		MethodRead = True;
	ElsIf StrStartsWith(String, StringProcedure() + " ") > 0 Or StrStartsWith(String, StringFunction() + " ") > 0 Then
		MethodStructure.MethodSyntax = String;
	ElsIf ValueIsFilled(MethodStructure.MethodSyntax) Then
		// Read method's parameters.
		MethodStructure.MethodSyntax = MethodStructure.MethodSyntax + Chars.LF + String;
	EndIf;
	
	If Recursion Then
		Return;
	EndIf;
	
	While Not MethodRead Do
		Iterator_SSLy = Iterator_SSLy + 1;
		String = TextDocument.GetLine(Iterator_SSLy);
		ReadMethod(String, TextDocument, Iterator_SSLy, MethodReadError, True);
		If MethodReadError Then
			Break;
		EndIf;
	EndDo;
	
EndProcedure

// Output the API to a file.

Procedure PrepareDetails()
	
	SaveDetailsToHtml();
	
EndProcedure

Procedure SaveDetailsToHtml()
	
	Header = "
		|<html>
		|<head>
		|<meta http-equiv=""Content-Type"" content=""text/html; charset=Windows-1251"">
		|<title>%1</title>
		|<link rel=""stylesheet"" href=""style.css"">
		|</head>
		|<body class=""bspdoc"">";
	
	Header = StringFunctionsClientServer.SubstituteParametersToString(Header,
		LineChapter4ProgrammingInterface());
	
	Footer = "
		|</body>
		|</html>
		|";
	
	CurrentSubsystem = "";
	CurrentPlacement = "";
	CurrentArea    = "";
	
	PageHeader = "<h1>%1</h1>";
	PageHeader = StringFunctionsClientServer.SubstituteParametersToString(PageHeader,
		LineChapter4ProgrammingInterface());
	
	Details_ = LineDetails();
	
	RefToStandards = StringReferenceToStandards();
	Details_ = StrReplace(Details_, "%1", RefToStandards);
	Result = PageHeader + Chars.LF + Details_;
	
	MethodsTotal = APIStructure.Count();
	OutputIdenticalMethods = False;
	MappedMethodIndex= 1;
	For Each Method In APIStructure Do
		
		If Method.Subsystem <> CurrentSubsystem Then
			CurrentPlacement   = "";
			CurrentArea      = "";
			CurrentSubsystem   = Method.Subsystem;
			TitleSubsystem = StringFunctionsClientServer.SubstituteParametersToString("<h2>%1</h2>", Method.Subsystem);
			Result = Result + Chars.LF + TitleSubsystem;
		EndIf;
		
		If Method.Location <> CurrentPlacement Then
			CurrentPlacement = Method.Location;
			// API layout title.
			If CurrentPlacement = LineInterface() Then
				Location = LineInterface();
			Else
				Location = LineOverrideDescription();
			EndIf;
			TitlePlacement = StringFunctionsClientServer.SubstituteParametersToString("<h3>%1</h3>", Location);
			Result = Result + Chars.LF + TitlePlacement;
		EndIf;
		
		If Method.Area <> CurrentArea Then
			CurrentArea = Method.Area;
			If ValueIsFilled(CurrentArea) Then
				AreaHeader = StringFunctionsClientServer.SubstituteParametersToString("<h4>%1</h4>", CurrentArea);
				Result = Result + Chars.LF + AreaHeader;
			EndIf;
		EndIf;
		
		// Method title.
		If Not OutputIdenticalMethods Then
			If ValueIsFilled(CurrentArea) Then
				HeaderLevel = "h5";
			Else
				HeaderLevel = "h4";
			EndIf;
			MethodTitle = StringFunctionsClientServer.SubstituteParametersToString("<%3><a name=""%1""></a>%2</%3>", "_" + HyperlinkAddress(Method), Method.MethodName, HeaderLevel);
		Else
			MethodTitle = "";
		EndIf;
		
		// Search for method name duplicates.
		MethodIndex   = APIStructure.IndexOf(Method);
		If MethodsTotal = (MethodIndex + 1) Then
			NextMethod = Undefined;
		Else
			NextMethod = APIStructure.Get(MethodIndex + 1);
		EndIf;
		
		If NextMethod <> Undefined And Method.MethodName = NextMethod.MethodName Then
			MatchingMethodsTitle = MatchingMethodsTitle1(Method, MappedMethodIndex);
			MappedMethodIndex = MappedMethodIndex + 1;
			OutputIdenticalMethods = True;
		ElsIf OutputIdenticalMethods Then
			MatchingMethodsTitle = MatchingMethodsTitle1(Method, MappedMethodIndex);
			OutputIdenticalMethods = False;
			MappedMethodIndex = 1;
		Else
			MatchingMethodsTitle = "";
		EndIf;
		
		// Method details.
		MethodDesc = "<pre>" + AddRefToDetails(Method.MethodDesc, Method) + "</pre>";
		If ValueIsFilled(MethodTitle) Then
			Result = Result + Chars.LF + MethodTitle;
		Else
			Result = Result + "<pre>" + Chars.LF + Chars.LF + "</pre>";
		EndIf;
		
		If ValueIsFilled(MatchingMethodsTitle) Then
			StringWithAddress = StringFunctionsClientServer.SubstituteParametersToString("<a name=""%1""></a>", "_" + Method.AvailabilityID + HyperlinkAddress(Method));
			MatchingMethodsTitle = StrReplace(MatchingMethodsTitle, "[Address]", StringWithAddress);
			
			If OutputIdenticalMethods Then
				MatchingMethodsDetails = "<pre>" + MatchingMethodsDetails(Method, NextMethod) + "</pre>";
				Result = Result + Chars.LF + MatchingMethodsDetails;
			EndIf;
			
			Result = Result + Chars.LF + MatchingMethodsTitle;
			
		EndIf;
		
		Result = Result + Chars.LF + MethodDesc;
		
		// Syntax.
		SyntaxHeader = "<p class=""Paragraph0c""><span class=""Bold"">" + "%1" + "</span></p>";
		SyntaxHeader = StringFunctionsClientServer.SubstituteParametersToString(SyntaxHeader, StringSyntax());
		SyntaxDetails = "<pre>" + " " + Method.MethodSyntax + "</pre>";
		
		Result = Result + Chars.LF + SyntaxHeader;
		Result = Result + Chars.LF + SyntaxDetails;
		
		If Not IsBlankString(Method.ParametersDetails) Then
			TitleParameters = "<p class=""Paragraph0c""><span class=""Bold"">" + "%1" + "</span></p>";
			TitleParameters = StringFunctionsClientServer.SubstituteParametersToString(TitleParameters, StringParameters_());
			ParametersDetails = "<pre>" + AddRefToDetails(Method.ParametersDetails, Method) + "</pre>";
			
			Result = Result + Chars.LF + TitleParameters;
			Result = Result + Chars.LF + ParametersDetails;
		EndIf;
		
		If Not IsBlankString(Method.DescriptionOfReturnValue) Then
			ReturnsHeader = "<p class=""Paragraph0c""><span class=""Bold"">" + "%1" + "</span></p>";
			ReturnsHeader = StringFunctionsClientServer.SubstituteParametersToString(ReturnsHeader, StringReturnValue());
			DescriptionOfReturnValue = "<pre>" + AddRefToDetails(Method.DescriptionOfReturnValue , Method) + "</pre>";
			
			Result = Result + Chars.LF + ReturnsHeader;
			Result = Result + Chars.LF + DescriptionOfReturnValue;
		EndIf;
		
		If Method.Location = LineInterface() Then
			CallExampleHeader = "<p class=""Paragraph0c""><span class=""Bold"">" + "%1" + "</span></p>";
			CallExampleHeader = StringFunctionsClientServer.SubstituteParametersToString(CallExampleHeader, StringExampleCall());
			If Method.ExampleDetails <> "" Then
				CallExampleDetails = "<pre>" + AddRefToDetails(Method.ExampleDetails, Method) + "</pre>";
			Else
				CallExampleDetails = "<pre>" + Method.CallSyntax + "</pre>";
			EndIf;
			
			Result = Result + Chars.LF + CallExampleHeader;
			Result = Result + Chars.LF + CallExampleDetails;
		Else
			
			If Method.ExampleDetails <> "" Then
				ImplementationExampleHeader = "<p class=""Paragraph0c""><span class=""Bold"">" + "%1" + "</span></p>";
				ImplementationExampleHeader = StringFunctionsClientServer.SubstituteParametersToString(ImplementationExampleHeader, StringExampleImplementation());
				CallExampleDetails      = "<pre>" + AddRefToDetails(Method.ExampleDetails, Method) + "</pre>";
				
				Result = Result + Chars.LF + ImplementationExampleHeader;
				Result = Result + Chars.LF + CallExampleDetails;
			EndIf;
			
			LocationHeader = "<p class=""Paragraph0c""><span class=""Bold"">" + "%1" + "</span></p>";
			LocationHeader = StringFunctionsClientServer.SubstituteParametersToString(LocationHeader, StringLocation());
			
			PlacementDetails = StringCommonModule() + " %1";
			PlacementDetails = "<pre>" + " " + StringFunctionsClientServer.SubstituteParametersToString(PlacementDetails, StrSplit(Method.FullObjectName, ".")[1]) + "</pre>";
			
			Result = Result + Chars.LF + LocationHeader;
			Result = Result + Chars.LF + PlacementDetails;
		EndIf;
		
		// Availability.
		AvailabilityHeader = "<p class=""Paragraph0c""><span class=""Bold"">" + "%1" + "</span></p>";
		AvailabilityHeader = StringFunctionsClientServer.SubstituteParametersToString(AvailabilityHeader, AvailabilityLine_());
		AvailabilityDetails  = "<pre>" + " " + Method.Enabled + "</pre>";
		
		Result = Result + Chars.LF + AvailabilityHeader;
		Result = Result + Chars.LF + AvailabilityDetails;
		
	EndDo;
	
	Result = Header + Result + Chars.LF + Footer;
	
	TextDocument = New TextDocument;
	TextDocument.SetText(Result);
	TextDocument.Write(PathToFile);
	
	FilePathInParts = StrSplit(PathToFile, "/");
	FileName          = FilePathInParts.Get(FilePathInParts.Count() - 1);
	StyleFilePath   = StrReplace(PathToFile, FileName, "style.css");
	
	TextDocument = GetTemplate("Template");
	TextDocument.Write(StyleFilePath);
	
EndProcedure

// Convert the filename to the object full name.

Function FullNameByModuleName(FullPathWithName, FileNameWithExtension)
	FullFileName = StrReplace(FullPathWithName, "\", "/");
	FormPath     = StrReplace(FullFileName, DumpDirectory + "/", "");
	ModuleNameByParts = StrSplit(FormPath, "/");
	
	FullObjectName = "";
	FullModuleName  = "";
	Step = 0;
	For Each PathPart In ModuleNameByParts Do
		Step = Step + 1;
		If Upper(PathPart) = "EXT" Then
			Continue;
		EndIf;
		
		If PathPart = FileNameWithExtension Then
			PathPart = StrSplit(PathPart, ".")[0];
		EndIf;
		
		TransformedPathPart = EnglishAndNationalNamesMap()[PathPart];
		If TransformedPathPart = Undefined Then
			TransformedPathPart = PathPart;
		EndIf;
		
		If Step < 3 Then
			FullObjectName = ?(FullObjectName = "",
				                 TransformedPathPart,
				                 FullObjectName + "." + TransformedPathPart);
		EndIf;
		
		FullModuleName = ?(FullModuleName = "",
			                 TransformedPathPart,
			                 FullModuleName + "." + TransformedPathPart);
	EndDo;
	
	Result = New Structure;
	Result.Insert("FullObjectName", FullObjectName);
	Result.Insert("FullModuleName", FullModuleName);
	
	Return Result;
EndFunction

Function FullMethodNameByModuleName(Method)
	
	FullNameParts = StrSplit(Method.FullObjectName, ".");
	ModuleName = FullNameParts[FullNameParts.UBound()];
	
	Return ModuleName +"."+ Method.MethodName;
	
EndFunction

Function EnglishAndNationalNamesMap()
	Result = New Map;
	
	// Metadata object kinds.
	Result.Insert("AccountingRegister", "AccountingRegister");
	Result.Insert("AccumulationRegister", "AccumulationRegister");
	Result.Insert("BusinessProcess", "BusinessProcess");
	Result.Insert("CalculationRegister", "CalculationRegister");
	Result.Insert("Catalog", "Catalog");
	Result.Insert("ChartOfAccounts", "ChartOfAccounts");
	Result.Insert("ChartOfCalculationTypes", "ChartOfCalculationTypes");
	Result.Insert("ChartOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	Result.Insert("CommandGroup", "CommandGroup");
	Result.Insert("CommonAttribute", "CommonAttribute");
	Result.Insert("CommonCommand", "CommonCommand");
	Result.Insert("CommonForm", "CommonForm");
	Result.Insert("CommonModule", "CommonModule");
	Result.Insert("CommonPicture", "CommonPicture");
	Result.Insert("CommonTemplate", "CommonTemplate");
	Result.Insert("Configuration", "Configuration");
	Result.Insert("Constant", "Constant");
	Result.Insert("DataProcessor", "DataProcessor");
	Result.Insert("DefinedType", "DefinedType");
	Result.Insert("Document", "Document");
	Result.Insert("DocumentJournal", "DocumentJournal");
	Result.Insert("DocumentNumerator", "DocumentNumerator");
	Result.Insert("Enum", "Enum");
	Result.Insert("EventSubscription", "EventSubscription");
	Result.Insert("ExchangePlan", "ExchangePlan");
	Result.Insert("FilterCriterion", "FilterCriterion");
	Result.Insert("FunctionalOption", "FunctionalOption");
	Result.Insert("FunctionalOptionsParameter", "FunctionalOptionsParameter");
	Result.Insert("InformationRegister", "InformationRegister");
	Result.Insert("Language", "Language");
	Result.Insert("Report", "Report");
	Result.Insert("Role", "Role");
	Result.Insert("ScheduledJob", "ScheduledJob");
	Result.Insert("Sequence", "Sequence");
	Result.Insert("SessionParameter", "SessionParameter");
	Result.Insert("SettingsStorage", "SettingsStorage");
	Result.Insert("Style", "Style");
	Result.Insert("StyleItem", "StyleItem");
	Result.Insert("Subsystem", "Subsystem");
	Result.Insert("Task", "Task");
	Result.Insert("WebService", "WebService");
	Result.Insert("WSReference", "WSReference");
	Result.Insert("XDTOPackage", "XDTOPackage");
	
	// Metadata object kinds (plural form).
	Result.Insert("AccountingRegisters", "AccountingRegister");
	Result.Insert("AccumulationRegisters", "AccumulationRegister");
	Result.Insert("BusinessProcesses", "BusinessProcess");
	Result.Insert("CalculationRegisters", "CalculationRegister");
	Result.Insert("Catalogs", "Catalog");
	Result.Insert("ChartsOfAccounts", "ChartOfAccounts");
	Result.Insert("ChartsOfCalculationTypes", "ChartOfCalculationTypes");
	Result.Insert("ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes");
	Result.Insert("CommandGroups", "CommandGroup");
	Result.Insert("CommonAttributes", "CommonAttribute");
	Result.Insert("CommonCommands", "CommonCommand");
	Result.Insert("CommonForms", "CommonForm");
	Result.Insert("CommonModules", "CommonModule");
	Result.Insert("CommonPictures", "CommonPicture");
	Result.Insert("CommonTemplates", "CommonTemplate");
	Result.Insert("Configurations", "Configuration"); // Obsolete.
	Result.Insert("Constants", "Constant");
	Result.Insert("DataProcessors", "DataProcessor");
	Result.Insert("DefinedTypes", "DefinedType");
	Result.Insert("Documents", "Document");
	Result.Insert("DocumentJournals", "DocumentJournal");
	Result.Insert("DocumentNumerator", "DocumentNumerator");
	Result.Insert("Enums", "Enum");
	Result.Insert("EventSubscriptions", "EventSubscription");
	Result.Insert("ExchangePlans", "ExchangePlan");
	Result.Insert("FilterCriteria", "FilterCriterion");
	Result.Insert("FunctionalOptions", "FunctionalOption");
	Result.Insert("FunctionalOptionsParameters", "FunctionalOptionsParameter");
	Result.Insert("InformationRegisters", "InformationRegister");
	Result.Insert("Languages", "Language");
	Result.Insert("Reports", "Report");
	Result.Insert("Roles", "Role");
	Result.Insert("ScheduledJobs", "ScheduledJob");
	Result.Insert("Sequences", "Sequence");
	Result.Insert("SessionParameters", "SessionParameter");
	Result.Insert("SettingsStorages", "SettingsStorage");
	Result.Insert("Style", "Style");
	Result.Insert("StyleItems", "StyleItem");
	Result.Insert("Subsystems", "Subsystem");
	Result.Insert("Tasks", "Task");
	Result.Insert("WebServices", "WebService");
	Result.Insert("WSReference", "WSReference");
	Result.Insert("XDTOPackages", "XDTOPackage");
	
	// Types of nested metadata objects.
	Result.Insert("Module", "Module");
	Result.Insert("ManagerModule", "ManagerModule");
	Result.Insert("ObjectModule", "ObjectModule");
	Result.Insert("CommandModule", "CommandModule");
	Result.Insert("RecordSetModule", "RecordSetModule");
	Result.Insert("ValueManagerModule", "ValueManagerModule");
	
	Result.Insert("ExternalConnectionModule", "ExternalConnectionModule");
	Result.Insert("ManagedApplicationModule", "ManagedApplicationModule");
	Result.Insert("OrdinaryApplicationModule", "OrdinaryApplicationModule");
	Result.Insert("SessionModule", "SessionModule");
	
	Result.Insert("Help", "Help");
	Result.Insert("Form", "Form");
	Result.Insert("Flowchart", "Flowchart");
	Result.Insert("Picture", "Picture");
	Result.Insert("CommandInterface", "CommandInterface");
	
	Result.Insert("Template", "Template");
	Result.Insert("Command", "Command");
	Result.Insert("Aggregates", "Aggregates");
	Result.Insert("Recalculation", "Recalculation");
	Result.Insert("Predefined", "Predefined");
	Result.Insert("Content", "Content");
	Result.Insert("Rights", "Rights");
	Result.Insert("Schedule", "Schedule");
	
	// Types of nested metadata objects (plural form).
	Result.Insert("Module", "Module");
	Result.Insert("ManagerModule", "ManagerModule");
	Result.Insert("ObjectModule", "ObjectModule");
	Result.Insert("CommandModule", "CommandModule");
	Result.Insert("RecordSetModule", "RecordSetModule");
	Result.Insert("ValueManagerModule", "ValueManagerModule");
	
	Result.Insert("ExternalConnectionModule", "ExternalConnectionModule");
	Result.Insert("ManagedApplicationModule", "ManagedApplicationModule");
	Result.Insert("OrdinaryApplicationModule", "OrdinaryApplicationModule");
	Result.Insert("SessionModule", "SessionModule");
	
	Result.Insert("Help", "Help");
	Result.Insert("Forms", "Form");
	Result.Insert("Flowchart", "Flowchart");
	Result.Insert("Picture", "Picture");
	Result.Insert("CommandInterface", "CommandInterface");
	
	Result.Insert("Templates", "Template");
	Result.Insert("Commands", "Command");
	Result.Insert("Aggregates", "Aggregates");
	Result.Insert("Recalculations", "Recalculation");
	Result.Insert("Predefined", "Predefined");
	Result.Insert("Content", "Content");
	Result.Insert("Rights", "Rights");
	Result.Insert("Schedule", "Schedule");
	
	Return Result;
EndFunction

// Dump the configuration into files.

Procedure UploadConfigurationToXML()
	
	If ValueIsFilled(DumpDirectory) Then
		Directory = New File(DumpDirectory);
		If Not Directory.Exists() Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Указанный каталог выгрузки ""%1"" не существует.';
					|en = 'Specified ""%1"" export directory does not exist.';"), DumpDirectory);
		EndIf;
		If FindFiles(DumpDirectory, "Configuration.xml").Count() = 0 Then
			Raise StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Указанный каталог выгрузки ""%1"" не содержит файлов выгрузки конфигурации.';
					|en = 'Specified ""%1"" export directory does not contain configuration export files.';"), DumpDirectory);
		EndIf;
		Return;
	EndIf;
	
	If InfoBaseUsers.CurrentUser().PasswordIsSet Then
		Raise NStr("ru = 'Проверка возможна только для пользователя без пароля.';
								|en = 'Can check only for users without password.';");
	EndIf;
	
	DumpDirectory = GetTempFileName("ProgrammingInterfaceDetails");
	
	BinDir = StandardSubsystemsServer.ClientParametersAtServer().Get("BinDir");
	CreateDirectory(DumpDirectory);
	
	DumpDirectory = StrReplace(DumpDirectory, "\", "/");
	
	ConnectionString = InfoBaseConnectionString();
	If DesignerIsOpen() Then
		If Common.FileInfobase() Then
			InfobaseDirectory = StringFunctionsClientServer.ParametersFromString(ConnectionString).file;
			FileCopy(InfobaseDirectory + "/1Cv8.1CD", DumpDirectory + "/1Cv8.1CD");
			ConnectionString = StringFunctionsClientServer.SubstituteParametersToString("File=""%1"";", DumpDirectory);
		Else
			Raise NStr("ru = 'Для проверки закройте конфигуратор.';
									|en = 'To check, close Designer.';");
		EndIf;
	EndIf;
	
	MessagesFileName = DumpDirectory + "/UploadConfigurationToFilesMessages.txt";
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir + "1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(ConnectionString);
	StartupCommand.Add("/N");
	StartupCommand.Add(UserName());
	StartupCommand.Add("/P");
	StartupCommand.Add();
	StartupCommand.Add("/DumpConfigToFiles");
	StartupCommand.Add(DumpDirectory);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	If Result.ReturnCode <> 0 Then
		Try
			Text = New TextDocument;
			Text.Read(MessagesFileName);
			Messages = Text.GetText();
		Except
			Messages = "";
		EndTry;
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось выполнить выгрузку конфигурации в файлы по причине:
			           |%1';
						|en = 'Failed to import configuration to files due to:
						|%1';"), Messages);
	EndIf;
	
EndProcedure

Function DesignerIsOpen()
	Sessions = GetInfoBaseSessions();
	For Each Session In Sessions Do
		If Upper(Session.ApplicationName) = "DESIGNER" Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

// API area details.

Function APIArea1()
	
	If EnglishVersion Then
		Return "#Region Public";
	Else
		Return "#Area Public";
	EndIf;
	
EndFunction

Function AreaStart()
	
	If EnglishVersion Then
		Return "#Region";
	Else
		Return "#Area";
	EndIf;
	
EndFunction

Function EndRegion()
	
	If EnglishVersion Then
		Return "#EndRegion";
	Else
		Return "#EndRegion";
	EndIf;
	
EndFunction

// Add crossreferences to the details.

Function AddRefToDetails(LongDesc, Method)
	
	NormalizeString(LongDesc);
	
	PositionSee = StrFind(Upper(LongDesc), " SEE.");
	If PositionSee = 0 Then
		Return LongDesc;
	EndIf;
	
	EntryNumber = 1;
	While PositionSee > 0 Do
		EntireRow = "see. ";
		
		PositionSee   = PositionSee + 4;
		EndOfRow = StrFind(LongDesc, Chars.LF, , PositionSee);
		String = Mid(LongDesc, PositionSee, EndOfRow - PositionSee);
		EntireRow = EntireRow + String;
		RefAdded = False;
		FindAndAddRef(LongDesc, String, RefAdded, Method);
		If Not RefAdded Then
			BeginningOfTheLine = EndOfRow + 1;
			EndOfRow  = StrFind(LongDesc, Chars.LF, , BeginningOfTheLine);
			String = Mid(LongDesc, BeginningOfTheLine, EndOfRow - BeginningOfTheLine);
			FindAndAddRef(LongDesc, String, RefAdded, Method);
			EntireRow = EntireRow + Chars.LF + String;
		EndIf;
		
		If Not RefAdded Then
			SaveMissedHyperlink(Method, EntireRow);
		EndIf;
		
		EntryNumber = EntryNumber + 1;
		PositionSee = StrFind(Upper(LongDesc), " SEE.",,, EntryNumber);
	EndDo;
	
	Return LongDesc;
EndFunction

Procedure FindAndAddRef(LongDesc, String, RefAdded, Method)
	
	StringParts = StrSplit(String, " ", False);
	If StrFind(Upper(String), "SYNTHAX-ASSISTANT") > 0 Then
		RefAdded = True;
		Return;
	ElsIf StrFind(String, "<a href=""#_") > 0 Then
		RefAdded = True;
		Return;
	EndIf;
	
	For Each RowPart In StringParts Do
		RowPart = TrimAll(RowPart);
		RowPart = StrReplace(RowPart, "(", "");
		RowPart = StrReplace(RowPart, ")", "");
		RowPart = StrReplace(RowPart, """", "");
		RowPart = StrReplace(RowPart, ",", "");
		RowPart = StrReplace(RowPart, ":", "");
		RowPart = StrReplace(RowPart, ";", "");
		
		FirstChar = Left(RowPart, 1);
		If FirstChar = Lower(FirstChar) Then
			// Not a method.
			Continue;
		EndIf;
		
		RefDestination = Undefined;
		RowPartAsParts = StrSplit(RowPart, ".", False);
		If RowPartAsParts.Count() = 2 Then
			RefDestination = RefDestination(RowPartAsParts, Method.FullObjectName);
		ElsIf RowPartAsParts.Count() = 1 Then
			RefDestination = RefDestination(RowPartAsParts, Method.FullObjectName, True);
		Else
			RefAdded = True;
			// Logging.
			SaveMissedHyperlink(Method, String);
			Return;
		EndIf;
		
		If RefDestination = Undefined Then
			Continue;
		EndIf;
		
		If RefDestination.MethodName = Method.MethodName
			And RefDestination.FullObjectName = Method.FullObjectName Then
			RefAdded = True;
			// Logging.
			IssueText = NStr("ru = 'Ссылка на самого себя:';
								|en = 'A reference to itself:';");
			IssueText = IssueText + Chars.LF + String;
			SaveMissedHyperlink(Method, IssueText);
			Return;
		EndIf;
		
		RefBody = StrConcat(RowPartAsParts, ".");
		HyperlinkAddress = "#_" + HyperlinkAddress(RefDestination);
		Ref = StringFunctionsClientServer.SubstituteParametersToString("<a href=""%1"">%2</a>", HyperlinkAddress, RefBody);
		
		// Logging.
		RefPosition = StrFind(String, RefBody);
		CharBeforeRef = Mid(String, RefPosition-1, 1);
		If CharBeforeRef = """" Then
			MethodCallSyntax = MethodCallSyntax(Method.MethodSyntax, Method.FullObjectName);
			HyperlinkInQuotes = DetailsGenerationLog.HyperlinkInQuotes; // ValueList
			HyperlinkInQuotes.Add(MethodCallSyntax.CallSyntaxWithoutParameters);
		EndIf;
		
		NewRow = StrReplace(String, RefBody, Ref);
		LongDesc = StrReplace(LongDesc, String, NewRow);
		RefAdded = True;
		Break;
	EndDo;
	
EndProcedure

Function RefDestination(RowPartAsParts, RefSource, WithinModule = False)
	FilterParameters = New Structure;
	FilterParameters.Insert("MethodName", RowPartAsParts[RowPartAsParts.Count()-1]);
	Result = APIStructure.FindRows(FilterParameters);
	
	RefDestination = Undefined;
	If Result.Count() = 1 Then
		RefDestination = Result[0];
	ElsIf Result.Count() > 1 Then
		For Each ResultString1 In Result Do
			If WithinModule And ResultString1.FullObjectName = RefSource Then
				RefDestination = ResultString1;
				Break;
			ElsIf Not WithinModule
				And StrFind(ResultString1.FullObjectName, RowPartAsParts[0]) > 0 Then
				RefDestination = ResultString1;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return RefDestination;
EndFunction

// Auxiliary procedures and functions.

Procedure SetVariables()
	
	CommentRead        = False;
	ReadParameters1           = False;
	ReadReturnValues = False;
	ReadMethod1               = False;
	ReadExample              = False;
	MethodRead              = False;
	
	MethodStructure = New Structure;
	MethodStructure.Insert("MethodDesc", "");
	MethodStructure.Insert("ParametersDetails", "");
	MethodStructure.Insert("DescriptionOfReturnValue", "");
	MethodStructure.Insert("ExampleDetails", "");
	MethodStructure.Insert("MethodSyntax", "");
	MethodStructure.Insert("FullObjectName", "");
	MethodStructure.Insert("Subsystem", "");
	MethodStructure.Insert("Enabled", MethodAvailability);
	MethodStructure.Insert("Location", "");
	MethodStructure.Insert("Area", "");
	MethodStructure.Insert("MethodName", "");
	MethodStructure.Insert("CallSyntax", "");
	MethodStructure.Insert("AvailabilityID", AvailabilityID);
	
EndProcedure

Function ObjectManagerNameByType(ObjectType)
	
	If ObjectTypeAndManager = Undefined Then
		ObjectTypeAndManager = New Map;
		ObjectTypeAndManager.Insert("CommonModule", "");
		ObjectTypeAndManager.Insert("ExchangePlan", "ExchangePlans.");
		ObjectTypeAndManager.Insert("SettingsStorage", "SettingsStorages.");
		ObjectTypeAndManager.Insert("Constant", "Constant.");
		ObjectTypeAndManager.Insert("Catalog", "Catalogs.");
		ObjectTypeAndManager.Insert("Document", "Documents.");
		ObjectTypeAndManager.Insert("DocumentJournal", "DocumentJournals.");
		ObjectTypeAndManager.Insert("Enum", "Enums.");
		ObjectTypeAndManager.Insert("Report", "Reports.");
		ObjectTypeAndManager.Insert("DataProcessor", "DataProcessors.");
		ObjectTypeAndManager.Insert("ChartOfCharacteristicTypes", "ChartsOfCharacteristicTypes.");
		ObjectTypeAndManager.Insert("ChartOfAccounts", "ChartsOfAccounts.");
		ObjectTypeAndManager.Insert("ChartOfCalculationTypes", "ChartsOfCalculationTypes.");
		ObjectTypeAndManager.Insert("InformationRegister", "InformationRegisters.");
		ObjectTypeAndManager.Insert("AccumulationRegister", "AccumulationRegisters.");
		ObjectTypeAndManager.Insert("AccountingRegister", "AccountingRegisters.");
		ObjectTypeAndManager.Insert("CalculationRegister", "CalculationRegisters.");
		ObjectTypeAndManager.Insert("BusinessProcess", "BusinessProcesses.");
		ObjectTypeAndManager.Insert("Task", "Tasks.");
	EndIf;
	
	Return ObjectTypeAndManager[ObjectType];
	
EndFunction

Procedure FillObjectsToSubsystemsMap(Map, SubsystemsCollection = Undefined)
	
	AnalysisByList = SubsystemsBeingAnalyzed.Count() > 0;
	If AnalysisByList Then
		FillInCorrespondenceOfObjectsToSubsystemsInList(Map, SubsystemsBeingAnalyzed.UnloadValues());
	Else
		FillInCorrespondenceOfObjectsToSubsystemsForUnloading(Map);
	EndIf;
	
EndProcedure

Procedure FillInCorrespondenceOfObjectsToSubsystemsInList(Map, SubsystemsCollection = Undefined)
	
	For Each SubsystemItem In SubsystemsCollection Do
		
		SubsystemItem = Common.MetadataObjectByFullName(SubsystemItem);
		
		SubsystemComposition = SubsystemItem.Content;
		For Each MetadataObject In SubsystemComposition Do
			FullMetadataObjectName2 = MetadataObject.FullName();
			Subsystem   = SubsystemItem.Synonym;
			Map.Insert(FullMetadataObjectName2, Subsystem);
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure FillInCorrespondenceOfObjectsToSubsystemsForUnloading(Map)
	
	If EnglishVersion Then
		SynonymLanguage = "en";
		SPCatalog    = "StandardSubsystems";
	Else
		SynonymLanguage = "ru";
		SPCatalog    = "StandardSubsystems";
	EndIf;
	
	PathSeparator = GetPathSeparator();
	SubsystemFiles = FindFiles(DumpDirectory + PathSeparator + "Subsystems" + PathSeparator + SPCatalog, "*xml", True);
	For Each SubsystemFile In SubsystemFiles Do
		
		If SubsystemFile.Name = "Help.xml" 
			Or SubsystemFile.Name = "CommandInterface.xml" Then
			Continue;
		EndIf;
		
		DOMDocument    = DOMDocument(SubsystemFile.FullName);
		Dereferencer = DOMDocument.CreateNSResolver();
		XPathExpression = "//xmlns:Synonym/v8:item/v8:lang[text() = '" + SynonymLanguage + "']/../v8:content";
		
		Result = DOMDocument.EvaluateXPathExpression(XPathExpression, DOMDocument, Dereferencer).IterateNext();
		Synonym   = Result.TextContent;
		
		XPathExpression = "//xmlns:Content/xr:Item";
		Result      = DOMDocument.EvaluateXPathExpression(XPathExpression, DOMDocument, Dereferencer);
		While True Do
			CurElementComposition = Result.IterateNext();
			If CurElementComposition = Undefined Then
				Break;
			EndIf;
			TagName = StrReplace(CurElementComposition.TextContent, "CommonModule", "CommonModule");
			If StrStartsWith(TagName, "CommonModule") Then
				Map.Insert(TagName, Synonym);
			EndIf;
		EndDo;
		
	EndDo;
	
EndProcedure

Function DOMDocument(XMLFilePath)
	
	XMLReader = New XMLReader;
	DOMBuilder = New DOMBuilder;
	XMLReader.OpenFile(XMLFilePath);
	DOMDocument = DOMBuilder.Read(XMLReader);
	XMLReader.Close();
	
	Return DOMDocument;
	
EndFunction

Procedure FillMethodAvailability(ModuleFile)
	FullModuleName = StrReplace(ModuleFile.FullName, "\", "/");
	
	ModuleRootXML = StrReplace(FullModuleName, "/Ext/Module.bsl", ".xml");
	DOMDocument       = DOMDocument(ModuleRootXML);
	MethodAvailability = New Array;
	
	ServerAvailability = DOMDocument.GetElementByTagName("Server")[0].TextContent;
	If Boolean(ServerAvailability) Then
		MethodAvailability.Add(StringServer());
	EndIf;
	
	ServerCallAvailability = DOMDocument.GetElementByTagName("ServerCall")[0].TextContent;
	If Boolean(ServerCallAvailability) Then
		MethodAvailability.Add(ServerCallString());
	EndIf;
	
	ClientManagedApplicationAvailability = DOMDocument.GetElementByTagName("ClientManagedApplication")[0].TextContent;
	If Boolean(ClientManagedApplicationAvailability) Then
		MethodAvailability.Add(StringThinClient());
	EndIf;
	
	ClientOrdinaryApplicationAvailability = DOMDocument.GetElementByTagName("ClientOrdinaryApplication")[0].TextContent;
	If Boolean(ClientOrdinaryApplicationAvailability) Then
		MethodAvailability.Add(FatClientLine());
	EndIf;
	
	ExternalConnectionAvailability = DOMDocument.GetElementByTagName("ExternalConnection")[0].TextContent;
	If Boolean(ExternalConnectionAvailability) Then
		MethodAvailability.Add(ExternalConnectionString());
	EndIf;
	
	If Boolean(ServerAvailability) And (Boolean(ClientManagedApplicationAvailability) Or Boolean(ServerCallAvailability)) Then
		AvailabilityID = ClientAndServerString();
	ElsIf Boolean(ServerAvailability) Then
		AvailabilityID = StringServer();
	Else
		AvailabilityID = StringClient();
	EndIf;
	
	MethodAvailability = StrConcat(MethodAvailability, ", ");
	
EndProcedure

Function HyperlinkAddress(Method)
	FullNameParts = StrSplit(Method.FullObjectName, ".");
	ModuleName = FullNameParts[1];
	Return ModuleName + Method.MethodName;
EndFunction

Function MethodCallSyntax(Val Method, Val Placement)
	
	IsFunction = StrFind(Method, StringFunction() + " ") > 0;
	
	Method = StrReplace(Method, StringFunction() + " ", "");
	Method = StrReplace(Method, StringProcedure() + " ", "");
	Method = StrReplace(Method, " " + ExportLine(), "");
	Method = StrReplace(Method, ")", "");
	
	MethodAndParameters = StrSplit(Method, "(");
	
	MethodName = MethodAndParameters[0];
	Parameters = MethodAndParameters[1];
	
	ParametersString1 = "";
	If Not IsBlankString(Parameters) Then
		ParametersArray = StrSplit(Parameters, ",");
		For Each Parameter In ParametersArray Do
			Parameter = TrimAll(StrReplace(Parameter, Line1(), ""));
			Parameter = TrimAll(StrSplit(Parameter, "=")[0]);
			ParametersString1 = ?(IsBlankString(ParametersString1), Parameter, ParametersString1 + ", " + Parameter);
		EndDo;
	EndIf;
	
	FullObjectNameInParts = StrSplit(Placement, ".");
	ObjectType   = FullObjectNameInParts[0];
	ManagerName = ObjectManagerNameByType(ObjectType);
	
	CallSyntaxWithoutParameters = ManagerName + FullObjectNameInParts[1] + "." + MethodName;
	CallSyntax = CallSyntaxWithoutParameters + "(" + ParametersString1 + ")";
	
	Result = New Structure;
	Result.Insert("CallSyntax", CallSyntax);
	Result.Insert("MethodName", MethodName);
	Result.Insert("CallSyntaxWithoutParameters", CallSyntaxWithoutParameters);
	Result.Insert("IsFunction", IsFunction);
	
	Return Result;
	
EndFunction

Procedure SaveMissedHyperlink(Method, Placement)
	MethodCallSyntax = MethodCallSyntax(Method.MethodSyntax, Method.FullObjectName);
	HyperlinkNotFound = DetailsGenerationLog.HyperlinkNotFound; // ValueList 
	HyperlinkNotFound.Add(MethodCallSyntax.CallSyntaxWithoutParameters, Placement);
EndProcedure

Procedure NormalizeString(Text)
	Text = StrReplace(Text, "&",  "&amp;");
	Text = StrReplace(Text, "'",  "&apos;");
	Text = StrReplace(Text, "<",  "&lt;");
	Text = StrReplace(Text, ">",  "&gt;");
EndProcedure

Function MatchingMethodsTitle1(Method, MappedMethodIndex)
	
	If Method.AvailabilityID = ClientAndServerString() Then
		Title = String(MappedMethodIndex) + ". " + StringToCallFromClientAndServer();
	ElsIf Method.AvailabilityID = StringClient() Then
		Title = String(MappedMethodIndex) + ". " + StringToCallFromClient();
	Else
		Title = String(MappedMethodIndex) + ". " +  StringToCallFromServer();
	EndIf;
	
	MatchingMethodsTitle = "<p class=""Paragraph0c""><span class=""Bold"">[Адрес]%1</span></p>";//@Non-NLS
	MatchingMethodsTitle = StringFunctionsClientServer.SubstituteParametersToString(MatchingMethodsTitle, Title);
	
	Return MatchingMethodsTitle;
	
EndFunction

Function MatchingMethodsDetails(Method, NextMethod)
	
	ServerMethod = ?(Method.AvailabilityID = StringServer(), Method, NextMethod);
	ClientMethod = ?(Method.AvailabilityID = StringClient(), Method, NextMethod);
	
	GoToDetailsBlockRefServer = StringFunctionsClientServer.SubstituteParametersToString("<a href=""%1"">%2</a> " + Lower(StringToCallFromServer()), "#_" + ServerMethod.AvailabilityID + HyperlinkAddress(ServerMethod), FullMethodNameByModuleName(ServerMethod));//@Non-NLS
	GoToDetailsBlockRefClient  = StringFunctionsClientServer.SubstituteParametersToString("<a href=""%1"">%2</a> " + Lower(StringToCallFromClient()), "#_" + ClientMethod.AvailabilityID + HyperlinkAddress(ClientMethod), FullMethodNameByModuleName(ClientMethod));//@Non-NLS
	
	DetailsText = StringProvidesTwoFunctions() + ":
		|%1
		|%2";
	
	LongDesc = StringFunctionsClientServer.SubstituteParametersToString(DetailsText, GoToDetailsBlockRefServer, GoToDetailsBlockRefClient);
	
	Return LongDesc;
	
EndFunction

Function LineOverrideDescription()
	
	If EnglishVersion Then
		Return "Redefine";//@Non-NLS
	Else
		Return "Переопределение";//@Non-NLS
	EndIf;
	
EndFunction

Function StringProvidesTwoFunctions()
	
	If EnglishVersion Then
		Return "There are two functions with the same name";//@Non-NLS
	Else
		Return "Предусмотрено две одноименных функции";//@Non-NLS
	EndIf;
	
EndFunction

Function ClientAndServerString()
	
	If EnglishVersion Then
		Return "ClientAndServer";//@Non-NLS
	Else
		Return "КлиентИСервер";//@Non-NLS
	EndIf;
	
EndFunction

Function StringClient()
	
	If EnglishVersion Then
		Return "Client";//@Non-NLS
	Else
		Return "Клиент";//@Non-NLS
	EndIf;
	
EndFunction

Function StringCommonModule()
	
	If EnglishVersion Then
		Return "Common module";//@Non-NLS
	Else
		Return "Общий модуль";//@Non-NLS
	EndIf;
	
EndFunction

Function StringToCallFromServer()
	
	If EnglishVersion Then
		Return "To call from the server";//@Non-NLS
	Else
		Return "Для вызова с сервера";//@Non-NLS
	EndIf;
	
EndFunction

Function StringToCallFromClient()
	
	If EnglishVersion Then
		Return "To call from the client";//@Non-NLS
	Else
		Return "Для вызова с клиента";//@Non-NLS
	EndIf;
	
EndFunction

Function StringToCallFromClientAndServer()
	
	If EnglishVersion Then
		Return "To call both from the client and server";//@Non-NLS
	Else
		Return "Для вызова с клиента и сервера";//@Non-NLS
	EndIf;
	
EndFunction

Function Line1()
	
	If EnglishVersion Then
		Return "Val ";//@Non-NLS
	Else
		Return "Знач ";//@Non-NLS
	EndIf;
	
EndFunction

Function ExternalConnectionString()
	
	If EnglishVersion Then
		Return "External connection";//@Non-NLS
	Else
		Return "Внешнее соединение";//@Non-NLS
	EndIf;
	
EndFunction

Function FatClientLine()
	
	If EnglishVersion Then
		Return "Thick client";//@Non-NLS
	Else
		Return "Толстый клиент";//@Non-NLS
	EndIf;
	
EndFunction

Function StringThinClient()
	
	If EnglishVersion Then
		Return "Thin client";//@Non-NLS
	Else
		Return "Тонкий клиент";//@Non-NLS
	EndIf;
	
EndFunction

Function ServerCallString()
	
	If EnglishVersion Then
		Return "Server call";//@Non-NLS
	Else
		Return "Вызов сервера";//@Non-NLS
	EndIf;
	
EndFunction

Function StringServer()
	
	If EnglishVersion Then
		Return "Server";//@Non-NLS
	Else
		Return "Сервер";//@Non-NLS
	EndIf;
	
EndFunction

Function AvailabilityLine_()
	
	If EnglishVersion Then
		Return "Availability";//@Non-NLS
	Else
		Return "Доступность";//@Non-NLS
	EndIf;
	
EndFunction

Function StringLocation()
	
	If EnglishVersion Then
		Return "Location";//@Non-NLS
	Else
		Return "Расположение";//@Non-NLS
	EndIf;
	
EndFunction

Function StringExampleImplementation()
	
	If EnglishVersion Then
		Return "Implementation example";//@Non-NLS
	Else
		Return "Пример реализации";//@Non-NLS
	EndIf;
	
EndFunction

Function StringExampleCall()
	
	If EnglishVersion Then
		Return "Call example";//@Non-NLS
	Else
		Return "Пример вызова";//@Non-NLS
	EndIf;
	
EndFunction

Function StringSyntax()
	
	If EnglishVersion Then
		Return "Syntax";//@Non-NLS
	Else
		Return "Синтаксис";//@Non-NLS
	EndIf;
	
EndFunction

Function StringReferenceToStandards()
	
	If EnglishVersion Then
		Return "<a href=""https://1c-dn.com/library/methodology/"">1C:Enterprise best practises</a>"; //@Non-NLS
	Else
		Return "<a href=""http://its.1c.eu/db/v8std"">""Системе стандартов и методик разработки конфигураций для платформы 1С:Предприятие 8""</a>"; //@Non-NLS
	EndIf;
	
EndFunction

Function LineDetails()
	
	If EnglishVersion Then
		Details_ = "<p class=""Paragraph0c"">
		|Application interface 1C:Standard subsystem library in developer set of tools includes
		| all export procedures and functions that are located in the Public code areas.
		|When developing your own libraries and applications it is strongly recommended to use 
		|procedures and functions of the library interface only.</p>
		|<p class=""Paragraph0c"">When issuing new library versions, backward compatibility is provided in these procedures in functions. This
		|does not require application developers to revise their code and adapt metadata objects of their
		| configurations to new requirements and features of each new library version. It is not guaranteed for
		|all other internal export procedures and functions.</p>
		|<p class=""Paragraph0c"">For the convenience of searching and studying, application interface is grouped by subsystems and divided into two main categories:</p>
		|<p class=""MsoListBullet""><span class=""Bold"">Interface</span> – 
		|export procedures and functions that are designed to call from the applied code.</p>
		|<p class=""MsoListBullet""><span class=""Bold"">Redefine</span> – 
		|export procedures of overridable modules whose composition can or must be changed in 
		|consumer configuration. Using them, the tasks of changing the library functionality behavior and
		|its parameterization by the specifics of the consumer configuration are solved. It is also used for attaching library functionality
		|to the consumer configuration objects. They are not designed for calling from the applied code.</p>
		|<p class=""Paragraph0c"">See more about application interface and overridable modules in 
		|%1,
		|the ""Library development and usage section"".</p>";//@Non-NLS
	Else
		Details_ = "<p class=""Paragraph0c"">
		|Программный интерфейс инструментария разработчика ""1С:Библиотека стандартных подсистем"" включает в
		|себя все экспортные процедуры и функции, которые размещены в областях кода ПрограммныйИнтерфейс.
		|При разработке собственных библиотек и прикладных решений настоятельно рекомендуется использовать
		|только процедуры и функции программного интерфейса библиотеки.</p>
		|<p class=""Paragraph0c"">При выпуске новых версий библиотеки в этих процедурах и функциях обеспечивается обратная совместимость,
		|поэтому прикладным разработчикам не требуется пересматривать свой код и адаптировать объекты метаданных своих
		|конфигураций под новые требования и возможности каждой новой версии библиотеки. Это не гарантируется для
		|всех прочих служебных экспортных процедур и функций.</p>
		|<p class=""Paragraph0c"">Для удобства поиска и изучения программный интерфейс сгруппирован по подсистемам и разделен на две основные категории:</p>
		|<p class=""MsoListBullet""><span class=""Bold"">Интерфейс</span> – 
		|экспортные процедуры и функции, которые предназначены для вызова из прикладного кода;</p>
		|<p class=""MsoListBullet""><span class=""Bold"">Переопределение</span> – 
		|экспортные процедуры переопределяемых модулей, содержимое которых может или должно быть изменено в 
		|конфигурации-потребителе. С их помощью решаются задачи изменения поведения библиотечной функциональности,
		|ее параметризации спецификой конфигурации-потребителя, а также для подключения библиотечной функциональности
		|к объектам конфигурации-потребителя. Они не предназначены для вызова из прикладного кода.</p>
		|<p class=""Paragraph0c"">Подробнее о программном интерфейсе и переопределяемых модулях см. в 
		|%1,
		|в разделе ""Разработка и использование библиотек"".</p>"; //@Non-NLS
	EndIf;
	
	Return Details_;
	
EndFunction

Function LineChapter4ProgrammingInterface()
	
	If EnglishVersion Then
		Return "Chapter 4. Application interface";//@Non-NLS
	Else
		Return "Глава 4. Программный интерфейс";//@Non-NLS
	EndIf;
	
EndFunction

Function StringFunction()
	
	If EnglishVersion Then
		Return "Function";//@Non-NLS
	Else
		Return "Функция";//@Non-NLS
	EndIf;
	
EndFunction

Function StringProcedure()
	
	If EnglishVersion Then
		Return "Procedure";//@Non-NLS
	Else
		Return "Процедура";//@Non-NLS
	EndIf;
	
EndFunction

Function ExportLine()
	
	If EnglishVersion Then
		Return "Export";//@Non-NLS
	Else
		Return "Экспорт";//@Non-NLS
	EndIf;
	
EndFunction

Function StringInternal()
	
	If EnglishVersion Then
		Return "Internal";//@Non-NLS
	Else
		Return "Служебный";//@Non-NLS
	EndIf;
	
EndFunction

Function StringIsForInternalUseOnly()
	
	If EnglishVersion Then
		Return "For internal use only";//@Non-NLS
	Else
		Return "Только для внутреннего использования";//@Non-NLS
	EndIf;
	
EndFunction

Function StringSyntaxOfFunctionCallResult()
	
	If EnglishVersion Then
		Return "Result = ";//@Non-NLS
	Else
		Return "Результат = ";//@Non-NLS
	EndIf;
	
EndFunction

Function LineInterface()
	
	If EnglishVersion Then
		Return "Interface";//@Non-NLS
	Else
		Return "Интерфейс";//@Non-NLS
	EndIf;
	
EndFunction

Function LineOverride()
	
	If EnglishVersion Then
		Return "Override";//@Non-NLS
	Else
		Return "Переопределение";//@Non-NLS
	EndIf;
	
EndFunction

Function StringOverridable()
	
	If EnglishVersion Then
		Return "Overridable";//@Non-NLS
	Else
		Return "Переопределяемый";//@Non-NLS
	EndIf;
	
EndFunction

Function StringExample()
	
	If EnglishVersion Then
		Return "// Example:";//@Non-NLS
	Else
		Return "// Пример:";//@Non-NLS
	EndIf;
	
EndFunction

Function StringReturnValue()
	
	If EnglishVersion Then
		Return "Returns";//@Non-NLS
	Else
		Return "Возвращаемое значение";//@Non-NLS
	EndIf;
	
EndFunction

Function StringParameters_()
	
	If EnglishVersion Then
		Return "Parameters";//@Non-NLS
	Else
		Return "Параметры";//@Non-NLS
	EndIf;
	
EndFunction

Function LineEndOfArea()
	
	If EnglishVersion Then
		Return "#EndRegion";//@Non-NLS
	Else
		Return "#КонецОбласти";//@Non-NLS
	EndIf;
	
EndFunction

Function StringArea()
	
	If EnglishVersion Then
		Return "#Region";//@Non-NLS
	Else
		Return "#Область";//@Non-NLS
	EndIf;
	
EndFunction

Function StringScopeForCallingFromOtherSubsystems()
	
	If EnglishVersion Then
		Return "#Region ForCallsFromOtherSubsystems";//@Non-NLS
	Else
		Return "#Область ДляВызоваИзДругихПодсистем";//@Non-NLS
	EndIf;
	
EndFunction

Function ScopeStringObsoleteProceduresAndFunctions()
	
	If EnglishVersion Then
		Return "#Region ObsoleteProceduresAndFunctions";//@Non-NLS
	Else
		Return "#Область УстаревшиеПроцедурыИФункции";//@Non-NLS
	EndIf;
	
EndFunction

Function LineEndOfFunction()
	
	If EnglishVersion Then
		Return "EndFunction";//@Non-NLS
	Else
		Return "КонецФункции";//@Non-NLS
	EndIf;
	
EndFunction

Function LineEndOfProcedure()
	
	If EnglishVersion Then
		Return "EndProcedure";//@Non-NLS
	Else
		Return "КонецПроцедуры";//@Non-NLS
	EndIf;
	
EndFunction
 
#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf