///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "Application update" subsystem.
// CommonModule.GetApplicationUpdatesClientServer.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

Function IsReturnCodeOfSystemPoliciesRestriction(ReturnCode) Export
	
	Return (ReturnCode = 1625 Or ReturnCode = 1643 Or ReturnCode = 1644);
	
EndFunction

Function Is64BitApplication() Export
	
	SystInfo = New SystemInfo;
	Return (SystInfo.PlatformType = PlatformType.Windows_x86_64
		Or SystInfo.PlatformType = PlatformType.Linux_x86_64
		Or SystInfo.PlatformType = PlatformType.MacOS_x86_64);
	
EndFunction

////////////////////////////////////////////////////////////////////////////////
// Directories for working with updates.

#If Not WebClient Then

Function OneCEnterprisePlatformInstallationDirectory(VersionNumber) Export
	
	ProgramDataDirectory = SystemDirectory(35);
	
	ConfigurationFilePath = ProgramDataDirectory + "1C\1CEStart\1CEStart.cfg";
	FileSpecifier = New File(ConfigurationFilePath);
	If Not FileSpecifier.Exists() Then
		Return Undefined;
	EndIf;
	
	// Reading installation directories and searching for platform installation directories
	TextReader = New TextReader(ConfigurationFilePath);
	ReadString = TextReader.ReadLine();
	While ReadString <> Undefined Do
		If Upper(Left(ReadString, 17)) = "INSTALLEDLOCATION" Then
			SetupDirectoryPath = Mid(ReadString, 19);
			If Not IsBlankString(SetupDirectoryPath) Then
				PlatformVersionDirectoryPath = SetupDirectoryPath
					+ ?(Right(SetupDirectoryPath, 1) = "\", "", "\")
					+ VersionNumber + "\bin\";
				FileSpecifier = New File(PlatformVersionDirectoryPath);
				If FileSpecifier.Exists() Then
					TextReader.Close();
					Return PlatformVersionDirectoryPath;
				EndIf;
			EndIf;
		EndIf;
		ReadString = TextReader.ReadLine();
	EndDo;
	
	TextReader.Close();
	
	Return Undefined;
	
EndFunction

Function DirectoryToWorkWithPlatformUpdates() Export
	
	AppDataDirectory = SystemDirectory(28);
	DirectoryPath = AppDataDirectory + ?(Right(AppDataDirectory, 1) = "\", "", "\")
		+ "1C\1Cv8PlatformUpdate";
	
	FileSpecifier = New File(DirectoryPath);
	If Not FileSpecifier.Exists() Then
		CreateDirectory(DirectoryPath);
	EndIf;
	
	Return DirectoryPath + "\";
	
EndFunction

Function DirectoryToWorkWithConfigurationUpdates()
	
	AppDataDirectory = SystemDirectory(28);
	DirectoryPath = AppDataDirectory + ?(Right(AppDataDirectory, 1) = "\", "", "\")
		+ "1C\1Cv8ConfigUpdate";
	
	FileSpecifier = New File(DirectoryPath);
	If Not FileSpecifier.Exists() Then
		CreateDirectory(DirectoryPath);
	EndIf;
	
	Return DirectoryPath + "\";
	
EndFunction

// Returns the directory for saving patch files considering the user's operating system.
//
// Parameters:
//  IsWindowsClient - Boolean
//
// Returns:
//  String
//
Function DirectoryForWorkWithPatches(IsWindowsClient)
	
	Separator     = GetPathSeparator();
	ShouldCheckAccess = False;
	
	If IsWindowsClient Then
		DirectoryPath = CommonClientServer.AddLastPathSeparator(SystemDirectory(28));
	Else
		DirectoryPath    = TempFilesDir(); // ACC:495 - Cannot auto-delete temporary directories.
		ShouldCheckAccess = True;
	EndIf;
	DirectoryPath = DirectoryPath + StrReplace("1C|1Cv8ConfigUpdate|Patches|", "|", Separator);
	
	// An attempt to create a directory.
	Try
		
		FileSpecifier = New File(DirectoryPath);
		If Not FileSpecifier.Exists() Then
			CreateDirectory(DirectoryPath);
		ElsIf ShouldCheckAccess Then
			
			FileName = DirectoryPath + "test.txt";
			
			Record = New TextWriter(FileName);
			Record.Close();
			
			DeleteFiles(FileName);
			
		EndIf;
		
	Except
		DirectoryPath = CommonClientServer.AddLastPathSeparator(
			GetTempFileName(""));
		CreateDirectory(DirectoryPath);
	EndTry;
	
	Return DirectoryPath;
	
EndFunction

Function TemplatesDirectory()
	
	DirectoryName = SystemDirectory(26);
	DefaultDirectory = DirectoryName + "1C\1Cv8\tmplts\";
	FileName = DirectoryName + "1C\1CEStart\1CEStart.cfg";
	If Not FileExists(FileName) Then
		Return DefaultDirectory;
	EndIf;
	
	Text = New TextReader(FileName, TextEncoding.UTF16);
	Page1 = "";
	While Page1 <> Undefined Do
		
		Page1 = Text.ReadLine();
		If Page1 = Undefined Then
			Break;
		EndIf;
		
		If StrFind(Upper(Page1), Upper("ConfigurationTemplatesLocation")) = 0 Then
			Continue;
		EndIf;
		
		SeparatorPosition = StrFind(Page1, "=");
		If SeparatorPosition = 0 Then
			Continue;
		EndIf;
		
		FoundDirectory = Mid(Page1, SeparatorPosition + 1);
		If Right(FoundDirectory, 1) <> "\" Then
			FoundDirectory = FoundDirectory + "\";
		EndIf;
		
		Return ?(FileExists(FoundDirectory), FoundDirectory, DefaultDirectory);
		
	EndDo;
	
	Return DefaultDirectory;

EndFunction

Function FileExists(FilePath, IsDirectory = Undefined, Size = Undefined) Export
	
	Specifier = New File(FilePath);
	If Not Specifier.Exists() Then
		Return False;
	ElsIf IsDirectory = Undefined Then
		Return (Size = Undefined Or Specifier.IsDirectory() Or Specifier.Size() = Size);
	Else
		Return (Specifier.IsDirectory() = IsDirectory
			And (IsDirectory Or Size = Undefined Or Specifier.Size() = Size));
	EndIf;
	
EndFunction

Function SystemDirectory(Id)
	
	// ACC:574-off Mobile client doesn't use this code.
	
	SystemInfo = New SystemInfo;
	If SystemInfo.PlatformType = PlatformType.Windows_x86
		Or SystemInfo.PlatformType = PlatformType.Windows_x86_64 Then
		
		App = New COMObject("Shell.Application");
		Folder = App.Namespace(Id);
		Result = Folder.Self.Path;
		
		Return ?(Right(Result, 1) = "\", Result, Result + "\");
		
	Else
		// ACC:495-off - Cannot auto-delete temporary directories.
		Return CommonClientServer.AddLastPathSeparator(TempFilesDir());
		// ACC:495-on
	EndIf;
	
	// ACC:574-on
	
EndFunction

#EndIf

////////////////////////////////////////////////////////////////////////////////
// Implementing the context of receiving and installing application updates.

#If Not WebClient Then

Function NewContextOfGetAndInstallUpdates(Parameters) Export
	
	UpdateFilesDetails = Parameters.UpdateFilesDetails;
	
	Result = New Structure;
	Result.Insert("ErrorName"                , "");
	Result.Insert("Message"                , "");
	Result.Insert("ErrorInfo"       , "");
	Result.Insert("MessageForTechSupport"    , "");
	Result.Insert("Completed"                , False);
	Result.Insert("PlatformVersion"          , UpdateFilesDetails.PlatformVersion);
	Result.Insert("CurrentUpdateIndex" , 0);
	Result.Insert("CurrentPatchIndex", 0);
	Result.Insert("ReceivedFilesVolume"    , 0);
	
	Result.Insert("Progress", 0);
	If Parameters.UpdateConfiguration Then
		Result.Insert("ConfigurationUpdates", UpdateFilesDetails.ConfigurationUpdates);
		Result.Insert("ConfigurationUpdateCount", Result.ConfigurationUpdates.Count());
	Else
		Result.Insert("ConfigurationUpdates", New Array);
		Result.Insert("ConfigurationUpdateCount", 0);
	EndIf;
	
	If Parameters.InstallPatches Then
		Result.Insert("Corrections"          , UpdateFilesDetails.Corrections);
		Result.Insert("RevokedPatches", UpdateFilesDetails.RevokedPatches);
	Else
		Result.Insert("Corrections"          , New Array);
		Result.Insert("RevokedPatches", New Array);
	EndIf;
	
	Result.Insert("PatchesInstalled", False);
	
	FilesCount = 0;
	FilesVolume      = 0;
	If Not Parameters.UpdatePlatform Or IsBlankString(Result.PlatformVersion) Then
		Result.Insert("UpdatePlatform", False);
	Else
		Result.Insert("UpdatePlatform", True);
		FilesCount = FilesCount + 1;
		FilesVolume      = FilesVolume + UpdateFilesDetails.PlatformUpdateSize;
	EndIf;
	Result.Insert("ProtocolFilePath", "");
	
	If Result.ConfigurationUpdates.Count() > 0 Then
		
		Result.Insert("TempDirectoryOfConfigurationUpdates",
			DirectoryToWorkWithConfigurationUpdates());
		Result.Insert("FilesIndexDirectory",
			Result.TempDirectoryOfConfigurationUpdates + "FileIndex\");
		Result.Insert("TemplatesDirectory", TemplatesDirectory());
		
		For Each CurrUpdate In Result.ConfigurationUpdates Do
			
			FilesCount = FilesCount + 1;
			FilesVolume      = FilesVolume + CurrUpdate.FileSize;
			CurrUpdate.Insert("ReceivedEmails"           , False);
			CurrUpdate.Insert("DistributionPackageDirectory", Result.TemplatesDirectory + CurrUpdate.TemplatesSubdirectory);
			CurrUpdate.Insert("CFUFileDirectoryInDistributionPackagesDirectory",
				CurrUpdate.DistributionPackageDirectory + CurrUpdate.CfuSubdirectory);
			CurrUpdate.Insert("FullNameOfCFUFileInDistributionDirectory",
				CurrUpdate.DistributionPackageDirectory + CurrUpdate.RelativeCFUFilePath);
			CurrUpdate.Insert("IndexFileName",
				StrReplace(CurrUpdate.TemplatesSubdirectory, "\", "_") + "_"
					+ StrReplace(StrReplace(CurrUpdate.RelativeCFUFilePath, "\", "_"), ".", "_")
					+ ".txt");
			
		EndDo;
		
	Else
		
		Result.Insert("TempDirectoryOfConfigurationUpdates", "");
		Result.Insert("FilesIndexDirectory"                  , "");
		Result.Insert("TemplatesDirectory"                       , "");
		
	EndIf;
	
	If Parameters.InstallPatches Then
		Result.Insert("DirectoryForWorkWithPatches",
			DirectoryForWorkWithPatches(Parameters.IsWindowsClient));
		// Deleting patch files that were created more than 90 days ago.
		
		// ACC:143-off The time zone does not matter.
		DeleteObsoleteFiles(
			Result.DirectoryForWorkWithPatches,
			CurrentDate() - 7776000); // 7776000 = 60 * 60 * 24 * 90.
		// ACC:143-on
	Else
		Result.Insert("DirectoryForWorkWithPatches", "");
	EndIf;
	
	FilesCount = FilesCount + Result.Corrections.Count();
	For Each CurPatch In Result.Corrections Do
		FilesVolume = FilesVolume + CurPatch.Size;
		CurPatch.ReceivedFileName =
			Result.DirectoryForWorkWithPatches + CurPatch.Name
				+ StrReplace(
					StrReplace(
						StrReplace(
							CurPatch.Checksum,
							"=",
							"_e_"),
						"/",
						"_s_"),
					"+",
					"_p_")
				+ ".zip";
		CurPatch.ReceivedEmails = FileExists(CurPatch.ReceivedFileName, False, CurPatch.Size);
	EndDo;
	
	Result.Insert("PlatformUpdateInstalled", False);
	Result.Insert("PlatformDistributionPackageDirectory"  , "");
	Result.Insert("PlatformUpdateFileURL"   , UpdateFilesDetails.PlatformUpdateFileURL);
	Result.Insert("PlatformUpdateSize"     , UpdateFilesDetails.PlatformUpdateSize);
	Result.Insert("PlatformInstallationCanceled"    , 0);
	Result.Insert("InstallerReturnCode" , 0);
	
	Result.Insert("FilesCount"       , FilesCount);
	Result.Insert("FilesVolume"            , FilesVolume);
	Result.Insert("UpdateFilesReceived", False);
	Result.Insert("CurrentAction1",
		StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Подготовка к получению обновления...';
				|en = 'Preparing to receive the update…';"),
			FilesCount));
	
	Return Result;
	
EndFunction

Procedure DeleteObsoleteFiles(Directory, UpdateDate)
	
	FilesInDirectory = FindFiles(Directory);
	FilesChecked  = 0;
	FilesProcessed = 0;
	FilesNamesWithDeletionErrors = New Array;
	DeletionErrorDetails = "";
	For Each CurFile In FilesInDirectory Do
		
		FilesChecked = FilesChecked + 1;
		If CurFile.GetModificationTime() < UpdateDate Then
			
			Try
				DeleteFiles(CurFile.FullName);
			Except
				FilesNamesWithDeletionErrors.Add(CurFile.FullName);
				If IsBlankString(DeletionErrorDetails) Then
					DeletionErrorDetails = ErrorProcessing.DetailErrorDescription(
						ErrorInfo());
				EndIf;
			EndTry;
			
			FilesProcessed = FilesProcessed + 1;
			
		EndIf;
		
		If FilesProcessed >= 100 Or FilesChecked >= 1000 Then
			// Attempt to batch-delete files. Undeleted files will be processed during the next update.
			// 
			Break;
		EndIf;
		
	EndDo;
	
	If FilesNamesWithDeletionErrors.Count() > 0 Then
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось удалить устаревшие файлы исправлений (патчей):
					|%1
					|%2';
					|en = 'Cannot delete obsolete patch files:
					|%1
					|%2';"),
				StrConcat(FilesNamesWithDeletionErrors, Chars.LF),
				DeletionErrorDetails));
	EndIf;
	
EndProcedure

Function ConfigurationUpdateReceived(RefreshEnabled, Context) Export
	
	If RefreshEnabled.ReceivedEmails Then
		
		Return True;
		
	ElsIf Not FileExists(RefreshEnabled.FullNameOfCFUFileInDistributionDirectory, False)
		Or IsBlankString(RefreshEnabled.Checksum) Then
		
		Return False;
		
	Else
		
		// Check checksums.
		#If Not ThinClient Then
		
		// ACC:574-off Mobile client doesn't use this code.
		
		Hashing = New DataHashing(HashFunction.MD5);
		Hashing.AppendFile(RefreshEnabled.FullNameOfCFUFileInDistributionDirectory);
		Try
			If RefreshEnabled.Checksum <> Base64String(Hashing.HashSum) Then
				Return False;
			Else
				RefreshEnabled.ReceivedEmails = True;
				Return True;
			EndIf;
		Except
			GetApplicationUpdatesServerCall.WriteErrorToEventLog(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return False;
		EndTry;
		
		// ACC:574-on
		
		#Else
		
		Try
			
			FullIndexFileName = Context.FilesIndexDirectory + RefreshEnabled.IndexFileName;
			If Not FileExists(FullIndexFileName, False) Then
				Return False;
			EndIf;
			
			TextReader = New TextReader(FullIndexFileName);
			CurRow = TextReader.ReadLine();
			If CurRow = Undefined
				Or CurRow <> RefreshEnabled.FullNameOfCFUFileInDistributionDirectory Then
				Return False;
			EndIf;
			
			CurRow = TextReader.ReadLine();
			If CurRow = Undefined
				Or CurRow <> RefreshEnabled.Checksum Then
				Return False;
			EndIf;
			
			UpdateFileSpecifier = New File(RefreshEnabled.FullNameOfCFUFileInDistributionDirectory);
			CurRow = TextReader.ReadLine();
			If CurRow = Undefined
				Or CurRow <> String(UpdateFileSpecifier.Size()) Then
				Return False;
			EndIf;
			
			CurRow = TextReader.ReadLine();
			If CurRow = Undefined
				Or CurRow <> String(UpdateFileSpecifier.GetModificationUniversalTime()) Then
				Return False;
			EndIf;
			
			TextReader.Close();
			RefreshEnabled.ReceivedEmails = True;
			Return True;
			
		Except
			GetApplicationUpdatesServerCall.WriteErrorToEventLog(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			Return False;
		EndTry;
		
		#EndIf
		
	EndIf;
	
EndFunction

Procedure CreateDirectoriesToGetUpdate(RefreshEnabled, Context) Export
	
	TempDirectoryOfConfigurationUpdates = Context.TempDirectoryOfConfigurationUpdates;
	Try
		CreateDirectory(TempDirectoryOfConfigurationUpdates);
	Except
		
		ErrorInfo = ErrorInfo();
		LogMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при создании каталога для сохранения дистрибутива конфигурации (%1).';
					|en = 'An error occurred while creating the directory to save configuration distribution (%1).';"),
				TempDirectoryOfConfigurationUpdates)
			+ Chars.LF
			+ ErrorProcessing.DetailErrorDescription(ErrorInfo);
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName = "FileSystemOperationError";
		Context.ErrorInfo = LogMessage;
		Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось создать каталог %1 для сохранения дистрибутива конфигурации. %2';
				|en = 'Cannot create the %1 directory to save configuration distribution. %2';"),
			TempDirectoryOfConfigurationUpdates,
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return;
		
	EndTry;
	
	FilesIndexDirectory = Context.FilesIndexDirectory;
	Try
		CreateDirectory(FilesIndexDirectory);
	Except
		
		ErrorInfo = ErrorInfo();
		LogMessage =
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Ошибка при создании каталога (%1).';
					|en = 'An error occurred while creating the directory (%1).';"),
				FilesIndexDirectory)
			+ Chars.LF
			+ ErrorProcessing.DetailErrorDescription(ErrorInfo);
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(LogMessage);
		
		Context.ErrorName = "FileSystemOperationError";
		Context.ErrorInfo = LogMessage;
		Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("ru = 'Не удалось создать каталог %1. %2';
				|en = 'Cannot create the %1 directory. %2';"),
			FilesIndexDirectory,
			ErrorProcessing.BriefErrorDescription(ErrorInfo));
		Return;
		
	EndTry;
	
	// Creating a distribution package directory.
	If RefreshEnabled.UpdateFileFormat <> "zip" Then
		
		// Only CFU file.
		Try
			CreateDirectory(RefreshEnabled.CFUFileDirectoryInDistributionPackagesDirectory);
		Except
			
			ErrorInfo = ErrorInfo();
			LogMessage =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при создании каталога дистрибутива конфигурации (%1).';
						|en = 'An error occurred while creating the configuration distribution directory (%1).';"),
					RefreshEnabled.CFUFileDirectoryInDistributionPackagesDirectory)
				+ Chars.LF
				+ ErrorProcessing.DetailErrorDescription(ErrorInfo);
			GetApplicationUpdatesServerCall.WriteErrorToEventLog(LogMessage);
			
			Context.ErrorName = "FileSystemOperationError";
			Context.ErrorInfo = LogMessage;
			Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать каталог %1 для сохранения дистрибутива конфигурации. %2';
					|en = 'Cannot create the %1 directory to save configuration distribution. %2';"),
				RefreshEnabled.DistributionPackageDirectory,
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Return;
			
		EndTry;
		
		RefreshEnabled.Insert("ReceivedFileName", RefreshEnabled.FullNameOfCFUFileInDistributionDirectory);
		
	Else
		
		Try
			CreateDirectory(RefreshEnabled.DistributionPackageDirectory);
		Except
			
			ErrorInfo = ErrorInfo();
			LogMessage =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при создании каталога дистрибутива конфигурации (%1).';
						|en = 'An error occurred while creating the configuration distribution directory (%1).';"),
					RefreshEnabled.DistributionPackageDirectory)
				+ Chars.LF
				+ ErrorProcessing.DetailErrorDescription(ErrorInfo);
			GetApplicationUpdatesServerCall.WriteErrorToEventLog(LogMessage);
			
			Context.ErrorName = "FileSystemOperationError";
			Context.ErrorInfo = LogMessage;
			Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось создать каталог %1 для сохранения дистрибутива конфигурации. %2';
					|en = 'Cannot create the %1 directory to save configuration distribution. %2';"),
				RefreshEnabled.DistributionPackageDirectory,
				ErrorProcessing.BriefErrorDescription(ErrorInfo));
			Return;
			
		EndTry;
		
		RefreshEnabled.Insert("ReceivedFileName",
			TempDirectoryOfConfigurationUpdates
				+ StrReplace(RefreshEnabled.TemplatesSubdirectory, "\", "_")
				+ "1cv8.zip");
		
	EndIf;
	
EndProcedure

Procedure CompleteUpdateReceipt(RefreshEnabled, Context) Export
	
	// Extract a distribution package.
	If RefreshEnabled.UpdateFileFormat = "zip" Then
		
		// Extracting from the archive.
		Try
			// ACC:574-off Mobile client doesn't use this code.
			ZIPReader = New ZipFileReader(RefreshEnabled.ReceivedFileName);
			ZIPReader.ExtractAll(
				RefreshEnabled.DistributionPackageDirectory,
				ZIPRestoreFilePathsMode.Restore);
			// ACC:574-on
		Except
			
			LogMessage =
				StringFunctionsClientServer.SubstituteParametersToString(
					NStr("ru = 'Ошибка при извлечении файлов архива (%1) в каталог %2.';
						|en = 'An error occurred while extracting archive files (%1) to directory %2.';"),
					RefreshEnabled.ReceivedFileName,
					RefreshEnabled.DistributionPackageDirectory)
				+ Chars.LF
				+ ErrorProcessing.DetailErrorDescription(ErrorInfo());
			
			GetApplicationUpdatesServerCall.WriteErrorToEventLog(LogMessage);
			
			Context.ErrorName          = "FileDataExtractionError";
			Context.ErrorInfo = LogMessage;
			Context.Message = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Не удалось извлечь файлы дистрибутива. %1';
					|en = 'Cannot extract distribution files. %1';"),
				ErrorProcessing.BriefErrorDescription(ErrorInfo()));
			Return;
			
		EndTry;
		
		ZIPReader.Close();
		
		// Checking whether a CFU file exists in the distribution package.
		If Not FileExists(RefreshEnabled.FullNameOfCFUFileInDistributionDirectory, False) Then
			
			Context.ErrorName          = "ConfigurationDistributionPackageError";
			Context.ErrorInfo = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("ru = 'Некорректный файл дистрибутива %1. Отсутствует файл обновления конфигурации %2.';
					|en = 'Incorrect distribution file %1. No %2 configuration update file.';"),
				RefreshEnabled.UpdateFileURL,
				RefreshEnabled.RelativeCFUFilePath);
			GetApplicationUpdatesServerCall.WriteErrorToEventLog(Context.ErrorInfo);
			Context.Message = NStr("ru = 'Дистрибутив не содержит файл обновления конфигурации.';
										|en = 'The distribution does not contain the configuration update file.';");
			Return;
			
		EndIf;
		
	EndIf;
	
	If RefreshEnabled.UpdateFileFormat = "zip" Then
		Try
			DeleteFiles(RefreshEnabled.ReceivedFileName);
		Except
			GetApplicationUpdatesServerCall.WriteErrorToEventLog(
				ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		EndTry;
	EndIf;
	
	// Write the index file.
	Try
		
		FullIndexFileName = Context.FilesIndexDirectory + RefreshEnabled.IndexFileName;
		UpdateFileSpecifier = New File(RefreshEnabled.FullNameOfCFUFileInDistributionDirectory);
		
		TextWriter = New TextWriter(FullIndexFileName);
		TextWriter.WriteLine(RefreshEnabled.FullNameOfCFUFileInDistributionDirectory);
		TextWriter.WriteLine(RefreshEnabled.Checksum);
		TextWriter.WriteLine(String(UpdateFileSpecifier.Size()));
		TextWriter.WriteLine(String(UpdateFileSpecifier.GetModificationUniversalTime()));
		TextWriter.Close();
		
	Except
		GetApplicationUpdatesServerCall.WriteErrorToEventLog(
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
	EndTry;
	
EndProcedure

#EndIf

////////////////////////////////////////////////////////////////////////////////
// Other internal procedures and functions

Function EventLogEventName(DefaultLanguageCode) Export
	
	Return NStr("ru = 'Получение обновлений программы';
				|en = 'Receive application updates';", DefaultLanguageCode);
	
EndFunction

// Returns the key ID of the common settings storage object.
//
// Returns:
//  String
//
Function CommonSettingsID() Export
	
	Return "Online_Support";
	
EndFunction

// Returns the ID of the setting key of the common storage containing the date when
// the user was notified on the start of the patch download.
//
// Returns:
//  String
//
Function SettingKeyPatchDownloadEnablementNotificationDate() Export
	
	Return "PatchImportEnableNotificationDate";
	
EndFunction

#EndRegion