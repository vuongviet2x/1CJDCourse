///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	MetadataObject = Common.MetadataObjectByFullName(Parameters.FullObjectName);
	
	If Common.IsConstant(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'константе';
										|en = 'constant';");
	ElsIf Common.IsCatalog(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'справочнику';
										|en = 'catalog';");
	ElsIf Common.IsDocument(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'документу';
										|en = 'document';");
	ElsIf ODataInterfaceInternal.IsSequenceRecordSet(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'последовательности';
										|en = 'sequence';");
	ElsIf Common.IsDocumentJournal(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'журналу документов';
										|en = 'document journal';");
	ElsIf Common.IsEnum(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'перечислению';
										|en = 'enumeration';");
	ElsIf Common.IsChartOfCharacteristicTypes(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'плану видов характеристик';
										|en = 'chart of characteristic types';");
	ElsIf Common.IsChartOfAccounts(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'плану счетов';
										|en = 'chart of accounts';");
	ElsIf Common.IsChartOfCalculationTypes(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'плану видов расчета';
										|en = 'chart of calculation types';");
	ElsIf Common.IsInformationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'регистру сведений';
										|en = 'information register';");
	ElsIf Common.IsAccumulationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'регистру накопления';
										|en = 'accumulation register';");
	ElsIf Common.IsAccountingRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'регистру бухгалтерии';
										|en = 'accounting register';");
	ElsIf Common.IsCalculationRegister(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'регистру расчета';
										|en = 'calculation register';");
	ElsIf ODataInterfaceInternal.IsRecalculationRecordSet(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'перерасчету';
										|en = 'recalculation';");
	ElsIf Common.IsBusinessProcess(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'бизнес-процессу';
										|en = 'business process';");
	ElsIf Common.IsTask(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'задаче';
										|en = 'task';");
	ElsIf Common.IsExchangePlan(MetadataObject) Then
		ObjectTypePresentation = NStr("ru = 'плану обмена';
										|en = 'exchange plan';");
	EndIf;
	
	If Parameters.Create Then
		
		Items.GroupPageHeader.CurrentPage = Items.PageHeaderAddGroup;
		Items.PagesFooterGroup.CurrentPage = Items.PageFooterAddGroup;
		Items.TitleHeaderAddDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.TitleHeaderAddDecoration.Title,
			ObjectTypePresentation,
			MetadataObject.Presentation());
		
	Else
		
		Items.GroupPageHeader.CurrentPage = Items.PageHeaderDeletionGroup;
		Items.PagesFooterGroup.CurrentPage = Items.PageFooterDeleteGroup;
		Items.TitleHeaderDeletionDecoration.Title = StringFunctionsClientServer.SubstituteParametersToString(
			Items.TitleHeaderDeletionDecoration.Title,
			ObjectTypePresentation,
			MetadataObject.Presentation());
		
	EndIf;
	
	Title = StringFunctionsClientServer.SubstituteParametersToString(
		Title, MetadataObject.Presentation());
	
	// Populate tree.
	
	Tree = New ValueTree();
	
	Tree.Columns.Add("FullName", New TypeDescription("String"));
	Tree.Columns.Add("Presentation", New TypeDescription("String"));
	Tree.Columns.Add("Class", New TypeDescription("Number", , New NumberQualifiers(10, 0, AllowedSign.Nonnegative)));
	Tree.Columns.Add("Picture", New TypeDescription("Picture"));
	
	AddTreeRootRow(Tree, "Constant", NStr("ru = 'Константы';
															|en = 'Constants';"), 1, PictureLib.Constant);
	AddTreeRootRow(Tree, "Catalog", NStr("ru = 'Справочники';
															|en = 'Catalogs';"), 2, PictureLib.Catalog);
	AddTreeRootRow(Tree, "Document", NStr("ru = 'Документы';
															|en = 'Documents';"), 3, PictureLib.Document);
	AddTreeRootRow(Tree, "DocumentJournal", NStr("ru = 'Журналы документов';
																	|en = 'Document journals';"), 4, PictureLib.DocumentJournal);
	AddTreeRootRow(Tree, "Enum", NStr("ru = 'Перечисление';
																|en = 'Enumeration';"), 5, PictureLib.Enum);
	AddTreeRootRow(Tree, "ChartOfCharacteristicTypes", NStr("ru = 'Планы видов характеристик';
																		|en = 'Charts of characteristic types';"), 6, PictureLib.ChartOfCharacteristicTypes);
	AddTreeRootRow(Tree, "ChartOfAccounts", NStr("ru = 'Планы счетов';
															|en = 'Charts of accounts';"), 7, PictureLib.ChartOfAccounts);
	AddTreeRootRow(Tree, "ChartOfCalculationTypes", NStr("ru = 'Планы видов расчета';
																	|en = 'Charts of calculation types';"), 8, PictureLib.ChartOfCalculationTypes);
	AddTreeRootRow(Tree, "InformationRegister", NStr("ru = 'Регистры сведений';
																|en = 'Information registers';"), 9, PictureLib.InformationRegister);
	AddTreeRootRow(Tree, "AccumulationRegister", NStr("ru = 'Регистры накопления';
																	|en = 'Accumulation registers';"), 10, PictureLib.AccumulationRegister);
	AddTreeRootRow(Tree, "AccountingRegister", NStr("ru = 'Регистры бухгалтерии';
																	|en = 'Accounting registers';"), 11, PictureLib.AccountingRegister);
	AddTreeRootRow(Tree, "CalculationRegister", NStr("ru = 'Регистры расчета';
																|en = 'Calculation registers';"), 12, PictureLib.CalculationRegister);
	AddTreeRootRow(Tree, "BusinessProcess", NStr("ru = 'Бизнес-процессы';
																|en = 'Business processes';"), 13, PictureLib.BusinessProcess);
	AddTreeRootRow(Tree, "Task", NStr("ru = 'Задачи';
														|en = 'Tasks';"), 14, PictureLib.Task);
	AddTreeRootRow(Tree, "ExchangePlan", NStr("ru = 'Планы обмена';
															|en = 'Exchange plans';"), 15, PictureLib.ExchangePlan);
	
	For Each Dependence In Parameters.ObjectDependencies Do
		AddNestedTreeRow(Tree, Common.MetadataObjectByFullName(Dependence));
	EndDo;
	
	Tree.Columns.Delete(Tree.Columns["FullName"]);
	Tree.Columns.Delete(Tree.Columns["Class"]);
	
	LinesToDelete = New Array();
	For Each TreeRow In Tree.Rows Do
		If TreeRow.Rows.Count() = 0 Then
			LinesToDelete.Add(TreeRow);
		Else
			TreeRow.Rows.Sort("Presentation");
		EndIf;
	EndDo;
	For Each RowToDelete In LinesToDelete Do
		Tree.Rows.Delete(RowToDelete);
	EndDo;
	
	ValueToFormAttribute(Tree, "MetadataObjects");
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure AddTreeRootRow(Tree,Val FullName, Val Presentation, Val Class, Val Picture)
	
	NewRow = Tree.Rows.Add();
	NewRow.FullName = FullName;
	NewRow.Presentation = Presentation;
	NewRow.Class = Class;
	NewRow.Picture = Picture;
	
EndProcedure

&AtServer
Procedure AddNestedTreeRow(Tree, Val MetadataObject)
	
	FullName = MetadataObject.FullName();
	
	NameStructure = StrSplit(FullName, ".");
	ObjectClass = NameStructure[0];
	
	RowOwner = Undefined;
	For Each TreeRow In Tree.Rows Do
		If TreeRow.FullName = ObjectClass Then
			RowOwner = TreeRow;
			Break;
		EndIf;
	EndDo;
	
	If RowOwner = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Неизвестный объект метаданных: %1';
				|en = 'Unknown metadata object: %1';"), FullName);
	EndIf;
	
	NewRow = RowOwner.Rows.Add();
	
	NewRow.Presentation = MetadataObject.Presentation();
	NewRow.Class = RowOwner.Class;
	NewRow.Picture = RowOwner.Picture;
	
EndProcedure

#EndRegion