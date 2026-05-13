////////////////////////////////////////////////////////////////////////////////
// ServiceProgrammingInterface: Runs the standard Service Manager features via an external API.
//  
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Returns version properties of the Service Manager API.
// 
// Returns:
//  Structure - Properties of the external API version:
//   * Version - Number - External API version.
//   * ServiceManagerVersion - String - Service manager version.
//   * TimeZoneOfServiceManager - String - Service Manager time zone.
//
Function InterfaceVersionProperties() Export

	Return ServiceProgrammingInterfaceCached.InterfaceVersionProperties();

EndFunction

#Region Account

// Returns a list of subscribers for the active user.
// 
// Returns:
//  ValueTable - Subscriber list.:
//    * Description - String - Subscriber description.
//    * Code - Number - Subscriber code.
//    * UserRole - EnumRef.SubscriberUsersRoles - Role of the active subscriber user.
//
Function Subscribers_() Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/list";
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriber();
	Renamings.Insert("role", IsInternal.ColumnDetails("UserRole", 
		New TypeDescription("EnumRef.SubscriberUsersRoles")));

	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.account, Renamings);

EndFunction

// Returns additional information (attributes and properties) of the app subscriber.
// Implements the API method: account/customers/attached_info.
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Structure - Additional attributes and properties of a subscriber:
//   * PublicId - String - Public subscriber ID.
//   * Attributes - ValueTable - Subscriber additional attributes:
//     ** Key - String - Additional attribute's name.
//     ** Type - String - Value type. 
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
//   * Properties - ValueTable - Subscriber additional properties:
//     ** Key - String - Additional property name.
//     ** Type - String - Value type.
//     ** Value - String, Number, Date, Boolean - Additional property value.
//
Function AdditionalSubscriberInformation(RaiseExceptionAtError = True, 
	BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	Subscriber = SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Subscriber.Code);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, 
		RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
		
	ResponseData.Delete("general");
	
	Renamings = New Map;
	Renamings.Insert("public_id", IsInternal.ColumnDetails(
		"PublicId", Common.StringTypeDetails(36)));
	Renamings.Insert("properties", "Properties");
	Renamings.Insert("fields", "Attributes");
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	
	Result.Properties = IsInternal.StructuresArrayIntoValueTable(
		Result.Properties, IsInternal.RenamingAdditionalInformation());
	Result.Attributes = IsInternal.StructuresArrayIntoValueTable(
		Result.Attributes, IsInternal.RenamingAdditionalInformation());
	
	Return Result;
	
EndFunction

// Updates additional information (attributes and properties) of the subscriber.
// Implements the API method: account/update_attached_info.
//
// Parameters:
//  AddProperties - See NewAdditionalSubscriberInformation
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//  
// Returns:
//  Boolean - Additional information register value flag. If True, a value is set. If False, an error occurred.
//
Function UpdateAdditionalSubscriberInformation(AddProperties, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/update_attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", AddProperties.SubscriberCode);

	If AddProperties.Property("PublicId") Then
		QueryData.Insert("public_id", AddProperties.PublicId);
	EndIf;
	Renamings = IsInternal.RenamingAdditionalInformation(False);
	If AddProperties.Property("Attributes") Then
		QueryData.Insert("fields", IsInternal.TableOfValuesInArrayOfStructures(
			AddProperties.Attributes, Renamings));
	EndIf;
	If AddProperties.Property("Properties") Then
		QueryData.Insert("properties", IsInternal.TableOfValuesInArrayOfStructures(
			AddProperties.Properties, Renamings));
	EndIf;

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Updates subscriber's additional information (attributes and properties)
// that is required for buying a paid subscription.
// Implements the API method: account/attached_info_for_subscribing.
//
// Parameters:
//  SubscriberCode - Number - Code of the subscriber whose additional information records are required.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  Structure - Additional attributes and properties of the subscriber:
//   * HasErrors - Boolean - Invalid entry flag.
//   * Attributes - ValueTable - Subscriber additional attributes:
//     ** Key - String - Additional attribute's name.
//     ** Title - String - Additional attribute's title.
//     ** Type - String - Value type. 
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
//     ** RequiredToFill - Boolean - Required value flag. 
//     ** ToolTip - String - Entry field tooltip.
//     ** Error - Boolean - Invalid value flag.
//     ** Message - String - Error message.
//   * Properties - ValueTable - Subscriber additional properties:
//     ** Key - String - Additional property name.
//     ** Title - String - Additional attribute's title.
//     ** Type - String - Value type.
//     ** Value - String, Number, Date, Boolean - Additional property value.
//     ** RequiredToFill - Boolean - Required value flag. 
//     ** ToolTip - String - Entry field tooltip.
//     ** Error - Boolean - Invalid value flag.
//     ** Message - String - Error message.
//
Function RequiredInformationForSubscribing(SubscriberCode, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/attached_info_for_subscribing";

	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingAdditionalInformation();
	Renamings.Insert("required", IsInternal.ColumnDetails(
		"RequiredToFill", New TypeDescription("Boolean")));
	Renamings.Insert("tooltip", IsInternal.ColumnDetails(
		"ToolTip", New TypeDescription("String")));
	Renamings.Insert("error", IsInternal.ColumnDetails(
		"Error", New TypeDescription("Boolean")));
	Renamings.Insert("message", IsInternal.ColumnDetails(
		"Message", New TypeDescription("String")));
		
	If ResponseData <> Undefined Then
		Properties = IsInternal.StructuresArrayIntoValueTable(ResponseData.properties, Renamings);
		Attributes = IsInternal.StructuresArrayIntoValueTable(ResponseData.fields, Renamings);
	Else
		Properties = IsInternal.NewAdditionalInformation();
		Attributes = IsInternal.NewAdditionalInformation();
	EndIf;

	Return New Structure("HasErrors, Properties, Attributes", ResponseData.errors, Properties, Attributes);

EndFunction

// Returns the additional information record values.
// 
// Parameters:
//  NameOfProperty - String - Name of the information record whose values you want to get.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  ValueTable - Additional information record values.:
//   * Description - String - The length is 100 characters.
//   * Weight - Number - Precision is 10.2.  
Function AdditionalInformationValues(NameOfProperty, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "attached_info_values";

	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("key", NameOfProperty);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method, , False);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	Renamings = New Map;
	Renamings.Insert("name", IsInternal.ColumnDetails(
		"Description", Common.StringTypeDetails(100)));
	Renamings.Insert("weight", IsInternal.ColumnDetails(
		"Weight", Common.TypeDescriptionNumber(10, 2)));
	
	If ResponseData <> Undefined Then
		Values = IsInternal.StructuresArrayIntoValueTable(ResponseData.values, Renamings);
	Else 
		Values = New ValueTable;
	EndIf;
	
	Return Values;

EndFunction

#EndRegion

#Region Account_Users

// Returns the list of the subscriber's application users.
// Implements the API method: account/users/list.
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//  
//  Returns:
//  ValueTable - Subscriber users.:
//   * Login - String - Username.
//   * FullName - String - User's full name.
//   * Mail - String - User's email.
//   * UserRole - EnumRef.SubscriberUsersRoles - User role.
//   * AllowedNumberOfSessions - Number - Session count limit.
//   * TemporaryAccess - Boolean - Temporary access.
//
Function SubscriberUsers(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Subscriber.Code);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	
	Renamings = IsInternal.RenamingSubscriberUsers();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.user, Renamings);
	
EndFunction

// Returns subscriber properties.
// Implements the API method: account/customers/info.
// Parameters:
//  Login - String - Username.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Structure - Subscriber user properties:
//   * Login - String - Username.
//   * FullName - String - User's full name.
//   * Mail - String - User's email.
//   * UserRole - EnumRef.SubscriberUsersRoles - User roles.
//   * AllowedNumberOfSessions - Number - Session count limit.
//   * TemporaryAccess - Boolean - Temporary access.
//   * AdditionalAttributes - ValueTable - Subscriber's user additional attributes:
//     ** Key - String - Additional attribute's name.
//     ** Type - String - Value type. 
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
Function SubscriberUserProperties(Login,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Subscriber.Code);
	QueryData.Insert("login", Login);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriberUsers();
	
	Result = IsInternal.RenameProperties(ResponseData.user, Renamings);
	If Result.Property("fields") Then
		Renamings = IsInternal.RenamingAdditionalInformation();
		AdditionalAttributes = IsInternal.StructuresArrayIntoValueTable(Result.fields, Renamings);
		Result.Delete("fields");
		Result.Insert("AdditionalAttributes", AdditionalAttributes);
	Else
		Result.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	EndIf;
	
	Return Result;

EndFunction

// Creates a new account for a service user and connects the created user to the app subscriber. 
//
// Parameters:
//  CreationParameters - See NewUserCreationOptions
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - Indicates whether the user is added. If True, the user is added. If False, an error occurred.
//
Function CreateSubscriberUser(CreationParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/create";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Subscriber.Code);
	QueryData.Insert("role", Enums.SubscriberUsersRoles.NameByValue(CreationParameters.UserRole));
	QueryData.Insert("login", CreationParameters.Login);
	QueryData.Insert("password", CreationParameters.Password);
	QueryData.Insert("email", CreationParameters.Mail);
	QueryData.Insert("email_required", CreationParameters.MailRequired);
	QueryData.Insert("name", CreationParameters.FullName);
	QueryData.Insert("phone", CreationParameters.Phone);
	QueryData.Insert("timezone", CreationParameters.TimeZone);
	QueryData.Insert("description", CreationParameters.LongDesc);
	If CreationParameters.Property("AdditionalAttributes") 
	   And CreationParameters.AdditionalAttributes.Count() > 0 Then
		AdditionalAttributes = New Array; // Array of Structure
		For Each String In CreationParameters.AdditionalAttributes Do
			TypeValueName = New Structure;
			TypeValueName.Insert("key", String.Key);
			If ValueIsFilled(String.Type) Then
				TypeValueName.Insert("type", String.Type);
			EndIf;
			TypeValueName.Insert("value", String.Value);
			AdditionalAttributes.Add(TypeValueName);
		EndDo;
		QueryData.Insert("fields", AdditionalAttributes);
	EndIf;
		
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Adds an existing service user to an application subscriber. 
//
// Parameters:
//  AddingOptions - See NewParametersForAddingUser
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - Indicates whether the account is created. If True, the account is created. If False, an error occurred.
//
Function AddSubscriberUser(AddingOptions,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/add";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Subscriber.Code);
	QueryData.Insert("role", Enums.SubscriberUsersRoles.NameByValue(AddingOptions.UserRole));
	QueryData.Insert("login", AddingOptions.Login);
	QueryData.Insert("description", AddingOptions.LongDesc);
	QueryData.Insert("force", AddingOptions.Forcibly);
	If AddingOptions.Property("AdditionalAttributes") 
	   And AddingOptions.AdditionalAttributes.Count() > 0 Then
		AdditionalAttributes = New Array; // Array of Structure
		For Each String In AddingOptions.AdditionalAttributes Do
			TypeValueName = New Structure;
			TypeValueName.Insert("key", String.Key);
			If ValueIsFilled(String.Type) Then
				TypeValueName.Insert("type", String.Type);
			EndIf;
			TypeValueName.Insert("value", String.Value);
			AdditionalAttributes.Add(TypeValueName);
		EndDo;
		QueryData.Insert("fields", AdditionalAttributes);
	EndIf;
		
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Assigns the given user a role.
// Implements the API method: account/users/set_role.
// 
// Parameters:
//  Login - String - a username. 
//  Role - EnumRef.SubscriberUsersRoles - a user role to specify.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - ] indicates role setting. True means that it is set, False - an error has occurred.
//
Function SetSubscriberUserRole(Login, Role,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
		
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/set_role";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Subscriber.Code);
	QueryData.Insert("login", Login);
	QueryData.Insert("role", Enums.SubscriberUsersRoles.NameByValue(Role));
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
			
EndFunction

// Updates additional user (subscriber) attributes.
// Implements the API method: account/users/update_attached_info.
// 
// Parameters:
//  Login - String - Username. 
//  AddAttributes - ValueTable - Subscriber's user additional attributes:
//     * Key - String - Additional attribute's name.
//     * Type - String - Value type. 
//     * Value - String, Number, Date, Boolean - Additional attribute's value.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - Additional attribute value flag. If True, a value is set. If False, an error occurred.
Function UpdateAdditionalDetailsOfSubscriberSUser(Login, AddAttributes,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/users/update_attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Subscriber.Code);
	QueryData.Insert("login", Login);
	QueryData.Insert("fields", New Array);
	
	For Each String In AddAttributes Do
		Data = New Structure;
		Data.Insert("key", String.Key);
		Data.Insert("value", String.Value);
		If ValueIsFilled(String.Type) Then
			Data.Insert("type", String.Type);
		EndIf;
		QueryData.fields.Add(Data);
	EndDo;

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;

EndFunction

// Returns a parameter template for creating a user for the ServiceProgrammingInterface.CreateSubscriberUser method.
// 
// Returns:
//  Structure - Template of parameters to create a user:
//	 * Login - String - Username.
//	 * Password - String - user password
//   * MailRequired - Boolean - indicates that email is required (True by default)
//   * Mail - String - email
//   * UserRole - EnumRef.SubscriberUsersRoles - Role. By default, SubscriberUser.
//   * FullName - String - a full username
//   * Phone - String - a user phone
//   * TimeZone - String - a working user time zone
//   * LongDesc - String - User details.
//   * AdditionalAttributes - ValueTable - Subscriber's user additional attributes:
//     ** Key - String - Attribute name.
//     ** Type - String - Attribute type. 
//              Primitive types: String, Decimal, Date, Boolean.
//              Reference types: User, Subscriber, Tariff, Service_provider_tariff, Tariff_period, 
//                         Subscription, Service, Additional_value, Additional_value_group.
//     ** Value - String, Number, Date, Boolean - Attribute value.
//
Function NewUserCreationOptions() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	
	Parameters = New Structure;
	Parameters.Insert("Login", "");
	Parameters.Insert("Password", "");
	Parameters.Insert("MailRequired", True);
	Parameters.Insert("Mail", "");
	Parameters.Insert("UserRole", Enums.SubscriberUsersRoles.SubscriberUser);
	Parameters.Insert("FullName", "");
	Parameters.Insert("Phone", "");
	Parameters.Insert("TimeZone", "");
	Parameters.Insert("LongDesc", "");
	
	Parameters.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	
	Return Parameters;
	
EndFunction

// Returns a parameter template for adding an existing user for the ServiceProgrammingInterface.CreateSubscriberUser method.
// 
// Returns:
//  Structure - Template of parameters to create a user:
//	 * Login - String - Username.
//   * UserRole - EnumRef.SubscriberUsersRoles - Role. By default, SubscriberUser.
//   * LongDesc - String - User details.
//   * Forcibly - Boolean - Execute even if there are warnings.
//   * AdditionalAttributes - ValueTable - Subscriber's additional user attributes.:
//     ** Key - String - Attribute name.
//     ** Type - String - Attribute type. 
//              Primitive types: String, Decimal, Date, Boolean.
//              Reference types: User, Subscriber, Tariff, Service_provider_tariff, Tariff_period, 
//                         Subscription, Service, Additional_value, Additional_value_group.
//     ** Value - String, Number, Date, Boolean - Attribute value.
//
Function NewParametersForAddingUser() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	
	Parameters = New Structure;
	Parameters.Insert("Login", "");
	Parameters.Insert("UserRole", Enums.SubscriberUsersRoles.SubscriberUser);
	Parameters.Insert("LongDesc", "");
	Parameters.Insert("Forcibly", False);
	
	Parameters.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	
	Return Parameters;
	
EndFunction

#EndRegion 

#Region Account_Servants

// Returns the list of the intermediaries for the subscriber.
// Implements the API method: account/servants/list.
//
// Returns:
//  ValueTable - Service providers of the subscriber.:
//   * Code - Number - Code (number) of the intermediary.
//   * Description - String - Intermediary provider description.
//   * Id - String - Subscriber ID.
//   * City - String - City.
//   * Website1 - String - Website.
//   * Mail - String - Email.
//   * Phone - String - Phone number.
//   * YouCanSubscribeToPricingPlans - Boolean - Subscribing to service plans is allowed.
//   * AutomaticInvoiceIssuanceAllowed - Boolean - Automatic invoicing is allowed.
//   * TariffOverrideAllowed - Boolean - Service plan overriding is allowed.
//   * FareSelectionPageOnly - Boolean - Show only service plan choice page in the payment form.
//
Function SubscriberSServiceOrganizations() Export

	Return ServiceProgrammingInterfaceCached.SubscriberSServiceOrganizations();

EndFunction

// Returns the HTML page where the application subscriber can select an intermediary's service plan.
// Implements the API method: account/servants/tariff_selection_page.
// Parameters:
//  SCCode - Number - Intermediary code.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  String - a HTML page for selecting a tariff of the service company.
//
Function PageForSelectingServiceCompanySPricingPlan(SCCode,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servants/tariff_selection_page";

	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;

	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", SCCode);

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(
		Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData <> Undefined Then
		Return ResponseData.html;
	Else
		Return Undefined;
	EndIf;

EndFunction

// Returns the list of service plans the intermediary recommends.
// Implements the API method: account/servants/recommended_tariffs.
//
// Parameters:
//  SCCode - Number - Intermediary code.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  ValueTable - Service plan list:
//   * ProviderServicePlanCode - String - Provider service plan code.
//   * ServiceProviderPlanCode - String - Service plan code as per the intermediary.
Function RecommendedRates(SCCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servants/recommended_tariffs";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", SCCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingRecommendedRates();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.recommended_tariffs, Renamings);

EndFunction

// Returns the intermediary's service plan list.
// Implements the API method: account/servant_tariffs/list.
//
// Parameters:
//  Filter - See NewSelectionOfSupportCompanyTariffsList
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  ValueTable - Service plan list:
//   * Code - String - tariff code
//   * Description - String - a tariff description
//   * ProviderServicePlanCode - String - base service plan code
//   * ShortDescription - String - Service plan brief details.
//   * ActionPeriods - ValueTable - Validity periods. Populated if :
//     ** Code - String - a validity period code
//     ** Description - String - a validity period description
//     ** Sum - Number - Service plan price for the given validity period.
//     ** Recommended_ - Boolean - Recommended validity period flag. 
//     ** Comment - String - Comment to the validity period.
//
Function ServiceOrganizationRates(Filter, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/servant_tariffs/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", Filter.ServiceProviderCode);
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	If InterfaceVersion >= 19 Then
		QueryData.Insert("scope", Filter.ReceivingParameters);
	EndIf;
	
	If InterfaceVersion >= 23 And Filter.AvailableServicePlans.Count() > 0 Then
		QueryData.Insert("available_tariffs", Filter.AvailableServicePlans);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	RenamingValidityPeriods = IsInternal.RenamingServiceOrganizationTariffValidityPeriods();
	ValidityPeriodsField = "validity_periods";
	TariffField = "servant_tariff";
	
	If InterfaceVersion >= 19	And Not Filter.ReceivingParameters.Find(ParameterForGettingValidityPeriods()) = Undefined Then
		For Each Item In ResponseData[TariffField] Do
			Item[ValidityPeriodsField] = IsInternal.StructuresArrayIntoValueTable(Item[ValidityPeriodsField], RenamingValidityPeriods);
		EndDo;
	EndIf;
	
	Renamings = IsInternal.RenamingServiceOrganizationRates(Method);
	Result = IsInternal.StructuresArrayIntoValueTable(ResponseData[TariffField], Renamings);

	Return Result;

EndFunction

// Returns information about the intermediary's service plan.
//
// Parameters:
//  SCCode - Number - Intermediary code.
//  ServicePlanCode - String - Service plan code as per the intermediary. 
// 
// Returns:
//  Structure - Information about the service plan:
//   * Code - String - tariff code
//   * Description - String - a tariff description
//   * ProviderServicePlanCode - String - Provider service plan code.
//   * ShortDescription - String - Service plan brief details.
//   * DescriptionForSubscribers - FormattedDocument - tariff details for subscribers.
//   * ActionPeriods - ValueTable - Service plan validity periods:
//     ** Code - String - a validity period code
//     ** Description - String - a validity period description
//     ** Sum - Number - Price.
//     ** Recommended_ - Boolean - Recommended service plan flag.
//     ** Comment - String - a comment to a validity period
//
Function ServiceOrganizationTariff(SCCode, ServicePlanCode) Export
	
	Return ServiceProgrammingInterfaceCached.ServiceOrganizationTariff(SCCode, ServicePlanCode);
	
EndFunction

#EndRegion 

#Region Customers

// Returns the subscriber list.
// Implements the API method: account/customers/list.
//
// Parameters:
//  SCCode - Number - Main subscriber code (number). If not specified, the current application subscriber is used.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  ValueTable:
//   * Description - String - Subscriber name. The length is 64 characters.
//   * Code - String - Subscriber code (number). The length is 12 characters.
Function ServedSubscribers(SCCode = Undefined, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customers/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberOfThisApplication().Code;
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SCCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.customer, IsInternal.RenamingSubscriber());

EndFunction

// Returns subscriber properties.
// Implements the API method: account/customers/info.
//
// Parameters:
//  SubscriberCode - Number - Subscriber code (number).
//  SCCode - Number - Main subscriber code (number). If not specified, the current application subscriber is used.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  Structure:
//   * Description - String - Subscriber name. The length is 64 characters.
//   * Code - String - Subscriber code (number). The length is 12 characters.
//   * Website1 - String - Website as per contact information. The length is 500 characters.
//   * City - String - City as per contact information. The length is 500 characters.
//   * Mail - String - Email as per contact information. The length is 500 characters.
//   * Phone - String - Phone number as per contact information. The length is 500 characters.
//
Function PropertiesOfServedSubscriber(SubscriberCode, SCCode = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customers/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberOfThisApplication().Code;
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SCCode);
	QueryData.Insert("account", SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return IsInternal.RenameProperties(ResponseData.customer, IsInternal.RenamingSubscriber(True));
	
EndFunction

// Returns additional attributes and properties of the subscriber.
// Implements the API method: account/customers/attached_info.
//
// Parameters:
//  SubscriberCode - Number - Subscriber code (number).
//  SCCode - Number - Main subscriber code (number). If not specified, the current application subscriber is used.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//  
// Returns:
//  Structure - Additional attributes and properties of a subscriber:
//   * PublicId - String - Public subscriber ID.
//   * Attributes - ValueTable - Subscriber additional attributes:
//     ** Key - String - Additional attribute's name.
//     ** Type - String - Value type. 
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
//   * Properties - ValueTable - Subscriber additional properties:
//     ** Key - String - Additional property name.
//     ** Type - String - Value type.
//     ** Value - String, Number, Date, Boolean - Additional property value.
Function AdditionalInformationOfServedSubscriber(SubscriberCode, SCCode = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customers/attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberOfThisApplication().Code;
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SCCode);
	QueryData.Insert("account", SubscriberCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	ResponseData.Delete("general");
	
	Renamings = New Map;
	Renamings.Insert("public_id", IsInternal.ColumnDetails(
		"PublicId", Common.StringTypeDetails(36)));
	Renamings.Insert("properties", "Properties");
	Renamings.Insert("fields", "Attributes");
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	
	Result.Properties = IsInternal.StructuresArrayIntoValueTable(
		Result.Properties, IsInternal.RenamingAdditionalInformation());
	Result.Attributes = IsInternal.StructuresArrayIntoValueTable(
		Result.Attributes, IsInternal.RenamingAdditionalInformation());
	
	Return Result;
	
EndFunction

// Updates additional information (attributes and properties) of the subscriber.
// Implements the API method: account/customers/update_attached_info.
//
// Parameters:
//  AddProperties - See NewAdditionalSubscriberInformation
//  SCCode - Number - Main subscriber code (number). If not specified, the current application subscriber is used.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//  
// Returns:
//  Boolean - Additional information register value flag. If True, a value is set. If False, an error occurred.
//
Function UpdateAdditionalInformationOfServedSubscriber(AddProperties, SCCode = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customers/update_attached_info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberOfThisApplication().Code;
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SCCode);
	QueryData.Insert("account", AddProperties.SubscriberCode);
	QueryData.Insert("public_id", AddProperties.PublicId);
	
	Renamings = IsInternal.RenamingAdditionalInformation(False);
	If AddProperties.Property("Attributes") Then
		QueryData.Insert("fields", IsInternal.TableOfValuesInArrayOfStructures(
			AddProperties.Attributes, Renamings));
	EndIf;
	If AddProperties.Property("Properties") Then
		QueryData.Insert("properties", IsInternal.TableOfValuesInArrayOfStructures(
			AddProperties.Properties, Renamings));
	EndIf;

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);

	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a template with subscriber additional information.
// 
// Returns:
//  Structure:
//   * SubscriberCode - Number - Subscriber code.
//   * PublicId - String - Subscriber public ID. The length is 36 characters. Optional.
//   * Attributes - ValueTable - Subscriber additional attributes: 
//     ** Key - String - Additional attribute's name.
//     ** Type - String - Value type. Optional if the additional attribute can take only one value type.
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
//   * Properties - ValueTable - Subscriber additional properties: 
//     ** Key - String - Additional property name.
//     ** Type - String - Value type. Optional if the additional property can take only one value type.
//     ** Value - String, Number, Date, Boolean - Additional property value.
//
Function NewAdditionalSubscriberInformation() Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	
	Result = New Structure;
	Result.Insert("SubscriberCode", 0);
	Result.Insert("PublicId", "");
	Result.Insert("Attributes", IsInternal.NewAdditionalInformation());
	Result.Insert("Properties", IsInternal.NewAdditionalInformation());
	
	Return Result;

EndFunction

#EndRegion

#Region CustomerSubscriptions

// Returns the subscription list for the given subscribers.
// Implements the API method: account/customer_subscriptions/list.
//
// Parameters:
//  Filter - See NewPricingPlanSubscriptionSelection
//  SCCode - Number - Main subscriber code (number). If not specified, the current application subscriber is used.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  ValueTable - Available service plan subscriptions.:
//   * Number - String - Subscription number.
//   * Date - Date - Subscription start date.
//   * ConnectionDate - Date - Date the user subscribed to the service plan.
//   * DateOfExpiration - Date - Date the service plan was canceled.
//   * ServicedSubscriberCode - Number - Code (number) of the subscriber.
//   * MasterSubscriberCode - Number - Code (number) of the main subscriber.
//   * ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//   * ProviderServicePlanCode - String - Service plan code in the subscription.
//   * ValidityPeriodCode - String - Validity period code.
//   * Count - Number - Number of support plans in the subscription.
//   * PrimarySubscriptionNumber - String - Number of the basic subscription if a user is subscribed to a service plan add-on.
//   * SubscriptionType - EnumRef.ServiceSubscriptionsTypes - Subscription type.
//   * InvoiceNum - String - Proforma invoice number.
//   * PaymentInvoiceID - UUID - Proforma invoice ID.
//
Function SubscriptionsToPricingPlans(Filter, SCCode = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customer_subscriptions/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If SCCode = Undefined Then
		SCCode = SubscriberOfThisApplication().Code;
	EndIf; 
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("servant", SCCode);
	
	If TypeOf(Filter) = Type("Structure") Then
		FilterFields = New Map;
		FilterFields.Insert("ServicedSubscriberCode", "account");
		FilterFields.Insert("ActiveOnly", "active");
		FilterFields.Insert("MainOnly", "basic");
		FilterFields.Insert("BeginOfPeriod", "start_date");
		FilterFields.Insert("EndOfPeriod", "end_date");
		For Each Item In FilterFields Do
			If Filter.Property(Item.Key) And ValueIsFilled(Filter[Item.Key]) Then
				QueryData.Insert(Item.Value, Filter[Item.Key]);
			EndIf; 
		EndDo;
	Else
		Filter = NewPricingPlanSubscriptionSelection();
	EndIf; 
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriptionPlan(True);
	
	Result = IsInternal.StructuresArrayIntoValueTable(ResponseData.subscription, Renamings);
	Result.Sort("Date");
	InterfaceVersion = InterfaceVersionProperties().Version;
	For IndexOf = 1 To Result.Count() Do
		String = Result[Result.Count() - IndexOf];
		If Filter.MainOnly And InterfaceVersion < 14 And Not IsBlankString(String.PrimarySubscriptionNumber) Then
			Result.Delete(String);
			Continue;
		EndIf;
		If String.Count = 0 Then
			String.Count = 1;
		EndIf;
	EndDo;
	
	Return Result;

EndFunction

// Returns the service plan properties for the given subscriber.
// Implements the API method: account/customer_subscriptions/info.
// 
// Parameters:
//  SubscriptionNumber - String - Subscription number.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//  
// Returns:
//  Structure - Subscription properties:
//   * Number - String - Subscription number.
//   * Date - Date - Subscription start date.
//   * ConnectionDate - Date - Date the user subscribed to the service plan.
//   * DateOfExpiration - Date - Date the service plan was canceled.
//   * ServicedSubscriberCode - Number - Code (number) of the subscriber.
//   * MasterSubscriberCode - Number - Code (number) of the main subscriber.
//   * ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//   * ProviderServicePlanCode - String - Service plan code in the subscription.
//   * ValidityPeriodCode - String - Validity period code.
//   * Count - Number - Number of support plans in the subscription.
//   * PrimarySubscriptionNumber - String - Number of the basic subscription if a user is subscribed to a service plan add-on.
//   * SubscriptionType - EnumRef.ServiceSubscriptionsTypes - Subscription type.
//   * InvoiceNum - String - Proforma invoice number.
//   * PaymentInvoiceID - UUID - Proforma invoice ID.
Function TariffSubscriptionProperties(SubscriptionNumber,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customer_subscriptions/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriptionNumber);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriptionPlan(True);
	
	Result = IsInternal.RenameProperties(ResponseData.subscription, Renamings);
	If Result.Count = 0 Then
		Result.Count = 1;
	EndIf; 
	
	Return Result;
	
EndFunction

// Returns the service plan properties for the subscriber.
// Implements the API method: subscription/info.
// 
// Parameters:
//  SubscriptionNumber - String - subscription number.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//  
// Returns:
//  Structure - Subscription properties:
//   * Number - String - Subscription number.
//   * Date - Date - Subscription start date.
//   * ConnectionDate - Date - Date the user subscribed to the service plan.
//   * DateOfExpiration - Date - Date the service plan was canceled.
//   * ServicedSubscriberCode - Number - Code (number) of the subscriber.
//   * MasterSubscriberCode - Number - Code (number) of the main subscriber.
//   * ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//   * ProviderServicePlanCode - String - Service plan code in the subscription.
//   * ValidityPeriodCode - String - a validity period code
//   * Count - Number - Number of support plans in the subscription.
//   * PrimarySubscriptionNumber - String - Number of the basic subscription if a user is subscribed to a service plan add-on.
//   * SubscriptionType - EnumRef.ServiceSubscriptionsTypes - Subscription type.
//   * InvoiceNum - String - Proforma invoice number.
//   * PaymentInvoiceID - UUID - Proforma invoice ID.
Function SubscriberTariffSubscriptionProperties(SubscriptionNumber,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "subscription/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SubscriptionNumber);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	Renamings = IsInternal.RenamingSubscriptionPlan(True);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Result = IsInternal.RenameProperties(ResponseData.subscription, Renamings);
	If Result.Count = 0 Then
		Result.Count = 1;
	EndIf; 
	
	Return Result;
	
EndFunction

// Creates a subscription to the main subscriber's service plan.
// Implements the API method: account/customer_subscriptions/create.
//
// Parameters:
//  SubscriptionData_ - See NewSubscriptionTemplateForBasicPlan
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  Undefined, Structure - If subscribing succeeded:
//   * Number - String - Subscription number.
//   * DateOfExpiration - Date - Date the subscription was removed.
Function CreateSubscriptionToMainTariff(SubscriptionData_,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customer_subscriptions/create";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	PropertiesNames = IsInternal.SubscriptionCreationPropertyNames();
	For Each Item In PropertiesNames Do
		If SubscriptionData_.Property(Item.Key) And ValueIsFilled(SubscriptionData_[Item.Key]) Then
			QueryData.Insert(Item.Value, SubscriptionData_[Item.Key]);
		EndIf; 
	EndDo; 
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	If BasicResponseProperties.ResponseCode >=10200 And BasicResponseProperties.ResponseCode <= 10299 Then
		Renamings = IsInternal.RenamingAndCreatingSubscriptionToPricingPlan();
		Result = IsInternal.RenameProperties(ResponseData, Renamings);
		Result.Delete("general");
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;

EndFunction

// Creates one or more subscriptions to upgrade the current service plan.
// Implements the API method: account/customer_subscriptions/create_enhanced.
//
// Parameters:
//  TariffExtensionData - See NewSubscriptionTemplateForTariffExpansion
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  Undefined, ValueTable - If subscribing succeeded:
//   * Number - String - Subscription number.
//   * DateOfExpiration - Date - Date the subscription was removed.
Function CreateSubscriptionToTariffExtension(TariffExtensionData,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "account/customer_subscriptions/create_enhanced";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	
	PropertiesNames = IsInternal.SubscriptionCreationPropertyNames(True);
	For Each Item In PropertiesNames Do
		If TariffExtensionData.Property(Item.Key) And ValueIsFilled(TariffExtensionData[Item.Key]) Then
			QueryData.Insert(Item.Value, TariffExtensionData[Item.Key]);
		EndIf; 
	EndDo; 
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	If BasicResponseProperties.ResponseCode >=10200 And BasicResponseProperties.ResponseCode <= 10299 Then
		Renamings = IsInternal.RenamingAndCreatingSubscriptionToPricingPlan();
		Result = IsInternal.StructuresArrayIntoValueTable(ResponseData.subscription_info, Renamings);
	Else
		Result = Undefined;
	EndIf;
	
	Return Result;

EndFunction

// Returns a template for a new subscription to the subscriber main service plan.
//
// Returns:
//  Structure:
//   * MasterSubscriberCode - Number - Code (number) of the main subscriber.
//   * ServicedSubscriberCode - Number - Code (number) of the subscriber.
//   * ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//   * ProviderServicePlanCode - String - Service plan code in the subscription.
//   * ValidityPeriodCode - String - Code of the subscription validity period.
//   * ConnectionDate - Date - Date the user subscribed to the service plan.
//   * DateOfExpiration - Date - Date the service plan was canceled.
Function NewSubscriptionTemplateForBasicPlan() Export

	Template = New Structure;
	Template.Insert("MasterSubscriberCode", 0);
	Template.Insert("ServicedSubscriberCode", 0);
	Template.Insert("ServiceProviderPlanCode", "");
	Template.Insert("ProviderServicePlanCode", "");
	Template.Insert("ValidityPeriodCode", "");
	Template.Insert("ConnectionDate", '00010101');
	Template.Insert("DateOfExpiration", '00010101');
	
	Return Template;
	
EndFunction

// Returns a template for a subscription to an upgraded service plan.
//
// Returns:
//  Structure:
//   * MasterSubscriberCode - Number - Code (number) of the main subscriber.
//   * ServicedSubscriberCode - Number - Code (number) of the subscriber.
//   * ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//   * ProviderServicePlanCode - String - Service plan code in the subscription.
//   * ValidityPeriodCode - String - Code of the subscription validity period.
//   * ConnectionDate - Date - Date the user subscribed to the service plan.
//   * DateOfExpiration - Date - Date the service plan was canceled.
//   * PrimarySubscriptionNumber - String - Main service plan subscription number.
//   * Count - Number - Number of support plans in the subscription.
Function NewSubscriptionTemplateForTariffExpansion() Export
	
	Template = NewSubscriptionTemplateForBasicPlan();
	Template.Insert("PrimarySubscriptionNumber", "");
	Template.Insert("Count", 0);
	
	Return Template;
	
EndFunction

#EndRegion

#Region AccountingSystem

// Returns the list of accounting systems available to a user.
// Implements the API method: accounting_system/list.
//
// Parameters:
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  ValueTable - List of user's accounting systems:
//   * Code - Number - Accounting system code.
//   * Description - String - Accounting system name.
//   * OwnerCode - Number - Accounting system owner subscriber code.
//   * ImportingData - Boolean - Data import flag.
//   * LoginUserToUpload - String - Username for data import.
//   * ExportingData - Boolean - Data export flag.
//   * ExportingURL - String - Accounting system URL. Required for data export.
//   * ExportingUserLogin - String - Username for data export.
//
Function ListOfAccountingSystems(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "accounting_system/list";
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
		
	Renamings = IsInternal.RenamingAccountingSystem(Method);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.accounting_system, Renamings);
	
EndFunction

// Returns the properties of the subscriber's accounting system by the system code.
// Implements the API method: accounting_system/info.
//
// Parameters:
//  Code - Number - Accounting system code.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Structure - Accounting system properties:
//   * Code - Number - Accounting system code.
//   * Description - String - Accounting system name.
//   * LongDesc - String - Accounting system description.
//   * OwnerCode - Number - Accounting system owner subscriber code.
//   * ImportingData - Boolean - Data import flag.
//   * ImportingUserLogin - String - User login required for data import to a Service Manager.
//   * ImportingRules - ValueTable - Data export settings:
//     ** RuleCode - String - Data import rule code.
//     ** Address - String - Object address for data import.
//   * ExportingData - Boolean - Data export flag.
//   * ExportingURL - String - Accounting system URL. Required for data export.
//   * ExportingUserLogin - String - Username for data export. 
//   * ExportingRules - ValueTable - Data export rules:
//     ** RuleCode - String - Data export rule code.
//     ** RowID - UUID - Export rule line ID. 
//     ** ConditionCode - String - Data export rule criteria code.
//     ** Address - String - Object address for data export.
//     ** FastSending - Boolean - Instant export flag.
//     ** ScheduledExport - Boolean - Scheduled export flag.
//     ** SelectionBySupplier - Boolean - Flag indicating whether a filter by provider is applied.
//   * ResponseProcessingRules - ValueTable:
//     ** ExportingRuleLineId - UUID - Export rule line ID.
//     ** RuleCode - String - Respond processing rule code.
//     ** ResponseCodes - Array of Number - Response codes for calling the processing rule.
//   
Function AccountingSystemProperties(Code, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "accounting_system/info";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", Code);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingAccountingSystem(Method);
	
	Result = IsInternal.RenameProperties(ResponseData.accounting_system, Renamings);
	
	Result.ExportingRules = IsInternal.StructuresArrayIntoValueTable(
		Result.ExportingRules, IsInternal.RenamingAccountingSystemUploadRules());
		
	Result.ImportingRules = IsInternal.StructuresArrayIntoValueTable(
		Result.ImportingRules, IsInternal.RenamingAccountSystemUploadRules());
		
	Result.ResponseProcessingRules = IsInternal.StructuresArrayIntoValueTable(
		Result.ResponseProcessingRules, IsInternal.RenamingAccountSystemResponseProcessingRules());
	
	Return Result;
	
EndFunction

// Creates a new or updates the existing billing management system.
// Implements the API method: accounting_system/create_update_billing.
//
// Parameters:
//  UpdateCreationParameters - See NewSettingsForCreatingUpdatingBillingAccountSystem
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  Structure - Accounting system properties:
//   * Code - Number - Accounting system code.
//   * Description - String - Accounting system name.
//
Function CreateUpdateBillingAccountSystem(UpdateCreationParameters, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "accounting_system/create_update_billing";
	QueryData = IsInternal.QueryTemplate(Method);
	If ValueIsFilled(UpdateCreationParameters.AccountingSystemCode) Then
		QueryData.Insert("id", UpdateCreationParameters.AccountingSystemCode);
	EndIf; 
	QueryData.Insert("import_login", UpdateCreationParameters.ImportingUserLogin);
	QueryData.Insert("export_url", UpdateCreationParameters.ExportingURL);
	QueryData.Insert("export_login", UpdateCreationParameters.ExportingUserLogin);
	QueryData.Insert("export_password", UpdateCreationParameters.ExportingPassword);

	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails(
		"Code", Common.TypeDescriptionNumber(9, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("name", IsInternal.ColumnDetails(
		"Description", Common.StringTypeDetails(100)));
	
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	Result.Delete("general");
	
	Return Result;

EndFunction

// Returns a template for creating or updating a billing management system.
//
// Returns:
//  Structure - Parameter template.:
//   * ImportingUserLogin - String - User login required for data import to a Service Manager.
//   * ExportingUserLogin - String - User login required for data import to an accounting system.
//   * ExportingURL - String - Accounting system URL. Required for data export.
//   * ExportingPassword - String - User password required for data import to an accounting system. 
//   * AccountingSystemCode - Number - Code of the accounting system being updated.
//   								If not specified, a new accounting system is created.
Function NewSettingsForCreatingUpdatingBillingAccountSystem() Export

	Parameters = New Structure;
	Parameters.Insert("AccountingSystemCode", 0);
	Parameters.Insert("ImportingUserLogin", "");
	Parameters.Insert("ExportingURL", "");
	Parameters.Insert("ExportingUserLogin", "");
	Parameters.Insert("ExportingPassword", "");
	
	Return Parameters;
	
EndFunction

#EndRegion 

#Region Application

// Returns the list of applied configurations that are available to the app subscriber.
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//   
// Returns:
//  ValueTable - Available configurations.:
//    * Code - String - Configuration code.
//    * Description - String - Configuration synonym. 
//    * Name - String - Configuration name as it is set in Designer.
//    * LongDesc - String - Configuration details. 
//    * SubscriberCode - Number - Subscriber code. 
//
Function Configurations(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "application/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", Subscriber.Code);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("Code", Common.StringTypeDetails(9)));
	Renamings.Insert("name", IsInternal.ColumnDetails("Description", Common.StringTypeDetails(64)));
	Renamings.Insert("sysname", IsInternal.ColumnDetails("Name", Common.StringTypeDetails(255)));
	Renamings.Insert("description", IsInternal.ColumnDetails("LongDesc", Common.StringTypeDetails(0)));
	Renamings.Insert("account", IsInternal.ColumnDetails("SubscriberCode", 
		Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative)));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.application, Renamings);
	
EndFunction

#EndRegion

#Region Bill

// Returns the proforma invoice list.
// Implements the API method: bill/list.
// 
// Parameters:
//  Filter - See NewSelectionOfInvoicesForPayment
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  ValueTable - Proforma invoice list:
//	 * Number - String - Proforma invoice number.
//	 * Date - Date - Date the proforma invoice was created.
//	 * ChangeDate - Date - Date the proforma invoice was modified.
//	 * InvoiceId - UUID - Proforma invoice ID.
//	 * SellerCode - Number - Seller subscriber code (number).
//	 * BuyerSCode - Number - Customer subscriber code (number).
//	 * Sum - Number - Proforma invoice amount.
//	 * Renewal - Boolean - Prolongation flag.
//	 * PaymentURL - String - Payment link.
//	 * Paid - Boolean - Proforma invoice payment flag.
//	 * AdditionalInformation - String - Additional information on the proforma invoice.
//	 * Comment - String - Comment to the proforma invoice.
Function ListOfInvoices(Filter = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/list";
	QueryData = IsInternal.QueryTemplate(Method);
	
	If TypeOf(Filter) = Type("Structure") Then
		FilterFields = New Map;
		FilterFields.Insert("Seller", "seller_id");
		FilterFields.Insert("Customer", "customer_id");
		FilterFields.Insert("BeginOfPeriod", "start_date");
		FilterFields.Insert("EndOfPeriod", "end_date");
		For Each Item In FilterFields Do
			If Filter.Property(Item.Key) And ValueIsFilled(Filter[Item.Key]) Then
				QueryData.Insert(Item.Value, Filter[Item.Key]);
			EndIf; 
		EndDo; 
	EndIf; 
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.InvoiceRenamings(Method);
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.bill, Renamings);
	
EndFunction

// Returns the proforma invoice data by its number of ID.
// Implements the API method: bill/info.
//
// Parameters:
//  InvoiceId - UUID - Proforma invoice ID. Not passed if the proforma invoice number is passed.
//  AccountNumber - String - Proforma invoice number. Not passed if the proforma invoice ID is passed.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Structure - Proforma invoice parameters.:
//	 * Number - String - Proforma invoice number.
//	 * Date - Date - Date the proforma invoice was created.
//	 * ChangeDate - Date - Date the proforma invoice was modified.
//	 * InvoiceId - UUID - Proforma invoice ID.
//	 * SellerCode - Number - Seller subscriber code (number).
//	 * BuyerSCode - Number - Customer subscriber code (number).
//	 * Sum - Number - Proforma invoice amount.
//	 * Renewal - Boolean - Prolongation flag.
//	 * PaymentURL - String - Payment link.
//	 * Paid - Boolean - Proforma invoice payment flag.
//	 * AdditionalInformation - String - Additional information on the proforma invoice.
//	 * Comment - String - Comment to the proforma invoice.
//   * ServicePlans - ValueTable - Service plans:
//     ** ProviderServicePlanCode - String - Provider service plan code.
//     ** ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//     ** ValidityPeriodCode - String - Support plan validity code.
//     ** Count - Number - Number of support plans in the subscription.
//     ** Sum - Number - Service plan price for the given validity period.
//     ** NumberOfBaseDocument - String - Number of the parent subscription.
//   * Services - ValueTable - Services:
//     ** OperationService - String - Service description.
//     ** Sum - Number - Service price.
//   * Files - ValueTable - Current proforma invoice presentation files:
//     ** Id - UUID - File ID.
//     ** LongDesc - String - Proforma invoice presentation file name.
//   * AdditionalAttributes - ValueTable - Additional proforma invoice details:
//     ** Key - String - Additional attribute's name.
//     ** Type - String - Value type. 
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
//	 * State - Structure - Proforma invoice status data:
//     ** Error - Boolean - Error flag.
//     ** LongDesc - String - Status details.
//     ** Name - String - Statuses:
//         created
//         wait_sending
//         wait_registration
//         wait_payment
//         paid
//         billing_error
Function CustomerInvoiceDetails(InvoiceId = Undefined, AccountNumber = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/info";
	QueryData = IsInternal.QueryTemplate(Method);
	If Not IsBlankString(AccountNumber) Then
		QueryData.Insert("id", AccountNumber);
	ElsIf TypeOf(InvoiceId) = Type("UUID") 
		And InvoiceId <> CommonClientServer.BlankUUID() Then
		QueryData.Insert("bill_id", InvoiceId);
	EndIf; 
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.InvoiceRenamings(Method);
	Renamings.Insert("tariffs", "ServicePlans");
	Renamings.Insert("services", "Services");
	Renamings.Insert("files", "Files");
	Renamings.Insert("fields", "AdditionalAttributes");
	Renamings.Insert("status", "State");
	
	Result = IsInternal.RenameProperties(ResponseData.bill, Renamings);
	Result.ServicePlans = IsInternal.StructuresArrayIntoValueTable(Result.ServicePlans, IsInternal.RenamingInvoice());
	Result.Services = IsInternal.StructuresArrayIntoValueTable(Result.Services, IsInternal.RenamingServiceAccount());
	Result.Files = IsInternal.StructuresArrayIntoValueTable(Result.Files, IsInternal.RenamingAccountFiles());
	Result.AdditionalAttributes = IsInternal.StructuresArrayIntoValueTable(
		Result.AdditionalAttributes, IsInternal.RenamingAdditionalInformation());
	Result.State = IsInternal.RenameProperties(Result.State, IsInternal.RenamingAccountState());
	
	Return Result;

EndFunction

// Creates a proforma invoice.
// Implements the API method: bill/create.
// 
// Parameters:
//  InvoiceData - Structure:
//	 * InvoiceId - UUID - Proforma invoice ID.
//	 * SellerCode - Number - Seller subscriber code (number).
//	 * BuyerSCode - Number - Customer subscriber code (number).
//	 * Sum - Number - Proforma invoice amount.
//	 * Renewal - Boolean - Prolongation flag.
//	 * PaymentURL - String - Payment link.
//	 * Paid - Boolean - Proforma invoice payment flag.
//	 * AdditionalInformation - String - Additional information on the proforma invoice.
//	 * Comment - String - Comment to the proforma invoice.
//   * ServicePlans - ValueTable - Service plans:
//     ** ProviderServicePlanCode - String - Provider service plan code.
//     ** ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//     ** ValidityPeriodCode - String - Support plan validity code.
//     ** Count - Number - Number of support plans in the subscription.
//     ** Sum - Number - Service plan price for the given validity period.
//     ** NumberOfBaseDocument - String - Number of the parent subscription.
//   * Services - ValueTable - Services:
//     ** OperationService - String - Service description.
//     ** Sum - Number - Service price.
//   * Files - ValueTable - Current proforma invoice presentation files:
//     ** Id - UUID - File ID.
//     ** LongDesc - String - Name of the proforma invoice presentation file.
//   * AdditionalAttributes - ValueTable - Additional proforma invoice details:
//     ** Key - String - Additional attribute's name.
//     ** Type - String - Value type. Optional if the additional attribute can take only one value type.
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  Structure:
//   * Number - String - Proforma invoice number.
//   * InvoiceId - UUID - Proforma invoice ID.	
Function CreatePaymentInvoice(InvoiceData,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/create";
	QueryData = IsInternal.RequestDataForCreatingAndModifyingInvoiceForPayment(InvoiceData, Method);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	Result = New Structure;
	Result.Insert("Number");
	Result.Insert("InvoiceId", CommonCTL.BlankUUID());
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Renamings = IsInternal.RenamingAccountResultOfCreatingChange();
		IsInternal.RenameProperties(ResponseData, Renamings);
		FillPropertyValues(Result, ResponseData);
	EndIf;
	
	Return Result;
	
EndFunction

// Modifies the given proforma invoice.
// Implements the API method: bill/update.
// 
// Parameters:
//  InvoiceData - Structure:
//   * InvoiceId - UUID - Proforma invoice ID.
//   * SellerCode - Number - Seller subscriber code (number).
//	 * BuyerSCode - Number - Customer subscriber code (number).
//	 * Sum - Number - Proforma invoice amount.
//	 * Renewal - Boolean - Prolongation flag.
//	 * PaymentURL - String - Payment link.
//	 * Paid - Boolean - Proforma invoice payment flag.
//	 * AdditionalInformation - String - Additional information on the proforma invoice.
//	 * Comment - String - Comment to the proforma invoice.
//   * ServicePlans - ValueTable - Service plans:
//     ** ProviderServicePlanCode - String - Provider service plan code.
//     ** ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//     ** ValidityPeriodCode - String - Support plan validity code.
//     ** Count - Number - Number of support plans in the subscription.
//     ** Sum - Number - Service plan price for the given validity period.
//     ** NumberOfBaseDocument - String - Number of the parent subscription.
//   * Services - ValueTable - Services:
//     ** OperationService - String - Service description.
//     ** Sum - Number - Service price.
//   * Files - ValueTable - Current proforma invoice presentation files:
//     ** Id - UUID - File ID.
//     ** LongDesc - String - Proforma invoice presentation file name.
//   * AdditionalAttributes - ValueTable - Additional proforma invoice details:
//     ** Key - String - Additional attribute's name.
//     ** Type - String - Value type. Optional if the additional attribute can take only one value type.
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  Structure:
//   * Number - String - Number of the modified proforma invoice.
//   * InvoiceId - UUID - ID of the modified proforma invoice.	
Function ChangeInvoiceForPayment(InvoiceData,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/update";
	
	QueryData = IsInternal.RequestDataForCreatingAndModifyingInvoiceForPayment(InvoiceData, Method) ;
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, BasicResponseProperties.ResponseCode, BasicResponseProperties.Message);

	Result = New Structure;
	Result.Insert("Number");
	Result.Insert("InvoiceId", CommonCTL.BlankUUID());
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Renamings = IsInternal.RenamingAccountResultOfCreatingChange();
		IsInternal.RenameProperties(ResponseData, Renamings);
		FillPropertyValues(Result, ResponseData);
	EndIf;
	
	Return Result;
	
EndFunction	

// Returns a token that allows uploading a file to an existing proforma invoice.
// Implements the API method: bill/file_token/upload.
//
// Parameters:
//  ReceivingParameters - See NewOptionsForGettingFileUploadCoupon
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//  
// Returns:
//  Structure:
//  * AccountNumber - String - Proforma invoice number.
//  * InvoiceId - UUID - Proforma invoice ID.
//  * DataTransferDirection - String - File transfer direction is "upload".
//  * FileImportCoupon - String - File upload token.
//  * ImportURL - String - URL for uploading files with PUT method.
Function InvoiceForPaymentAndDownloadCoupon(ReceivingParameters,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/file_token/upload";
	QueryData = IsInternal.QueryTemplate(Method);
	If ReceivingParameters.Property("AccountNumber") Then
		AccountNumber = ReceivingParameters.AccountNumber;
	Else
		AccountNumber = "";
	EndIf; 
	If ReceivingParameters.Property("InvoiceId") Then
		InvoiceId = ReceivingParameters.InvoiceId;	
	Else
		InvoiceId = CommonClientServer.BlankUUID();
	EndIf; 
	If Not IsBlankString(AccountNumber) Then
		QueryData.Insert("id", AccountNumber);
	ElsIf TypeOf(InvoiceId) = Type("UUID") 
		And InvoiceId <> CommonClientServer.BlankUUID() Then
		QueryData.Insert("bill_id", InvoiceId);
	EndIf; 
	QueryData.Insert("name", ReceivingParameters.FileName);
	QueryData.Insert("size", ReceivingParameters.Size);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingInvoiceDownloadCoupon();
	Result = IsInternal.RenameProperties(ResponseData, Renamings);
	Result.Delete("general");
	
	Return Result;
	
EndFunction

// Create service plan subscriptions based on the proforma invoice.
// 
// Parameters:
//  CreationParameters - See NewParametersForCreatingTariffSubscriptionsBasedOnPaymentInvoice
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Array of String - Numbers of created subscriptions.
Function CreateTariffSubscriptionsBasedOnPaymentInvoice(CreationParameters, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Method = "bill/create_subscription";
	QueryData = IsInternal.QueryTemplate(Method);
	If CreationParameters.Property("AccountNumber") Then
		AccountNumber = CreationParameters.AccountNumber;
	Else
		AccountNumber = "";
	EndIf; 
	If CreationParameters.Property("InvoiceId") Then
		InvoiceId = CreationParameters.InvoiceId;
	Else
		InvoiceId = CommonClientServer.BlankUUID();
	EndIf; 
	If Not IsBlankString(AccountNumber) Then
		QueryData.Insert("id", AccountNumber);
	ElsIf TypeOf(InvoiceId) = Type("UUID") 
		And InvoiceId <> CommonClientServer.BlankUUID() Then
		QueryData.Insert("bill_id", InvoiceId);
	EndIf;
	 
	If ValueIsFilled(CreationParameters.ConnectionDate) Then
		QueryData.Insert("start", CreationParameters.ConnectionDate);
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
		
	CreatedSubscriptions = New ValueList;
	For Each Item In ResponseData.subscription Do
		CreatedSubscriptions.Add(Item.id);
	EndDo;
	
	CreatedSubscriptions.SortByValue();
	
	Return CreatedSubscriptions.UnloadValues();

EndFunction

// Returns a template for selecting proforma invoices.
// 
// Returns:
//  Structure:
//   * PeddlerCode - Number - Seller's subscriber code.
//   * BuyerSCode - Number - Subscriber (customer) code.
//   * BeginOfPeriod - Date - Period start date.
//   * EndOfPeriod - Date - Period end date. 
//   
Function NewSelectionOfInvoicesForPayment() Export

	SelectingInvoicesForPayment = New Structure;
	SelectingInvoicesForPayment.Insert("Seller", 0);
	SelectingInvoicesForPayment.Insert("Customer", 0);
	SelectingInvoicesForPayment.Insert("BeginOfPeriod", '00010101');
	SelectingInvoicesForPayment.Insert("EndOfPeriod", '00010101');
	
	Return SelectingInvoicesForPayment;
	
EndFunction

// Returns a template for a new proforma invoices.
//
// Returns:
//  Structure:
//   * InvoiceId - UUID - Proforma invoice ID.
//	 * SellerCode - Number - Seller subscriber code (number).
//	 * BuyerSCode - Number - Customer subscriber code (number).
//	 * Sum - Number - Proforma invoice amount.
//	 * Renewal - Boolean - Prolongation flag.
//	 * PaymentURL - String - Payment link.
//	 * Paid - Boolean - Proforma invoice payment flag.
//	 * AdditionalInformation - String - Additional information on the proforma invoice.
//	 * Comment - String - Comment to the proforma invoice.
//   * ServicePlans - ValueTable - Service plans:
//     ** ProviderServicePlanCode - String - Provider service plan code.
//     ** ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//     ** ValidityPeriodCode - String - Support plan validity code.
//     ** NumberOfBaseDocument - String - Number of the parent subscription.
//     ** Sum - Number - Service plan price for the given validity period.
//   * Services - ValueTable - Services:
//     ** OperationService - String - Service description.
//     ** Sum - Number - Service price.
//   * Files - ValueTable - Current proforma invoice presentation files:
//     ** Id - UUID - File ID.
//     ** LongDesc - String - Proforma invoice presentation file name.
//   * AdditionalAttributes - ValueTable - Additional proforma invoice details:
//     ** Key - String - Additional attribute's name.
//     ** Type - String - Value type. Optional if the additional attribute can take only one value type.
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
Function NewInvoiceTemplate() Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	
	InvoiceData = New Structure;
	InvoiceData.Insert("InvoiceId", New TypeDescription("UUID"));
	InvoiceData.Insert("SellerCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative));
	InvoiceData.Insert("BuyerSCode", Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative));
	InvoiceData.Insert("Sum", Common.TypeDescriptionNumber(31, 2, AllowedSign.Nonnegative));
	InvoiceData.Insert("Renewal", New TypeDescription("Boolean"));
	InvoiceData.Insert("PaymentURL", Common.StringTypeDetails(1024));
	InvoiceData.Insert("Paid", New TypeDescription("Boolean"));
	InvoiceData.Insert("AdditionalInformation", New TypeDescription("String"));
	InvoiceData.Insert("Comment", New TypeDescription("String"));
	
	InvoiceData.Insert("ServicePlans", NewPaymentInvoiceNumber());
	InvoiceData.Insert("Services", NewInvoiceNumber());
	InvoiceData.Insert("Files", NewInvoiceFile());
	InvoiceData.Insert("AdditionalAttributes", IsInternal.NewAdditionalInformation());
	
	Return InvoiceData;
	
EndFunction

// Returns a parameter template for getting a file upload token.
// 
// Returns:
//  Structure:
//   * AccountNumber - String - Proforma invoice number. Not passed if the proforma invoice ID is passed.
//   * InvoiceId - UUID - Proforma invoice ID. Not passed if the proforma invoice number is passed.
//   * FileName - String - File name including the extension.
//   * Size - String - File size in bytes.
Function NewOptionsForGettingFileUploadCoupon() Export

	Parameters = New Structure;
	Parameters.Insert("AccountNumber", "");
	Parameters.Insert("InvoiceId", CommonClientServer.BlankUUID());
	Parameters.Insert("FileName", "");
	Parameters.Insert("Size", 0);
	
	Return Parameters;

EndFunction

// Returns a template of parameters to create service plan subscriptions based on proforma invoices.
// 
// Returns:
//  Structure:
//   * AccountNumber - String - Proforma invoice number. Not passed if the proforma invoice ID is passed.
//   * InvoiceId - UUID - Proforma invoice ID. Not passed if the proforma invoice number is passed.
//   * ConnectionDate - Date - Activation date of created service plan subscriptions.
Function NewParametersForCreatingTariffSubscriptionsBasedOnPaymentInvoice() Export
	
	Parameters = New Structure;
	Parameters.Insert("AccountNumber", "");
	Parameters.Insert("InvoiceId", CommonClientServer.BlankUUID());
	Parameters.Insert("ConnectionDate", '00010101000000');
	
	Return Parameters;
	
EndFunction

// Returns a template of the proforma invoice "Tariffs" table.
// 
// Returns:
//  ValueTable - New proforma invoice subscription plans.:
// * ProviderServicePlanCode - String - The length is 9 characters.
// * ServiceProviderPlanCode - String - The length is 9 characters.
// * ValidityPeriodCode - String - The length is 10 characters.
// * Count - Number - Digit capacity is 10.0.
// * Sum  - Number - Digit capacity is 31.2.
// * NumberOfBaseDocument - String - Digit capacity is 9.
Function NewPaymentInvoiceNumber() Export
	
 	ServicePlans = New ValueTable;
	ServicePlans.Columns.Add("ProviderServicePlanCode", Common.StringTypeDetails(9));
	ServicePlans.Columns.Add("ServiceProviderPlanCode", Common.StringTypeDetails(9));
	ServicePlans.Columns.Add("ValidityPeriodCode", Common.StringTypeDetails(10));
	ServicePlans.Columns.Add("Count", Common.TypeDescriptionNumber(10,0));
	ServicePlans.Columns.Add("Sum", Common.TypeDescriptionNumber(31,2));
	ServicePlans.Columns.Add("NumberOfBaseDocument", Common.StringTypeDetails(9));
	
	Return ServicePlans;
	
EndFunction

// Returns a template of the proforma invoice "Services" table.
// 
// Returns:
//  ValueTable - New proforma invoice services.:
// * OperationService - String - The length is 1,000 characters.
// * Sum - Number - Digit capacity is 31.2.
Function NewInvoiceNumber() Export
	
	Services = New ValueTable;
	Services.Columns.Add("OperationService", Common.StringTypeDetails(1000));
	Services.Columns.Add("Sum",Common.TypeDescriptionNumber(31,2));
	
	Return Services;

EndFunction

// Returns a template of the proforma invoice "Files" table.
// 
// Returns:
//  ValueTable - New proforma invoice files.:
// * Id - UUID
// * LongDesc - String -The length is 150 characters.
Function NewInvoiceFile() Export
	
	Files = New ValueTable;
	Files.Columns.Add("Id", New TypeDescription("UUID"));
	Files.Columns.Add("LongDesc", Common.StringTypeDetails(150));
	
	Return Files;

EndFunction

#EndRegion

#Region Tenant

// Returns data of the application subscriber.
//
// Parameters:
//	User - CatalogRef.Users - User whose subscriber must be defined. If not specified, uses the current user.
//	Token - String - Key given to the infobase administrator to run the operation.
// 
// Returns:
//  Structure - Subscriber data.:
//    * Description - String - Subscriber description.
//    * Code - Number - Subscriber code.
//    * UserRole - EnumRef.SubscriberUsersRoles - Role of the active subscriber user.
//
Function SubscriberOfThisApplication(Val User = Undefined, Val Token = Undefined) Export
	
	Return ServiceProgrammingInterfaceCached.SubscriberOfThisApplication(User, Token);
	
EndFunction

// Returns the list of applications available to the subscriber user of this application. 
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  ValueTable - Available applications:
//   * Code - Number - Application code (number).
//   * Description - String - Description.
//   * SubscriberOwnerCode - Number - Code of the subscriber that owns the application.
//   * ConfigurationCode - String - Configuration code.
//   * ConfigurationVersion - String - Configuration version.
//   * ConfigurationDescription - String - Configuration description.
//   * ApplicationState - EnumRef.ApplicationsStates - Application status.
//   * ApplicationURL - String - App URL.
//   * TimeZone - String - Application time zone.
//
Function Applications(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	Renamings = IsInternal.RenamingApp();

	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.tenant, Renamings);

EndFunction

// Returns information about the specified application.
//
// Parameters:
//  ApplicationCode - String - Application code (an area number).
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Structure - Application properties:
//   * Code - Number - Application code (number).
//   * Description - String- Description.
//   * SubscriberOwnerCode - Number - Code of the subscriber that owns the application.
//   * ConfigurationCode - String - Configuration code.
//   * ConfigurationVersion - String - Configuration version.
//   * ConfigurationDescription - String - Configuration description.
//   * ApplicationState - EnumRef.ApplicationsStates - Application status.
//   * ApplicationURL - String - App URL.
//   * TimeZone - String - Application time zone.
//
Function ApplicationProperties(ApplicationCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ApplicationCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingApp();
	
	Return IsInternal.RenameProperties(ResponseData.tenant, Renamings);
	
EndFunction

// Returns a list of users who can access the specified application.
//
// Parameters:
//  ApplicationCode - Number - Application code (an area number).
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// 
// Returns:
//  ValueTable - Users who have access:
//   * Login - String - Username.
//   * Role - EnumRef.ApplicationUserRights - Right to use the current application in the Service Manager.
//
Function ApplicationUsers(ApplicationCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/users/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ApplicationCode);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;

	Renamings = New Map;
	Renamings.Insert("login", IsInternal.ColumnDetails("Login", Common.StringTypeDetails(50)));
	Renamings.Insert("role", IsInternal.ColumnDetails("Right", 
		New TypeDescription("EnumRef.ApplicationUserRights")));
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.user, Renamings);
	
EndFunction

// Sets the user with the specified username access to the given application. 
// Assigns the user the given role that allows to work in the application.
//
// Parameters:
//  AddingOptions - See NewOptionsForAddingUserToApplication
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - the result of setting access right to the application: True means the right is set up, False - an error occurred.
//
Function AddUserToApp(AddingOptions,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/users/add";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", AddingOptions.ApplicationCode);
	QueryData.Insert("login", AddingOptions.Login);
	QueryData.Insert("role", Enums.ApplicationUserRights.NameByValue(AddingOptions.Right));
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Denies the user with the specified username access to the specified application.
//
// Parameters:
//  Login - String - Username.
//  ApplicationCode - Number - an application code (an area number)
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - the result of canceling access right to the application: True means the right is canceled, False - an error occurred.
//
Function RemoveUserFromApp(Login, ApplicationCode,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/users/delete";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", ApplicationCode);
	QueryData.Insert("login", Login);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// The method creates a new application with the specified configuration.
//
// Parameters:
//  CreationParameters - See NewAppCreationOptions
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Structure - Result of creating the application:
//  * Code - Number - Application code (an area number).
//  * ApplicationState - EnumRef.ApplicationsStates - Application status.
//  * ApplicationURL - String - Application address.
//
Function CreateApp(CreationParameters,
		RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/create";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("application", CreationParameters.ConfigurationCode);
	QueryData.Insert("name", CreationParameters.Description);
	QueryData.Insert("timezone", CreationParameters.TimeZone);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = New Map;
	Renamings.Insert("id", IsInternal.ColumnDetails("Code", Common.TypeDescriptionNumber(7, 0, AllowedSign.Nonnegative)));
	Renamings.Insert("status", IsInternal.ColumnDetails("ApplicationState", New TypeDescription("EnumRef.ApplicationsStates")));
	Renamings.Insert("url", IsInternal.ColumnDetails("ApplicationURL", Common.StringTypeDetails(500)));
	
	If BasicResponseProperties.ResponseCode = 10200 Or BasicResponseProperties.ResponseCode = 10202 Then
		Result = Common.CopyRecursive(ResponseData.tenant);
		Result = IsInternal.RenameProperties(Result, Renamings);
	Else
		Result = New Structure;
		Result.Insert("Code", 0);
		Result.Insert("ApplicationState", Enums.ApplicationsStates.EmptyRef());
		Result.Insert("ApplicationURL", "");
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the list of the application backup copies.
// Implements the API method: tenant/backup/list.
//
// Returns:
//  ValueTable - Backup copy list:
//   * BackupIdentificator - String - Backup copy ID. The length is 36 characters.
//   * BackupTimestamp - Date - Time when the backup was created (DateTime).
//   * ForTechSupport - Boolean - Back up flag for the technical support.
//
Function ListOfApplicationBackups() Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tenant/backup/list";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", SaaSOperations.SessionSeparatorValue());
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result);

	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingApplicationBackups();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.backup, Renamings);
	
EndFunction
 
// Returns a parameter template for creating an application for the ServiceProgrammingInterface.CreateApplication method.
// 
// Returns:
//  Structure - Template of parameters to create an application:
//	 * Description - String - Application description.
//	 * ConfigurationCode - String - Configuration code (application type) 
//   * TimeZone - String - a working application time zone
Function NewAppCreationOptions() Export
	
	Parameters = New Structure;
	Parameters.Insert("Description", "");
	Parameters.Insert("ConfigurationCode", "");
	Parameters.Insert("TimeZone", "");
	
	Return Parameters;
	
EndFunction

// Returns a parameter template for adding a user into the app.
// Required for ServiceProgrammingInterface.AddUserToApplication.
// 
// Returns:
//  Structure - Template of parameters to add a user into the application:
//	 * ApplicationCode - String - Application description.
//	 * Login - String - Username. 
//   * Right - EnumRef.ApplicationUserRights - User right to the application in the Service Manager. 
//
Function NewOptionsForAddingUserToApplication() Export
	
	Parameters = New Structure;
	Parameters.Insert("ApplicationCode", 0);
	Parameters.Insert("Login", "");
	Parameters.Insert("Right", Enums.ApplicationUserRights.EmptyRef());
	
	Return Parameters;
	
EndFunction

#EndRegion

#Region Tariff

// Returns information about service tariff by the tariff code.
//
// Parameters:
//  ServicePlanCode - String - tariff code.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  Structure - Information about the service plan:
//   * Code - String - tariff code
//   * Description - String - a tariff description
//   * DescriptionForServiceOrganizations - String - Service plan details for the intermediary.
//   * DescriptionForSubscribers - FormattedDocument - tariff details for subscribers.
//   * ValidityStartDate - Date - a start date of a tariff.
//   * ValidityEndDate - Date - a tariff end date.
//   * ProlongationSubscriptionPeriod - Number - Grace period in days. Applicable if grace periods are enabled.
//   * ExtensionSubscriptionPeriod - Number - a period (in days) during which the extending subscription is valid.
//   * PeriodForAddingRenewingSubscription - Number - Period after a subscription is expired during which the user can activate a grace period.
//   * TariffExpansion - Boolean - indicates that tariff is an extension
//   * Paid - Boolean - indicates that you need to pay for the tariff because it contains paid validity periods.
//   * Test_ - Boolean - Test service plan flag.
//   * ThereIsCondition - Boolean - Flag indicating whether the service plan requires that the user accepts an End-User License Agreement.
//   * PeriodicPayment - Boolean - Recurring subscription flag.
//   * FrequencyOfPayment - String - Recurring period code.
//   * Services - ValueTable - Service plan services:
//     ** Code - String - a service code.
//     ** Description - String - Service description.
//     ** ServiceType - EnumRef.ServicesTypes - service type
//     ** LongDesc - String - Service details.
//     ** LicensesCount - Number - a number of licenses for a service included in tariff.
//     ** NumberOfAdditionalLicensesForExpandingSubscription - Number - Number of licenses provided by the extended subscription.
//     ** VendorID - String - Service provider ID.
//     ** SupplierName - String - Service provider description.
//   * Extensions - ValueTable - Service plan extensions:
//     ** Code - String - an extension tariff code
//     ** Description - String - an extension tariff description
//   * Configurations - ValueTable - Service plan configurations:
//     ** Code - String - Configuration code.
//     ** Description - String - a configuration name
//     ** LongDesc - String - Configuration details.
//   * ActionPeriods - ValueTable - Service plan validity periods:
//     ** Code - String - a validity period code
//     ** Description - String - a validity period description
//     ** Sum - Number - Price.
//     ** Comment - String - a comment to a validity period
//   * SubscriptionTerminationNotificationPeriods - ValueTable - Subscription expiration notification periods:
//     ** DaysCount - Number - Notification day count.
//
Function ServiceRate(ServicePlanCode, RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
		BasicResponseProperties.StatusCode = 200;
	EndIf;
	
	Try
		Result = ServiceProgrammingInterfaceCached.ServiceRate(ServicePlanCode);
		BasicResponseProperties.ResponseCode = 10200;
	Except
		If RaiseExceptionAtError Then
			Raise;
		Else
			Result = Undefined;
			BasicResponseProperties.ResponseCode = 10404;
			BasicResponseProperties.Message = CloudTechnology.ShortErrorText(ErrorInfo());
		EndIf; 
	EndTry;
	
	Return Result;
	
EndFunction

// Returns the list of service plans that are available to the subscriber of this application.
// Parameters:
//  Filter - See NewTariffsListFilter
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  ValueTable - Service plan list for the web service:
//   * Code - String - tariff code
//   * Description - String - a tariff description
//   * DescriptionForServiceOrganizations - String - Service plan details for the intermediary.
//   * DescriptionForSubscribers - FormattedDocument - tariff details for subscribers.
//   * ValidityStartDate - Date - a start date of a tariff.
//   * ValidityEndDate - Date - a tariff end date.
//   * ProlongationSubscriptionPeriod - Number - Grace period in days. Applicable if grace periods are enabled.
//   * ExtensionSubscriptionPeriod - Number - a period (in days) during which the extending subscription is valid.
//   * PeriodForAddingRenewingSubscription - Number - Period after a subscription is expired during which the user can activate a grace period.
//   * TariffExpansion - Boolean - indicates that tariff is an extension
//   * Paid - Boolean - indicates that you need to pay for the tariff because it contains paid validity periods.
//   * Test_ - Boolean - Test service plan flag.
//   * ThereIsCondition - Boolean - Flag indicating whether the service plan requires that the user accepts an End-User License Agreement.
//   * PeriodicPayment - Boolean - Recurring subscription flag.
//   * FrequencyOfPayment - String - Recurring period code.
//   * ActionPeriods - ValueTable - Validity periods. Populated if the ParameterGetValidPeriods receiving parameter is passed.:
//     ** Code - String - a validity period code
//     ** Description - String - a validity period description
//     ** Sum - Number - Price.
//     ** Comment - String - a comment to a validity period
//
Function ServiceRates(Filter = Undefined, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "tariff/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	If Filter = Undefined Then
		Filter = NewTariffsListFilter();
	EndIf; 
	
	QueryData = IsInternal.QueryTemplate(Method);
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	ValidityPeriodsField = "validity_periods";
	TariffField = "tariff";
		
	If Not IsBlankString(Filter.Description) Then
		QueryData.Insert("name", Filter.Description);
	EndIf;
	If InterfaceVersion >= 23 And Filter.AvailableServicePlans.Count() > 0 Then
		QueryData.Insert("available_tariffs", Filter.AvailableServicePlans);
	EndIf;
		
	If InterfaceVersion >= 19 Then
		If Filter.ReceivingParameters.Count() > 0 Then
			QueryData.Insert("scope", New Array);
			For Each String In Filter.ReceivingParameters Do
				If String = ParameterForGettingExtensionsOnly() And InterfaceVersion < 23 Then
					Continue;
				Else
					QueryData["scope"].Add(String);
				EndIf;
			EndDo;
		EndIf;
	EndIf;
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
		
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	If InterfaceVersion >= 19 And Not Filter.ReceivingParameters.Find(ParameterForGettingValidityPeriods()) = Undefined Then
		RenamingValidityPeriods = IsInternal.RenamesAndValidityPeriods();
		For Each Item In ResponseData[TariffField] Do
			Item[ValidityPeriodsField] = IsInternal.StructuresArrayIntoValueTable(
				Item[ValidityPeriodsField], RenamingValidityPeriods);
		EndDo; 
	EndIf;
	
	Renamings = IsInternal.RenamingRates();
	Result = IsInternal.StructuresArrayIntoValueTable(ResponseData[TariffField], Renamings);
	
	Return Result;
	
EndFunction

// Returns a template to filter the list of service owner's plans.
// 
// Returns:
//  Structure:
//    * Description - String - Filter by a part of the name.
//    * AvailableServicePlans - Array of String - Filter service plans by available service plan codes.
//    * ReceivingParameters - Array of String - May contain data import parameters that the following methods return
//     - See ParameterForGettingValidityPeriods
//     - See ParameterForGettingPaidOnly
//     - See ParameterForGettingExtensionsOnly
Function NewTariffsListFilter() Export
	
	Filter = New Structure;
	Filter.Insert("Description", "");
	Filter.Insert("ReceivingParameters", New Array);
	Filter.Insert("AvailableServicePlans", New Array);
	
	Return Filter;
	
EndFunction

// Function returns a template to filter the list of service provider plans.
// 
// Returns:
//  Structure:
//    * ServiceProviderCode - String - Intermediary code.
//    * AvailableServicePlans - Array of String - Filter service plans by available service plan codes.
//    * ReceivingParameters - Array of String - May contain data import parameters that the following methods return
//     - See ParameterForGettingValidityPeriods
//     - See ParameterForGettingExtensionsOnly
Function NewSelectionOfSupportCompanyTariffsList() Export
	
	Filter = New Structure;
	Filter.Insert("ServiceProviderCode", "");
	Filter.Insert("ReceivingParameters", New Array);
	Filter.Insert("AvailableServicePlans", New Array);
	
	Return Filter;
	
EndFunction
	
// Returns the service plan import parameter "Validity periods".
// 
// Returns:
//  String 
//
Function ParameterForGettingValidityPeriods() Export
	
	Return "validity_periods";
	
EndFunction

// Returns the service plan import parameter "Only paid".
// 
// Returns:
//  String 
Function ParameterForGettingPaidOnly() Export
	
	Return "is_payable";
	
EndFunction

// Returns the "Only extensions" service plan import parameter.
// 
// Returns:
//  String 
Function ParameterForGettingExtensionsOnly() Export
	
	Return "is_extension";
	
EndFunction

#EndRegion

#Region Subscription

// Returns the list of existing subscriptions of the current application subscriber.
//
// Parameters:
//  Filter - See NewPricingPlanSubscriptionSelection
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//
// Returns:
//  ValueTable - Existing subscriptions of the subscriber:
//   * SubscriberCode - Number - Subscriber code (number).
//   * Number - String - Subscription number.
//   * Date - Date - Subscription start date.
//   * SubscriptionType - EnumRef.ServiceSubscriptionsTypes - Subscription type.
//   * ServiceProviderCode - Number - Intermediary code (number).
//   * ConnectionDate - Date - Date the user subscribed to the service plan.
//   * DateOfExpiration - Date - Date the service plan was canceled.
//   * ServicePlanCode - String - Service plan code in the subscription.
//   * ServiceProviderPlanCode - String - Service plan code as per the intermediary.
//   * ValidityPeriodCode - String - Validity period code.
//   * Count - Number - Number of support plans in the subscription.
//   * PrimarySubscriptionNumber - String - Number of the basic subscription if a user is subscribed to a service plan add-on.
//   * InvoiceNum - String - Proforma invoice number.
//   * PaymentInvoiceID - UUID - Proforma invoice ID.
//
Function SubscriberSubscriptions(Filter = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "subscription/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	SubscriberCode = Subscriber.Code;
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode);
	
	If TypeOf(Filter) = Type("Structure") Then
		FilterFields = New Map;
		FilterFields.Insert("ActiveOnly", "active");
		FilterFields.Insert("MainOnly", "basic");
		FilterFields.Insert("BeginOfPeriod", "start_date");
		FilterFields.Insert("EndOfPeriod", "end_date");
		For Each Item In FilterFields Do
			If Filter.Property(Item.Key) And ValueIsFilled(Filter[Item.Key]) Then
				QueryData.Insert(Item.Value, Filter[Item.Key]);
			EndIf; 
		EndDo;
	Else
		Filter = NewPricingPlanSubscriptionSelection();
	EndIf; 
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingSubscriptionPlan(False);
	Result = IsInternal.StructuresArrayIntoValueTable(ResponseData.subscription, Renamings);
	
	InterfaceVersion = InterfaceVersionProperties().Version;
	
	FiltersEnabled = (Filter.MainOnly Or Filter.ActiveOnly 
						Or ValueIsFilled(Filter.BeginOfPeriod) Or ValueIsFilled(Filter.EndOfPeriod));
						 
	SessionDate = CurrentSessionDate();
	For IndexOf = 1 To Result.Count() Do
		String = Result[Result.Count() - IndexOf];
		If InterfaceVersion < 14 And FiltersEnabled Then // Backward compatibility.
			If (Filter.MainOnly And Not IsBlankString(String.PrimarySubscriptionNumber))
			 Or (Filter.ActiveOnly And String.DateOfExpiration < SessionDate) 
			 Or (ValueIsFilled(Filter.BeginOfPeriod) And String.Date < Filter.BeginOfPeriod) 
			 Or (ValueIsFilled(Filter.EndOfPeriod) And String.Date > Filter.EndOfPeriod) Then
				Result.Delete(String);
				Continue;
			EndIf;
		EndIf;
		If String.Count = 0 Then
			String.Count = 1;
		EndIf; 
	EndDo;
	
	Return Result;
	
EndFunction

// Returns a template for filtering subscriptions for subscribers' service plans.
// 
// Returns:
//  Structure:
//   * ServicedSubscriberCode - Number - Code (number) of the subscriber. 
//										   Not used if it is called for method SubscriberSubscriptions.
//   * ActiveOnly - Boolean - Get only active subscriptions.
//   * MainOnly - Boolean - Get only basic subscriptions.
//   * BeginOfPeriod - Date - Period start date.
//   * EndOfPeriod - Date - Period end date.
Function NewPricingPlanSubscriptionSelection() Export
	
	Filter = New Structure;
	Filter.Insert("ServicedSubscriberCode", 0);
	Filter.Insert("ActiveOnly", False);
	Filter.Insert("MainOnly", False);
	Filter.Insert("BeginOfPeriod", '00010101');
	Filter.Insert("EndOfPeriod", '00010101');
	
	Return Filter;
	
EndFunction

#EndRegion

#Region PromoCode

// Activates the given promo code for the current subscriber.
//
// Parameters:
//  PromoCode - String - Active promo code.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - usage result: True - a promo code is activated, False - an error occurred.
//
Function UsePromoCode(PromoCode,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "promo_code/activate";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	SubscriberCode = Subscriber.Code;
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode);
	QueryData.Insert("code", PromoCode);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Activates the given promo code for the current subscriber.
//
// Parameters:
//  PromoCode - String - Active promo code.
//  Label - String - Additional information on the promo code.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - Activation result. If True, the promo code is activated. If False, an error occurred.
//
Function UsePromoCodeWithTag(PromoCode, Label, 
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "promo_code/activate";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication();
	SubscriberCode = Subscriber.Code;
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", SubscriberCode);
	QueryData.Insert("code", PromoCode);
	QueryData.Insert("subid", Label);
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;

EndFunction

#EndRegion

#Region Sessions

// Closes user sessions.
// 
// Parameters:
// 	SessionsNumbers - Array of Number - Numbers of the sessions to be terminated.
// 	User - CatalogRef.Users - Subscriber user
// 	on whose behalf the operation is performed or infobase administrator ID.
// 	Token - String - Secret key used to run the operation on behalf of the infobase administrator.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
Procedure EndSessions(Val SessionsNumbers, Val User = Undefined, Val Token = Undefined,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "session/terminate";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	Subscriber = SubscriberOfThisApplication(User, Token);
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method);
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("account", Subscriber.Code);
	QueryData.Insert("tenant", SaaSOperations.SessionSeparatorValue());
	QueryData.Insert("user", "DummyUser");
	QueryData.Insert("id", SessionsNumbers);
	QueryData.Insert("auth", IsInternal.AuthorizationProperties(Subscriber.Code, User, Token));
	
	Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
EndProcedure

#EndRegion

#Region Task

// Returns the list of active tasks that are assigned to a Service Manager user and associated with the user's area.
// 
// Parameters:
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
//   
// Returns:
//  ValueTable:
//	* TaskNumber - String - Task number.
//	* TaskDescription - String - Task number.
Function Tasks(RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "task/list";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Renamings = IsInternal.RenamingUserTask();
	
	Return IsInternal.StructuresArrayIntoValueTable(ResponseData.task, Renamings);
	
EndFunction

// Returns the user task details.
// 
// Parameters:
//  TaskNumber - String - Number of the task whose details are required.
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Structure:
//   * type - String - Task type.
//   * author - String - Task author.
//   * description - String - Task details.
//   * tenant - String - Application description.
//   * subscriber - String - Master subscriber description (subscriber of the service provider or a hotline).
//   * backup_type - String - Backup type (for tech support or not).
Function TaskProperties(TaskNumber,
	RaiseExceptionAtError = True, BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "task/info";
	
	If BasicResponseProperties = Undefined Then
		BasicResponseProperties = NewBasicResponseProperties();
	EndIf;
	
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("id", TaskNumber);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	ResponseData = IsInternal.ExecutionResult(Result, RaiseExceptionAtError,
		BasicResponseProperties.StatusCode,
		BasicResponseProperties.ResponseCode,
		BasicResponseProperties.Message);
	
	If ResponseData = Undefined Then
		Return Undefined;
	EndIf;
	
	Return ResponseData.task;

EndFunction

// Whether the user accepted or rejected a task.
//
// Parameters:
//  QueryOptions - See NewTaskConfirmationParameters
//  RaiseExceptionAtError - Boolean - Flag indicating whether to raise an exception if an error occurs.
//  BasicResponseProperties - Structure - Return parameter:
//   * StatusCode - Number - Status code of an HTTP service response.
//   * ResponseCode - Number - Takes its value from the "general.response" property.
//   * Message - String - Takes its value from the "general.message" property.
// 
// Returns:
//  Boolean - the result of the task execution: True - the task is completed, False - an error occurred.
Function ExecuteTask(QueryOptions,
		RaiseExceptionAtError = True,  BasicResponseProperties = Undefined) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "task/execute";
	QueryData = IsInternal.QueryTemplate(Method);
	QueryData.Insert("result", QueryOptions.ConsentObtained);
	QueryData.Insert("id", QueryOptions.TaskNumber);
	QueryData.Insert("date_access", QueryOptions.AccessExpirationDate);
	QueryData.Insert("backup_id", QueryOptions.CopyID);
	QueryData.Insert("backup_existing", QueryOptions.ExistingCopy);
	
	Result = IsInternal.SendDataToServiceManager(QueryData, Method);
	IsInternal.ExecutionResult(Result, RaiseExceptionAtError, 
		BasicResponseProperties.StatusCode, 
		BasicResponseProperties.ResponseCode, 
		BasicResponseProperties.Message);
	
	If BasicResponseProperties.ResponseCode = 10200 Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Returns a parameter template for task confirmation.
//
// Returns:
//  Structure:
//   * ConsentObtained - Boolean - Access approval flag.
//   * TaskNumber - String - Number of the task being approved.
//   * AccessExpirationDate - Date - Expiration date for file access.
//   * CopyID - String - Existing copy ID.
//   * ExistingCopy - Boolean - Existing copy usage flag.
Function NewTaskConfirmationParameters() Export

	Parameters = New Structure;
	Parameters.Insert("ConsentObtained", False);
	Parameters.Insert("TaskNumber", "");
	Parameters.Insert("AccessExpirationDate");
	Parameters.Insert("CopyID");
	Parameters.Insert("ExistingCopy");

	Return Parameters;

EndFunction

#EndRegion

#Region Srv

#Region Files

// Gets the parameters for the chunk upload.
//
// Parameters:
//  FileName - String 
//  FileSize - Number
//  FileType - String
//  Owner - Arbitrary
// 
// Returns:
//  Structure:
//    * FileID - String
//    * Type - String
//    * Address - String
//    * Headers - Map of KeyAndValue:
//      ** Key - String
//      ** Value - String
Function StartMultipartUpload(FileName, FileSize, FileType, Owner) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/new_multipart";
	InterfaceType = "srv";

	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("name", FileName);
	QueryData.Insert("size", FileSize);
	If FileType = "DataAreaBackup" Then
		QueryData.Insert("type", "tenant_backup");
	Else
		Raise NStr("ru = 'Неизестный тип файла';
								|en = 'Unknown file type';");
	EndIf;
	QueryData.Insert("owner", Owner);
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	ResponseData = IsInternal.ExecutionResult(Result);
	
	Var_Headers = New Map;
	headers = Undefined;
	If ResponseData.Property("headers", headers) Then
		For Each Title In ResponseData.headers Do
			Separator = StrFind(Title, ":");
			Var_Headers.Insert(Left(Title, Separator - 1), Mid(Title, Separator + 1));
		EndDo;
	EndIf;
	
	Response = New Structure;
	Response.Insert("Type", ResponseData.type);
	Response.Insert("FileID", ResponseData.file_id);
	Response.Insert("Address", String(ResponseData.url));
	Response.Insert("Headers", Var_Headers);
	
	Return Response;
	
EndFunction

// Gets parameters for the next chunk.
//
// Parameters:
//  FileID - String
//  PartNumber - String
// 
// Returns:
//  Structure:
//    * Type - String
//    * Address - String
//    * Headers - Map of KeyAndValue:
//      ** Key - String
//      ** Value - String
Function NewPart(FileID, PartNumber) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/new_part";
	InterfaceType = "srv";
	
	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("file_id", FileID);
	QueryData.Insert("part_number", PartNumber);
	
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	Result = SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	ResponseData = IsInternal.ExecutionResult(Result);
	
	Headers = New Map;
	For Each Title In ResponseData.headers Do
		Separator = StrFind(Title, ":");
		Headers.Insert(Left(Title, Separator - 1), Mid(Title, Separator + 1));
	EndDo;
	
	Response = New Structure;
	Response.Insert("Type", ResponseData.type);
	Response.Insert("Address", ResponseData.url);
	Response.Insert("Headers", Headers);
	
	Return Response;
	
EndFunction

// Completes chunk upload.
//
// Parameters:
//  FileID - String
//  Parts - Array of String
Procedure CompleteMultipartUpload(FileID, Parts) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/complete_multipart"; 
	InterfaceType = "srv";
	
	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("file_id", FileID);
	QueryData.Insert("parts", Parts);
	
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData, , Parts.Count() * 60);
	
EndProcedure

// Cancels chunk upload.
//
// Parameters:
//  FileID - String
Procedure CancelMultipartUpload(FileID) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	Method = "files/abort_multipart";
	InterfaceType = "srv";
	
	QueryData = IsInternal.QueryTemplate(Method, InterfaceType);
	QueryData.Insert("file_id", FileID);
	
	Address = IsInternal.ExecutionAddressOfExternalSoftwareInterface(Method, InterfaceType);
	SaaSOperationsCTL.SendRequestToServiceManager("POST", Address, QueryData);
	
EndProcedure

#EndRegion

#EndRegion

// Returns a template of a respond main properties.
// 
// Returns:
// 	Structure:
// * StatusCode - Number - HTTP service response status code.
// * ResponseCode - Number - API respond code. 
// * Message - String - API message.
Function NewBasicResponseProperties() Export
	
	Properties = New Structure;
	Properties.Insert("StatusCode", 0);
	Properties.Insert("ResponseCode", 0);
	Properties.Insert("Message", "");

	Return Properties;

EndFunction

#EndRegion

#Region Internal

// Returns the description of an additional property value type by name.
//
// Parameters:
//  TypeName - String - Name of the additional property value type.
// 
// Returns:
//  TypeDescription - Value data type details.
Function ValueTypeOfAdditionalPropertyByName(TypeName) Export
	
	If TypeName = "string" Then
		Return Common.StringTypeDetails(1024);
	ElsIf TypeName = "decimal" Then
		Return Common.TypeDescriptionNumber(10);
	ElsIf TypeName = "date" Then
		Return Common.DateTypeDetails(DateFractions.DateTime);
	ElsIf TypeName = "boolean" Then
		Return New TypeDescription("Boolean");
	ElsIf TypeName = "subscriber" Then
		Return Common.TypeDescriptionNumber(12, 0, AllowedSign.Nonnegative);
	ElsIf TypeName = "service" Then
		Return Common.StringTypeDetails(9);
	ElsIf TypeName = "additional_value" Then
		Return Common.StringTypeDetails(255);
	ElsIf TypeName = "additional_value_group" Then
		Return Common.StringTypeDetails(255);
	ElsIf TypeName = "tariff" Then
		Return Common.StringTypeDetails(9);
	ElsIf TypeName = "service_provider_tariff" Then
		Return Common.StringTypeDetails(9);
	ElsIf TypeName = "user" Then
		Return Common.StringTypeDetails(32);
	ElsIf TypeName = "tariff_period" Then
		Return Common.StringTypeDetails(10);
	ElsIf TypeName = "subscription" Then
		Return Common.StringTypeDetails(9);
	Else
		Return Type("Undefined");
	EndIf;
	
EndFunction

// Populates the choice list for additional property values.
//
// Parameters:
//  ChoiceList - ValueList of String - Form choice list.
Procedure FillInListForSelectingValueTypesForAdditionalProperties(ChoiceList) Export

	IsInternal = ServiceProgrammingInterfaceInternal;
	TypesPresentation1 = IsInternal.PresentationsOfValueTypesForAdditionalInformation();
	For Each String In TypesPresentation1 Do
		NewRow = ChoiceList.Add();
		FillPropertyValues(NewRow, String);
	EndDo; 

EndProcedure

// Populates the conditional appearance of an additional property type field by its value.
//
// Parameters:
//  ConditionalAppearance - DataCompositionConditionalAppearance - Conditional appearance.
//  AttributeName - String - Attribute name.
//  FieldName - String - Field name.
//
Procedure SetAppearanceOfAdditionalPropertyTypeField(ConditionalAppearance, AttributeName, FieldName) Export
	
	IsInternal = ServiceProgrammingInterfaceInternal;
	TypesPresentation1 = IsInternal.PresentationsOfValueTypesForAdditionalInformation();
	
	For Each Item In TypesPresentation1 Do
		ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
		
		Item_Text = ConditionalAppearanceItem.Appearance.Items.Find("Text");
		Item_Text.Value = Item.Presentation;
		Item_Text.Use = True;
		
		DataFilterItem = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
		DataFilterItem.LeftValue  = New DataCompositionField(AttributeName);
		DataFilterItem.ComparisonType   = DataCompositionComparisonType.Equal;
		DataFilterItem.RightValue = Item.Value;
		DataFilterItem.Use  = True;
		
		AppearanceFieldItem = ConditionalAppearanceItem.Fields.Items.Add();
		AppearanceFieldItem.Field = New DataCompositionField(FieldName);
		AppearanceFieldItem.Use = True;
		
	EndDo;
	
EndProcedure

#EndRegion
