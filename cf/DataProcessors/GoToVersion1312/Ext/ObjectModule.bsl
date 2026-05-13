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

// 
// 
//
// 
//  
//  
//  
Var LibraryObjects;

#EndRegion

#Region Private

#Region AssistantEvents

// The events that are triggered during metadata object looping.

Procedure OnReadMainSettings(Parameters)
	
	AttachableCommands_OnReadMainSettings(Parameters);
	
EndProcedure

Procedure OnAnalyzeObject(Parameters, ObjectDetails)
	
	AttachableCommands_OnAnalyzeObject(Parameters, ObjectDetails);
	
EndProcedure

Procedure OnAnalyzeForm(Parameters, ObjectDetails, FormDetails)
	
EndProcedure

#EndRegion

#Region AttachableCommands

Procedure AttachableCommands_OnReadMainSettings(Parameters)
	
	MetadataObjectsCollections = New Array;
	MetadataObjectsCollections.Add(Metadata.Catalogs);
	MetadataObjectsCollections.Add(Metadata.Documents);
	MetadataObjectsCollections.Add(Metadata.BusinessProcesses);
	MetadataObjectsCollections.Add(Metadata.Tasks);
	MetadataObjectsCollections.Add(Metadata.ChartsOfCalculationTypes);
	MetadataObjectsCollections.Add(Metadata.ChartsOfCharacteristicTypes);
	MetadataObjectsCollections.Add(Metadata.ChartsOfAccounts);
	MetadataObjectsCollections.Add(Metadata.ExchangePlans);
	
	PrefixOfObjectsToDelete = "Delete";
	InputOnBasis = New Map;
	
	For Each MetadataObjectCollection In MetadataObjectsCollections Do
		For Each MetadataObject In MetadataObjectCollection Do
			If StrStartsWith(MetadataObject.Name, PrefixOfObjectsToDelete) Then
				Continue;
			EndIf;
			
			If MetadataObject.BasedOn.Count() > 0 Then
				If InputOnBasis[MetadataObject] = Undefined Then
					InputOnBasis.Insert(MetadataObject, New Array);
				EndIf;
			EndIf;
			
			For Each Basis In MetadataObject.BasedOn Do
				ObjectsToEnter = InputOnBasis[Basis];
				If ObjectsToEnter = Undefined Then
					ObjectsToEnter = New Array;
					InputOnBasis.Insert(Basis, ObjectsToEnter);
				EndIf;
				
				ObjectsToEnter.Add(MetadataObject);
			EndDo;
		EndDo;
	EndDo;
	
	Parameters.Insert("InputOnBasis", InputOnBasis);
	
EndProcedure

// Parameters:
//   Parameters - See ChangeExportedTexts.Parameters
//
Procedure AttachableCommands_OnAnalyzeObject(Parameters, ObjectDetails)
	
	ObjectsToEnterOnBasis = Parameters.InputOnBasis[ObjectDetails.Metadata]; // Array of See WriteMessageByObject.ObjectString 
	If ObjectsToEnterOnBasis = Undefined Then
		Return;
	EndIf;
	
	ManagerModule = ManagerModule(ObjectDetails);
	
	ProcedureDetails =
	"// Defines list teams creation to1 basedon.
	|//
	|// Parameters:
	|//  GenerationCommands - see. GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
	|//  Parameters - see. GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
	|//";
	ModuleProcedure = FindModuleProcedure(ManagerModule, "AddGenerationCommands");
	
	If ModuleProcedure = Undefined Then
		AreaForCallsFromOtherSubsystems = GetAreaForCallsFromOtherSubsystems(ManagerModule);
		AttachableCommandsArea = GetSubsystemsArea(AreaForCallsFromOtherSubsystems, "StandardSubsystems.AttachableCommands");
		ModuleProcedure = AddItemToEnd(AttachableCommandsArea);
		ModuleProcedure.LongDesc = ProcedureDetails;
		ModuleProcedure.Title = "Procedure AddGenerationCommands(GenerationCommands, Parameters) Export";
		ModuleProcedure.Footer = "EndProcedure";
		
		ModuleProcedure.Content.Add(Chars.Tab);
		For Each MetadataObject In ObjectsToEnterOnBasis Do
			TextForInsert = "";
			If MetadataObject <> ObjectDetails.Metadata Then
				TextForInsert = Common.BaseTypeNameByMetadataObject(MetadataObject)
					+ "." + MetadataObject.Name + ".";
			EndIf;
			ModuleProcedure.Content.Add(Chars.Tab + TextForInsert + "AddGenerateCommand(GenerationCommands);");
		EndDo;
		If ObjectsToEnterOnBasis.Count() > 0 Then
			ModuleProcedure.Content.Add(Chars.Tab);
		EndIf;
	Else
		If ModuleProcedure.LongDesc <> ProcedureDetails Then
			ModuleProcedure.LongDesc = ProcedureDetails;
		EndIf;
	EndIf;
	
	ProcedureDetails = 
	"// For usage In procedure AddGenerationCommands other modules managers objects_.
	|// Adds In list teams creation to1 basedon thisone object.
	|//
	|// Parameters:
	|//  GenerationCommands - see. GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
	|//
	|// Return value:
	|//  ValueTableRow, Undefined - longdesc ofadded commands.
	|//";
	ModuleProcedure = FindModuleFunction(ManagerModule, "AddGenerateCommand");
	If ModuleProcedure = Undefined Then
		AreaForCallsFromOtherSubsystems = GetAreaForCallsFromOtherSubsystems(ManagerModule);
		AttachableCommandsArea = GetSubsystemsArea(AreaForCallsFromOtherSubsystems, "StandardSubsystems.AttachableCommands");
		ModuleProcedure = AddItemToEnd(AttachableCommandsArea);
		ModuleProcedure.LongDesc = ProcedureDetails;
		ModuleProcedure.Title = "Function AddGenerateCommand(GenerationCommands) Export";
		ModuleProcedure.Footer = "EndFunction";
		
		TextToInsertTemplate = 
		"Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.%1);";
		
		ObjectMetadata = ObjectDetails.Metadata; // MetadataObject - 
		If IsLibraryObject(ObjectMetadata) Then
			TextToInsertTemplate = 
			"If Common.SubsystemExists(""StandardSubsystems.AttachableCommands"") Then
			|	ModuleGeneration = Common.CommonModule(""GenerateFrom"");
			|	Return ModuleGeneration.AddGenerationCommand(GenerationCommands, Metadata.%1);
			|EndIf;
			|
			|Return Undefined;";
		EndIf;
		
		ObjectName = Common.BaseTypeNameByMetadataObject(ObjectMetadata)
			+ "." + ObjectMetadata.Name;
		TextForInsert = StringFunctionsClientServer.SubstituteParametersToString(TextToInsertTemplate, ObjectName);
		AddIndents(TextForInsert);
		
		ModuleProcedure.Content.Add(Chars.Tab);
		ModuleProcedure.Content.Add(TextForInsert);
		ModuleProcedure.Content.Add(Chars.Tab);
	Else
		If ModuleProcedure.LongDesc <> ProcedureDetails Then
			ModuleProcedure.LongDesc = ProcedureDetails;
		EndIf;
	EndIf;
	
	If WriteModule(ManagerModule) Then
		Parameters.ChangedFiles.Add(ManagerModule.FullModuleName);
	EndIf;
	
	FullModuleName = Parameters.WorkingDirectory + StrReplace("CommonModules\GenerateFromOverridable\Ext\Module.bsl", "\", GetPathSeparator());
	CommonModule = ModuleDetails(FullModuleName);
	ModuleProcedure = FindModuleProcedure(CommonModule, "OnDefineObjectsWithCreationBasedOnCommands");
	
	TemplateOfInsert = "	Objects.Add(Metadata.%1.%2);";
	
	ObjectParent = ObjectDetails.Parent; // See WriteMessageByObject.ObjectString
	TextForInsert = StringFunctionsClientServer.SubstituteParametersToString(
		TemplateOfInsert, ObjectParent.Name, ObjectDetails.Name);
		
	ProcedureByString = BlockToString(ModuleProcedure);
	If StrFind(ProcedureByString, TextForInsert) = 0 Then
		AddRowToEnd(ModuleProcedure, TextForInsert);
		If WriteModule(CommonModule) Then
			Parameters.ChangedFiles.Add(CommonModule.FullModuleName);
		EndIf;
	EndIf;
	
EndProcedure

#EndRegion

#Region ForEditingMethodsAPI

Procedure AddIndents(Text)
	NewText = "";
	For LineNumber = 1 To StrLineCount(Text) Do
		String = StrGetLine(Text, LineNumber);
		NewText = NewText + Chars.Tab + String + Chars.LF;
	EndDo;
	Text = TrimR(NewText);
EndProcedure

Function FindModuleProcedure(Module, ProcedureName)
	ReadModuleStructure(Module);
	Return FindBlock(Module.Structure.Content, "Procedure" + " " + ProcedureName + "(");
EndFunction

Function FindModuleFunction(Module, FunctionName)
	ReadModuleStructure(Module);
	Return FindBlock(Module.Structure.Content, "Function" + " " + FunctionName + "(");
EndFunction

Function FindModuleArea(Module, AreaName)
	ReadModuleStructure(Module);
	Return FindBlock(Module.Structure.Content, "#Area" + " " + AreaName);
EndFunction

Function FindModulePreprocessorInstruction(Module, InstructionText)
	ReadModuleStructure(Module);
	Return FindBlock(Module.Structure.Content, InstructionText, False);
EndFunction

Function GetInstructionIfServerOrThickClientOrdinaryApplicationOrExternalConnection(Module);
	Title = "#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then";
	Footer = "#EndIf";
	
	Instruction = FindModulePreprocessorInstruction(Module, Title);
	If Instruction = Undefined Then
		Instruction = AddItemToBeginning(Module.Structure);
		Instruction.Title = Title;
		Instruction.Footer = Footer;
	EndIf;
	
	Return Instruction;
EndFunction

Function GetAPIArea(Module);
	AreaName = "Public";
	
	Title = "#Area" + " " + AreaName;
	Footer = "#EndRegion";
	
	Area = FindModuleArea(Module, AreaName);
	If Area = Undefined Then
		ModuleItem = GetInstructionIfServerOrThickClientOrdinaryApplicationOrExternalConnection(Module);
		Area = AddItemToBeginning(ModuleItem);
		Area.Title = Title;
		Area.Footer = Footer;
	EndIf;
	
	Return Area;
EndFunction

Function GetAreaForCallsFromOtherSubsystems(Module);
	AreaName = "ForCallsFromOtherSubsystems";
	
	Title = "#Area" + " " + AreaName;
	Footer = "#EndRegion";
	
	Area = FindModuleArea(Module, AreaName);
	If Area = Undefined Then
		ModuleItem = GetAPIArea(Module);
		Area = AddItemToEnd(ModuleItem);
		Area.Title = Title;
		Area.Footer = Footer;
	EndIf;
	
	Return Area;
EndFunction

Function GetSubsystemsArea(ModuleItem, SubsystemName, AddIndents = False, CreateBeforeOtherAreas = False);
	Title = "//" + " " + SubsystemName;
	Footer = "//" + " " + "End" + " " + SubsystemName;
	
	Result = FindBlock(ModuleItem.Content, Title);
	If Result = Undefined Then
		If AddIndents Then
			AddIndents(Title);
			AddIndents(Footer);
		EndIf;
		
		If CreateBeforeOtherAreas Then
			Result = AddItemToBeginning(ModuleItem);
		Else
			Result = AddItemToEnd(ModuleItem);
		EndIf;
		
		Result.Title = Title;
		Result.Footer = Footer;
	EndIf;
	
	Return Result;
EndFunction

Function AddItemToEnd(ModuleItem, AddIndents1 = True)
	
	NewBlock = NewBlock(ModuleItem);
	
	HasIndentAtEnd = ModuleItem.Content.Count() > 0
		And (TypeOf(ModuleItem.Content[ModuleItem.Content.Count() - 1]) <> Type("Structure")
			And IsBlankString(ModuleItem.Content[ModuleItem.Content.Count() - 1]));
	
	Indent = Indent(ModuleItem);
	
	If AddIndents1 And Not HasIndentAtEnd Then
		ModuleItem.Content.Add(Indent);
	EndIf;
	
	ModuleItem.Content.Add(NewBlock);
	
	If AddIndents1 Then
		ModuleItem.Content.Add(Indent);
	EndIf;
	
	Return NewBlock;
	
EndFunction

Function AddItemToBeginning(ModuleItem, AddIndents1 = True)
	
	NewBlock = NewBlock(ModuleItem);
	
	HasIndentInBeginning = ModuleItem.Content.Count() > 0
		And (TypeOf(ModuleItem.Content[0]) <> Type("Structure") And IsBlankString(ModuleItem.Content[0]));
		
	Indent = Indent(ModuleItem);
	
	If AddIndents1 And Not HasIndentInBeginning Then
		ModuleItem.Content.Insert(0, Indent);
	EndIf;
	
	ModuleItem.Content.Insert(0, NewBlock);
	
	If AddIndents1 Then
		ModuleItem.Content.Insert(0, Indent);
	EndIf;
	
	Return NewBlock;
	
EndFunction

Procedure AddRowToEnd(ModuleItem, String)
	
	ContentCount = ModuleItem.Content.Count();
	InsertPosition = ContentCount;
	
	For IndexOf = -ModuleItem.Content.Count() + 1 To 0 Do
		InsertPosition = -IndexOf + 1;
		If ValueIsFilled(ModuleItem.Content[-IndexOf]) Then
			Break;
		EndIf;
	EndDo;
	
	HasIndentAtEnd = InsertPosition <= ContentCount And ContentCount > 0;
	
	ModuleItem.Content.Insert(InsertPosition, String);
	
	If HasIndentAtEnd And InsertPosition = ContentCount Then
		ModuleItem.Content.Add(Indent(ModuleItem));
	EndIf;
	
EndProcedure

Function Indent(ModuleItem)
	
	If ValueIsFilled(ModuleItem.Title) Then
		Title = TrimL(ModuleItem.Title);
		If StrStartsWith(Title, "Procedure") Or StrStartsWith(Title, "Function") Then
			Return Chars.Tab;
		ElsIf StrStartsWith(Title, "#") Then
			Return Indent(ModuleItem.Parent);
		Else
			Return "";
		EndIf;
	Else
		Return "";
	EndIf;
	
EndFunction

Function LineToBlock(Text)
	BlocksTypes = BlocksTypes();
	
	Result = NewBlock();
	If StrLen(Text) = 0 Then
		Return Result;
	EndIf;
	
	CurrentBlock = Result;
	LongDesc = New Array;
	PreprocessorInstruction = "";
	For Each String In StrSplit(Text, Chars.LF, True) Do
		If IsBlockHeader(String, BlocksTypes) Then
			NewBlock = NewBlock(CurrentBlock, String, StrConcat(LongDesc, Chars.LF));
			CurrentBlock.Content.Add(NewBlock);
			CurrentBlock = NewBlock;
			CurrentBlock.PreprocessorInstruction = PreprocessorInstruction;
			PreprocessorInstruction = "";
			LongDesc.Clear();
		ElsIf IsTitleContinuation(CurrentBlock.Title, String) Then
			CurrentBlock.Title = CurrentBlock.Title + Chars.LF + String;
		ElsIf IsBlockFooter(String, CurrentBlock, BlocksTypes) Then
			PutDescriptionLinesToContent(CurrentBlock.Content, LongDesc);
			CurrentBlock.Footer = String;
			CurrentBlock = CurrentBlock.Parent;
		ElsIf StrStartsWith(String, "//") And IsBlankString(PreprocessorInstruction) Then
			LongDesc.Add(String);
		ElsIf StrStartsWith(String, "&") And IsBlankString(PreprocessorInstruction) Then
			PreprocessorInstruction = String;
		Else
			PutDescriptionLinesToContent(CurrentBlock.Content, LongDesc);
			If Not IsBlankString(PreprocessorInstruction) Then
				CurrentBlock.Content.Add(PreprocessorInstruction);
				PreprocessorInstruction = "";
			EndIf;
			CurrentBlock.Content.Add(String);
		EndIf;
	
		If StrStartsWith(TrimL(CurrentBlock.Title), "Var") And StrFind(CurrentBlock.Title, ";") > 0 Then
			CurrentBlock = CurrentBlock.Parent;
		EndIf;
	EndDo;
	
	PutDescriptionLinesToContent(CurrentBlock.Content, LongDesc);
	If Not IsBlankString(PreprocessorInstruction) Then
		CurrentBlock.Content.Add(PreprocessorInstruction);
	EndIf;
	
	Return Result;
EndFunction

Function BlockToString(Block)
	If TypeOf(Block) = Type("String") Then
		Return Block;
	EndIf;
	
	RowsCollection = BlockToStringsCollection(Block);
	
	Result = StrConcat(RowsCollection, Chars.LF);
	Return Result;
EndFunction

// Parameters:
//   Block - See NewBlock
// Returns:
//   Array
//
Function BlockToStringsCollection(Val Block)
	
	RowsCollection = New Array;
	
	If StrLen(Block.LongDesc) > 0 Then
		RowsCollection.Add(Block.LongDesc);
	EndIf;
	
	If StrLen(Block.PreprocessorInstruction) > 0 Then
		RowsCollection.Add(Block.PreprocessorInstruction);
	EndIf;
	
	If StrLen(Block.Title) > 0 Then
		RowsCollection.Add(Block.Title);
	EndIf;
	
	For Each ContentBlock In Block.Content Do
		RowsCollection.Add(BlockToString(ContentBlock));
	EndDo;
	
	If StrLen(Block.Footer) > 0 Then
		RowsCollection.Add(Block.Footer);
	EndIf;
	
	Return RowsCollection;

EndFunction

// Returns:
//   Structure:
//   * Parent - Structure
//              - Undefined:
//   ** Parent - Undefined
//   ** Footer - String
//   ** Content - Array
//   ** Title - String
//   ** PreprocessorInstruction - String
//   ** LongDesc - String
//   * Footer - String
//   * Content - Array
//   * Title - String
//   * PreprocessorInstruction - String
//   * LongDesc - String
//
Function NewBlock(Parent = Undefined, Title = "", LongDesc = "")
	Result = New Structure;
	Result.Insert("LongDesc", LongDesc);
	Result.Insert("PreprocessorInstruction", "");
	Result.Insert("Title", Title);
	Result.Insert("Content", New Array);
	Result.Insert("Footer", "");
	
	Result.Insert("Parent", Parent);
	Return Result;
EndFunction

Function FindBlock(CollectionBlocks, Title, SearchSubordinateItems = True)
	Result = Undefined;
	
	// Search in the upper level.
	For Each Item In CollectionBlocks Do
		If TypeOf(Item) = Type("String") Then
			Continue;
		EndIf;
		If StrStartsWith(TrimL(Item.Title), Title) Then
			Return Item;
		EndIf;
		If Result <> Undefined Then
			Break;
		EndIf;
	EndDo;
	
	// Search in the lower level.
	If Result = Undefined And SearchSubordinateItems Then
		For Each Item In CollectionBlocks Do
			If TypeOf(Item) = Type("String") Then
				Continue;
			EndIf;
			Result = FindBlock(Item.Content, Title);
			If Result <> Undefined Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

Function FindBlocks(CollectionBlocks, Val Headers)
	
	If TypeOf(Headers) = Type("String") Then
		Headers = CommonClientServer.ValueInArray(Headers);
	EndIf;
	
	Result = New Array;
	
	For Each Item In CollectionBlocks Do
		If TypeOf(Item) = Type("String") Then
			Continue;
		EndIf;
		For Each Title In Headers Do
			If StrStartsWith(TrimL(Item.Title), Title) Then
				Result.Add(Item);
				Break;
			EndIf;
		EndDo;
		BlocksFound = FindBlocks(Item.Content, Headers);
		CommonClientServer.SupplementArray(Result, BlocksFound);
	EndDo;
	
	Return Result;
	
EndFunction


Function IsTitleContinuation(Title, String)
	Return (StrStartsWith(Title, "Function") Or StrStartsWith(Title, "Procedure"))
		And StrFind(Title, ")") = 0
		Or StrStartsWith(TrimL(Title), "Var") And StrFind(Title, ";") = 0;
EndFunction

Function IsBlockHeader(Val String, BlocksTypes)
	String = TrimAll(String);
	
	For Each BlockKind In BlocksTypes Do
		If StrStartsWith(String, BlockKind.Key) Then
			Return True;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

Function IsBlockFooter(Val String, Block, BlocksTypes)
	String = TrimL(String);
	BlockHeader = TrimL(Block.Title);
	
	For Each BlockKind In BlocksTypes Do
		If BlockKind.Value = Undefined Then
			Continue;
		EndIf;
			
		If StrStartsWith(String, BlockKind.Value) Then
			If StrStartsWith(BlockHeader, BlockKind.Key) Then
				Return True;
			Else
				// This footer is from another block. Check it with the parent blocks.
				CurrentBlock = Block;
				While CurrentBlock <> Undefined And Not StrStartsWith(TrimL(CurrentBlock.Title), BlockKind.Key) Do
					CurrentBlock = CurrentBlock.Parent;
				EndDo;
				If CurrentBlock = Undefined Then
					// This is a footer of a block that has no beginning.
					Return False;
				Else
					// Move error block content to the parent block.
					For Each Item In Block.Content Do
						CurrentBlock.Content.Add(Item);
					EndDo;
					Block.Content = New Array;
					
					// Change the current block to the parent block.
					Block = CurrentBlock; 
					Return True;
				EndIf;
			EndIf;
		EndIf;
	EndDo;
	
	Return False;
EndFunction

Function BlocksTypes()
	Result = New Map;
	Result.Insert("#If", "#EndIf");
	Result.Insert("Function", "EndFunction");
	Result.Insert("Procedure", "EndProcedure");
	Result.Insert("#Area", "#EndRegion");
	Result.Insert("// _Demo begin", "// _Demo end");
	Result.Insert("// StandardSubsystems.", "// End StandardSubsystems.");
	Result.Insert("Var ", Undefined);
	Return Result;
EndFunction

Procedure PutDescriptionLinesToContent(Content, LongDesc)
	If LongDesc.Count() > 0 Then
		For Each DetailsString In LongDesc Do
			Content.Add(DetailsString);
		EndDo;
		LongDesc.Clear();
	EndIf;
EndProcedure

Function ManagerModule(ObjectString)
	FullModuleName = ObjectString.Directory + "Ext\ManagerModule.bsl";
	Return ModuleDetails(FullModuleName);
EndFunction

Function WriteModule(Module)
	ModuleText = BlockToString(Module.Structure);
	FullModuleName = Module.FullModuleName;
	If ModuleText <> ReadModuleText(FullModuleName) Then
		Module.ModuleText = ModuleText;
		WriteModuleText(FullModuleName, ModuleText);
		Return True;
	EndIf;
	Return False;
EndFunction

Function ModuleDetails(FullModuleName)
	Result = New Structure;
	Result.Insert("FullModuleName", FullModuleName);
	Result.Insert("ModuleText", ReadModuleText(FullModuleName));
	Return Result;
EndFunction

Procedure ReadModuleStructure(Module)
	If Not Module.Property("Structure") Then
		Module.Insert("Structure", LineToBlock(Module.ModuleText));
	EndIf;
EndProcedure

#EndRegion

#Region WizardInternalProceduresAndFunctions

// Parameters:
//   Parameters - Structure:
//     * GlobalMessages - ValueTable
//
Procedure WriteGlobalMessage(Parameters, Text, Order)
	Message = Parameters.GlobalMessages.Add();
	Message.GlobalMessageText   = Text;
	Message.GlobalMessageOrder = Order;
EndProcedure

// Parameters:
//  Parameters - Structure:
//   * MessagesByObjects - ValueTable
//   ObjectString - Structure:
//   * Metadata - MetadataObject
//   * Name - String
//   * FullName - String
//   * ListPresentation - String
//   * ObjectPresentation - String
//   * Directory - String
//   * PictureNumber - Number
//   * Referential - Boolean
//  FormString - Structure:
//   * Metadata - MetadataObject
//   * Name - String
//   * FullName - String
//   * ListPresentation - String
//   * ObjectPresentation - String
//   * Directory - String
//   * PictureNumber - Number
//   * Referential - Boolean
//
Procedure WriteMessageByObject(Parameters, ObjectString, FormString, MessageType, Text)
	KindRow = ObjectString.Parent;
	
	Message = Parameters.MessagesByObjects.Add();
	Message.KindPriority    = Parameters.KindsPriority[KindRow.Name];
	Message.Kind              = KindRow.ListPresentation;
	Message.MetadataObject = ObjectString.FullName;
	If TypeOf(FormString) = Type("String") Then
		Message.Form = FormString;
	Else
		Message.Form            = FormString.Name;
	EndIf;
	Message.MessageType     = MessageType;
	Message.Text            = Text;
EndProcedure

// Background job handlers.

Procedure Integrate(Parameters, ResultAddress) Export
	If Not ValueIsFilled(Parameters.WorkingDirectory) Then
		PathToDirectory = CommonClientServer.AddLastPathSeparator(GetTempFileName("DevTools"));
		CreateDirectory(PathToDirectory);
		Parameters.WorkingDirectory = PathToDirectory;
	EndIf;
	If Not ValueIsFilled(Parameters.User) Then
		Parameters.User = UserName();
	EndIf;
	
	If Parameters.ExportFilesToDirectory Then
		UploadConfigurationToXML(Parameters);
	EndIf;
	
	ReadGeneralSettings(Parameters);
	ChangeExportedTexts(Parameters);
	LoadConfigurationFromXML(Parameters);
	
	Result = New Structure;
	Result.Insert("WorkingDirectory",    Parameters.WorkingDirectory);
	Result.Insert("MetadataTree",  Parameters.MetadataTree);
	Result.Insert("SpreadsheetDocument", GenerateReport(Parameters));
	PutToTempStorage(Result, ResultAddress);
EndProcedure

// Functions used from the form and from this module.

Function DesignerIsOpen() Export
	Sessions = GetInfoBaseSessions();
	For Each Session In Sessions Do
		If Upper(Session.ApplicationName) = "DESIGNER" Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

// Read metadata of the current configuration.

Procedure ReadGeneralSettings(Parameters)
	
	TimeConsumingOperations.ReportProgress(1, NStr("ru = 'Чтение основных настроек из переопределяемых модулей...';
												|en = 'Reading main settings from overridable modules…';"));
	
	Parameters.Insert("DCS", GetTemplate("DataCompositionSchema"));
	Parameters.Insert("GlobalMessages", CreateTableBySetSchema(Parameters.DCS, "GlobalMessages"));
	Parameters.Insert("MessagesByObjects", CreateTableBySetSchema(Parameters.DCS, "MessagesByObjects"));
	Parameters.Insert("ChangedFiles", New Array);
	
	OnReadMainSettings(Parameters);
	
	TimeConsumingOperations.ReportProgress(2, NStr("ru = 'Построение дерева метаданных...';
												|en = 'Building metadata tree…';"));
	RegisterMapsForQuickNamesTransformation(Parameters);
	
	Parameters.Insert("ObjectCount", 0);
	Parameters.Insert("MetadataTree", MetadataTree());
	Parameters.Insert("KindPriority", 0);
	Parameters.Insert("KindsPriority", New Map);
	
	RegisterMetadataCollection(Parameters, "CommonModules", NStr("ru = 'Общие модули';
																		|en = 'Common modules';"), NStr("ru = 'Общий модуль';
																									|en = 'Common module';"), False);
	RegisterMetadataCollection(Parameters, "CommonForms", NStr("ru = 'Общие формы';
																		|en = 'Common forms';"), NStr("ru = 'Общая форма';
																									|en = 'Common form';"), False);
	RegisterMetadataCollection(Parameters, "ExchangePlans", NStr("ru = 'Планы обмена';
																		|en = 'Exchange plans';"), NStr("ru = 'План обмена';
																									|en = 'Exchange plan';"), True);
	RegisterMetadataCollection(Parameters, "Catalogs", NStr("ru = 'Справочники';
																		|en = 'Catalogs';"), NStr("ru = 'Справочник';
																									|en = 'Catalog';"), True);
	RegisterMetadataCollection(Parameters, "Documents", NStr("ru = 'Документы';
																	|en = 'Documents';"), NStr("ru = 'Документ';
																								|en = 'Document';"), True);
	RegisterMetadataCollection(Parameters, "DocumentJournals", NStr("ru = 'Журналы документов';
																			|en = 'Document journals';"), NStr("ru = 'Журнал документов';
																												|en = 'Document journal';"), False);
	RegisterMetadataCollection(Parameters, "Reports", NStr("ru = 'Отчеты';
																	|en = 'Reports';"), NStr("ru = 'Отчет';
																						|en = 'Report';"), False);
	RegisterMetadataCollection(Parameters, "DataProcessors", NStr("ru = 'Обработки';
																	|en = 'Data processors';"), NStr("ru = 'Обработка';
																								|en = 'Processing';"), False);
	RegisterMetadataCollection(Parameters, "ChartsOfCharacteristicTypes", NStr("ru = 'Планы видов характеристик';
																					|en = 'Charts of characteristic types';"), NStr("ru = 'План видов характеристик';
																															|en = 'Chart of characteristic types';"), True);
	RegisterMetadataCollection(Parameters, "ChartsOfAccounts", NStr("ru = 'Планы счетов';
																		|en = 'Charts of accounts';"), NStr("ru = 'План счетов';
																									|en = 'Chart of accounts.';"), True);
	RegisterMetadataCollection(Parameters, "ChartsOfCalculationTypes", NStr("ru = 'Планы видов расчета';
																			|en = 'Charts of calculation types';"), NStr("ru = 'План видов расчета';
																												|en = 'Chart of calculation types.';"), True);
	RegisterMetadataCollection(Parameters, "InformationRegisters", NStr("ru = 'Регистры сведений';
																			|en = 'Information registers';"), NStr("ru = 'Регистр сведений';
																												|en = 'Information register';"), False);
	RegisterMetadataCollection(Parameters, "AccumulationRegisters", NStr("ru = 'Регистры накопления';
																				|en = 'Accumulation registers';"), NStr("ru = 'Регистр накопления';
																													|en = 'Accumulation register';"), False);
	RegisterMetadataCollection(Parameters, "AccountingRegisters", NStr("ru = 'Регистры бухгалтерии';
																				|en = 'Accounting registers';"), NStr("ru = 'Регистр бухгалтерии';
																													|en = 'Accounting register';"), False);
	RegisterMetadataCollection(Parameters, "CalculationRegisters", NStr("ru = 'Регистры расчета';
																			|en = 'Calculation registers';"), NStr("ru = 'Регистр расчета';
																											|en = 'Calculation register';"), False);
	RegisterMetadataCollection(Parameters, "BusinessProcesses", NStr("ru = 'Бизнес-процессы';
																			|en = 'Business processes';"), NStr("ru = 'Бизнес-процесс';
																											|en = 'Business process';"), True);
	RegisterMetadataCollection(Parameters, "Tasks", NStr("ru = 'Задачи';
																	|en = 'Tasks';"), NStr("ru = 'Задача';
																						|en = 'Task';"), True);
	RegisterMetadataCollection(Parameters, "Roles", NStr("ru = 'Роли';
																|en = 'Roles';"), NStr("ru = 'Роль';
																					|en = 'Role';"), False);
	
	Parameters.Delete("KindPriority");
	
EndProcedure

// Returns:
//  ValueTree:
//   * Metadata - MetadataObject
//   * Name - String
//   * FullName - String
//   * ListPresentation - String
//   * ObjectPresentation - String
//   * Directory - String
//   * PictureNumber - Number
//   * Referential - Boolean
//  
Function MetadataTree()
	
	MetadataTree = New ValueTree();
	
	MetadataTree.Columns.Add("Metadata");
	MetadataTree.Columns.Add("Name", New TypeDescription("String"));
	MetadataTree.Columns.Add("FullName", New TypeDescription("String"));
	MetadataTree.Columns.Add("ListPresentation", New TypeDescription("String"));
	MetadataTree.Columns.Add("ObjectPresentation", New TypeDescription("String"));
	MetadataTree.Columns.Add("Directory", New TypeDescription("String"));
	MetadataTree.Columns.Add("PictureNumber", New TypeDescription("Number"));
	MetadataTree.Columns.Add("Referential", New TypeDescription("Boolean"));
	
	Return MetadataTree;
	
EndFunction

Function CreateTableBySetSchema(DataCompositionSchema, DataSetName)
	Result = New ValueTable;
	DataSetFieldsOfDCSchema = DataCompositionSchema.DataSets[DataSetName].Fields;
	For Each DCItem In DataSetFieldsOfDCSchema Do
		If TypeOf(DCItem) = Type("DataCompositionSchemaDataSetField") Then
			ColumnName = StrReplace(String(DCItem.Field), ".", "_");
			Result.Columns.Add(ColumnName, DCItem.ValueType);
		EndIf;
	EndDo;
	Return Result;
EndFunction

// Parameters:
//   Parameters - Structure:
//   * MetadataTree - ValueTree:
//   ** Metadata - MetadataObject
//   ** Name - String
//   ** FullName - String
//   ** ListPresentation - String
//   ** ObjectPresentation - String
//   ** Directory - String
//   ** PictureNumber - Number
//   ** Referential - Boolean
//
Procedure RegisterMetadataCollection(Parameters, Kind, ListPresentation, ObjectPresentation, Referential)
	
	Parameters.KindPriority = Parameters.KindPriority + 1;
	Parameters.KindsPriority.Insert(Kind, Parameters.KindPriority);
	
	Collection = Metadata[Kind];
	Count = Collection.Count();
	If Count = 0 Then
		Return;
	EndIf;
	Parameters.ObjectCount = Parameters.ObjectCount + Count;
	
	TreeInParameters = Parameters.MetadataTree;
	KindRow = TreeInParameters.Rows.Add();
	KindRow.Name       = Kind;
	KindRow.FullName = Kind;
	KindRow.ListPresentation  = ListPresentation;
	KindRow.ObjectPresentation = ObjectPresentation;
	KindRow.PictureNumber = Parameters.PicturesNumbers[Lower(Kind)];
	KindRow.Referential = Referential;
	
	For Each MetadataObject In Collection Do
		If MetadataObject.ConfigurationExtension() <> Undefined Then
			Continue; // Extension object.
		EndIf;
		
		ObjectString = KindRow.Rows.Add();
		ObjectString.Metadata         = MetadataObject;
		ObjectString.Name                = MetadataObject.Name;
		ObjectString.FullName          = MetadataObject.FullName();
		ObjectString.PictureNumber      = KindRow.PictureNumber;
		ObjectString.ObjectPresentation = Common.ObjectPresentation(MetadataObject);
		ObjectString.ListPresentation = Common.ListPresentation(MetadataObject);
		
		ObjectString.Referential = Referential;
		
		If Kind = "CommonForms" Or Kind = "CommonModules" Or Kind = "Roles" Then
			Continue;
		EndIf;
		
		For Each FormMetadata In MetadataObject.Forms Do
			FormString = ObjectString.Rows.Add();
			FormString.Metadata = FormMetadata;
			FormString.Name        = FormMetadata.Name;
			FormString.FullName  = FormMetadata.FullName();
			FormString.ListPresentation  = FormMetadata.Presentation();
			FormString.ObjectPresentation = FormString.ListPresentation;
			FormString.Referential = Referential;
		EndDo;
	EndDo;
EndProcedure

// Dump configuration into and restore from XML.

Function UploadConfigurationToXML(Parameters)
	
	If FileExists(Parameters.WorkingDirectory) Then
		DeleteFiles(Parameters.WorkingDirectory, "*");
	Else
		CreateDirectory(Parameters.WorkingDirectory);
	EndIf;
	
	ConfigurationPath = InfoBaseConnectionString();
	OneCDCopyDirectory = Undefined;
	
	If DesignerIsOpen() Then
		If Common.FileInfobase() Then
			TimeConsumingOperations.ReportProgress(5, StringFunctionsClientServer.SubstituteParametersToString(NStr(
				"ru = 'Копирование %1, т.к. не закрыт конфигуратор...';
				|en = 'Copying %1 as Designer is not closed…';"),
				"1Cv8.1CD"));
			InfobaseDirectory = StringFunctionsClientServer.ParametersFromString(ConfigurationPath).file;
			OneCDCopyDirectory = Parameters.WorkingDirectory + "BaseCopy" + GetPathSeparator();
			CreateDirectory(OneCDCopyDirectory);
			FileCopy(InfobaseDirectory + "\1Cv8.1CD", OneCDCopyDirectory + "1Cv8.1CD");
			ConfigurationPath = StringFunctionsClientServer.SubstituteParametersToString(
				"File=""%1"";", OneCDCopyDirectory);
		Else
			Raise NStr("ru = 'Для выгрузки модулей необходимо закрыть конфигуратор.';
									|en = 'To export modules, close the designer.';");
		EndIf;
	EndIf;
	
	MessagesFileName = Parameters.WorkingDirectory + "Upload0.log";
	
	TimeConsumingOperations.ReportProgress(10, NStr("ru = 'Выгрузка конфигурации в XML...';
												|en = 'Exporting configuration to XML…';"));
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir() + "\1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(ConfigurationPath);
	If Not IsBlankString(Parameters.User) Then 
		StartupCommand.Add("/N");
		StartupCommand.Add(Parameters.User);
		StartupCommand.Add("/P");
		StartupCommand.Add(Parameters.Password);
	EndIf;
	StartupCommand.Add("/DumpConfigToFiles");
	StartupCommand.Add(Parameters.WorkingDirectory);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	If OneCDCopyDirectory <> Undefined Then
		DeleteFiles(OneCDCopyDirectory);
	EndIf;
	
	If Result.ReturnCode <> 0 Then
		Messages = "";
		File = New File(MessagesFileName);
		If File.Exists() Then
			TextReader = New TextReader(MessagesFileName);
			Messages = TrimAll(TextReader.Read());
			TextReader.Close();
			DeleteFiles(MessagesFileName);
		EndIf;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось выгрузить конфигурацию в XML (код ошибки ""%1"")';
				|en = 'Cannot export configuration to XML (error code ""%1"")';"),
			Result.ReturnCode);
		If Messages <> "" Then
			ErrorText = ErrorText + ":" + StrReplace(Chars.LF + Messages, Chars.LF, Chars.LF + Chars.Tab);
		Else
			ErrorText = ErrorText + "."
		EndIf;
		Raise ErrorText;
	EndIf;
	
	Return True;
	
EndFunction

Function LoadConfigurationFromXML(Parameters)
		
	If Parameters.ChangedFiles.Count() = 0 Then
		MessageText = NStr("ru = 'Файлы конфигурации не изменены, загрузка не требуется.';
								|en = 'Configuration files are not changed, import is not required.';");
		WriteGlobalMessage(Parameters, MessageText, 90);
		Return False;
	EndIf;
	
	FileNameChangedFiles = Parameters.WorkingDirectory + "ChangedFiles.txt";
	TextWriter = New TextWriter(FileNameChangedFiles, TextEncoding.UTF8, , False);
	TextWriter.Write(StrConcat(Parameters.ChangedFiles, Chars.LF));
	TextWriter.Close();
	TextWriter = Undefined;
	
	MessagesFileName = Parameters.WorkingDirectory + "Load.log";
	
	StartupCommand = New Array;
	StartupCommand.Add(BinDir() + "\1cv8.exe");
	StartupCommand.Add("DESIGNER");
	StartupCommand.Add("/IBConnectionString");
	StartupCommand.Add(InfoBaseConnectionString());
	If Not IsBlankString(Parameters.User) Then 
		StartupCommand.Add("/N");
		StartupCommand.Add(Parameters.User);
		StartupCommand.Add("/P");
		StartupCommand.Add(Parameters.Password);
	EndIf;
	StartupCommand.Add("/LoadConfigFromFiles");
	StartupCommand.Add(Parameters.WorkingDirectory);
	StartupCommand.Add("-listfile");
	StartupCommand.Add(FileNameChangedFiles);
	StartupCommand.Add("/Out");
	StartupCommand.Add(MessagesFileName);
	StartupCommand.Add("/DisableStartupMessages");
	StartupCommand.Add("/DisableStartupDialogs");
	
	ManualImportFileAddress = Parameters.WorkingDirectory + "load.cmd";
	TextWriter = New TextWriter(ManualImportFileAddress, TextEncoding.OEM);
	TextWriter.Write(CommonInternalClientServer.SafeCommandString(StartupCommand));
	TextWriter.Close();
	
	If DesignerIsOpen() Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Конфигурация не загружена, т.к. открыт конфигуратор.
				|Загрузку можно выполнить в конфигураторе из каталога ""%1"" (или запустив файл ""%2"").';
				|en = 'Configuration is not imported as Designer is opened.
				|You can start import in Designer from directory %1 or by running file %2.';"),
			Parameters.WorkingDirectory,
			ManualImportFileAddress);
		WriteGlobalMessage(Parameters, MessageText, 10);
		Return False;
	EndIf;
	
	TimeConsumingOperations.ReportProgress(90, NStr("ru = 'Загрузка конфигурации из XML...';
												|en = 'Importing configuration from XML…';"));
	
	ApplicationStartupParameters = FileSystem.ApplicationStartupParameters();
	ApplicationStartupParameters.WaitForCompletion = True;
	
	Result = FileSystem.StartApplication(StartupCommand, ApplicationStartupParameters);
	
	If Result.ReturnCode <> 0 Then
		Messages = "";
		File = New File(MessagesFileName);
		If File.Exists() Then
			TextReader = New TextReader(MessagesFileName);
			Messages = TrimAll(TextReader.Read());
			TextReader.Close();
		EndIf;
		ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось загрузить изменения в конфигурацию (код ошибки ""%1"")';
				|en = 'Cannot import changes into the configuration (error code %1)';"),
			Result.ReturnCode);
		If Messages <> "" Then
			ErrorText = ErrorText + ":" + StrReplace(Chars.LF + Messages, Chars.LF, Chars.LF + Chars.Tab);
		Else
			ErrorText = ErrorText + "."
		EndIf;
		Raise ErrorText;
	EndIf;
	
	MessageText = NStr("ru = 'Внесены изменения в конфигурацию.';
							|en = 'Configuration is updated.';");
	WriteGlobalMessage(Parameters, MessageText, 90);
	
	Return True;
	
EndFunction

// Configuration file analysis and modification.
// 
// Parameters:
//   Parameters - Structure:
//   * ExportToDirectory - Boolean
//   * WorkingDirectory - String
//   * User - CatalogRef.Users
//   * Password - String
//   * DCS - DataCompositionSchema
//   * GlobalMessages - ValueTable
//   * MessagesByObjects - ValueTable
//   * ChangedFiles - Array of String
//   * ObjectCount - Number
//   * MetadataTree - See MetadataTree
//   * KindPriority - Number
//   * KindPriority - Map of KeyAndValue:
//     ** Key - String
//     ** Value - Number
//   * ObjectsWithCommands - See ObjectsWithCommands.
//   * NewObjectsWithCommands - See ObjectsWithCommands.
//   * ClosingDatesSectionsProperties - See ChartsOfCharacteristicTypes.PeriodClosingDatesSections.ClosingDatesSectionsProperties
//   * NewPredefinedClosingDatesSections - Array
//
Procedure ChangeExportedTexts(Parameters)
	PercentAchieved = 20;
	Span = 90 - PercentAchieved;
	Total = Parameters.ObjectCount;
	Number = 0;
	For Each KindRow In Parameters.MetadataTree.Rows Do // ValueTreeRow of See MetadataTree
		KindInEnglish = Parameters.RussianEnglishPlurar[Lower(KindRow.Name)];
		If KindInEnglish = Undefined Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не обнаружен перевод имени ""%1"" на английский язык.';
					|en = 'Translation of name %1 into English is not found.';"),
				KindRow.Name);
			WriteGlobalMessage(Parameters, Text, 0);
			Continue;
		EndIf;
		KindRow.Directory = Parameters.WorkingDirectory + KindInEnglish + GetPathSeparator();
		If Not FileExists(KindRow.Directory) Then
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не обнаружен каталог ""%1"".';
					|en = 'Directory %1 is not found.';"),
				KindRow.Directory);
			WriteGlobalMessage(Parameters, Text, 10);
			Continue;
		EndIf;
		For Each ObjectString In KindRow.Rows Do // ValueTreeRow of See MetadataTree
			// Analysis progress.
			Number = Number + 1;
			Percent = PercentAchieved + Span*Number/Total;
			Text = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Анализируется %1 ""%2""...';
					|en = 'Analyzing %1 %2…';"),
				Lower(KindRow.ObjectPresentation),
				ObjectString.Name);
			TimeConsumingOperations.ReportProgress(Percent, Text);
			
			// Form analysis.
			ObjectString.Directory = KindRow.Directory + ObjectString.Name + GetPathSeparator();
			For Each FormString In ObjectString.Rows Do // ValueTreeRow of See MetadataTree
				FormString.Directory = ObjectString.Directory + "Forms" + GetPathSeparator() + FormString.Name + GetPathSeparator();
				If Not FileExists(FormString.Directory) Then
					Text = StringFunctionsClientServer.SubstituteParametersToString(
						NStr("ru = 'Не обнаружен каталог ""%1"".';
							|en = 'Directory %1 is not found.';"),
						FormString.Directory);
					WriteMessageByObject(Parameters, ObjectString, FormString, "Error", Text);
					Continue;
				EndIf;
				
				OnAnalyzeForm(Parameters, ObjectString, FormString);
			EndDo;
			
			// Object module analysis.
			If KindRow.Name = "CommonForms" Then
				OnAnalyzeForm(Parameters, ObjectString, ObjectString);
			Else
				OnAnalyzeObject(Parameters, ObjectString);
			EndIf;
		EndDo;
	EndDo;

EndProcedure

// Generate the resulting report.

Function GenerateReport(Parameters)
	DCSettings = Parameters.DCS.SettingVariants.Main.Settings;
	
	ExternalDataSets = New Structure("GlobalMessages, MessagesByObjects");
	FillPropertyValues(ExternalDataSets, Parameters);
	
	DCTemplateComposer = New DataCompositionTemplateComposer;
	DCTemplate = DCTemplateComposer.Execute(Parameters.DCS, DCSettings);
	
	DCProcessor = New DataCompositionProcessor;
	DCProcessor.Initialize(DCTemplate, ExternalDataSets);
	
	ResultDocument = New SpreadsheetDocument;
	
	DCResultOutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	DCResultOutputProcessor.SetDocument(ResultDocument);
	DCResultOutputProcessor.Output(DCProcessor);
	
	Return ResultDocument;
EndFunction

// Manage files.

Function FileExists(FullFileName)
	File = New File(FullFileName);
	Return File.Exists();
EndFunction

// Conversion.

Procedure RegisterMapsForQuickNamesTransformation(Parameters)
	Parameters.Insert("RussianEnglishSingular", New Map);
	Parameters.Insert("RussianEnglishPlurar", New Map);
	Parameters.Insert("RussianFromSingularToPlural", New Map);
	Parameters.Insert("RussianFromPluralToSingular", New Map);
	Parameters.Insert("PicturesNumbers", New Map);
	
	// Metadata object kinds.
	RegisterTerm(Parameters, "WebService", "WebServices", "WebService", "WebServices", -1);
	RegisterTerm(Parameters, "WSReference", "WSReferences", "WSReference", "", -1);
	RegisterTerm(Parameters, "BusinessProcess", "BusinessProcesses", "BusinessProcess", "BusinessProcesses", 19);
	RegisterTerm(Parameters, "CommandGroup", "CommandGroups", "CommandGroup", "CommandGroups", -1);
	RegisterTerm(Parameters, "Document", "Documents", "Document", "Documents", 12);
	RegisterTerm(Parameters, "DocumentJournal", "DocumentJournals", "DocumentJournal", "DocumentJournals");
	RegisterTerm(Parameters, "Task", "Tasks", "Task", "Tasks", 21);
	RegisterTerm(Parameters, "Constant", "Constants", "Constant", "Constants", 25);
	RegisterTerm(Parameters, "Configuration", "", "Configuration", "Configurations", -1);
	RegisterTerm(Parameters, "FilterCriterion", "FilterCriteria", "FilterCriterion", "FilterCriteria");
	RegisterTerm(Parameters, "DocumentNumerator", "DocumentNumerators", "DocumentNumerator", "", -1);
	RegisterTerm(Parameters, "DataProcessor", "DataProcessors", "DataProcessor", "DataProcessors");
	RegisterTerm(Parameters, "CommonPicture", "CommonPictures", "CommonPicture", "CommonPictures", PictureLib.Picture);
	RegisterTerm(Parameters, "CommonCommand", "CommonCommands", "CommonCommand", "CommonCommands", -1);
	RegisterTerm(Parameters, "CommonForm", "CommonForms", "CommonForm", "CommonForms", PictureLib.Form);
	RegisterTerm(Parameters, "CommonTemplate", "CommonTemplates", "CommonTemplate", "CommonTemplates", -1);
	RegisterTerm(Parameters, "CommonModule", "CommonModules", "CommonModule", "CommonModules", -1);
	RegisterTerm(Parameters, "CommonAttribute", "CommonAttributes", "CommonAttribute", "CommonAttributes", 3);
	RegisterTerm(Parameters, "DefinedType", "DefinedTypes", "DefinedType", "DefinedTypes", -1);
	RegisterTerm(Parameters, "Report", "Reports", "Report", "Reports");
	RegisterTerm(Parameters, "XDTOPackage", "XDTOPackages", "XDTOPackage", "XDTOPackages", -1);
	RegisterTerm(Parameters, "SessionParameter", "SessionParameters", "SessionParameter", "SessionParameters", -1);
	RegisterTerm(Parameters, "FunctionalOptionsParameter", "FunctionalOptionsParameters", "FunctionalOptionsParameter", "FunctionalOptionsParameters", -1);
	RegisterTerm(Parameters, "Enum", "Enums", "Enum", "Enums");
	RegisterTerm(Parameters, "ChartOfCalculationTypes", "ChartsOfCalculationTypes", "ChartOfCalculationTypes", "ChartsOfCalculationTypes", 17);
	RegisterTerm(Parameters, "ChartOfCharacteristicTypes", "ChartsOfCharacteristicTypes", "ChartOfCharacteristicTypes", "ChartsOfCharacteristicTypes", 3);
	RegisterTerm(Parameters, "ExchangePlan", "ExchangePlans", "ExchangePlan", "ExchangePlans", 23);
	RegisterTerm(Parameters, "ChartOfAccounts", "ChartsOfAccounts", "ChartOfAccounts", "ChartsOfAccounts", 15);
	RegisterTerm(Parameters, "EventSubscription", "EventSubscriptions", "EventSubscription", "EventSubscriptions", -1);
	RegisterTerm(Parameters, "Subsystem", "Subsystems", "Subsystem", "Subsystems");
	RegisterTerm(Parameters, "Sequence", "Sequences", "Sequence", "Sequences", -1);
	RegisterTerm(Parameters, "AccountingRegister", "AccountingRegisters", "AccountingRegister", "AccountingRegisters", 34);
	RegisterTerm(Parameters, "AccumulationRegister", "AccumulationRegisters", "AccumulationRegister", "AccumulationRegisters", 28);
	RegisterTerm(Parameters, "CalculationRegister", "CalculationRegisters", "CalculationRegister", "CalculationRegisters", 38);
	RegisterTerm(Parameters, "InformationRegister", "InformationRegisters", "InformationRegister", "InformationRegisters", 26);
	RegisterTerm(Parameters, "ScheduledJob", "ScheduledJobs", "ScheduledJob", "ScheduledJobs");
	RegisterTerm(Parameters, "Role", "Roles", "Role", "Roles", -1);
	RegisterTerm(Parameters, "Catalog", "Catalogs", "Catalog", "Catalogs");
	RegisterTerm(Parameters, "Style", "Styles", "Style", "", -1);
	RegisterTerm(Parameters, "FunctionalOption", "FunctionalOptions", "FunctionalOption", "FunctionalOptions", PictureLib.CheckAll);
	RegisterTerm(Parameters, "SettingsStorage", "SettingsStorages", "SettingsStorage", "SettingsStorages");
	RegisterTerm(Parameters, "StyleItem", "StyleItems", "StyleItem", "StyleItems", -1);
	RegisterTerm(Parameters, "Language", "Languages", "Language", "Languages", -1);
	
	// Types of nested metadata objects.
	RegisterTerm(Parameters, "Module", "", "Module", "", -1);
	RegisterTerm(Parameters, "ManagerModule", "", "ManagerModule", "", -1);
	RegisterTerm(Parameters, "ObjectModule", "", "ObjectModule", "", -1);
	RegisterTerm(Parameters, "CommandModule", "", "CommandModule", "", -1);
	RegisterTerm(Parameters, "RecordSetModule", "", "RecordSetModule", "", -1);
	RegisterTerm(Parameters, "ValueManagerModule", "", "ValueManagerModule", "", -1);
	
	RegisterTerm(Parameters, "ExternalConnectionModule", "", "ExternalConnectionModule", "", -1);
	RegisterTerm(Parameters, "ManagedApplicationModule", "", "ManagedApplicationModule", "", -1);
	RegisterTerm(Parameters, "OrdinaryApplicationModule", "", "OrdinaryApplicationModule", "", -1);
	RegisterTerm(Parameters, "SessionModule", "", "SessionModule", "", -1);
	
	RegisterTerm(Parameters, "Help", "", "Help", "");
	RegisterTerm(Parameters, "Form", "Forms", "Form", "Forms");
	RegisterTerm(Parameters, "Flowchart", "", "Flowchart", "", -1);
	RegisterTerm(Parameters, "Picture", "Images", "Picture", "Pictures");
	RegisterTerm(Parameters, "CommandInterface", "", "CommandInterface", "", -1);
	
	RegisterTerm(Parameters, "Template", "Templates", "Template", "Templates", -1);
	RegisterTerm(Parameters, "Command", "Commands", "Command", "Commands", -1);
	RegisterTerm(Parameters, "Aggregates", "", "Aggregates", "", -1);
	RegisterTerm(Parameters, "Recalculation", "Recalculations", "Recalculation", "Recalculations", -1);
	RegisterTerm(Parameters, "Predefined", "", "Predefined", "", -1);
	RegisterTerm(Parameters, "Content", "", "Content", "", -1);
	RegisterTerm(Parameters, "Rights", "", "Rights", "", -1);
	RegisterTerm(Parameters, "Schedule", "", "Schedule", "", -1);
	
	// Form item types.
	RegisterTerm(Parameters, "ButtonGroup", "", "ButtonGroup", "", -1);
	RegisterTerm(Parameters, "ColumnGroup", "", "ColumnGroup", "", -1);
	RegisterTerm(Parameters, "CommandBar", "", "CommandBar", "", -1);
	RegisterTerm(Parameters, "ContextMenu", "", "ContextMenu", "", -1);
	RegisterTerm(Parameters, "UsualGroup", "", "UsualGroup", "", -1);
	RegisterTerm(Parameters, "Popup", "", "Popup", "", -1);
	RegisterTerm(Parameters, "Page", "", "Page", "", -1);
	RegisterTerm(Parameters, "Pages", "", "Pages", "", -1);
	
EndProcedure

Procedure RegisterTerm(Parameters, RussianSingular, RussianPlural, EnglishSingular, EnglishPlural, PictureNumber = 0)
	If RussianPlural = "" Then
		RussianPlural = RussianSingular;
	EndIf;
	If EnglishPlural = "" Then
		EnglishPlural = EnglishSingular;
	EndIf;
	Parameters.RussianEnglishSingular.Insert(Lower(RussianSingular), EnglishSingular);
	Parameters.RussianEnglishPlurar.Insert(Lower(RussianPlural), EnglishPlural);
	Parameters.RussianFromSingularToPlural.Insert(Lower(RussianSingular), RussianPlural);
	Parameters.RussianFromPluralToSingular.Insert(Lower(RussianPlural), RussianSingular);
	If PictureNumber = 0 Then
		PictureNumber = PictureLib[RussianSingular];
	EndIf;
	Parameters.PicturesNumbers.Insert(Lower(RussianPlural), PictureNumber);
EndProcedure

// Manage module files.

Function ReadModuleText(FullModuleName)
	If Not FileExists(FullModuleName) Then
		Return Undefined;
	EndIf;
	TextReader = New TextReader(FullModuleName);
	ModuleText = TextReader.Read();
	TextReader.Close();
	Return ModuleText;
EndFunction

Procedure WriteModuleText(FullModuleName, ModuleText)
	File = New File(FullModuleName);
	CreateDirectory(File.Path);
	TextWriter = New TextWriter(FullModuleName, TextEncoding.UTF8);
	TextWriter.Write(ModuleText);
	TextWriter.Close();
EndProcedure

// Check if objects belong to SSL.

Function IsLibraryObject(MetadataObject)
	
	Return LibraryObjects[MetadataObject.FullName()] <> Undefined;
	
EndFunction

Function ReadSubsystemObjectsList(Val Subsystem, ListOfObjects = Undefined)
	
	If ListOfObjects = Undefined Then
		ListOfObjects = New Map;
	EndIf;
	
	For Each MetadataObject In Subsystem.Content Do
		ListOfObjects.Insert(MetadataObject.FullName(), True);
	EndDo;
	
	For Each SubordinateSubsystem In Subsystem.Subsystems Do
		ReadSubsystemObjectsList(SubordinateSubsystem, ListOfObjects)
	EndDo;
	
	Return ListOfObjects;
	
EndFunction

#EndRegion

#EndRegion

#Region Initialize

LibraryObjects = ReadSubsystemObjectsList(Metadata.Subsystems.StandardSubsystems);

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
						|en = 'Invalid object call on the client.';");
#EndIf