#Region Public

// Returns the 1C:SaaS Technology Library version.
//
// Returns:
//  String - a library version in the RR.{S|SS}.ZZ.CC format.
//
Function LibraryVersion() Export
	
	Return "2.0.12.15";
	
EndFunction

// Returns the version of a 1C:CTL extension.
//
// Returns:
//  String, Undefined - Library extension version. Undefined in the extension is not installed or disabled. 
//
Function LibraryExtensionVersion() Export

	Extensions = ConfigurationExtensions.Get(New Structure("Name", "fresh"),
		ConfigurationExtensionsSource.SessionApplied);

	If Not ValueIsFilled(Extensions) Then
		Return Undefined;
	EndIf;

	Return Extensions[0].Version;

EndFunction

#EndRegion

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Handlers of SSL subsystem events

// Called when enabling data separation by data area.
//
Procedure OnEnableSeparationByDataAreas() Export
	
	CheckIfConfigurationCanBeUsedInServiceModel();
	
EndProcedure

// Adds update handler procedures
// required by the subsystem to the Handlers list.
//
// Parameters:
//	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure RegisterUpdateHandlers(Handlers) Export
	
	If Common.DataSeparationEnabled() Then
		
		Handler = Handlers.Add();
		Handler.Version = "*";
		Handler.Procedure = "CloudTechnology.CheckIfConfigurationCanBeUsedInServiceModel";
		Handler.SharedData = True;
		Handler.ExecuteInMandatoryGroup = True;
		Handler.Priority = 99;
		Handler.ExclusiveMode = False;
		
	EndIf;
	
EndProcedure

// Checks whether the configuration can be used SaaS.
//  If the configuration cannot be used SaaS, generates an exception indicating
//  why the configuration cannot be used SaaS.
//
Procedure CheckIfConfigurationCanBeUsedInServiceModel() Export
	
	SubsystemsDetails = Common.SubsystemsDetails(); // Array of Structure
	DetailsSSL = Undefined;
	
	For Each SubsystemDetails In SubsystemsDetails Do
		
		If SubsystemDetails.Name = "StandardSubsystems" Then
			
			DetailsSSL = SubsystemDetails;
			Break;
			
		EndIf;
		
	EndDo;
	
	If DetailsSSL = Undefined Then
		
		Raise StrTemplate(
			NStr("ru = 'В конфигурацию не внедрена библиотека ""1С:Библиотека стандартных подсистем"".
                  |Без внедрения этой библиотеки конфигурация не может использоваться в модели сервиса.
                  |
                  |Для использования этой конфигурации в модели сервиса требуется внедрить библиотеку
                  |""1С:Библиотека стандартных подсистем"" версии не младше %1';
					|en = 'To run 1C:Enterprise applications in SaaS mode,
					|Standard Subsystems Library (SSL) is required.
					|The application you are using is missing SSL.
					|To run the application in SaaS mode,
					|install SSL version %1 or higher.';", Metadata.DefaultLanguage.LanguageCode),
			RequiredVersionSSL());
		
	Else
		
		SSLVersion = DetailsSSL.Version;
		
		If CommonClientServer.CompareVersions(SSLVersion, RequiredVersionSSL()) < 0 Then
			
			Raise StrTemplate(
				NStr("ru = 'Для использования конфигурации в модели сервиса с текущей версией библиотеки
                      |""1С:Библиотека технологии сервиса"" требуется обновить используемую версию
                      |библиотеки ""1С:Библиотека стандартных подсистем"".
                      |
                      |Используемая версия: %1, требуется версия не младше %2';
						|en = 'To run the 1C:Enterprise application in the SaaS mode,
						|you need to update the embedded SSL.
						|
						|The current SSL version is %1.
						|The required SSL version is %2 or higher.';", Metadata.DefaultLanguage.LanguageCode),
				SSLVersion, RequiredVersionSSL());
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Generates error details to pass via a web service
//
// Parameters:
//  ErrorInfo - ErrorInfo - information about the error
//   used as a base to create details.
//
// Returns:
//  XDTODataObject - {http://www.1c.ru/SaaS/ServiceCommon}ErrorDescription -
//   error details to be passed using a web service.
//
Function GetDescriptionOfWebServiceError(ErrorInfo) Export
	
	WriteLogEvent(NStr("ru = 'Выполнение операции web-сервиса';
									|en = 'Web service operation';", Common.DefaultLanguageCode()), EventLogLevel.Error, , ,
		DetailErrorDescription(ErrorInfo));
	
	ErrorDescription = XDTOFactory.Create(
		XDTOFactory.Type("http://www.1c.ru/SaaS/ServiceCommon", "ErrorDescription"));
		
	ErrorDescription.BriefErrorDescription = ShortErrorText(ErrorInfo);
	ErrorDescription.DetailErrorDescription = DetailedErrorText(ErrorInfo);
	
	Return ErrorDescription;
	
EndFunction

// Runs before an infobase update.
// 
// Parameters: 
//  ExecuteDeferredHandlers1 - Boolean
// 
// Returns:
//  Boolean
Function BeforeUpdateInfobase(ExecuteDeferredHandlers1 = False) Export
	
	If Not Common.DataSeparationEnabled() 
		Or SaaSOperations.SeparatedDataUsageAvailable() Then
		
		Return False;
		
	EndIf;
		
	FreshExtension = Undefined;

	For Each Extension In ConfigurationExtensions.Get(New Structure("Name", "fresh"), ConfigurationExtensionsSource.Database) Do
		
		FreshExtension = Extension;
		Break;
		
	EndDo;
	
	DataFromSuppliedFreshExtension = GetCommonTemplate("fresh");
	InstallFreshExtension = False;
	
	If FreshExtension = Undefined Then
		
		InstallFreshExtension = True;
		
	Else
		
		MetadataOfSuppliedFreshExtension = New ConfigurationMetadataObject(DataFromSuppliedFreshExtension);
		MetadataOfInstalledFreshExtension = New ConfigurationMetadataObject(FreshExtension.GetData());
		
		If Not FreshExtension.Active
			Or FreshExtension.SafeMode
			Or FreshExtension.UnsafeActionProtection.UnsafeOperationWarnings
			Or FreshExtension.UseDefaultRolesForAllUsers
			Or CommonClientServer.CompareVersions(MetadataOfSuppliedFreshExtension.Version, MetadataOfInstalledFreshExtension.Version) > 0 Then
			
			FreshExtension.Delete();
			InstallFreshExtension = True;	
			
		EndIf;
		
	EndIf;
	
	If InstallFreshExtension Then
				
		FreshExtension = ConfigurationExtensions.Create();
		
		StructureOfExtensionDetails = New Structure();	
		StructureOfExtensionDetails.Insert("SafeMode", False);
		ProtectionAgainstDangerousActionsDoNotWarn = New UnsafeOperationProtectionDescription();
		ProtectionAgainstDangerousActionsDoNotWarn.UnsafeOperationWarnings = False;
		StructureOfExtensionDetails.Insert("UnsafeActionProtection", ProtectionAgainstDangerousActionsDoNotWarn);
		StructureOfExtensionDetails.Insert("UseDefaultRolesForAllUsers", False);	
		FillPropertyValues(FreshExtension, StructureOfExtensionDetails);

		FreshExtension.Write(DataFromSuppliedFreshExtension);
			
		ParametersOfUpdate = InfobaseUpdateInternal.ParametersOfUpdate();
		ParametersOfUpdate.ExecuteDeferredHandlers1 = ExecuteDeferredHandlers1;
			
		IBLock = New Structure;
		IBLock.Insert("Use", True);
		IBLock.Insert("SeamlessUpdate", False);
		IBLock.Insert("DebugMode", False);
		
		ParametersOfUpdate.IBLockSet = IBLock;
	  	
		ParametersForUpdateTask = New Array;
		ParametersForUpdateTask.Add(ParametersOfUpdate);
		
		SetExclusiveMode(True);
		
		StartDate = CurrentSessionDate();
		
		UpdateJob = CompleteTaskWithExtensions("InfobaseUpdateInternal.UpdateInfobase", ParametersForUpdateTask);
		UpdateJob = UpdateJob.WaitForExecutionCompletion();
		
		SetExclusiveMode(False);
		
		If UpdateJob.State = BackgroundJobState.Failed Then
			
			Raise DetailedErrorText(UpdateJob.ErrorInfo);
			
		ElsIf UpdateJob.State = BackgroundJobState.Canceled Then
			
			Raise NStr("ru = 'Фоновое задание обновления информационной базы отменено';
									|en = 'Background job canceled: Infobase update';");
			
		EndIf;	
		
		EndDate = CurrentSessionDate();
		InfobaseUpdateInternal.WriteUpdateExecutionTime(StartDate, EndDate);
	
		RefreshReusableValues();
		
		Return True;
		
	EndIf;
	
	Return False;
			
EndFunction

// Run a task with extensions.
// 
// Parameters:
//  JobName - String
//  Parameters - Array of Arbitrary
//  Var_Key - Undefined - Key.
//  Description - String
// 
// Returns:
//  BackgroundJob
Function CompleteTaskWithExtensions(JobName, Parameters, Var_Key = Undefined, Description = Undefined) Export
	
	//@skip-warning ObsoleteMethod - Implementation feature.
	Return ConfigurationExtensions.ExecuteBackgroundJobWithDatabaseExtensions(
		JobName, Parameters, Var_Key, Description);
	
EndFunction

// Detailed error text.
// 
// Parameters:
//  ErrorInfo - ErrorInfo
// 
// Returns:
//  String - Detailed error text.
Function DetailedErrorText(ErrorInfo) Export
	
	Return ErrorProcessing.DetailErrorDescription(ErrorInfo);

EndFunction

// Brief error text.
// 
// Parameters:
//  ErrorInfo - ErrorInfo
// 
// Returns:
//  String - Brief error text.
Function ShortErrorText(ErrorInfo) Export
	
	Return ErrorProcessing.BriefErrorDescription(ErrorInfo);

EndFunction

#EndRegion

#Region Private

// Returns the earliest supported 1C:Standard Subsystems Library version.
//
// Returns:
//   String - a library version in the RR.{S|SS}.ZZ.CC format.
//
Function RequiredVersionSSL()

	Return "3.1.1.1";

EndFunction

#EndRegion
