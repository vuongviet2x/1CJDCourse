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

#Region ForCallsFromOtherSubsystems

// StandardSubsystems.Core

// See ConfigurationSubsystemsOverridable.OnAddSubsystems.
Procedure OnAddSubsystems(SubsystemsModules) Export
	
	SubsystemsModules.Add("_DemoInfobaseUpdateSSL");
	
EndProcedure

// End StandardSubsystems.Core

// StandardSubsystems.IBVersionUpdate

////////////////////////////////////////////////////////////////////////////////
// Info about the library or configuration.

// See InfobaseUpdateSSL.OnAddSubsystem.
Procedure OnAddSubsystem(LongDesc) Export
	
	LongDesc.Name = "StandardSubsystemsLibrary_Demo";
	LongDesc.Version = "3.1.10.386";
	LongDesc.OnlineSupportID = "SSL";
	LongDesc.DeferredHandlersExecutionMode = "Parallel";
	LongDesc.ParallelDeferredUpdateFromVersion = "2.3.3.20";
	LongDesc.FillDataNewSubsystemsWhenSwitchingFromAnotherProgram = True;
	
	// 1C:Standard Subsystems Library is required.
	LongDesc.RequiredSubsystems1.Add("StandardSubsystems");
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update handlers.

// See InfobaseUpdateOverridable.OnDefineSettings.
Procedure OnDefineSettings(Parameters) Export
	
	Parameters.UncompletedDeferredHandlersMessageParameters.MessagePicture = PictureLib.DialogStop;
	Parameters.Insert("MultiThreadUpdate", True);
	Parameters.Insert("DefaultInfobaseUpdateThreadsCount", 4);
	
	Parameters.ObjectsWithInitialFilling.Add(Metadata.ChartsOfCharacteristicTypes._DemoExtDimensionTypes);
	Parameters.ObjectsWithInitialFilling.Add(Metadata.ChartsOfAccounts._DemoMain);
	Parameters.ObjectsWithInitialFilling.Add(Metadata.Catalogs._DemoProductsKinds);
	Parameters.ObjectsWithInitialFilling.Add(Metadata.ChartsOfCalculationTypes._DemoBaseEarnings);
	
EndProcedure

// See InfobaseUpdateSSL.OnAddUpdateHandlers.
Procedure OnAddUpdateHandlers(Handlers) Export
	
	// Handlers that run during infobase updates.
	//
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.SharedData = True;
	Handler.HandlerManagement = True;
	Handler.ExclusiveMode = True; // To demonstrate conditional execution in the exclusive mode.
	Handler.Procedure = "_DemoInfobaseUpdateSSL.AlwaysExecuteOnVersionChange";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.SharedData = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.RealTimeHandler";
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "*";
	Handler.SharedData = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.RealTimeHandlerWithError";
	Handler.ExecutionMode = "Seamless";
	
	// Handlers that run during empty infobase population.
	//
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.FirstRun";
	
	Handler = Handlers.Add();
	Handler.InitialFilling = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.CreateContactInformationKinds";
	
	// Handlers that run during updates and empty infobase population.
	//
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.1.6";
	Handler.InitialFilling = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.ExecuteInitialCurrenciesFilling";
	
	Handler = Handlers.Add();
	Handler.Version = "2.1.3.16";
	Handler.InitialFilling = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdatePredefinedCompanyContactInformationKinds";
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.12";
	Handler.InitialFilling = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.FillInUseMultipleOrganizationsConstant";
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.1.34";
	Handler.InitialFilling = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdatePredefinedContactInformationKinds";
	Handler.ExecuteInMandatoryGroup = True;
	Handler.Priority = 99;
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.2.10";
	Handler.InitialFilling = True;
	Handler.SharedData = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdatePredefinedKeyOperations";
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.1.8";
	Handler.InitialFilling = True;
	Handler.Procedure = "_DemoInfobaseUpdateSSL.InitializeExecutorRoles";
	
	Handler = Handlers.Add();
	Handler.Version = "2.2.5.8";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdatePredefinedCounterpartyContactInformationKinds";
	Handler.ExecuteInMandatoryGroup = True;
	Handler.Priority = 99;
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version = "2.3.1.7";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdatePredefinedContactInformationKind";
	Handler.ExecuteInMandatoryGroup = True;
	Handler.Priority = 99;
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version    = "2.3.1.19";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdateContactInformationUsageForPartnerContacts";
	Handler.ExecutionMode = "Seamless";
	Handler.SharedData      = False;
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version    = "2.3.1.21";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdateExternalUserPropertySetsUsage";
	Handler.ExecutionMode = "Seamless";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version    = "2.3.1.44";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.AssignPerformerRoles";
	Handler.ExecutionMode = "Seamless";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version    = "2.3.2.4";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.SetUpContactInformationHistoryAndMultilineField";
	Handler.ExecutionMode = "Seamless";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.5.6";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdatePredefinedTypesOfContactInformationOfIndividuals";
	Handler.ExecuteInMandatoryGroup = True;
	Handler.Priority = 99;
	Handler.InitialFilling = True;
	
	// Real-time update handlers.
	//
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.82";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.FillContactInformationKindInternationalAddress";
	Handler.ExecutionMode = "Seamless";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.2.82";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.FillContactInformationKindPartnerWebsite";
	Handler.ExecutionMode = "Seamless";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.2.100";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.RemovePredefinedAttributeForContactInformationKinds";
	Handler.ExecuteInMandatoryGroup = True;
	Handler.InitialFilling = False;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.8.186";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.AddCounterpartyContactInformationKindMessengers";
	Handler.ExecuteInMandatoryGroup = True;
	Handler.ExecutionMode = "Seamless";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.9.107";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.AddCounterpartyContactInformationKindPhone";
	Handler.ExecuteInMandatoryGroup = True;
	Handler.ExecutionMode = "Seamless";

	Handler = Handlers.Add();
	Handler.Version = "3.1.10.17";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.AddCounterpartyContactInformationKindLegalAddress";
	Handler.ExecuteInMandatoryGroup = True;
	Handler.ExecutionMode = "Seamless";
	
	// Deferred update handlers.
	//
	
	Handler = Handlers.Add();
	Handler.Version = "*"; // For testing purposes.
	Handler.Id = New UUID("39e98a12-69b3-40a0-95e9-03469462f506");
	Handler.Procedure = "_DemoInfobaseUpdateSSL.DeferredHandlerWithError";
	Handler.Comment = NStr("ru = 'Демонстрационный обработчик отложенного обновления данных.
		|Для имитации нештатной ситуации нажать на кнопку ""Имитировать ошибку при отложенном обновлении"" в инструменте разработчика и выполнить перезапуск приложения.';
		|en = 'Demonstration handler for deferred data update.
		|To simulate an emergency situation, click ""Simulate deferred update error"" in the developer tool and restart the application.';");
	Handler.ExecutionMode = "Deferred";
	
	Handler = Handlers.Add();
	Handler.Version = Metadata.Version; // For testing purposes.
	Handler.Id = New UUID("b3be66c5-708d-42c8-a019-818036d09d06");
	Handler.Procedure = "Documents._DemoSalesOrder.ProcessDataForMigrationToNewVersion";
	Handler.Comment = NStr("ru = 'Заполнение значения нового реквизита ""Статус заказа"" у документов ""Демо: Заказ покупателя"" прошлых периодов.
		|До завершения обработки ""Статус заказа"" данных документов будет отображаться некорректно.';
		|en = 'New attribute “Order status” is being populated in the “Demo: Sales order” documents.
		|Until the population is complete, the attribute might be displayed incorrectly.';");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Documents._DemoSalesOrder.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Document._DemoSalesOrder";
	Handler.ObjectsToChange    = "Document._DemoSalesOrder";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock   = "Document._DemoSalesOrder, Report._DemoCustomerOrderStatuses";
	Handler.Multithreaded        = True;
	
	Handler = Handlers.Add();
	Handler.Version = "2.4.3.2";
	Handler.Id = New UUID("d58853ca-0549-4c60-8427-5c2a41832837");
	Handler.Procedure = "Catalogs.AdditionalAttributesAndInfoSets.ProcessDataForMigrationToNewVersion";
	Handler.Comment = NStr("ru = 'Обновление состава наборов свойств справочника Демо: Контрагенты.
		|Дополнительные реквизиты данного справочника будут недоступны до завершения обновления.';
		|en = 'Updating the record set composition of the Demo: Counterparties catalog.
		|Additional attributes of this register will be unavailable until the update ends.';");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.AdditionalAttributesAndInfoSets.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog.AdditionalAttributesAndInfoSets";
	Handler.ObjectsToChange    = "Catalog.AdditionalAttributesAndInfoSets";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock   = "Catalog._DemoCounterparties";
	
	Handler = Handlers.Add();
	Handler.Version = "3.0.1.22";
	Handler.Id = New UUID("a58854ca-0549-4c60-8427-5c2a41832837");
	Handler.Procedure = "Documents._DemoCustomerProformaInvoice.ProcessDataForMigrationToNewVersion";
	Handler.Comment = NStr("ru = 'Отражает в настройках печати переименование макета печатной формы в документе Демо: Счет на оплату покупателю.';
									|en = 'Reflects in the print settings the renaming of the print form template in the Demo: Sales proforma invoice document.';");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Documents._DemoCustomerProformaInvoice.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "InformationRegister.UserPrintTemplates";
	Handler.ObjectsToChange    = "InformationRegister.UserPrintTemplates";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	Priority = Handler.ExecutionPriorities.Add();
	Priority.Order = "After";
	Priority.Procedure = "InformationRegisters.UserPrintTemplates.ProcessUserTemplates";
	
	AccessManagement.AddUpdateHandlerToEnableUniversalRestriction("3.1.2.69", Handlers);
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.3";
	Handler.Id = New UUID("368609d8-0ecf-47fb-9751-a9f66fb21c29");
	Handler.Comment = NStr("ru = 'Заполняет ключи аналитики в документе Реализация товаров';
									|en = 'Fills in dimension keys in the Goods sales document';");
	Handler.ExecutionMode = "Deferred";
	Handler.Procedure = "Documents._DemoGoodsSales.ProcessDataForMigrationToNewVersion";
	Handler.UpdateDataFillingProcedure = "Documents._DemoGoodsSales.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Document._DemoGoodsSales";
	Handler.ObjectsToChange    = "Document._DemoGoodsSales";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.50";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.ActivateCorrectionOfObsoletePartnersAddresses";
	Handler.ExecutionMode = "Seamless";
	Handler.InitialFilling = True;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.140";
	Handler.Id = New UUID("3a8f247f-2090-4f8b-bbd1-9b4ab55c85c6");
	Handler.Procedure = "Catalogs._DemoPartnersContactPersons.ProcessDataForMigrationToNewVersion";
	Handler.Comment = NStr("ru = 'Конвертация контактной информации контактных лиц партнеров из устаревших форматов в современный формат JSON.';
									|en = 'Converting contact information of partner contacts from outdated formats to the modern JSON format.';");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs._DemoPartnersContactPersons.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog._DemoPartnersContactPersons";
	Handler.ObjectsToChange    = "Catalog._DemoPartnersContactPersons";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	
	If Not Common.DataSeparationEnabled() Then
		
		Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
		
		NewRow = Handler.ExecutionPriorities.Add();
		NewRow.Procedure = "Catalogs.ExternalUsers.ProcessDataForMigrationToNewVersion";
		NewRow.Order = "After";
	
	EndIf;
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.3.170";
	Handler.Id = New UUID("d57859ca-1543-4c60-8427-5c2a41832831");
	Handler.Procedure = "Catalogs.PerformerRoles.ProcessDataForMigrationToNewVersion";
	Handler.Comment = NStr("ru = 'Обновление предопределенных ролей исполнителей.
		|До завершения обработки наименования ролей в ряде случаев будет отображаться на другом языке.';
		|en = 'Updating predefined business roles.
		|While the update is in progress, role descriptions might be displayed in another language.';");
	Handler.ExecutionMode = "Deferred";
	Handler.UpdateDataFillingProcedure = "Catalogs.PerformerRoles.RegisterDataToProcessForMigrationToNewVersion";
	Handler.ObjectsToRead      = "Catalog.PerformerRoles";
	Handler.ObjectsToChange    = "Catalog.PerformerRoles";
	Handler.CheckProcedure    = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.ObjectsToLock   = "Catalog.PerformerRoles";
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "Before";
	

	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	NewRow = Handler.ExecutionPriorities.Add();
	NewRow.Procedure = "NationalLanguageSupportServer.ProcessDataForMigrationToNewVersion";
	NewRow.Order = "Before";
	
	
	Handler = Handlers.Add();
	Handler.Version = "3.1.10.74";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpdateContactInformationKinds";
	Handler.ExecutionMode = "Seamless";
	Handler.Comment = NStr("ru = 'Обновление свойств предопределенных элементов видов контактной информации.';
									|en = 'Update properties of predefined items for contact information kinds';");
	
EndProcedure

////////////

// See InfobaseUpdateSSL.BeforeUpdateInfobase.
Procedure BeforeUpdateInfobase() Export
	
EndProcedure

// See InfobaseUpdateSSL.AfterUpdateInfobase.
Procedure AfterUpdateInfobase(Val PreviousVersion, Val CurrentVersion,
		Val CompletedHandlers, OutputUpdatesDetails, Val ExclusiveMode) Export
	
EndProcedure

// See InfobaseUpdateSSL.OnPrepareUpdateDetailsTemplate.
Procedure OnPrepareUpdateDetailsTemplate(Val Template) Export
	
EndProcedure

// See InfobaseUpdateSSL.OnDefineDataUpdateMode.
Procedure OnDefineDataUpdateMode(DataUpdateMode, StandardProcessing) Export
	
EndProcedure

// See InfobaseUpdateSSL.OnAddApplicationMigrationHandlers.
Procedure OnAddApplicationMigrationHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "StandardSubsystemsLibraryDemoBase";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.UpgradeFromBasicVersionToPROF";
	
	Handler = Handlers.Add();
	Handler.PreviousConfigurationName = "*";
	Handler.Procedure = "_DemoInfobaseUpdateSSL.MigrateFromAnotherApplication";
	
EndProcedure

// See InfobaseUpdateSSL.OnCompleteApplicationMigration.
Procedure OnCompleteApplicationMigration(PreviousConfigurationName, PreviousConfigurationVersion, Parameters) Export
	
	If PreviousConfigurationName = "PreviousConfigurationNameBasic" Then
		Parameters.ConfigurationVersion = PreviousConfigurationVersion;
	EndIf;
	
EndProcedure

// See InfobaseUpdateOverridable.WhenFormingAListOfSubsystemsUnderDevelopment.
Procedure WhenFormingAListOfSubsystemsUnderDevelopment(SubsystemsToDevelop) Export
	
	SubsystemsToDevelop.Add("StandardSubsystems");
	SubsystemsToDevelop.Add("StandardSubsystemsLibrary_Demo");
	
EndProcedure

// End StandardSubsystems.IBVersionUpdate

#EndRegion

#EndRegion

#Region Private

////////////////////////////////////////////////////////////////////////////////
// Populate empty infobase.

// Showcase of a handler procedure for updating and initial infobase data population.
// Runs during update to version 1.0.0.0.
//
Procedure FirstRun() Export
	
	// Code for initial infobase population.
	
EndProcedure

// Showcase of a handler procedure for update and initial contact information kind population.
// 
//
Procedure CreateContactInformationKinds() Export
	
	// "Partner contacts" catalog contact information
	ContactInformationGroup1     = ContactsManager.ContactInformationKindGroupParameters();
	ContactInformationGroup1.Name = "Catalog_DemoPartnersContactPersons";
	ContactInformationGroup1.Description =  NStr("ru = 'Контактная информация справочника ""Контактные лица партнеров""';
													|en = '""Partner contacts"" catalog contact information';");
	
	Group = ContactsManager.SetContactInformationKindGroupProperties(ContactInformationGroup1);
	
	Kind = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	Kind.Name          = "_DemoContactPersonAddress";
	Kind.Description = NStr("ru = 'Адрес контактного лица';
							|en = 'Contact person address';");
	Kind.Group     = Group;
	Kind.CanChangeEditMethod = True;
	Kind.IsAlwaysDisplayed                  = True;
	ContactsManager.SetContactInformationKindProperties(Kind);
	
	Kind = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	Kind.Name          = "_DemoContactPersonEmail";
	Kind.Description = NStr("ru = 'Электронная почта контактного лица';
							|en = 'Contact person''s email';");
	Kind.Group     = Group;
	Kind.CanChangeEditMethod = True;
	Kind.AllowMultipleValueInput   = True;
	Kind.IsAlwaysDisplayed                  = True;
	ContactsManager.SetContactInformationKindProperties(Kind);
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure AttheInitialFillingoftheTypesofContactInformation(LanguagesCodes, Items, TabularSections) Export
	
	// Demo: "ContactPersonsForPartners"
	Item = Items.Add(); 
	Item.PredefinedKindName = "Catalog_DemoPartnersContactPersons";
	Item.IsFolder = True;
	Item.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
			"ru = 'Контактная информация справочника ""Контактные лица партнеров""';
			|en = '""Partner contacts"" catalog contact information';", LanguagesCodes); // @NStr-1
	
	// _DemoContactPersonAddress
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoContactPersonAddress";
	Item.Parent = "Catalog_DemoPartnersContactPersons";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.IDForFormulas       = "Contact_Address";
	Item.EditingOption            = "InputField";
	Item.IncludeCountryInPresentation = False;
	Item.StoreChangeHistory      = False;
	Item.IsAlwaysDisplayed             = True;
	Item.AddlOrderingAttribute    = 1;
	Item.Used                 = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
			"ru = 'Адрес контактного лица';
			|en = 'Contact person address';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.Parent = "Catalog_DemoPartnersContactPersons";
	Item.Type = Enums.ContactInformationTypes.Email;
	Item.EditingOption                 = "InputField";
	Item.IDForFormulas            = "ContactPersonEmail";
	Item.GroupName                         = "Catalog_DemoPartnersContactPersons";
	Item.PredefinedKindName          = "_DemoContactPersonEmail";
	Item.Used                      = True;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.AddlOrderingAttribute         = 2;
	Item.IsAlwaysDisplayed                  = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Электронная почта контактного лица';
		|en = 'Contact person''s email';", LanguagesCodes); // @NStr-1
	
	// Demo: Companies.
	Item = Items.Add(); 
	Item.PredefinedKindName = "Catalog_DemoCompanies";	
	Item.IsFolder = True;
	Item.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
			"ru = 'Контактная информация справочника ""Демо: Организации""';
			|en = '""Demo: Companies"" catalog contact information';", LanguagesCodes); // @NStr-1
	
	// _DemoCompanyLegalAddress
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCompanyLegalAddress";
	Item.Parent = "Catalog_DemoCompanies";
	Item.Type      = Enums.ContactInformationTypes.Address;
	Item.EditingOption                 = "Dialog";
	Item.CanChangeEditMethod = True;
	Item.StoreChangeHistory           = True;
	Item.CheckValidity             = True;
	Item.OnlyNationalAddress           = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	Item.AddlOrderingAttribute         = 1;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Юридический адрес';
		|en = 'Registered address';", LanguagesCodes); // @NStr-1
	
	// _DemoCompanyPhysicalAddress
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCompanyPhysicalAddress";
	Item.Parent = "Catalog_DemoCompanies";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.AddlOrderingAttribute         = 2;
	Item.CanChangeEditMethod = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Фактический адрес';
		|en = 'Business address';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCompanyPostalAddress";
	Item.Parent = "Catalog_DemoCompanies";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.AddlOrderingAttribute         = 3;
	Item.CanChangeEditMethod = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Почтовый адрес';
		|en = 'Postal address';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoInternationalCompanyAddress";
	Item.Parent = "Catalog_DemoCompanies";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.CanChangeEditMethod = True;
	Item.InternationalAddressFormat         = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	Item.AddlOrderingAttribute         = 4;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Международный адрес для платежей / Address for payments';
		|en = 'Address for payments';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCompanyPhone";
	Item.Parent = "Catalog_DemoCompanies";
	Item.Type = Enums.ContactInformationTypes.Phone;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.PhoneWithExtensionNumber         = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	Item.AddlOrderingAttribute         = 5;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Телефон';
		|en = 'Phone';", LanguagesCodes); // @NStr-1
		
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCompanyFax";
	Item.Parent = "Catalog_DemoCompanies";
	Item.Type = Enums.ContactInformationTypes.Fax;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	Item.AddlOrderingAttribute         = 6;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Факс';
		|en = 'Fax';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCompanyEmail";
	Item.Parent = "Catalog_DemoCompanies";
	Item.Type = Enums.ContactInformationTypes.Email;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	Item.AddlOrderingAttribute         = 7;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Электронная почта';
		|en = 'Email';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCompanyOtherInformation";
	Item.Parent = "Catalog_DemoCompanies";
	Item.Type = Enums.ContactInformationTypes.Other;
	Item.CanChangeEditMethod = True;
	Item.FieldKindOther   = "SingleLineWide";
	Item.AddlOrderingAttribute         = 8;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Другое';
		|en = 'Other';", LanguagesCodes); // @NStr-1
	
	// "Partners" catalog contact information
	Item = Items.Add(); 
	Item.PredefinedKindName = "Catalog_DemoPartners";	
	Item.IsFolder    = True;
	Item.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Контактная информация справочника ""Партнеры""';
		|en = '""Partners"" catalog contact information';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoPartnerAddress";
	Item.Parent = "Catalog_DemoPartners";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.CanChangeEditMethod = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Адрес';
		|en = 'Address';", LanguagesCodes); // @NStr-1
		
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoPartnerWebsite";
	Item.Parent = "Catalog_DemoPartners";
	Item.Type = Enums.ContactInformationTypes.WebPage;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Веб-сайт';
		|en = 'Website';", LanguagesCodes); // @NStr-1
		
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoPartnerPhone";
	Item.Parent = "Catalog_DemoPartners";
	Item.Type = Enums.ContactInformationTypes.Phone;
	Item.CanChangeEditMethod = True;
	Item.PhoneWithExtensionNumber         = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Телефон';
		|en = 'Phone';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoPartnerEmail";
	Item.Parent = "Catalog_DemoPartners";
	Item.Type = Enums.ContactInformationTypes.Email;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.CheckValidity             = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Электронная почта партнера';
		|en = 'Partner email';", LanguagesCodes); // @NStr-1
		
	// "Counterparties" catalog contact information
	Item = Items.Add(); 
	Item.PredefinedKindName = "Catalog_DemoCounterparties";	
	Item.IsFolder    = True;
	Item.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Контактная информация справочника ""Контрагенты""';
		|en = '""Counterparties"" catalog contact information';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCounterpartyAddress";
	Item.Parent = "Catalog_DemoCounterparties";
	Item.GroupName = "Catalog_DemoCounterparties";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.CanChangeEditMethod = True;
	Item.OnlyNationalAddress = True;
	Item.IsAlwaysDisplayed        = True;
	Item.Used            = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Адрес';
		|en = 'Address';", LanguagesCodes); // @NStr-1
		
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCounterpartyEmail";
	Item.Parent = "Catalog_DemoCounterparties";
	Item.GroupName = "Catalog_DemoCounterparties";
	Item.Type = Enums.ContactInformationTypes.Email;
	Item.AllowMultipleValueInput = True;
	Item.IsAlwaysDisplayed                = True;
	Item.Used                    = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Электронная почта';
		|en = 'Email';", LanguagesCodes); // @NStr-1

	Item = Items.Add();
	Item.PredefinedKindName = "_DemoSkypeCounterparties";
	Item.Parent = "Catalog_DemoCounterparties";
	Item.GroupName = "Catalog_DemoCounterparties";
	Item.Type = Enums.ContactInformationTypes.Skype;
	Item.CanChangeEditMethod = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Skype';
		|en = 'Skype';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCounterpartyPhone";
	Item.Parent = "Catalog_DemoCounterparties";
	Item.GroupName = "Catalog_DemoCounterparties";
	Item.Type = Enums.ContactInformationTypes.Phone;
	Item.CanChangeEditMethod = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.AllowMultipleValueInput   = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Телефон';
		|en = 'Phone';", LanguagesCodes); // @NStr-1
		
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCounterpartyMessengers";
	Item.Parent = "Catalog_DemoCounterparties";
	Item.GroupName = "Catalog_DemoCounterparties";
	Item.Type = Enums.ContactInformationTypes.Other;
	Item.CanChangeEditMethod = False;
	Item.FieldKindOther   = "SingleLineWide";
	Item.AddlOrderingAttribute         = 8;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Мессенджеры';
		|en = 'Messengers';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoCounterpartyLegalAddress";
	Item.Parent = "Catalog_DemoCounterparties";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.EditingOption = "Dialog";
	Item.CanChangeEditMethod = False;
	Item.AllowMultipleValueInput   = True;
	Item.OnlyNationalAddress           = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Юридический адрес';
		|en = 'Registered address';", LanguagesCodes); // @NStr-1
	
	// "Demo: Individuals" catalog contact information
	Item = Items.Add(); 
	Item.PredefinedKindName = "Catalog_DemoIndividuals";	
	Item.IsFolder    = True;
	Item.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Контактная информация справочника ""Демо: Физические лица""';
		|en = '""Demo: Individuals"" catalog contact information';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoIndividualAddress";
	Item.Parent = "Catalog_DemoIndividuals";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Адрес';
		|en = 'Address';", LanguagesCodes); // @NStr-1
		
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoIndividualPhone";
	Item.Parent = "Catalog_DemoIndividuals";
	Item.Type = Enums.ContactInformationTypes.Phone;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Телефон';
		|en = 'Phone';", LanguagesCodes); // @NStr-1	
	
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoIndividualEmail";
	Item.Parent = "Catalog_DemoIndividuals";
	Item.Type = Enums.ContactInformationTypes.Email;
	Item.CanChangeEditMethod = True;
	Item.AllowMultipleValueInput   = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Электронная почта';
		|en = 'Email';", LanguagesCodes); // @NStr-1	
	
	// "Sales order" table contact information
	// "Partners and contacts" table contact information
	Item = Items.Add(); 
	Item.PredefinedKindName = "Document_DemoSalesOrder";	
	Item.IsFolder    = True;
	Item.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Контактная информация документа ""Заказ покупателя""';
		|en = '""Sales order"" document contact information';", LanguagesCodes); // @NStr-1
	
	Item = Items.Add(); 
	Item.PredefinedKindName = "Document_DemoSalesOrderPartnersAndContactPersons";
	Item.Parent     = "Document_DemoSalesOrder";
	Item.IsFolder    = True;
	Item.Used = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Контактная информация табличной части ""Партнеры и контактные лица""';
		|en = '""Partners and contacts"" table contact information';", LanguagesCodes); // @NStr-1

	Item = Items.Add();
	Item.PredefinedKindName = "_DemoPartnersAndContactPersonsPartnerAddress";
	Item.Parent = "Document_DemoSalesOrderPartnersAndContactPersons";
	Item.Type = Enums.ContactInformationTypes.Address;
	Item.IsAlwaysDisplayed                  = True;
	Item.CanChangeEditMethod = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Адрес партнера';
		|en = 'Partner address';", LanguagesCodes); // @NStr-1

	Item = Items.Add();
	Item.PredefinedKindName = "_DemoPartnersAndContactPersonsPartnerPhone";
	Item.Parent = "Document_DemoSalesOrderPartnersAndContactPersons";
	Item.Type = Enums.ContactInformationTypes.Phone;
	Item.CanChangeEditMethod = True;
	Item.PhoneWithExtensionNumber         = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Телефон партнера';
		|en = 'Partner phone';", LanguagesCodes); // @NStr-1
		
	Item = Items.Add();
	Item.PredefinedKindName = "_DemoPartnersAndContactPersonsPartnerEmail";
	Item.Parent = "Document_DemoSalesOrderPartnersAndContactPersons";
	Item.Type = Enums.ContactInformationTypes.Email;
	Item.CanChangeEditMethod = True;
	Item.IsAlwaysDisplayed                  = True;
	Item.Used                      = True;
	NationalLanguageSupportServer.FillMultilanguageAttribute(Item, "Description",
		"ru = 'Электронная почта';
		|en = 'Email';", LanguagesCodes); // @NStr-1
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Update the infobase.

// Showcase of a handler procedure that updates infobase data. 
// It runs each time the configuration version changes.
//
Procedure AlwaysExecuteOnVersionChange(Parameters = Undefined) Export
	
	If Parameters <> Undefined And Not Parameters.ExclusiveMode Then
		Parameters.ExclusiveMode = Common.CommonSettingsStorageLoad("IBUpdate", "ExecuteExclusiveUpdate", False);
	EndIf;
	
EndProcedure

// Demo of setting attribute values for predefined items of catalog PerformerRoles.
// 
//
Procedure InitializeExecutorRoles() Export
	
	RoleObject1 = Catalogs.PerformerRoles._DemoCEO.GetObject();
	RoleObject1.UsedWithoutAddressingObjects = True;
	InfobaseUpdate.WriteData(RoleObject1);
	
	RoleObject1 = Catalogs.PerformerRoles._DemoChiefAccountant.GetObject();
	RoleObject1.UsedWithoutAddressingObjects = True;
	RoleObject1.UsedByAddressingObjects = True;
	RoleObject1.MainAddressingObjectTypes = ChartsOfCharacteristicTypes.TaskAddressingObjects._DemoCompany;
	InfobaseUpdate.WriteData(RoleObject1);
	
	RoleObject1 = Catalogs.PerformerRoles._DemoDepartmentManager.GetObject();
	RoleObject1.UsedByAddressingObjects = True;
	RoleObject1.MainAddressingObjectTypes = ChartsOfCharacteristicTypes.TaskAddressingObjects._DemoDepartment;
	InfobaseUpdate.WriteData(RoleObject1);
	
	RoleObject1 = Catalogs.PerformerRoles._DemoProjectManager.GetObject();
	RoleObject1.UsedByAddressingObjects = True;
	RoleObject1.MainAddressingObjectTypes = ChartsOfCharacteristicTypes.TaskAddressingObjects._DemoProject;
	InfobaseUpdate.WriteData(RoleObject1);
	
EndProcedure

// See also InfobaseUpdateOverridable.OnInitialItemsFilling
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialPopulationOfMessageTemplates(LanguagesCodes, Items, TabularSections) Export
	
	SetOfParametersNames = New Array;
	SetOfParametersNames.Add("_DemoCustomerProformaInvoice.Number");
	SetOfParametersNames.Add("_DemoCustomerProformaInvoice.Date{DLF=''D''}");
	SetOfParametersNames.Add("_DemoCustomerProformaInvoice.PayDate{DLF=''DD''}");
	SetOfParametersNames.Add("_DemoCustomerProformaInvoice.PayAmount");
	SetOfParametersNames.Add("_DemoCustomerProformaInvoice.YandexCheckoutPayButton");
	SetOfParametersNames.Add("CommonAttributes.CurrentUser.Description");
	SetOfParametersNames.Add("CommonAttributes.MainCompany");
	SetOfParametersNames.Add("CommonAttributes.CurrentDate");
	
	Item = Items.Add();
	Item.Ref = "138cf11f-8c99-11e6-a11f-50465d9e25f1";
	Item.Description = NStr("ru = 'Уведомление о выставленном счете';
								|en = 'Issued invoice notification';", Common.DefaultLanguageCode());
	Item.Code = "000000002";
	Item.Purpose = NStr("ru = 'Демо: Счет на оплату покупателю';
								|en = 'Demo: Sales proforma invoice';", Common.DefaultLanguageCode());
	Item.InputOnBasisParameterTypeFullName = "Document._DemoCustomerProformaInvoice";
	Item.ForInputOnBasis = True;
	Item.ForEmails = True;

	Item.MessageTemplateText = NStr("ru = 'Выставлен счет № [%1] от [%2]. который
		| необходимо оплатить до [%3].
		|
		|Сумма к оплате: [%4] Руб.
		|
		|Просим оплатить счет в течение 5 (пяти) банковских дней с момента получения.
		|
		|[%5]
		|
		|[%6], [%7]
		|[%8]';
		|en = 'Issued invoice No. [%1] from [%2]
		| that must be paid by [%3].
		|
		|Amount due: [%4] rub.
		|
		|Please, pay the invoice within 5 (five) banking days from the date of receipt.
		|
		|[%5]
		|
		|[%6], [%7]
		|[%8]';", Common.DefaultLanguageCode());
	
	Item.MessageTemplateText = StringFunctionsClientServer.SubstituteParametersToStringFromArray(Item.MessageTemplateText, SetOfParametersNames);
	
	Item.HTMLEmailTemplateText = NStr("ru = '<!DOCTYPE html PUBLIC ""-//W3C//DTD HTML 4.0 Transitional//EN""><html><head> 
		|<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8""></meta>
		|<style type=""text/css"">
		|body{margin:0;padding:8px;}
		|p{line-height:1.15;margin:0;}
		|ol,ul{margin-top:0;margin-bottom:0;}
		|img{border:none;}
		|li>p{display:inline;}
		|</style></head><body>
		| <p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;"">Выставлен счет № [%1]
		| от [%2]. который необходимо оплатить до [%3].</span></p>
		|<p></p>
		| <p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;font-weight: bold;"">Сумма к оплате: [%4] Руб.</span></p>
		|<p></p>
		| <p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;"">Просим оплатить счет в течение 5 (пяти) банковских
		| дней с момента получения.</span></p>
		|<p></p>
		|<p>[%5]</p>
		|<p></p>
		| <p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;"">[%6], [%7]</span></p>
		|<p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;"">[%8]</span></p>
		|<p></p>
		|<p><img height=""69"" src=""cid:e7c73532-a774-4336-841c-63237a0e240c"" style=""border:none;"" width=""144""></img></p>
		|</body></html>';
		|en = '<!DOCTYPE html PUBLIC ""-//W3C//DTD HTML 4.0 Transitional//EN""><html><head> 
		|<meta http-equiv=""Content-Type"" content=""text/html; charset=utf-8""></meta>
		|<style type=""text/css"">
		|body{margin:0;padding:8px;}
		|p{line-height:1.15;margin:0;}
		|ol,ul{margin-top:0;margin-bottom:0;}
		|img{border:none;}
		|li>p{display:inline;}
		|</style></head><body>
		| <p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;"">Issued invoice No. [%1]
		| from [%2] that must be paid by [%3].</span></p>
		|<p></p>
		| <p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;font-weight: bold;"">Amount due: [%4] rub.</span></p>
		|<p></p>
		| <p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;"">Please, pay the invoice within 5 (five) banking
		| days from the date of receipt.</span></p>
		|<p></p>
		|<p>[%5]</p>
		|<p></p>
		| <p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;"">[%6], [%7]</span></p>
		|<p><span style=""color: #000000;font-family: Tahoma;font-size: 9pt;"">[%8]</span></p>
		|<p></p>
		|<p><img height=""69"" src=""cid:e7c73532-a774-4336-841c-63237a0e240c"" style=""border:none;"" width=""144""></img></p>
		|</body></html>';", Common.DefaultLanguageCode());
	
	Item.HTMLEmailTemplateText = StringFunctionsClientServer.SubstituteParametersToStringFromArray(Item.HTMLEmailTemplateText, SetOfParametersNames);
	
	Item.EmailSubject = NStr("ru = 'Выставлен счет №[%1] от [%2]';
								|en = 'Issued invoice No. [%1] from [%2]';", Common.DefaultLanguageCode());
	Item.EmailSubject = StringFunctionsClientServer.SubstituteParametersToString(Item.EmailSubject, SetOfParametersNames.Get(0),
		SetOfParametersNames.Get(1));
	
	Item.EmailTextType = Enums.EmailEditingMethods.HTML;

	Item.PrintFormsAndAttachments = TabularSections.PrintFormsAndAttachments.Copy();
	TSItem = Item.PrintFormsAndAttachments.Add();
	TSItem.Id = "821D67D1C590CBD5D4FDDA28F9D30C16";
	TSItem.Name           = NStr("ru = 'Счет';
									|en = 'Account';", Common.DefaultLanguageCode());

	TSItem = Item.PrintFormsAndAttachments.Add();
	TSItem.Id ="CheckoutPayButtonPicture";
	TSItem.Name           = "CheckoutPayButtonPicture";
	
EndProcedure

// See also InfobaseUpdateOverridable.OnSetUpInitialItemsFilling
//
// Parameters:
//  Object                  - CatalogObject.ContactInformationKinds - Object to populate.
//  Data                  - ValueTableRow - Object fill data.
//  AdditionalParameters - Structure:
//   * PredefinedData - ValueTable - Data populated in the OnInitialItemsFilling procedure.
//
Procedure OnInitialPopulationOfMessagesTemplateItem(Object, Data, AdditionalParameters) Export
	
	If Object.Code = "000000002" And Object.Ref = Catalogs.MessageTemplates.EmptyRef() Then
		
		EventLogEventName = NStr("ru = 'Шаблоны сообщений: создание поставляемых шаблонов';
											|en = 'Message templates: Create 1C-supplied templates';", Common.DefaultLanguageCode());
		
		BaseName = "QRCode";
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Description", BaseName);
		AdditionalParameters.Insert("EmailFileID", BaseName);
		
		FileAddingOptions = FilesOperations.FileAddingOptions(AdditionalParameters);
		FileAddingOptions.BaseName = BaseName;
		FileAddingOptions.ExtensionWithoutPoint = "png";
		FileAddingOptions.Author = Users.AuthorizedUser(); 
		 
		FileAddingOptions.FilesOwner = Object.GetNewObjectRef();
		
		Try
			FilesOperations.AppendFile(FileAddingOptions, 
				PutToTempStorage(PictureLib._DemoQRCode.GetBinaryData()));
		Except
			// An exception is thrown when the files are stored in volumes that are unacceptable during writing.
			// If an exception is thrown, create a template without attachments.
			ErrorInfo = ErrorInfo();
			WriteLogEvent(EventLogEventName, 
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo));
		EndTry;
		
		BaseName = NStr("ru = 'Инструкция по созданию факсимильной подписи и печати';
								|en = 'Facsimile instruction';", Common.DefaultLanguageCode());
		
		AdditionalParameters = New Structure;
		AdditionalParameters.Insert("Description", BaseName);
		
		FileAddingOptions = FilesOperations.FileAddingOptions(AdditionalParameters);
		FileAddingOptions.BaseName = BaseName;
		FileAddingOptions.ExtensionWithoutPoint = "pdf";
		
		FileAddingOptions.Author = Users.AuthorizedUser();
		FileAddingOptions.FilesOwner = Object.GetNewObjectRef();   
		SpreadsheetDocument = GetCommonTemplate("GuideToCreateFacsimileAndStamp");
		
		FileThread = New MemoryStream();
		SpreadsheetDocument.Write(FileThread, SpreadsheetDocumentFileType.PDF);
		FileBinaryData = FileThread.CloseAndGetBinaryData();
		FileAddressInTempStorage = PutToTempStorage(FileBinaryData);
		
		Try
			FilesOperations.AppendFile(FileAddingOptions, FileAddressInTempStorage);
		Except
			// An exception is thrown when the files are stored in volumes that are unacceptable during writing.
			// If an exception is thrown, create a template without attachments.
			ErrorInfo = ErrorInfo();
			WriteLogEvent(EventLogEventName,
				EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo));
		EndTry;
	
	EndIf;
	
EndProcedure

// The procedure populates the Currencies catalog in the new data area.
//
Procedure ExecuteInitialCurrenciesFilling() Export
	
	If Common.DataSeparationEnabled() Then
		ListOfCurrencies = New Array; 
		ListOfCurrencies.Add("840");
		ListOfCurrencies.Add("643");
		ListOfCurrencies.Add("978");
		
		CurrencyRateOperations.AddCurrenciesByCode(ListOfCurrencies);
		
	EndIf;

EndProcedure

// Runs during update to to SSL v.2.1.3.16.
//
Procedure UpdatePredefinedCompanyContactInformationKinds() Export
	
	KindParameters = ContactsManager.ContactInformationKindParameters("Address");
	KindParameters.Kind = "_DemoCompanyLegalAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 1;
	KindParameters.ValidationSettings.OnlyNationalAddress = True;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters("Address");
	KindParameters.Kind = "_DemoCompanyPhysicalAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 2;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters("Address");
	KindParameters.Kind = "_DemoCompanyPostalAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 3;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters("Phone");
	KindParameters.Kind = "_DemoCompanyPhone";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 4;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters("Email");
	KindParameters.Kind = "_DemoCompanyEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 5;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters("Fax");
	KindParameters.Kind = "_DemoCompanyFax";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 6;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters("Other");
	KindParameters.Kind = "_DemoCompanyOtherInformation";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 7;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during update to SSL v.2.2.1.12.
//
Procedure FillInUseMultipleOrganizationsConstant() Export
	
	If Constants._DemoUseMultipleCompanies.Get() =
		Constants._DemoNeverUseMultipleCompanies.Get() Then
		// The options must have opposite values.
		// If they don't, the infobase didn't have these options. Initialize them.
		Constants._DemoUseMultipleCompanies.Set(Catalogs._DemoCompanies.NumberOfOrganizations() > 1);
	EndIf;
	
EndProcedure

// Updates attribute values of predefined contact information kinds.
Procedure UpdatePredefinedContactInformationKinds() Export
	
	// "Partners" catalog.
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	KindParameters.Kind = "_DemoPartnerAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 1;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	KindParameters.Kind = "_DemoPartnerPhone";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 2;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	KindParameters.Kind = "_DemoPartnerEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 3;
	KindParameters.ValidationSettings.CheckValidity = True;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	// "Individuals" catalog.
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	KindParameters.Kind = "_DemoIndividualEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 1;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	// "Partner contacts" catalog.
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	KindParameters.Kind = "_DemoContactPersonAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 1;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	KindParameters.Kind = "_DemoContactPersonEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 2;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	// "Counterparties" catalog.
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	KindParameters.Kind = "_DemoCounterpartyAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 1;
	KindParameters.ValidationSettings.OnlyNationalAddress = True;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	KindParameters.Kind = "_DemoCounterpartyEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 2;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	// "Sales order" document.
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	KindParameters.Kind = "_DemoPartnersAndContactPersonsPartnerAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 1;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	KindParameters.Kind = "_DemoPartnersAndContactPersonsPartnerPhone";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 2;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	KindParameters.Kind = "_DemoPartnersAndContactPersonsPartnerEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.Order = 3;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during update to to SSL v.2.2.5.8.
Procedure UpdatePredefinedCounterpartyContactInformationKinds() Export
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	KindParameters.Kind = "_DemoCounterpartyAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.DenyEditingByUser = True;
	KindParameters.Order = 1;
	KindParameters.ValidationSettings.OnlyNationalAddress = True;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	KindParameters.Kind = "_DemoCounterpartyEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.DenyEditingByUser = True;
	KindParameters.Order = 2;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during update to to SSL v.3.1.5.6.
Procedure UpdatePredefinedTypesOfContactInformationOfIndividuals() Export
	
	ContactInformationGroup1     = ContactsManager.ContactInformationKindGroupParameters();
	ContactInformationGroup1.Name = "Catalog_DemoIndividuals";
	ContactInformationGroup1.Description = NStr("ru = 'Контактная информация справочника ""Демо: Физические лица""';
													|en = '""Demo: Individuals"" catalog contact information';");
	
	Group = ContactsManager.SetContactInformationKindGroupProperties(ContactInformationGroup1);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Email);
	KindParameters.Group = Group;
	KindParameters.Kind = "_DemoIndividualEmail";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 1;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	KindParameters.Group = Group;
	KindParameters.Kind = "_DemoIndividualPhone";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.Order = 2;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	KindParameters.Group = Group;
	KindParameters.Kind = "_DemoIndividualAddress";
	KindParameters.CanChangeEditMethod = True;
	KindParameters.DenyEditingByUser = True;
	KindParameters.Order = 3;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during update to SSL v.3.0.1.82.
// Populates the new predefined contact information kind.
//
Procedure FillContactInformationKindInternationalAddress() Export
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	KindParameters.Kind                               = "_DemoInternationalCompanyAddress";
	KindParameters.Order                           = 4;
	KindParameters.CanChangeEditMethod = True;
	KindParameters.EditingOption                 = "InputFieldAndDialog";
	KindParameters.Mandatory            = False;
	KindParameters.InternationalAddressFormat         = True;
	
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during migration to configuration version 3.1.3.50.
// Sets contact information kind property CorrectObsoleteAddresses to True.
// That triggers a scheduled job which fixes partners' obsolete addresses.
//
Procedure ActivateCorrectionOfObsoletePartnersAddresses() Export
	
	CIKind = ContactsManager.ContactInformationKindByName("_DemoPartnerAddress");
	
	KindParameters = ContactsManager.ContactInformationKindParameters(CIKind);
	KindParameters.CorrectObsoleteAddresses  = True;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during update to SSL v.3.0.2.82.
// Populates the new predefined contact information kind.
//
Procedure FillContactInformationKindPartnerWebsite() Export
	
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.WebPage);
	KindParameters.Kind                               = "_DemoPartnerWebsite";
	KindParameters.Order                           = 4;
	KindParameters.CanChangeEditMethod = True;
	KindParameters.AllowMultipleValueInput   = True;
	
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Called when updating the configuration to v.3.1.10.74.
// It updates predefined contact information kinds:
// - Updates attributes with data from "OnInitialItemsFilling".
// - Skips attributes that were modified by the user.
// - Adds contact information kinds that are missing from the infobase.
// - Updates only the listed attributes and contact information kinds.
//
Procedure UpdateContactInformationKinds() Export
	
	ParametersOfUpdate = InfobaseUpdate.PredefinedItemsUpdateParameters();
	ParametersOfUpdate.Items.Add(ContactsManager.ContactInformationKindByName("UserPhone"));
	ParametersOfUpdate.Items.Add(ContactsManager.ContactInformationKindByName("_DemoIndividualEmail"));
	ParametersOfUpdate.Attributes = "AllowMultipleValueInput, EditingOption, IsAlwaysDisplayed";
	InfobaseUpdate.DoUpdatePredefinedItems(Metadata.Catalogs.ContactInformationKinds, ParametersOfUpdate);
	
EndProcedure

// A real-time handler that runs at every synchronization.
Procedure RealTimeHandler() Export
	
	Message = New UserMessage;
	Message.Text = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("ru = 'Демо: Выполнен оперативный обработчик ""%1"".';
			|en = 'Demo: Real-time handler %1 is executed.';"), "RealTimeHandler");
	Message.Message();
	
EndProcedure

// Test handler to simulate an error upon update.
Procedure RealTimeHandlerWithError() Export
	
	SimulateError = Common.CommonSettingsStorageLoad(
		"IBUpdate", "SimuateErrorOnUpdate", , UserName());
	
	If SimulateError = True Then
		Common.CommonSettingsStorageSave("IBUpdate",
			"SimuateErrorOnUpdate", False, UserName());
		MessageText = NStr("ru = 'Демо: Оперативный обработчик ""%1"" выполнен с ошибкой.';
								|en = 'Demo: Real-time handler %1 is executed with error.';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText,
			"RealTimeHandlerWithError");
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,,,
			MessageText);
		Raise MessageText;
	EndIf;
	
EndProcedure

// Updates attribute values of predefined key operations.
Procedure UpdatePredefinedKeyOperations() Export
	
	BeginTransaction();
	
	Try
		DataLock = New DataLock;
		LockItem = DataLock.Add("Catalog.KeyOperations");
		LockItem.SetValue("Name", "");
		DataLock.Lock();

		Query = New Query;
		Query.Text = "SELECT
		               |	KeyOperations.Ref,
		               |	KeyOperations.PredefinedDataName
		               |FROM
		               |	Catalog.KeyOperations AS KeyOperations
		               |WHERE
		               |	KeyOperations.Name = """"
		               |	AND KeyOperations.Predefined";
		
		QueryResult = Query.Execute();
		Selection = QueryResult.Select();
		While Selection.Next() Do
			KeyOperation = Selection.Ref.GetObject(); // CatalogObject.KeyOperations
			KeyOperation.Name = Selection.PredefinedDataName;
			InfobaseUpdate.WriteData(KeyOperation);
		EndDo;
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("ru = 'ЗаписьПредопределенныхКлючевыхОпераций';
										|en = 'PredefinedKeyOperationsRecord';", Common.DefaultLanguageCode()), EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
		
EndProcedure

// Examples of deferred update handlers.

// Test deferred update handler to show an exception.
//
Procedure DeferredHandlerWithError(Parameters) Export
	
	SimulateError = Common.CommonSettingsStorageLoad("IBUpdate", "SimuateErrorOnDeferredUpdate", False);
	If Not SimulateError Then
		Return;
	EndIf;
	
	If Not Parameters.Property("StartsCount") Then
		Parameters.Insert("StartsCount", 1);
	Else
		Parameters.StartsCount = Parameters.StartsCount + 1;
	EndIf;
	
	If Parameters.StartsCount = 3 Then
		Common.CommonSettingsStorageSave("IBUpdate", "SimuateErrorOnDeferredUpdate", False);
	EndIf;
	
	MessageText = NStr("ru = 'Процедура %1 завершилась с ошибкой.';
							|en = 'Procedure %1 was completed with an error.';");
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "TestingDeferredUpdate");
	Raise MessageText;
	
EndProcedure

// Example of migration from configuration StandardSubsystemsLibraryDemoBase.
// 
Procedure UpgradeFromBasicVersionToPROF() Export
	
	MessageText = NStr("ru = 'Выполнен обработчик перехода %1';
							|en = 'Migration handler %1 is executed.';", Common.DefaultLanguageCode());
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "UpgradeFromBasicVersionToPROF");
	
	WriteLogEvent(InfobaseUpdate.EventLogEvent(),
		EventLogLevel.Information,,,
		MessageText);
	
EndProcedure

// An example of a migration handler.
//
Procedure MigrateFromAnotherApplication() Export
	
	SimulateError = Common.CommonSettingsStorageLoad(
		"IBUpdate", "ShouldSimulateErrorOnMigration", , UserName());
	If SimulateError = True Then
		// Emulate an error occurred when migrating to another app.
		Common.CommonSettingsStorageSave("IBUpdate",
			"ShouldSimulateErrorOnMigration", False, UserName());
		
		MessageText = NStr("ru = 'Процедура %1 выполнилась с ошибкой.
			|Имитация ошибки при переходе с другого приложения.';
			|en = 'Procedure %1 completed with an error.
			|Simulate an error when migrating from another application.';");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "MigrateFromAnotherApplication");
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
			EventLogLevel.Information,,,
			MessageText);
		Raise MessageText;
	EndIf;
	
	MessageText = NStr("ru = 'Выполнен обработчик перехода %1';
							|en = 'Migration handler %1 is executed.';", Common.DefaultLanguageCode());
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageText, "MigrateFromAnotherApplication");
	
	WriteLogEvent(InfobaseUpdate.EventLogEvent(),
		EventLogLevel.Information,,,
		MessageText);
	
EndProcedure

// Runs during initial data population.
Procedure UpdatePredefinedContactInformationKind() Export
	
	// Add a new predefined contact information kind: Skype.
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Skype);
	KindParameters.Kind = "_DemoSkypeCounterparties";
	KindParameters.Order = 3;
	KindParameters.CanChangeEditMethod = False;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
	// Set the kind of contact information parameters "Company phone".
	KindParameters = ContactsManager.ContactInformationKindParameters("Phone");
	KindParameters.Kind = "_DemoCompanyPhone";
	KindParameters.ValidationSettings.PhoneWithExtensionNumber = True;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during initial data population.
// Updates the flag indicating the use of contact information kinds of the PartnersContactPersons catalog.
//
Procedure UpdateContactInformationUsageForPartnerContacts() Export
	
	// Initialize the new constant.
	Constants._DemoUsePartnersContactPersons.Set(True);
	
	ContactPersonsPartners = ContactsManager.ContactInformationKindByName("Catalog_DemoPartnersContactPersons");
	If ContactPersonsPartners <> Undefined Then
		Return;
	EndIf;
	PartnersContactPersonsObject = ContactPersonsPartners.GetObject();
	PartnersContactPersonsObject.Used = GetFunctionalOption("_DemoUsePartnersContactPersons");
	InfobaseUpdate.WriteData(ContactPersonsPartners);
	
EndProcedure

// Runs during initial data population.
// Updates the flag indicating the use of the "External users" catalog property sets.
//
Procedure UpdateExternalUserPropertySetsUsage() Export
	
	SetParameters = PropertyManager.PropertySetParametersStructure();
	SetParameters.Used = GetFunctionalOption("UseExternalUsers");
	PropertyManager.SetPropertySetParameters("Catalog_ExternalUsers", SetParameters);
	
EndProcedure

// Updates numeration of counterparty contact information kinds.
Procedure AssignPerformerRoles() Export
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		Block.Add("Catalog.PerformerRoles");
		Block.Lock();
		
		CatalogItem = Catalogs.PerformerRoles.Select();
		While CatalogItem.Next() Do
			If CatalogItem.Purpose.Count() = 0 Then
				RoleObject1 = CatalogItem.GetObject();
				RoleObject1.Purpose.Add().UsersType = Catalogs.Users.EmptyRef();
				If CatalogItem.Ref = Catalogs.PerformerRoles._DemoCEO Then
					RoleObject1.Purpose.Add().UsersType = Catalogs._DemoPartners.EmptyRef();
					RoleObject1.Purpose.Add().UsersType = Catalogs._DemoPartnersContactPersons.EmptyRef();
				EndIf;
				InfobaseUpdate.WriteData(RoleObject1);
			EndIf;
		EndDo;
		CommitTransaction();
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
EndProcedure

// Runs to update contact information kinds for SSL v.2.3.2.4 and later.
// Selects the StoreChangesHistory check box for the company's registered address.
// Sets the MultilineField property to True to save backward compatibility with the "Other" contact information kind.
// 
//
Procedure SetUpContactInformationHistoryAndMultilineField() Export
	
	LegalAddressOrganization = ContactsManager.ContactInformationKindByName("_DemoCompanyLegalAddress");
	
	DataLock = New DataLock;
	DataLockItem = DataLock.Add("Catalog.ContactInformationKinds");
	DataLockItem.SetValue("Ref", LegalAddressOrganization);
	
	BeginTransaction();
	
	Try
		
		DataLock.Lock();
		
		LegalAddressOfOrganizationItem = LegalAddressOrganization.GetObject();
		
		If LegalAddressOfOrganizationItem <> Undefined Then
			
			LegalAddressOfOrganizationItem.StoreChangeHistory      = True;
			LegalAddressOfOrganizationItem.EditingOption            = "Dialog";
			InfobaseUpdate.WriteObject(LegalAddressOfOrganizationItem);
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		WriteLogEvent(NStr("ru = 'ВидыКонтактнойИнформации';
										|en = 'ContactInformationKinds';", Common.DefaultLanguageCode()), 
			EventLogLevel.Error,,, ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		Raise;
	EndTry;
	
EndProcedure

// Runs during update to v.3.0.2.100.
// 
//
Procedure RemovePredefinedAttributeForContactInformationKinds() Export
	
	ContactsManager.RemovePredefinedAttributeForContactInformationKinds();
	
EndProcedure

// Runs during update to v. 3.1.8.186.
//
Procedure AddCounterpartyContactInformationKindMessengers() Export
	
	// Add a new predefined kind of contact information: "Messengers".
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Other);
	KindParameters.Description = NStr("ru = 'Мессенджеры';
										|en = 'Messengers';");
	KindParameters.Kind = "_DemoCounterpartyMessengers";
	KindParameters.Name = "_DemoCounterpartyMessengers";
	KindParameters.Group = ContactsManager.ContactInformationKindByName("Catalog_DemoCounterparties");
	KindParameters.Order = 4;
	KindParameters.CanChangeEditMethod = False;
	KindParameters.IsAlwaysDisplayed = True;
	KindParameters.FieldKindOther   = "SingleLineWide";
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during update to v. 3.1.9.107.
//
Procedure AddCounterpartyContactInformationKindPhone() Export
	
	// Add a new predefined kind of contact information: "Messengers".
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Phone);
	KindParameters.Description = NStr("ru = 'Телефон';
										|en = 'Phone';");
	KindParameters.Kind = "_DemoCounterpartyPhone";
	KindParameters.Name = "_DemoCounterpartyPhone";
	KindParameters.Group = ContactsManager.ContactInformationKindByName("Catalog_DemoCounterparties");
	KindParameters.Order = 5;
	KindParameters.CanChangeEditMethod = True;
	KindParameters.IsAlwaysDisplayed = True;
	KindParameters.AllowMultipleValueInput = True;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

// Runs during update to v. 3.1.10.17.
//
Procedure AddCounterpartyContactInformationKindLegalAddress() Export
	
	// Add a new predefined kind of contact information: "Legal address".
	KindParameters = ContactsManager.ContactInformationKindParameters(Enums.ContactInformationTypes.Address);
	KindParameters.Description = NStr("ru = 'Юридический адрес';
										|en = 'Registered address';");
	KindParameters.Kind = "_DemoCounterpartyLegalAddress";
	KindParameters.Name = "_DemoCounterpartyLegalAddress";
	KindParameters.Group = ContactsManager.ContactInformationKindByName("Catalog_DemoCounterparties");
	KindParameters.Order = 5;
	KindParameters.EditingOption = "Dialog";
	KindParameters.AllowMultipleValueInput = True;
	KindParameters.CanChangeEditMethod = False;
	KindParameters.IsAlwaysDisplayed = True;
	ContactsManager.SetContactInformationKindProperties(KindParameters);
	
EndProcedure

#EndRegion
