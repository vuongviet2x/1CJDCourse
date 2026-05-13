///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

#Region ObsoleteProceduresAndFunctions

// Deprecated. Instead, use the new function (See DataExchangeServer.IsStandaloneWorkplace).
// .
//
Function IsStandaloneWorkplace() Export
	
	Return StandaloneWorkstationMode();
	
EndFunction

// Deprecated. Instead, use the new function (See DataExchangeServer.ExchangePlanNodeByCode).
// .
//
Function FindExchangePlanNodeByCode(ExchangePlanName, NodeCode) Export
	
	TextTemplate1 = "ExchangePlan.%1";
	NameOfTheStringExchangePlan = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, ExchangePlanName);
	
	QueryText =
	"SELECT
	|	ExchangePlan.Ref AS Ref
	|FROM
	|	&ExchangePlanName AS ExchangePlan
	|WHERE
	|	ExchangePlan.Code = &Code";
	
	QueryText = StrReplace(QueryText, "&ExchangePlanName", NameOfTheStringExchangePlan);
	
	Query = New Query;
	Query.SetParameter("Code", NodeCode);
	Query.Text = QueryText;
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		
		Return Undefined;
		
	EndIf;
	
	Selection = QueryResult.Select();
	Selection.Next();
	
	Return Selection.Ref;
EndFunction

#EndRegion

#EndRegion

#Region Internal

// See DataExchangeServer.IsStandaloneWorkplace.
Function StandaloneWorkstationMode() Export
	
	SetPrivilegedMode(True);
	
	If Constants.SubordinateDIBNodeSetupCompleted.Get() Then
		
		Return Constants.IsStandaloneWorkplace.Get();
		
	Else
		
		MasterNodeOfThisInfobase = DataExchangeServer.MasterNode();
		Return MasterNodeOfThisInfobase <> Undefined
			And IsStandaloneWorkstationNode(MasterNodeOfThisInfobase);
		
	EndIf;
	
EndFunction

// Returns a flag that shows whether an exchange plan is used in data exchange.
// If an exchange plan contains at least one node apart from the predefined one,
// it is considered being used in data exchange.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//  Sender - ExchangePlanRef - the parameter value is set if it is necessary
//   to determine whether there are other exchange nodes besides the one from
//   which the object was received.
//
// Returns:
//  Boolean -  If True, exchange plan is used. Otherwise, False.
//
Function DataExchangeEnabled(Val ExchangePlanName, Val Sender = Undefined) Export
	
	If Not GetFunctionalOption("UseDataSynchronization") Then
		
		Return False;
		
	EndIf;
	
	QueryText = 
	"SELECT TOP 1
	|	TRUE
	|FROM
	|	&MetadataTableName AS ExchangePlan
	|WHERE
	|	NOT ExchangePlan.DeletionMark
	|	AND NOT ExchangePlan.ThisNode
	|	AND ExchangePlan.Ref <> &Sender";
	
	ReplacementString = StringFunctionsClientServer.SubstituteParametersToString("ExchangePlan.%1", ExchangePlanName);
	QueryText = StrReplace(QueryText, "&MetadataTableName", ReplacementString);
	
	Query = New Query(QueryText);
	Query.SetParameter("Sender", Sender);
	Return Not Query.Execute().IsEmpty();
	
EndFunction

// See DataExchangeServer.IsStandaloneWorkstationNode.
Function IsStandaloneWorkstationNode(Val InfobaseNode) Export
	
	Return DataExchangeCached.StandaloneModeSupported()
		And DataExchangeCached.GetExchangePlanName(InfobaseNode) = DataExchangeCached.StandaloneModeExchangePlan();
	
EndFunction

// See DataExchangeServer.ExchangePlanSettings
Function ExchangePlanSettings(ExchangePlanName, CorrespondentVersion = "", CorrespondentName = "", CorrespondentInSaaS = Undefined) Export
	Return DataExchangeServer.ExchangePlanSettings(ExchangePlanName, CorrespondentVersion, CorrespondentName, CorrespondentInSaaS);
EndFunction

// See DataExchangeServer.SettingOptionDetails
Function SettingOptionDetails(ExchangePlanName, SettingID, 
								CorrespondentVersion = "", CorrespondentName = "") Export
	Return DataExchangeServer.SettingOptionDetails(ExchangePlanName, SettingID, 
								CorrespondentVersion, CorrespondentName);
EndFunction
////////////////////////////////////////////////////////////////////////////////
// The mechanism of object registration on exchange plan nodes (ORM).

// Gets the name of this infobase from a constant or a configuration synonym.
// (For internal use only).
//
Function ThisInfobaseName() Export
	
	SetPrivilegedMode(True);
	
	Result = Constants.SystemTitle.Get();
	
	If IsBlankString(Result) Then
		
		Result = Metadata.Synonym;
		
	EndIf;
	
	Return Result;
EndFunction

// Gets a code of a predefined exchange plan node.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  String - a code of a predefined exchange plan node.
//
Function GetThisNodeCodeForExchangePlan(ExchangePlanName) Export
	
	Return Common.ObjectAttributeValue(GetThisExchangePlanNode(ExchangePlanName), "Code");
	
EndFunction

// Gets a name of a predefined exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node.
// 
// Returns:
//  String - a name of a predefined exchange plan node.
//
Function ThisNodeDescription(Val InfobaseNode) Export
	
	Return String(GetThisExchangePlanNode(GetExchangePlanName(InfobaseNode)));
	
EndFunction

// Gets an array of names of configuration exchange plans that use the SSL functionality.
//
// Parameters:
//  No.
// 
// Returns:
//   Array - an array of exchange plan name items.
//
Function SSLExchangePlans() Export
	
	Return SSLExchangePlansList().UnloadValues();
	
EndFunction

// Determines whether an exchange plan specified by name is used in SaaS mode.
// For this purpose, all exchange plans on their manager module level
// define the ExchangePlanUsedInSaaS() function
// which explicitly returns True or False.
//
// Parameters:
//   ExchangePlanName - String
//
// Returns:
//   Boolean
//
Function ExchangePlanUsedInSaaS(Val ExchangePlanName) Export
	
	Result = False;
	
	If SSLExchangePlans().Find(ExchangePlanName) <> Undefined Then
		Result = DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName,
			"ExchangePlanUsedInSaaS", "");
	EndIf;
	
	Return Result;
	
EndFunction

// Fills in the list of possible error codes.
//
// Returns:
//  Map of KeyAndValue:
//    * Key - Number - error code
//    * Value - String - error details
//
Function ErrorsMessages() Export
	
	ErrorsMessages = New Map;
		
	ErrorsMessages.Insert(2,  NStr("ru = 'Ошибка распаковки файла обмена. Файл заблокирован.';
										|en = 'Error extracting exchange file. File is locked.';"));
	ErrorsMessages.Insert(3,  NStr("ru = 'Указанный файл правил обмена не существует.';
										|en = 'The exchange rules file does not exist.';"));
	ErrorsMessages.Insert(4,  NStr("ru = 'Ошибка при создании COM-объекта Msxml2.DOMDocument';
										|en = 'Cannot create COM object: Msxml2.DOMDocument';"));
	ErrorsMessages.Insert(5,  NStr("ru = 'Ошибка открытия файла обмена';
										|en = 'Error opening exchange file';"));
	ErrorsMessages.Insert(6,  NStr("ru = 'Ошибка при загрузке правил обмена';
										|en = 'Error importing exchange rules';"));
	ErrorsMessages.Insert(7,  NStr("ru = 'Ошибка формата правил обмена';
										|en = 'Exchange rule format error';"));
	ErrorsMessages.Insert(8,  NStr("ru = 'Некорректно указано имя файла для выгрузки данных';
										|en = 'Invalid data export file name';"));
	ErrorsMessages.Insert(9,  NStr("ru = 'Ошибка формата файла обмена';
										|en = 'Exchange file format error';"));
	ErrorsMessages.Insert(10, NStr("ru = 'Не указано имя файла для выгрузки данных (Имя файла данных)';
										|en = 'Data export file name is not specified';"));
	ErrorsMessages.Insert(11, NStr("ru = 'Ссылка на несуществующий объект метаданных в правилах обмена';
										|en = 'Exchange rules reference a metadata object that does not exist';"));
	ErrorsMessages.Insert(12, NStr("ru = 'Не указано имя файла с правилами обмена (Имя файла правил)';
										|en = 'Exchange rules file name is not specified';"));
			
	ErrorsMessages.Insert(13, NStr("ru = 'Ошибка получения значения свойства объекта (по имени свойства источника)';
										|en = 'Error getting value of object property by property name in source infobase';"));
	ErrorsMessages.Insert(14, NStr("ru = 'Ошибка получения значения свойства объекта (по имени свойства приемника)';
										|en = 'Error getting value of object property by property name in destination infobase';"));
	
	ErrorsMessages.Insert(15, NStr("ru = 'Не указано имя файла для загрузки данных (Имя файла для загрузки)';
										|en = 'Data import file name is not specified';"));
			
	ErrorsMessages.Insert(16, NStr("ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства источника)';
										|en = 'Error getting value of subordinate object property by property name in source infobase';"));
	ErrorsMessages.Insert(17, NStr("ru = 'Ошибка получения значения свойства подчиненного объекта (по имени свойства приемника)';
										|en = 'Error getting value of subordinate object property by property name in destination infobase';"));
	ErrorsMessages.Insert(18, NStr("ru = 'Ошибка при создании обработки с кодом обработчиков';
										|en = 'Error creating data processor with handlers code';"));
	ErrorsMessages.Insert(19, NStr("ru = 'Ошибка в обработчике события ПередЗагрузкойОбъекта';
										|en = 'Event handler error: BeforeImportObject';"));
	ErrorsMessages.Insert(20, NStr("ru = 'Ошибка в обработчике события ПриЗагрузкеОбъекта';
										|en = 'Event handler error: OnImportObject';"));
	ErrorsMessages.Insert(21, NStr("ru = 'Ошибка в обработчике события ПослеЗагрузкиОбъекта';
										|en = 'Event handler error: AfterImportObject';"));
	ErrorsMessages.Insert(22, NStr("ru = 'Ошибка в обработчике события ПередЗагрузкойДанных (конвертация)';
										|en = 'Event handler error (data conversion): BeforeDataImport';"));
	ErrorsMessages.Insert(23, NStr("ru = 'Ошибка в обработчике события ПослеЗагрузкиДанных (конвертация)';
										|en = 'Event handler error (data conversion): AfterImportData';"));
	ErrorsMessages.Insert(24, NStr("ru = 'Ошибка при удалении объекта';
										|en = 'Object deletion error';"));
	ErrorsMessages.Insert(25, NStr("ru = 'Ошибка при записи документа';
										|en = 'Document writing error';"));
	ErrorsMessages.Insert(26, NStr("ru = 'Ошибка записи объекта';
										|en = 'Object writing error';"));
	ErrorsMessages.Insert(27, NStr("ru = 'Ошибка в обработчике события ПередОбработкойПравилаОчистки';
										|en = 'Event handler error: BeforeProcessClearingRule';"));
	ErrorsMessages.Insert(28, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиПравилаОчистки';
										|en = 'Event handler error: AfterProcessClearingRule';"));
	ErrorsMessages.Insert(29, NStr("ru = 'Ошибка в обработчике события ПередУдалениемОбъекта';
										|en = 'Event handler error: BeforeDeleteObject';"));
	
	ErrorsMessages.Insert(31, NStr("ru = 'Ошибка в обработчике события ПередОбработкойПравилаВыгрузки';
										|en = 'Event handler error: BeforeProcessExportRule';"));
	ErrorsMessages.Insert(32, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиПравилаВыгрузки';
										|en = 'Event handler error: AfterProcessExportRule';"));
	ErrorsMessages.Insert(33, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта';
										|en = 'Event handler error: BeforeExportObject';"));
	ErrorsMessages.Insert(34, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта';
										|en = 'Event handler error: AfterExportObject';"));
			
	ErrorsMessages.Insert(41, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойОбъекта';
										|en = 'Event handler error: BeforeExportObject';"));
	ErrorsMessages.Insert(42, NStr("ru = 'Ошибка в обработчике события ПриВыгрузкеОбъекта';
										|en = 'Event handler error: OnExportObject';"));
	ErrorsMessages.Insert(43, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъекта';
										|en = 'Event handler error: AfterExportObject';"));
			
	ErrorsMessages.Insert(45, NStr("ru = 'Не найдено правило конвертации объектов';
										|en = 'Object conversion rule not found';"));
		
	ErrorsMessages.Insert(48, NStr("ru = 'Ошибка в обработчике события ПередОбработкойВыгрузки группы свойств';
										|en = 'Event handler error: BeforeProcessExport (of property group)';"));
	ErrorsMessages.Insert(49, NStr("ru = 'Ошибка в обработчике события ПослеОбработкиВыгрузки группы свойств';
										|en = 'Event handler error: AfterProcessExport (of property group)';"));
	ErrorsMessages.Insert(50, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкой (объекта коллекции)';
										|en = 'Event handler error: BeforeExport (of collection object)';"));
	ErrorsMessages.Insert(51, NStr("ru = 'Ошибка в обработчике события ПриВыгрузке (объекта коллекции)';
										|en = 'Event handler error: OnExport (of collection object)';"));
	ErrorsMessages.Insert(52, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузки (объекта коллекции)';
										|en = 'Event handler error: AfterExport (of collection object)';"));
	ErrorsMessages.Insert(53, NStr("ru = 'Ошибка в глобальном обработчике события ПередЗагрузкойОбъекта (конвертация)';
										|en = 'Global event handler error (data conversion): BeforeImportObject';"));
	ErrorsMessages.Insert(54, NStr("ru = 'Ошибка в глобальном обработчике события ПослеЗагрузкиОбъекта (конвертация)';
										|en = 'Global event handler error (data conversion): AfterImportObject';"));
	ErrorsMessages.Insert(55, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкой (свойства)';
										|en = 'Event handler error: BeforeExport (of property)';"));
	ErrorsMessages.Insert(56, NStr("ru = 'Ошибка в обработчике события ПриВыгрузке (свойства)';
										|en = 'Event handler error: OnExport (of property)';"));
	ErrorsMessages.Insert(57, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузки (свойства)';
										|en = 'Event handler error: AfterExport (of property)';"));
	
	ErrorsMessages.Insert(62, NStr("ru = 'Ошибка в обработчике события ПередВыгрузкойДанных (конвертация)';
										|en = 'Event handler error (data conversion): BeforeExportData';"));
	ErrorsMessages.Insert(63, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиДанных (конвертация)';
										|en = 'Event handler error (data conversion): AfterExportData';"));
	ErrorsMessages.Insert(64, NStr("ru = 'Ошибка в глобальном обработчике события ПередКонвертациейОбъекта (конвертация)';
										|en = 'Global event handler error (data conversion): BeforeConvertObject';"));
	ErrorsMessages.Insert(65, NStr("ru = 'Ошибка в глобальном обработчике события ПередВыгрузкойОбъекта (конвертация)';
										|en = 'Global event handler error (data conversion): BeforeExportObject';"));
	ErrorsMessages.Insert(66, NStr("ru = 'Ошибка получения коллекции подчиненных объектов из входящих данных';
										|en = 'Error getting collection of subordinate objects from incoming data';"));
	ErrorsMessages.Insert(67, NStr("ru = 'Ошибка получения свойства подчиненного объекта из входящих данных';
										|en = 'Error getting property of subordinate object from incoming data';"));
	ErrorsMessages.Insert(68, NStr("ru = 'Ошибка получения свойства объекта из входящих данных';
										|en = 'Error getting object property from incoming data';"));
	
	ErrorsMessages.Insert(69, NStr("ru = 'Ошибка в глобальном обработчике события ПослеВыгрузкиОбъекта (конвертация)';
										|en = 'Global event handler error (data conversion): AfterExportObject';"));
	
	ErrorsMessages.Insert(71, NStr("ru = 'Не найдено соответствие для значения Источника';
										|en = 'Cannot find a match for the source value';"));
	
	ErrorsMessages.Insert(72, NStr("ru = 'Ошибка при выгрузке данных для узла плана обмена';
										|en = 'Error exporting data for exchange plan node';"));
	
	ErrorsMessages.Insert(73, NStr("ru = 'Ошибка в обработчике события ПоследовательностьПолейПоиска';
										|en = 'Event handler error: SearchFieldSequence';"));
	ErrorsMessages.Insert(74, NStr("ru = 'Перезагрузите правила обмена для выгрузки данных.';
										|en = 'To export data, reload data exchange rules.';"));
	
	ErrorsMessages.Insert(75, NStr("ru = 'Ошибка в обработчике события ПослеЗагрузкиПравилОбмена (конвертация)';
										|en = 'Event handler error (data conversion): AfterImportExchangeRules';"));
	ErrorsMessages.Insert(76, NStr("ru = 'Ошибка в обработчике события ПередОтправкойИнформацииОбУдалении (конвертация)';
										|en = 'Event handler error (data conversion): BeforeSendDeletionInfo';"));
	ErrorsMessages.Insert(77, NStr("ru = 'Ошибка в обработчике события ПриПолученииИнформацииОбУдалении (конвертация)';
										|en = 'Event handler error (data conversion): OnGetDeletionInfo';"));
	
	ErrorsMessages.Insert(78, NStr("ru = 'Ошибка при выполнении алгоритма после загрузки значений параметров';
										|en = 'Algorithm fails after parameter values are imported';"));
	
	ErrorsMessages.Insert(79, NStr("ru = 'Ошибка в обработчике события ПослеВыгрузкиОбъектаВФайл';
										|en = 'Event handler error: AfterExportObjectToFile';"));
	
	ErrorsMessages.Insert(80, NStr("ru = 'Ошибка установки свойства предопределенного элемента.
		|Нельзя помечать на удаление предопределенный элемент. Пометка на удаление для объекта не установлена.';
		|en = 'Error marking item for deletion.
		|Predefined items cannot be marked for deletion.';"));
	//
	ErrorsMessages.Insert(81, NStr("ru = 'Возникла коллизия изменений объектов.
		|Объект этой информационной базы был заменен версией объекта из второй информационной базы.';
		|en = 'Object version conflict.
		|The object in the destination infobase is replaced with an object version from the source infobase.';"));
	//
	ErrorsMessages.Insert(82, NStr("ru = 'Возникла коллизия изменений объектов.
		|Объект из второй информационной базы не принят. Объект этой информационной базы не изменен.';
		|en = 'Object version conflict.
		|An object version from the source infobase is rejected. The object in the destination infobase is not changed.';"));
	//
	ErrorsMessages.Insert(83, NStr("ru = 'Ошибка обращения к табличной части объекта. Табличная часть объекта не может быть изменена.';
										|en = 'Object table access error. Cannot change the table.';"));
	ErrorsMessages.Insert(84, NStr("ru = 'Коллизия дат запрета изменения.';
										|en = 'Period-end closing dates conflict.';"));
	
	ErrorsMessages.Insert(174, NStr("ru = 'Сообщение обмена было принято ранее';
											|en = 'The exchange message was received earlier';"));
	ErrorsMessages.Insert(175, NStr("ru = 'Ошибка в обработчике события ПередПолучениемИзмененныхОбъектов (конвертация)';
											|en = 'Event handler error (data conversion): BeforeGetChangedObjects';"));
	ErrorsMessages.Insert(176, NStr("ru = 'Ошибка в обработчике события ПослеПолученияИнформацииОбУзлахОбмена (конвертация)';
											|en = 'Event handler error (data conversion): AfterGetExchangeNodesInformation';"));
		
	ErrorsMessages.Insert(177, NStr("ru = 'Имя плана обмена из сообщения обмена не соответствует ожидаемому.';
											|en = 'Unexpected exchange plan name in exchange message.';"));
	ErrorsMessages.Insert(178, NStr("ru = 'Получатель из сообщения обмена не соответствует ожидаемому.';
											|en = 'Unexpected destination in exchange message.';"));
	
	ErrorsMessages.Insert(1000, NStr("ru = 'Ошибка при создании временного файла выгрузки данных';
											|en = 'Error creating temporary data export file';"));
	
	Return ErrorsMessages;
	
EndFunction

Function StandaloneModeSupported() Export
	
	Return StandaloneModeExchangePlans().Count() = 1;
	
EndFunction

Function ExchangePlanPurpose(ExchangePlanName) Export
	
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "ExchangePlanPurpose");
	
EndFunction

// Determines whether an exchange plan has a template.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//  TemplateName - String - a name of the template to check for existence.
//
//  Returns:
//    Boolean - True if the exchange plan contains the specified template. Otherwise, False.
//
Function HasExchangePlanTemplate(Val ExchangePlanName, Val TemplateName) Export
	
	Return Metadata.ExchangePlans[ExchangePlanName].Templates.Find(TemplateName) <> Undefined;
	
EndFunction

// Returns the flag showing that the exchange plan belongs to the DIB exchange plan.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean - True if the exchange plan belongs to the DIB exchange plan. Otherwise, False.
//
Function IsDistributedInfobaseExchangePlan(ExchangePlanName) Export
	
	Return Metadata.ExchangePlans[ExchangePlanName].DistributedInfoBase;
	
EndFunction

Function StandaloneModeExchangePlan() Export
	
	Result = StandaloneModeExchangePlans();
	
	If Result.Count() = 0 Then
		
		Raise NStr("ru = 'Автономная работа в системе не предусмотрена.';
								|en = 'Application does not support offline work.';");
		
	ElsIf Result.Count() > 1 Then
		
		Raise NStr("ru = 'Создано более одного плана обмена для автономной работы.';
								|en = 'Multiple exchange plans are found for offline mode.';");
		
	EndIf;
	
	Return Result[0];
EndFunction

// See DataExchangeServer.IsXDTOExchangePlan
Function IsXDTOExchangePlan(ExchangePlan) Export
	If TypeOf(ExchangePlan) = Type("String") Then
		ExchangePlanName = ExchangePlan;
	Else
		ExchangePlanName = DataExchangeCached.GetExchangePlanName(ExchangePlan);
	EndIf;
	Return DataExchangeServer.ExchangePlanSettingValue(ExchangePlanName, "IsXDTOExchangePlan");
EndFunction

Function IsStringAttributeOfUnlimitedLength(FullName, AttributeName) Export
	
	MetadataObject = Metadata.FindByFullName(FullName);
	Attribute = MetadataObject.Attributes.Find(AttributeName);
	
	If Attribute <> Undefined
		And Attribute.Type.ContainsType(Type("String"))
		And (Attribute.Type.StringQualifiers.Length = 0) Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Gets a name of the exchange plan as a metadata object for the specified node.
//
// Parameters:
//  ExchangePlanNode - ExchangePlanRef - an exchange plan node.
// 
// Returns:
//  Имя - String - a name of the exchange plan as a metadata object.
//
Function GetExchangePlanName(ExchangePlanNode) Export
	
	Return ExchangePlanNode.Metadata().Name;
	
EndFunction

Function GetNameOfCorrespondentExchangePlan(ExchangePlanNode) Export
	
	ExchangePlanName = GetExchangePlanName(ExchangePlanNode);
	
	If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlanNode) Then
		Return ExchangePlanName;
	EndIf;
	
	CorrespondentExchangePlanName = InformationRegisters.CommonInfobasesNodesSettings.CorrespondentExchangePlanName(ExchangePlanNode);
	
	If CorrespondentExchangePlanName = "" Then
		CorrespondentExchangePlanName = ExchangePlanName;
	EndIf; 
	
	Return CorrespondentExchangePlanName;
	
EndFunction

// Gets an array of names of separated configuration exchange plans that use the SSL functionality.
// If the configuration does not contain separators, all exchange plans are treated as separated.
//
// Parameters:
//  No.
// 
// Returns:
//   Array - an array of elements of separated exchange plan names.
//
Function SeparatedSSLExchangePlans() Export
	
	Result = New Array;
	
	For Each ExchangePlanName In SSLExchangePlans() Do
		
		If Common.SubsystemExists("CloudTechnology.Core") Then
			ModuleSaaSOperations = Common.CommonModule("SaaSOperations");
			IsSeparatedConfiguration = ModuleSaaSOperations.IsSeparatedConfiguration();
		Else
			IsSeparatedConfiguration = False;
		EndIf;
		
		If IsSeparatedConfiguration Then
			
			If ModuleSaaSOperations.IsSeparatedMetadataObject("ExchangePlan." + ExchangePlanName,
					ModuleSaaSOperations.MainDataSeparator()) Then
				
				Result.Add(ExchangePlanName);
				
			EndIf;
			
		Else
			
			Result.Add(ExchangePlanName);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

// It determines whether versioning is used.
//
// Parameters:
//  Sender - ExchangePlanRef - determines
//		whether object version creating is needed for the passed node if the parameter is passed.
//
Function VersioningUsed(Sender = Undefined, CheckAccessRights = False) Export
	
	Used = False;
	
	If Common.SubsystemExists("StandardSubsystems.ObjectsVersioning") Then
		
		Used = ?(Sender <> Undefined, IsSSLDataExchangeNode(Sender), True);
		
		If Used And CheckAccessRights Then
			
			ModuleObjectsVersioning = Common.CommonModule("ObjectsVersioning");
			Used = ModuleObjectsVersioning.HasRightToReadObjectVersionInfo();
			
		EndIf;
			
	EndIf;
	
	Return Used;
	
EndFunction

// Determines whether an exchange plan has a registration manager.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean - If True, the exchange plan has a registration module. Otherwise, False.
//                                                            
Function RulesForRegisteringInManager(Val ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeServer.ExchangePlanSettings(ExchangePlanName, "", "", Undefined);
		
	Return ExchangePlanSettings.RulesForRegisteringInManager;	
	
EndFunction

// Returns the name of the registration manager (common module name) for the given exchange plan.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean - If True, the exchange plan has a registration module. Otherwise, False.
// 
Function RegistrationManagerName(Val ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeServer.ExchangePlanSettings(ExchangePlanName, "", "", Undefined);
	
	Return ExchangePlanSettings.RegistrationManagerName;	
	
EndFunction	

// Returns the flag indicating whether the cache was used for searching references in the "SynchronizedObjectPublicIDs" information register
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean - If True, cache was used. If False, requests to ""SynchronizedObjectPublicIDs" were used.
// 
Function UseCacheOfPublicIdentifiers(Val ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeServer.ExchangePlanSettings(ExchangePlanName, "", "", Undefined);
	
	Return ExchangePlanSettings.UseCacheOfPublicIdentifiers;
	
EndFunction

// Returns the "Global" flag value for an EnterpriseData exchange plan 
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
//  Returns:
//    Boolean
// 
Function ThisIsGlobalExchangeThroughUniversalFormat(Val ExchangePlanName) Export
	
	ExchangePlanSettings = DataExchangeServer.ExchangePlanSettings(ExchangePlanName, "", "", Undefined);
	
	Return ExchangePlanSettings.Global;
	
EndFunction



#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// The mechanism of object registration on exchange plan nodes (ORM).

// Retrieves the table of object registration rules for the exchange plan.
//
// Parameters:
//  ExchangePlanName - String - a name of the exchange plan as it is set in Designer
//                    for which the registration rules are to be received.
//
// Returns:
//   ValueTable - a table of registration rules for current exchange plan.
//
Function ExchangePlanObjectsRegistrationRules(Val ExchangePlanName) Export
	
	ObjectsRegistrationRules = DataExchangeInternal.SessionParametersObjectsRegistrationRules().Get();
	
	Return ObjectsRegistrationRules.Copy(New Structure("ExchangePlanName", ExchangePlanName));
EndFunction

// Gets the table of object registration rules for the specified exchange plan.
//
// Parameters:
//  ExchangePlanName   - String - an exchange plan name, as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object
//                   for which registration rules are to be received.
//
// Returns:
//   ValueTable - a table of object registration rules for the specified exchange plan.
//
Function ObjectRegistrationRules(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanObjectsRegistrationRules = DataExchangeEvents.ExchangePlanObjectsRegistrationRules(ExchangePlanName);
	
	Return ExchangePlanObjectsRegistrationRules.Copy(New Structure("MetadataObjectName3", FullObjectName));
	
EndFunction

// Returns a flag that shows whether registration rules exist for the object by the specified exchange plan.
//
// Parameters:
//  ExchangePlanName   - String - an exchange plan name, as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object
//                   whose registration rules must be checked for existence.
//
//  Returns:
//     Boolean - True if the object registration rules exist. Otherwise, False.
//
Function ObjectRegistrationRulesExist(Val ExchangePlanName, Val FullObjectName) Export
	
	Return DataExchangeEvents.ObjectRegistrationRules(ExchangePlanName, FullObjectName).Count() <> 0;
	
EndFunction

// Determines whether automatic registration of a metadata object in exchange plan is allowed.
//
// Parameters:
//  ExchangePlanName   - String - a name of the exchange plan as it is set in Designer which contains the metadata
//                              object.
//  FullObjectName - String - a full name of the metadata object whose automatic registration flag must be checked.
//
//  Returns:
//    Boolean - True if metadata object automatic registration is allowed in the exchange plan;
//   False if metadata object auto registration is denied in the exchange plan
//          or the exchange plan does not include the metadata object.
//
Function AutoRegistrationAllowed(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanContentItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(Metadata.FindByFullName(FullObjectName));
	
	If ExchangePlanContentItem = Undefined Then
		Return False; // The exchange plan does not include the metadata object.
	EndIf;
	
	Return ExchangePlanContentItem.AutoRecord = AutoChangeRecord.Allow;
EndFunction

// Determines whether the exchange plan includes the metadata object.
//
// Parameters:
//  ExchangePlanName   - String - an exchange plan name, as it is set in Designer.
//  FullObjectName - String - a full name of the metadata object whose automatic registration flag is to be checked.
//
//  Returns:
//    Boolean - True if the exchange plan includes the object. Otherwise, False.
//
Function ExchangePlanContainsObject(Val ExchangePlanName, Val FullObjectName) Export
	
	ExchangePlanContentItem = Metadata.ExchangePlans[ExchangePlanName].Content.Find(Metadata.FindByFullName(FullObjectName));
	
	Return ExchangePlanContentItem <> Undefined;
EndFunction

// Returns a list of exchange plans that contain at least one exchange node (ignoring ThisNode).
//
Function ExchangePlansInUse() Export
	
	Return DataExchangeServer.GetExchangePlansInUse();
	
EndFunction

// Returns the exchange plan content specified by the user.
// Custom exchange plan content is determined by the object registration rules
// and node settings specified by the user.
//
// Parameters:
//  Recipient - ExchangePlanRef - an exchange plan node reference.
//               User content is retrieved for this node.
//
//  Returns:
//   Map of KeyAndValue:
//     * Key     - String - a full name of a metadata object that is included in the exchange plan content;
//     * Value - EnumRef.ExchangeObjectExportModes - object export mode.
//
Function UserExchangePlanComposition(Val Recipient) Export
	
	SetPrivilegedMode(True);
	
	Result = New Map;
	
	RecipientProperties = Common.ObjectAttributesValues(Recipient,
		Common.AttributeNamesByType(Recipient, Type("EnumRef.ExchangeObjectExportModes")));
	
	Priorities = ObjectsExportModesPriorities();
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(Recipient);
	Rules = DataExchangeCached.ExchangePlanObjectsRegistrationRules(ExchangePlanName);
	Rules.Indexes.Add("MetadataObjectName3");
	
	For Each Item In Metadata.ExchangePlans[ExchangePlanName].Content Do
		
		ObjectName = Item.Metadata.FullName();
		ObjectRules = Rules.FindRows(New Structure("MetadataObjectName3", ObjectName));
		ExportMode = Undefined;
		
		If ObjectRules.Count() = 0 Then // Registration rules are not set.
			
			ExportMode = Enums.ExchangeObjectExportModes.ExportAlways;
			
		Else // Registration rules are set.
			
			For Each ORR In ObjectRules Do
				
				If ValueIsFilled(ORR.FlagAttributeName) Then
					ExportMode = ObjectExportMaxMode(RecipientProperties[ORR.FlagAttributeName], ExportMode, Priorities);
				EndIf;
				
			EndDo;
			
			If ExportMode = Undefined
				Or ExportMode = Enums.ExchangeObjectExportModes.EmptyRef() Then
				ExportMode = Enums.ExchangeObjectExportModes.ExportByCondition;
			EndIf;
			
		EndIf;
		
		Result.Insert(ObjectName, ExportMode);
		
	EndDo;
	
	SetPrivilegedMode(False);
	
	Return Result;
EndFunction

// Returns the object export mode based on the custom exchange plan content (user settings).
//
// Parameters:
//  ObjectName - a metadata object full name. Export mode is retrieved for this metadata object;
//  Recipient - ExchangePlanRef - an exchange plan node reference. The function gets custom content from this node.
//
// Returns:
//   EnumRef.ExchangeObjectExportModes - object export mode.
//
Function ObjectExportMode(Val ObjectName, Val Recipient) Export
	
	Result = DataExchangeCached.UserExchangePlanComposition(Recipient).Get(ObjectName);
	
	Return ?(Result = Undefined, Enums.ExchangeObjectExportModes.ExportAlways, Result);
EndFunction

Function ObjectExportMaxMode(Val ExportMode1, Val ExportMode2, Val Priorities)
	
	If Priorities.Find(ExportMode1) < Priorities.Find(ExportMode2) Then
		
		Return ExportMode1;
		
	Else
		
		Return ExportMode2;
		
	EndIf;
	
EndFunction

Function ObjectsExportModesPriorities()
	
	Result = New Array;
	Result.Add(Enums.ExchangeObjectExportModes.ExportAlways);
	Result.Add(Enums.ExchangeObjectExportModes.ManualExport);
	Result.Add(Enums.ExchangeObjectExportModes.ExportByCondition);
	Result.Add(Enums.ExchangeObjectExportModes.EmptyRef());
	Result.Add(Enums.ExchangeObjectExportModes.ExportIfNecessary);
	Result.Add(Enums.ExchangeObjectExportModes.NotExport);
	Result.Add(Undefined);
	
	Return Result;
EndFunction

// Gets a predefined exchange plan node.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  ЭтотУзел - ExchangePlanRef - a predefined exchange plan node.
//
Function GetThisExchangePlanNode(ExchangePlanName) Export
	
	Return ExchangePlans[ExchangePlanName].ThisNode();
	
EndFunction

// Returns the flag showing whether the node belongs to DIB exchange plan.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//
//  Returns:
//    Boolean - If True, the node belongs to the exchange plan of the distributed infobase. Otherwise, False.
//
Function IsDistributedInfobaseNode(Val InfobaseNode) Export

	Return InfobaseNode.Metadata().DistributedInfoBase;
	
EndFunction

// Returns the flag showing that the node belongs to a standard exchange plan (without conversion rules).
//
// Parameters:
//  ExchangePlanName - String - a name of the exchange plan which requires the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the standard exchange plan. Otherwise, False.
//
Function IsStandardDataExchangeNode(ExchangePlanName) Export
	
	If DataExchangeServer.IsXDTOExchangePlan(ExchangePlanName) Then
		Return False;
	EndIf;
	
	Return Not DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		And Not DataExchangeCached.HasExchangePlanTemplate(ExchangePlanName, "ExchangeRules");
	
EndFunction

// Returns the flag showing whether the node belongs to a universal exchange plan (using conversion rules).
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the universal exchange plan. Otherwise, False.
//
Function IsUniversalDataExchangeNode(InfobaseNode) Export
	
	If DataExchangeServer.IsXDTOExchangePlan(InfobaseNode) Then
		Return True;
	Else
		Return Not IsDistributedInfobaseNode(InfobaseNode)
			And HasExchangePlanTemplate(GetExchangePlanName(InfobaseNode), "ExchangeRules");
	EndIf;
	
EndFunction

// Returns the flag showing whether the node belongs to an exchange plan that uses SSL exchange functionality.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef
//                         - ExchangePlanObject - an exchange plan node that requires receiving
//                           the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the exchange plan that uses the SSL functionality. Otherwise, False.
//
Function IsSSLDataExchangeNode(Val InfobaseNode) Export
	
	Return SSLExchangePlans().Find(GetExchangePlanName(InfobaseNode)) <> Undefined;
	
EndFunction

// Returns the flag showing whether the node belongs to a separated exchange plan that uses SSL exchange functionality.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the separated exchange plan that uses the SSL functionality. Otherwise, False.
//
Function IsSeparatedSSLDataExchangeNode(InfobaseNode) Export
	
	Return SeparatedSSLExchangePlans().Find(GetExchangePlanName(InfobaseNode)) <> Undefined;
	
EndFunction

// Returns the flag showing whether the node belongs to the exchange plan used for message exchange.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//
//  Returns:
//    Boolean - True if the node belongs to the message exchange plan. Otherwise, False.
//
Function IsMessagesExchangeNode(InfobaseNode) Export
	
	If Not Common.SubsystemExists("CloudTechnology.MessagesExchange") Then
		Return False;
	EndIf;
	
	Return DataExchangeCached.GetExchangePlanName(InfobaseNode) = "MessagesExchange";
	
EndFunction

// Gets a list of templates of standard exchange rules from configuration for the specified exchange plan;
// The list contains names and synonyms of the rule templates.
// 
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  СписокПравил - ValueList - a list of templates of standard exchange rules.
//
Function ConversionRulesForExchangePlanFromConfiguration(ExchangePlanName) Export
	
	Return RulesForExchangePlanFromConfiguration(ExchangePlanName, "ExchangeRules");
	
EndFunction

// Gets a list of templates of standard registration rules from configuration for the specified exchange plan;
// The list contains names and synonyms of the rule templates.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  СписокПравил - ValueList - a list of templates of standard registration rules.
//
Function RegistrationRulesForExchangePlanFromConfiguration(ExchangePlanName) Export
	
	Return RulesForExchangePlanFromConfiguration(ExchangePlanName, "RecordRules");
	
EndFunction

// Gets a list of configuration exchange plans that use the SSL functionality.
// The list is filled with names and synonyms of exchange plans.
//
// Parameters:
//  No.
// 
// Returns:
//  СписокПлановОбмена - ValueList - a list of configuration exchange plans.
//
Function SSLExchangePlansList() Export
	
	// Function return value.
	ExchangePlansList = New ValueList;
	
	SubsystemExchangePlans = New Array;
	
	DataExchangeOverridable.GetExchangePlans(SubsystemExchangePlans);
	
	For Each ExchangePlan In SubsystemExchangePlans Do
		
		ExchangePlansList.Add(ExchangePlan.Name, ExchangePlan.Synonym);
		
	EndDo;
	
	Return ExchangePlansList;
	
EndFunction

// For internal use.
//
Function CommonNodeData(Val InfobaseNode) Export
	
	Return DataExchangeServer.CommonNodeData(GetExchangePlanName(InfobaseNode),
		InformationRegisters.CommonInfobasesNodesSettings.CorrespondentVersion(InfobaseNode),
		"");
EndFunction

// For internal use.
//
Function ExchangePlanTabularSections(Val ExchangePlanName, Val CorrespondentVersion = "", Val SettingID = "") Export
	
	CommonTables             = New Array;
	ThisInfobaseTables          = New Array;
	AllTablesOfThisInfobase       = New Array;
	
	CommonNodeData = DataExchangeServer.CommonNodeData(ExchangePlanName, CorrespondentVersion, SettingID);
	
	TabularSections = DataExchangeEvents.ObjectTabularSections(Metadata.ExchangePlans[ExchangePlanName]);
	
	If Not IsBlankString(CommonNodeData) Then
		
		For Each TabularSection In TabularSections Do
			
			If StrFind(CommonNodeData, TabularSection) <> 0 Then
				
				CommonTables.Add(TabularSection);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	ThisInfobaseSettings = DataExchangeServer.NodeFiltersSetting(ExchangePlanName, CorrespondentVersion, SettingID);
	
	ThisInfobaseSettings = DataExchangeEvents.StructureKeysToString(ThisInfobaseSettings);
	
	If IsBlankString(CommonNodeData) Then
		
		For Each TabularSection In TabularSections Do
			
			AllTablesOfThisInfobase.Add(TabularSection);
			
			If StrFind(ThisInfobaseSettings, TabularSection) <> 0 Then
				
				ThisInfobaseTables.Add(TabularSection);
				
			EndIf;
			
		EndDo;
		
	Else
		
		For Each TabularSection In TabularSections Do
			
			AllTablesOfThisInfobase.Add(TabularSection);
			
			If StrFind(ThisInfobaseSettings, TabularSection) <> 0 Then
				
				If StrFind(CommonNodeData, TabularSection) = 0 Then
					
					ThisInfobaseTables.Add(TabularSection);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("CommonTables",             CommonTables);
	Result.Insert("ThisInfobaseTables",          ThisInfobaseTables);
	Result.Insert("AllTablesOfThisInfobase",       AllTablesOfThisInfobase);
	
	Return Result;
	
EndFunction

// Gets the exchange plan manager by exchange plan name.
//
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
//
// Returns:
//  ExchangePlanManager - an exchange plan manager.
//
Function GetExchangePlanManagerByName(ExchangePlanName) Export
	
	Return ExchangePlans[ExchangePlanName];
	
EndFunction

// Wrapper of the function with the same name.
//
Function ConfigurationMetadata(Filter) Export
	
	For Each FilterElement In Filter Do
		
		Filter[FilterElement.Key] = StrSplit(FilterElement.Value, ",");
		
	EndDo;
	
	Return DataExchangeServer.ConfigurationMetadataTree(Filter);
	
EndFunction

// For internal use.
//
Function ExchangeSettingsStructureForInteractiveImportSession(InfobaseNode, ExchangeMessageFileName) Export
	
	ExchangeSettingsStructure = DataExchangeServer.ExchangeSettingsForInfobaseNode(
		InfobaseNode,
		Enums.ActionsOnExchange.DataImport,
		Undefined,
		False);
		
	ExchangeSettingsStructure.DataExchangeDataProcessor.ExchangeFileName = ExchangeMessageFileName;
	
	Return ExchangeSettingsStructure;
	
EndFunction

// Wrapper of the function with the same name from the DataExchangeEvents module.
//
Function NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, FlagAttributeName, Val Upload0 = False) Export
	
	SetPrivilegedMode(True);
	
	Return DataExchangeEvents.NodesArrayByPropertiesValues(PropertiesValues, QueryText, ExchangePlanName, FlagAttributeName, Upload0);
	
EndFunction

// Returns a collection of exchange message transports that can be used for the specified exchange plan node.
//
// Parameters:
//  InfobaseNode - ExchangePlanRef - an exchange plan node that requires receiving the function value.
//  SettingsMode       - String           - ID of data synchronization setup option.
// 
//  Returns:
//   Array - message transports that are used for the specified exchange plan node.
//
Function UsedExchangeMessagesTransports(InfobaseNode, Val SettingsMode = "") Export
	
	ExchangePlanName = DataExchangeCached.GetExchangePlanName(InfobaseNode);
	
	If Not InfobaseNode.IsEmpty() Then
		SettingsMode = DataExchangeServer.SavedExchangePlanNodeSettingOption(InfobaseNode);
	EndIf;
	
	SettingOptionDetails = DataExchangeCached.SettingOptionDetails(ExchangePlanName,  
		SettingsMode, "", "");
	
	Result = SettingOptionDetails.UsedExchangeMessagesTransports;
	
	If Result.Count() = 0 Then
		Result = DataExchangeServer.AllConfigurationExchangeMessagesTransports();
	EndIf;
	
	// Data exchange over COM connections is not supported by:
	//  - Configurations with the basic license
	//  - Distributed infobases
	//  - Exchange without conversion rules
	//  - 1C:Enterprise servers that run on Linux
	//
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
		Or DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		Or DataExchangeCached.IsStandardDataExchangeNode(ExchangePlanName)
		Or Common.IsLinuxServer() Then
		
		CommonClientServer.DeleteValueFromArray(Result,
			Enums.ExchangeMessagesTransportTypes.COM);
			
	EndIf;
	
	// Data exchange over WS connections is not supported by:
	//  - Distributed infobases that are not a standalone workstation
	//
	If DataExchangeCached.IsDistributedInfobaseExchangePlan(ExchangePlanName)
		And Not DataExchangeCached.IsStandaloneWorkstationNode(InfobaseNode) Then
		
		CommonClientServer.DeleteValueFromArray(Result,
			Enums.ExchangeMessagesTransportTypes.WS);
		
	EndIf;
	
	// Data exchange over passive WS connections is not supported by:
	//  - Non-XDTO data exchange
	//  - File infobases
	//
	If Not DataExchangeCached.IsXDTOExchangePlan(ExchangePlanName)
		Or Common.FileInfobase() Then
		
		CommonClientServer.DeleteValueFromArray(Result,
			Enums.ExchangeMessagesTransportTypes.WSPassiveMode);
		
	EndIf;
	
	// Data exchange over email is not supported when:
	//  - "Email management" subsystem is unavailable
	//  - The configuration cannot receive email messages
	If Common.SubsystemExists("StandardSubsystems.EmailOperations") Then
		ModuleEmailOperationsInternal = Common.CommonModule("EmailOperationsInternal");
		If Not ModuleEmailOperationsInternal.CanReceiveEmails() Then
			CommonClientServer.DeleteValueFromArray(Result,
				Enums.ExchangeMessagesTransportTypes.EMAIL);
		EndIf;
	Else
		CommonClientServer.DeleteValueFromArray(Result,
			Enums.ExchangeMessagesTransportTypes.EMAIL);
	EndIf;
	
	Return Result;
	
EndFunction

// Establishes an external connection to the infobase and returns a reference to this connection.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - Exchange plan node for which
//  the external connection is required.
//  ErrorMessageString - String - if establishing connection fails,
//   this parameter will store the error details.
//
// Returns:
//  COM-object - If the connection is established. Undefined - If an error occurred.
//
Function GetExternalConnectionForInfobaseNode(InfobaseNode, ErrorMessageString = "") Export

	Result = ExternalConnectionForInfobaseNode(InfobaseNode);

	ErrorMessageString = Result.DetailedErrorDetails;
	Return Result.Join;
	
EndFunction

// Establishes an external connection to the infobase and returns a reference to this connection.
// 
// Parameters:
//  InfobaseNode - ExchangePlanRef - exchange plan node for which
//  the external connection is required.
//  ErrorMessageString (optional) - String - if establishing connection fails,
//   this parameter will store the error details.
//
// Returns:
//  COM-object - If the connection is established. Undefined - If an error occurred.
//
Function ExternalConnectionForInfobaseNode(InfobaseNode) Export
	
	Return DataExchangeServer.EstablishExternalConnectionWithInfobase(
        InformationRegisters.DataExchangeTransportSettings.TransportSettings(
            InfobaseNode, Enums.ExchangeMessagesTransportTypes.COM));
	
EndFunction

// Determines whether the exchange plan can be used.
// The flag is calculated by the configuration functional options composition.
// If no functional option includes the exchange plan, the function returns True.
// If functional options include the exchange plan and one or more functional option
// is enabled, the function returns True.
// Otherwise, the function returns False.
//
// Parameters:
//  ExchangePlanName - String - name of the exchange plan to get the flag for.
//
// Returns:
//   Boolean - True if the exchange plan can be used.
//  False - it cannot be used.
//
Function ExchangePlanUsageAvailable(Val ExchangePlanName) Export
	
	ObjectBelongsToFunctionalOptions = False;
	
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		
		If FunctionalOption.Content.Contains(Metadata.ExchangePlans[ExchangePlanName]) Then
			
			ObjectBelongsToFunctionalOptions = True;
			
			If GetFunctionalOption(FunctionalOption.Name) = True Then
				
				Return True;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If Not ObjectBelongsToFunctionalOptions Then
		
		Return True;
		
	EndIf;
	
	Return False;
EndFunction

// Returns an array of version numbers supported by correspondent API for the DataExchange subsystem.
// 
// Parameters:
//   Peer - Structure
//                 - ExchangePlanRef - Exchange plan node that corresponds
//                 the correspondent infobase.
//
// Returns:
//   Array of version numbers that are supported by correspondent API.
//
Function CorrespondentVersions(Val Peer) Export
	
	If TypeOf(Peer) = Type("Structure") Then
		SettingsStructure_ = Peer;
	Else
		If DataExchangeCached.IsMessagesExchangeNode(Peer) Then
			ModuleMessagesExchangeTransportSettings = Common.CommonModule("InformationRegisters.MessageExchangeTransportSettings");
			SettingsStructure_ = ModuleMessagesExchangeTransportSettings.TransportSettingsWS(Peer);
		Else
			SettingsStructure_ = InformationRegisters.DataExchangeTransportSettings.TransportSettingsWS(Peer);
		EndIf;
	EndIf;
	
	ConnectionParameters = New Structure;
	ConnectionParameters.Insert("URL",      SettingsStructure_.WSWebServiceURL);
	ConnectionParameters.Insert("UserName", SettingsStructure_.WSUserName);
	ConnectionParameters.Insert("Password", SettingsStructure_.WSPassword);
	
	Return Common.GetInterfaceVersions(ConnectionParameters, "DataExchange");
	
EndFunction

// Returns an array of all reference types available in the configuration.
//
Function AllConfigurationReferenceTypes() Export
	
	Result = New Array;
	
	CommonClientServer.SupplementArray(Result, Catalogs.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Documents.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, BusinessProcesses.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfCharacteristicTypes.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfAccounts.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ChartsOfCalculationTypes.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Tasks.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, ExchangePlans.AllRefsType().Types());
	CommonClientServer.SupplementArray(Result, Enums.AllRefsType().Types());
	
	Return Result;
EndFunction

Function StandaloneModeExchangePlans()
	
	// For SaaS standalone infobases, the exchange plan should be:
	// - Separated
	// - Set up for a distributed infobase
	// - Set up for SaaS mode ("ExchangePlanUsedInSaaS" is set to "True")
	
	Result = New Array;
	
	For Each ExchangePlan In Metadata.ExchangePlans Do
		
		If DataExchangeServer.IsSeparatedSSLExchangePlan(ExchangePlan.Name)
			And ExchangePlan.DistributedInfoBase
			And DataExchangeCached.ExchangePlanUsedInSaaS(ExchangePlan.Name) Then
			
			Result.Add(ExchangePlan.Name);
			
		EndIf;
		
	EndDo;
	
	Return Result;
EndFunction

Function SecurityProfileName(Val ExchangePlanName) Export
	
	If Not Common.SubsystemExists("StandardSubsystems.SecurityProfiles") Then
		Return Undefined;
	EndIf;
	
	If Catalogs.MetadataObjectIDs.IsDataUpdated() Then
		ExchangePlanID = Common.MetadataObjectID(Metadata.ExchangePlans[ExchangePlanName]);
		ModuleSafeModeManagerInternal = Common.CommonModule("SafeModeManagerInternal");
		SecurityProfileName = ModuleSafeModeManagerInternal.ExternalModuleAttachmentMode(ExchangePlanID);
	Else
		SecurityProfileName = Undefined;
	EndIf;
	
	If SecurityProfileName = Undefined Then
		ModuleSafeModeManager = Common.CommonModule("SafeModeManager");
		SecurityProfileName = ModuleSafeModeManager.InfobaseSecurityProfile();
		If IsBlankString(SecurityProfileName) Then
			SecurityProfileName = Undefined;
		EndIf;
	EndIf;
	
	Return SecurityProfileName;
	
EndFunction

Function RegistrationWhileLooping(InfobaseNode) Export
	
	Return InformationRegisters.CommonInfobasesNodesSettings.RegistrationWhileLooping(InfobaseNode);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Initialization of the data exchange settings structure.

// Gets the transport settings structure for data exchange.
//
Function TransportSettingsOfExchangePlanNode(InfobaseNode, ExchangeMessagesTransportKind) Export
	
	Return DataExchangeServer.ExchangeTransportSettings(InfobaseNode, ExchangeMessagesTransportKind);
	
EndFunction

// Gets a list of templates of standard rules for data exchange from configuration for the specified exchange plan;
// The list contains names and synonyms of the rule templates.
// 
// Parameters:
//  ExchangePlanName - String - an exchange plan name, as it is set in Designer.
// 
// Returns:
//  СписокПравил - ValueList - a list of templates of standard rules for data exchange.
//
Function RulesForExchangePlanFromConfiguration(ExchangePlanName, TemplateNameLiteral)
	
	RulesList = New ValueList;
	
	If IsBlankString(ExchangePlanName) Then
		Return RulesList;
	EndIf;
	
	For Each Template In Metadata.ExchangePlans[ExchangePlanName].Templates Do
		
		If StrFind(Template.Name, TemplateNameLiteral) <> 0 And StrFind(Template.Name, "Correspondent") = 0 Then
			
			RulesList.Add(Template.Name, Template.Synonym);
			
		EndIf;
		
	EndDo;
	
	Return RulesList;
EndFunction

// Returns a node content table (reference types only).
//
// Parameters:
//    ExchangePlanName - String - an exchange plan to analyze.
//    Periodic2  - Flag indicating that the result must include objects with dates (such as documents).
//    Regulatory     - флаг того, что надо включать в результат нормативно-reference objects.
//
// Returns:
//    ValueTable:
//      * FullMetadataName - String - a full metadata name (a table name for the query).
//      * ListPresentation - String - list presentation for a table.
//      * Presentation       - String - object presentation for a table.
//      * PictureIndex      - Number - a picture index according to PictureLib.MetadataObjectsCollection.
//      * Type                 - Type - the corresponding type.
//      * PeriodSelection        - Boolean - a flag showing that filter by period can be applied to the object.
//
Function ExchangePlanContent(ExchangePlanName, Periodic2 = True, Regulatory = True) Export
	
	ResultTable2 = New ValueTable;
	For Each KeyValue In (New Structure("FullMetadataName, Presentation, ListPresentation, PictureIndex, Type, PeriodSelection")) Do
		ResultTable2.Columns.Add(KeyValue.Key);
	EndDo;
	For Each KeyValue In (New Structure("FullMetadataName, Presentation, ListPresentation, Type")) Do
		ResultTable2.Indexes.Add(KeyValue.Key);
	EndDo;
	
	ExchangePlanContent = Metadata.ExchangePlans.Find(ExchangePlanName).Content;
	For Each CompositionItem In ExchangePlanContent Do
		
		ObjectMetadata = CompositionItem.Metadata;
		LongDesc = MetadataObjectDetails(ObjectMetadata);
		If LongDesc.PictureIndex >= 0 Then
			If Not Periodic2 And LongDesc.Periodic3 Then 
				Continue;
			ElsIf Not Regulatory And LongDesc.Reference Then 
				Continue;
			EndIf;
			
			String = ResultTable2.Add();
			FillPropertyValues(String, LongDesc);
			String.PeriodSelection        = LongDesc.Periodic3;
			String.FullMetadataName = ObjectMetadata.FullName();
			String.ListPresentation = DataExchangeServer.ObjectsListPresentation(ObjectMetadata);
			String.Presentation       = DataExchangeServer.ObjectPresentation(ObjectMetadata);
		EndIf;
	EndDo;
	
	ResultTable2.Sort("ListPresentation");
	Return ResultTable2;
	
EndFunction

// Returns the metadata object details.
// 
// Parameters:
//   Meta - MetadataObject - Metadata object.
//
// Returns:
//   Structure:
//     * PictureIndex - Number - picture index.
//     * Periodic3 - Boolean - True if the object is periodic.
//     * Reference - Boolean - True if the object is regulatory.
//     * Type - Type - a reference value type.
//
Function MetadataObjectDetails(Meta)
	
	Result = New Structure("PictureIndex, Periodic3, Reference, Type", -1, False, False);
	
	If Metadata.Catalogs.Contains(Meta) Then
		Result.PictureIndex = 3;
		Result.Reference = True;
		Result.Type = Type("CatalogRef." + Meta.Name);
		
	ElsIf Metadata.Documents.Contains(Meta) Then
		Result.PictureIndex = 7;
		Result.Periodic3 = True;
		Result.Type = Type("DocumentRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfCharacteristicTypes.Contains(Meta) Then
		Result.PictureIndex = 9;
		Result.Reference = True;
		Result.Type = Type("ChartOfCharacteristicTypesRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfAccounts.Contains(Meta) Then
		Result.PictureIndex = 11;
		Result.Reference = True;
		Result.Type = Type("ChartOfAccountsRef." + Meta.Name);
		
	ElsIf Metadata.ChartsOfCalculationTypes.Contains(Meta) Then
		Result.PictureIndex = 13;
		Result.Reference = True;
		Result.Type = Type("ChartOfCalculationTypesRef." + Meta.Name);
		
	ElsIf Metadata.BusinessProcesses.Contains(Meta) Then
		Result.PictureIndex = 23;
		Result.Periodic3 = True;
		Result.Type = Type("BusinessProcessRef." + Meta.Name);
		
	ElsIf Metadata.Tasks.Contains(Meta) Then
		Result.PictureIndex = 25;
		Result.Periodic3  = True;
		Result.Type = Type("TaskRef." + Meta.Name);
		
	EndIf;
	
	Return Result;
EndFunction

// Returns the name of the temporary file directory.
//
// Returns:
//  String - a path to the temporary file directory.
//
Function TempFilesStorageDirectory(SafeMode = Undefined) Export
	
	If Common.FileInfobase() And Not Common.DebugMode() Then
		
		Return TrimAll(TempFilesDir());
		
	EndIf;
	
	SetPrivilegedMode(True);
	
	CommonPlatformType = "";
	If Common.IsLinuxServer() Then
	
		Result         = Constants.DataExchangeMessageDirectoryForLinux.Get();
		CommonPlatformType = "Linux";
		
	Else
		
		Result         = Constants.DataExchangeMessageDirectoryForWindows.Get();
		CommonPlatformType = "Windows";
		
	EndIf;
	
	SetPrivilegedMode(False);
	
	If IsBlankString(Result) Then
		
		Result = TrimAll(TempFilesDir());
		
	Else
		
		Result = TrimAll(Result);
		
		// Check whether the directory exists.
		Directory = New File(Result);
		If Not Directory.Exists() Then
			
			ConstantPresentation = ?(CommonPlatformType = "Linux", 
				Metadata.Constants.DataExchangeMessageDirectoryForLinux.Presentation(),
				Metadata.Constants.DataExchangeMessageDirectoryForWindows.Presentation());
			
			MessageTemplate = NStr("ru = 'Каталог временных файлов не существует.
					|Необходимо убедиться, что в настройках программы задано правильное значение параметра
					|""%1"".';
					|en = 'Temporary file directory does not exist.
					|Ensure that the value is valid for the parameter:
					|""%1"".';", Common.DefaultLanguageCode());
			
			MessageText = StrTemplate(MessageTemplate, ConstantPresentation);
			Raise(MessageText);
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Initializes columns of object registration rule table by properties.
//
//  Returns:
//    ValueTree
//
Function FilterByExchangePlanPropertiesTableInitialization() Export

	DataProcessor = DataProcessors.ObjectsRegistrationRulesImport;
	Return DataProcessor.FilterByExchangePlanPropertiesTableInitialization();
	
EndFunction

// Initializes columns of object registration rule table by properties.
//
//  Returns:
//    ValueTree
//
Function FilterByObjectPropertiesTableInitialization() Export

	DataProcessor = DataProcessors.ObjectsRegistrationRulesImport;
	Return DataProcessor.FilterByObjectPropertiesTableInitialization();
	
EndFunction

Function IsRegister(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsRegister(MetadataObject);
	
EndFunction

Function IsDocument(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsDocument(MetadataObject);
	
EndFunction

Function IsCatalog(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsCatalog(MetadataObject);
	
EndFunction

Function IsEnum(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsEnum(MetadataObject);
	
EndFunction

Function IsChartOfCharacteristicTypes(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsChartOfCharacteristicTypes(MetadataObject);
	
EndFunction

Function IsBusinessProcess(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsBusinessProcess(MetadataObject);
	
EndFunction

Function IsTask(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsTask(MetadataObject);
	
EndFunction

Function IsChartOfAccounts(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsChartOfAccounts(MetadataObject);
	
EndFunction

Function IsChartOfCalculationTypes(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsChartOfCalculationTypes(MetadataObject);
	
EndFunction

Function IsConstant(FullObjectName) Export
	
	MetadataObject = Common.MetadataObjectByFullName(FullObjectName);
	Return Common.IsConstant(MetadataObject);
	
EndFunction

#EndRegion