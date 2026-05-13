
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// EXT API version of the service manager.
// 
// Returns:
//  Number - EXT API version of the service manager.
Function ServiceManagerExtAPIVersion() Export
	
	Return ServiceProgrammingInterfaceInternal.ServiceManagerExtAPIVersion();

EndFunction

// Indicates whether the method is supported in the address.
// 
// Returns:
//  Boolean - Service manager supports the method in the address.
Function ServiceManagerSupportsMethodInAddress() Export

	Return ServiceProgrammingInterfaceInternal.ServiceManagerSupportsMethodInAddress();

EndFunction

// Interface version properties.
// 
// Returns:
//  Structure:
//   * Version - Number
//   * ServiceManagerVersion - String - In the Revision.Subrevision.Version.Build format.
//   * TimeZoneOfServiceManager - String - Time zone.
Function InterfaceVersionProperties() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Address = VersionAddressOfExternalSoftwareInterface();
	
	If SaaSOperations.DataSeparationEnabled() Then
		Response = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address);
	Else
		Response = IsInternal.SendRequestToServiceFromLocalDatabase("POST", Address);
	EndIf;
		
	DataStream = Response.GetBodyAsStream();
	ResponseData = SaaSOperationsCTL.StructureFromJSONStream(DataStream);
	Renamings = New Map;
	Renamings.Insert("version", "Version");
	Renamings.Insert("sm_version", "ServiceManagerVersion");
	Renamings.Insert("sm_timezone", "TimeZoneOfServiceManager");
	
	Return IsInternal.RenameProperties(ResponseData, Renamings);
	
EndFunction

// Connection with the service manager from the local infobase.
// 
// Parameters:
//  ServerData - See CommonClientServer.URIStructure
//  Timeout - Number - Timeout.
// 
// Returns:
//  HTTPConnection - Connection with the Service Manager.
Function ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout = 60) Export
	
	Return ServiceProgrammingInterfaceInternal.ConnectingToServiceManagerFromLocalDatabase(ServerData, Timeout);
	
EndFunction

// Subscriber of this application.
// 
// Parameters:
//  User - CatalogRef.Users - User.
//  Token - String
// 
// Returns:
//  Structure - Subscriber data.:
//  * Description - String
//  * Code - Number
//  * UserRole - EnumRef.SubscriberUsersRoles
Function SubscriberOfThisApplication(Val User = Undefined, Val Token = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/account";

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SaaSOperations.SessionSeparatorValue());
	QueryData.Insert("auth", IsInternal.AuthorizationProperties(Undefined, User, Token));
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method);
	Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);

	ResponseData = IsInternal.ExecutionResult(Result);
	Subscriber = ResponseData.account;
	RoleField = "role";
	Subscriber[RoleField] = Enums.SubscriberUsersRoles.ValueByName(Subscriber[RoleField]);

	Renamings = IsInternal.RenamingSubscriber();
	Renamings.Insert(RoleField, "UserRole");

	Return IsInternal.RenameProperties(Subscriber, Renamings);

EndFunction

// Service providers of the subscriber.
// 
// Returns:
//  ValueTable:
//   * Description - String
//   * Code - Number
//   * Website1 - String
//   * Phone - String
//   * Mail - String
//   * City - String
//   * Id - String
//   * AutomaticInvoiceIssuanceAllowed - Boolean
//   * TariffOverrideAllowed - Boolean
//   * FareSelectionPageOnly - Boolean
Function SubscriberSServiceOrganizations() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servants/list";
	Subscriber = ServiceProgrammingInterface.SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Subscriber.Code);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);

	Renamings = IsInternal.RenamingSubscriber(True);
	Renamings.Insert("servant_id", IsInternal.ColumnDetails(
		"Id", Common.StringTypeDetails(50)));
	Renamings.Insert("tariff_subscribe_allowed", IsInternal.ColumnDetails(
		"YouCanSubscribeToPricingPlans", New TypeDescription("Boolean")));
	Renamings.Insert("automatic_billing_allowed", IsInternal.ColumnDetails(
		"AutomaticInvoiceIssuanceAllowed", New TypeDescription("Boolean")));
	Renamings.Insert("tariff_override_allowed", IsInternal.ColumnDetails(
		"TariffOverrideAllowed", New TypeDescription("Boolean")));
	Renamings.Insert("tariff_selection_page_only", IsInternal.ColumnDetails(
		"FareSelectionPageOnly", New TypeDescription("Boolean")));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.servants, Renamings);

EndFunction

// Service plan.
// 
// Parameters:
//  ServicePlanCode - String - tariff code
// 
// Returns:
//  See ServiceProgrammingInterface.ServiceRate
Function ServiceRate(ServicePlanCode) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tariff/info";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ServicePlanCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);
	Tariff = ResponseData.tariff;

	Renamings = IsInternal.RenamingRates();
	
	Renamings.Insert("condition", "TermsOfUse_");
	Renamings.Insert("services", IsInternal.ColumnDetails("Services", New TypeDescription("ValueTable")));
	Renamings.Insert("extensions", IsInternal.ColumnDetails("Extensions", New TypeDescription("ValueTable")));
	Renamings.Insert("applications", IsInternal.ColumnDetails(
		"Configurations", New TypeDescription("ValueTable")));
	Renamings.Insert("validity_periods", IsInternal.ColumnDetails(
		"ActionPeriods", New TypeDescription("ValueTable")));
	Renamings.Insert("notification_periods", IsInternal.ColumnDetails(
		"SubscriptionTerminationNotificationPeriods", New TypeDescription("ValueTable")));

	RenamingService = New Map;
	RenamingService.Insert("id", "Code");
	RenamingService.Insert("name", "Description");
	RenamingService.Insert("type", IsInternal.ColumnDetails(
		"ServiceType", New TypeDescription("EnumRef.ServicesTypes")));
	RenamingService.Insert("description", "LongDesc");
	RenamingService.Insert("amount", "LicensesCount");
	RenamingService.Insert("extend_amount", "NumberOfAdditionalLicensesForExpandingSubscription");
	RenamingService.Insert("provider_id", "VendorID");
	RenamingService.Insert("provider_name", "SupplierName");

	TariffExtensionsRenamings = IsInternal.TariffExtensionsRenamings();

	RenamingConfiguration = New Map;
	RenamingConfiguration.Insert("id", "Code");
	RenamingConfiguration.Insert("name", "Description");
	RenamingConfiguration.Insert("description", "LongDesc");

	RenamingValidityPeriods = IsInternal.RenamesAndValidityPeriods();
	
	RenamingAlertPeriods = New Map;
	RenamingAlertPeriods.Insert("days_quantity", IsInternal.ColumnDetails(
		"DaysCount", Common.TypeDescriptionNumber(2, 0, AllowedSign.Nonnegative)));

	IsInternal.RenameProperties(Tariff, Renamings);

	// Process description for subscribers
	AttachmentsStructure = New Structure;
	For Each Attachment In Tariff.DescriptionForSubscribers.images Do
		PictureData = GetBinaryDataFromBase64String(Attachment.data);
		AttachmentsStructure.Insert(Attachment.name, New Picture(PictureData, True));
	EndDo;
	DescriptionForSubscribers = New FormattedDocument;
	DescriptionForSubscribers.SetHTML(Tariff.DescriptionForSubscribers.html, AttachmentsStructure);
	Tariff.DescriptionForSubscribers = DescriptionForSubscribers;

	Tariff.Services = IsInternal.StructuresArrayIntoValueTable(Tariff.Services, RenamingService);
	Tariff.Extensions = IsInternal.StructuresArrayIntoValueTable(Tariff.Extensions, TariffExtensionsRenamings);
	Tariff.Configurations = IsInternal.StructuresArrayIntoValueTable(Tariff.Configurations, RenamingConfiguration);
	Tariff.ActionPeriods = IsInternal.StructuresArrayIntoValueTable(Tariff.ActionPeriods, RenamingValidityPeriods);
	Tariff.SubscriptionTerminationNotificationPeriods = IsInternal.StructuresArrayIntoValueTable(
		Tariff.SubscriptionTerminationNotificationPeriods, RenamingAlertPeriods);

	Return Tariff;

EndFunction

// Service provider's plan.
// 
// Parameters:
//  SCCode - Number - Intermediary code.
//  ServicePlanCode -String - Service plan code as per the intermediary.
// 
// Returns:
//  See ServiceProgrammingInterface.ServiceOrganizationTariff
Function ServiceOrganizationTariff(SCCode, ServicePlanCode) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servant_tariffs/info";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", SCCode);
	QueryData.Insert("id", ServicePlanCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);
	Tariff = ResponseData.servant_tariff;

	Renamings = IsInternal.RenamingServiceOrganizationRates(Method);
	RenamingPeriods = IsInternal.RenamingServiceOrganizationTariffValidityPeriods();
	IsInternal.RenameProperties(Tariff, Renamings);

	AttachmentsStructure = New Structure;
	For Each Attachment In Tariff.DescriptionForSubscribers.images Do
		PictureData = GetBinaryDataFromBase64String(Attachment.data);
		AttachmentsStructure.Insert(Attachment.name, New Picture(PictureData, True));
	EndDo;
	DescriptionForSubscribers = New FormattedDocument;
	DescriptionForSubscribers.SetHTML(Tariff.DescriptionForSubscribers.html, AttachmentsStructure);
	Tariff.DescriptionForSubscribers = DescriptionForSubscribers;

	Tariff.ActionPeriods = IsInternal.StructuresArrayIntoValueTable(Tariff.ActionPeriods, RenamingPeriods);

	Return Tariff;

EndFunction

#EndRegion

#Region Private

Function VersionAddressOfExternalSoftwareInterface()

	Return "hs/ext_api/version";

EndFunction

#EndRegion

#EndIf