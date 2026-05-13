//@strict-types

#Region Public

// Path of the shared directory of temporary files for access between sessions.
//
// Returns:
//   String - full path to a directory.
//
Function SharedDirectoryOfTemporaryFiles() Export
	
	SetPrivilegedMode(True);
	
	If Common.IsLinuxServer() Then
		SharedTemporaryDirectory = Constants.FileExchangeDirectorySaaSLinux.Get();
	Else
		SharedTemporaryDirectory = Constants.FileExchangeDirectorySaaS.Get();
	EndIf;
	
	If IsBlankString(SharedTemporaryDirectory) Then
		SharedTemporaryDirectory = TrimAll(TempFilesDir());
	Else
		SharedTemporaryDirectory = TrimAll(SharedTemporaryDirectory);
	EndIf;
	
	If Not StrEndsWith(SharedTemporaryDirectory, GetPathSeparator()) Then
		SharedTemporaryDirectory = SharedTemporaryDirectory + GetPathSeparator();
	EndIf;
	
	Return SharedTemporaryDirectory;
	
EndFunction

// Registers a unique file name in the temporary storage.
// 
// Parameters:
//  Prefix - String - File name prefix. English letters and numbers only, up to 20 characters.
//  Extension - String - File extension. English letters and numbers only, up to 4 characters.
//  MinutesOfStorage - Number - Minutes of file storage. At least one minute.
// 
// Returns:
//  String - Registered temporary file name.
Function NewTemporaryStorageFile(Val Prefix, Val Extension, MinutesOfStorage) Export

	If Not ValueIsFilled(MinutesOfStorage) Then
		Raise NStr("ru = 'Не указан срок хранения нового файла временного хранилища';
								|en = 'The retention period for the new temporary storage file is not specified';");
	EndIf;
	
	If Extension <> Undefined Then
		Extension = FileNamePart(Extension, 4);
		If ValueIsFilled(Extension) Then
			Extension = "." + Extension;
		EndIf;
	EndIf;

	If Prefix <> Undefined Then
		Prefix = FileNamePart(Prefix, 20);
		If ValueIsFilled(Prefix) Then
			Prefix = Prefix + "_";
		EndIf;
	EndIf;
	
	If SaaSOperations.DataSeparationEnabled() And SaaSOperations.SeparatedDataUsageAvailable() Then
		DataArea = SaaSOperations.SessionSeparatorValue();
	Else
		DataArea = 0;
	EndIf;

	FileName = "tmp_" + Format(DataArea, "NZ=0; NG=0;") + "_" + Prefix + New UUID
		+ Extension;

	RegisterATemporaryStorageFile(FileName, MinutesOfStorage);

	Return FileName;

EndFunction

// Properties of the temporary storage file.
// 
// Parameters:
//  FileName - String - Name of the file registered in the temporary storage.
// 
// Returns:
//  Structure - Properties of the temporary storage file.:
// * Registered - Boolean
// * RegistrationDate - Date
// * ShelfLife - Date
// * WindowsPath - String
// * LinuxPath - String 
Function TemporaryStorageFileProperties(FileName) Export

	Result = New Structure;
	Result.Insert("Registered", False);
	Result.Insert("RegistrationDate", Date(1, 1, 1));
	Result.Insert("ShelfLife", Date(1, 1, 1));
	Result.Insert("WindowsPath", "");
	Result.Insert("LinuxPath", "");
	
	SetPrivilegedMode(True);
	Record = TemporaryStorageFileManagerRecord(FileName);
	Record.Read();

	Result.Registered = Record.Selected();
	If Result.Registered Then
		FillPropertyValues(Result, Record);
	EndIf;

	Return Result;

EndFunction

// Full name of the temporary storage file.
// 
// Parameters: 
//  FileName - String - Name of the file registered in the temporary storage.
// 
// Returns: 
//  String, Undefined - Full name of the file. Undefined - If the file is not registered.
Function FullTemporaryStorageFileName(FileName) Export
	
	FileProperties = TemporaryStorageFileProperties(FileName);
	
	If Not FileProperties.Registered Then
		Return Undefined;
	EndIf;
	
	Return FullNameOfFileInSession(FileName, FileProperties.WindowsPath, FileProperties.LinuxPath);
	
EndFunction

// Full name of the file in the session depends on the production server OS.
// 
// Parameters: 
//  Name - String
//  WindowsPath - String
//  LinuxPath - String
// 
// Returns: 
//  String - Full filename in the session.
Function FullNameOfFileInSession(Name, WindowsPath, LinuxPath) Export
	
	If Common.IsLinuxServer() Then
		Path = LinuxPath;
	Else
		Path = WindowsPath;
	EndIf;
	
	If IsBlankString(Path) Then
		Path = TempFilesDir();
	EndIf;
	
	Separator = GetPathSeparator();
	If Not StrEndsWith(Path, Separator) Then
		Path = Path + Separator;
	EndIf;
	
	Return Path + Name;
	
EndFunction

// Delete the temporary storage file.
// 
// Parameters:
//  FileName - String - Name of the file registered in the temporary storage.
Procedure DeleteTemporaryStorageFile(FileName) Export

	SetPrivilegedMode(True);
	Record = TemporaryStorageFileManagerRecord(FileName);
	Record.Read();
	If Not Record.Selected() Then
		Return;
	EndIf;
	
	FullFileName = FullNameOfFileInSession(FileName, Record.WindowsPath, Record.LinuxPath);
	If Not DeleteFilesInAttempt(FullFileName, NStr("ru = 'Удаление файла. Файл временного хранилища';
														|en = 'Delete file. Temporary storage file';",
		Common.DefaultLanguageCode())) Then
		Return;
	EndIf;
		
	Record.Delete();

EndProcedure

// Delete all temporary storage files except for the locked ones.
// 
// Parameters:
//  Boundary - Date - Universal date before which files should be deleted.
Procedure DeleteAllTemporaryStorageFiles(Boundary) Export
	
	DeleteTemporaryStorageFiles(Boundary);
	
EndProcedure

// Lock the temporary storage file.
// 
// Parameters:
//  FileName - String - Name of the file registered in the temporary storage.
//  FormIdentifier - UUID, Undefined - ID of the form for the lifetime of which the file will
//  remain locked. 
// 
// Returns:
//  Boolean - True if the lock is set.
Function LocATemporaryStorageFile(FileName, FormIdentifier = Undefined) Export
	
	SetPrivilegedMode(True);
	Var_Key = TemporaryStorageFileEntryKey(FileName);

	Try
		LockDataForEdit(Var_Key, Undefined, FormIdentifier);
	Except
		Return False;
	EndTry;
	
	Return True;
	
EndFunction

// Unlock the temporary storage file.
// 
// Parameters:
//  FileName - String - Name of the file registered in the temporary storage.
//  FormIdentifier - UUID, Undefined - ID of the form where the file was locked. 
Procedure UnlockTemporaryStorageFile(FileName, FormIdentifier = Undefined) Export
	
	SetPrivilegedMode(True);
	Var_Key = TemporaryStorageFileEntryKey(FileName);
	UnlockDataForEdit(Var_Key, FormIdentifier);
	
EndProcedure

// The temporary storage file is locked.
// 
// Parameters:
//  FileName - String - Name of the file registered in the temporary storage.
// 
// Returns:
//  Boolean
Function TemporaryStorageFileBlocked(FileName) Export
	
	SetPrivilegedMode(True);
	Var_Key = TemporaryStorageFileEntryKey(FileName);
	
	Try
		LockDataForEdit(Var_Key);
	Except
		Return True;
	EndTry;
	
	UnlockDataForEdit(Var_Key);
	
	Return False;
	
EndFunction

// Set the retention period of the temporary storage file relative to the current universal date.
// 
// Parameters:
//  FileName - String - Name of the file registered in the temporary storage.
//  MinutesOfStorage - Number - File storage minutes.
// 
// Returns:
//  Boolean - True if the retention period is set.
Function SetTemporaryStorageFileRetentionPeriod(FileName, MinutesOfStorage) Export

	SetPrivilegedMode(True);
	Record = TemporaryStorageFileManagerRecord(FileName);
	Record.Read();
	
	If Not Record.Selected() Then
		Return False;
	EndIf;
	
	Record.ShelfLife = CurrentUniversalDate() + MinutesOfStorage * 60;
	Record.Write();
	
	Return True;
	
EndFunction

#EndRegion

#Region Internal

// Delete temporary storage files. The method of the same-named scheduled job.
Procedure DeletingTemporaryStorageFiles() Export
	
	Common.OnStartExecuteScheduledJob(
		Metadata.ScheduledJobs.DeletingTemporaryStorageFiles);

	DeleteTemporaryStorageFiles(CurrentUniversalDate());

EndProcedure

// Delete files in the attempt.
// 
// Parameters:
//  FileName - String
//  EventNameLR - Undefined, String - Name of an event in the event log.
// 
// Returns:
//  Boolean - True if the deletion was successful.
Function DeleteFilesInAttempt(FileName, EventNameLR = Undefined) Export
	
	Try

		DeleteFiles(FileName);
		Return True;

	Except

		If EventNameLR = Undefined Then
			EventNameLR = NStr("ru = 'Удаление файла';
								|en = 'Deleting file';", Common.DefaultLanguageCode());
		EndIf;

		CommentOnLREvent = CloudTechnology.DetailedErrorText(ErrorInfo());
		WriteLogEvent(EventNameLR, EventLogLevel.Error, Undefined, Undefined,
			CommentOnLREvent);

	EndTry;

	Return False;

EndFunction

#EndRegion

#Region Private

Procedure DeleteTemporaryStorageFiles(Boundary)

	SetPrivilegedMode(True);

	Query = New Query;
	Query.SetParameter("Boundary", Boundary);
	Query.Text =
	"SELECT
	|	TemporaryStorageFiles.FileName AS FileName,
	|	TemporaryStorageFiles.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.TemporaryStorageFiles AS TemporaryStorageFiles
	|WHERE
	|	TemporaryStorageFiles.ShelfLife < &Boundary";

	Selection = Query.Execute().Select();
	While Selection.Next() Do

		If TemporaryStorageFileBlocked(Selection.FileName) Then
			Continue;
		EndIf;
		
		Record = TemporaryStorageFileManagerRecord(Selection.FileName, Selection.DataArea);
		Record.Read();
		If Not Record.Selected() Then
			Continue;
		EndIf;

		FullFileName = FullNameOfFileInSession(Record.FileName, Record.WindowsPath, Record.LinuxPath);
		If Not DeleteFilesInAttempt(FullFileName, NStr("ru = 'Удаление файла. Файл временного хранилища';
															|en = 'Delete file. Temporary storage file';",
			Common.DefaultLanguageCode())) Then
			Continue;
		EndIf;
		Record.Delete();

	EndDo;
	
EndProcedure

Procedure RegisterATemporaryStorageFile(FileName, MinutesOfStorage)
	
	SetPrivilegedMode(True);
	FilePaths = TemporaryFilesSharedDirectoryNames();
	
	RegistrationDate = CurrentUniversalDate();
	Record = InformationRegisters.TemporaryStorageFiles.CreateRecordManager();
	Record.FileName = FileName;
	Record.RegistrationDate = RegistrationDate;
	Record.ShelfLife = RegistrationDate + Max(1, MinutesOfStorage) * 60;
	Record.WindowsPath = FilePaths.WindowsPath; 
	Record.LinuxPath = FilePaths.LinuxPath;
	Record.Write();
	
EndProcedure

Function TemporaryFilesSharedDirectoryNames()
	
	Result = New Structure;

	IsLinux = Common.IsLinuxServer();

	Result.Insert("WindowsPath", ExchangeDirectoryFromConstant(
		Constants.FileExchangeDirectorySaaS.Get(), Not IsLinux, "\"));
	
	Result.Insert("LinuxPath", ExchangeDirectoryFromConstant(
		Constants.FileExchangeDirectorySaaSLinux.Get(), IsLinux, "/"));

	Return Result;

EndFunction

Function ExchangeDirectoryFromConstant(ExchangeDirectory, DefaultDirectoryOfTemporaryFiles, Separator)

	ExchangeDirectory = TrimAll(ExchangeDirectory);
	If IsBlankString(ExchangeDirectory) And DefaultDirectoryOfTemporaryFiles Then
		ExchangeDirectory = TempFilesDir();
	EndIf;
	
	If ValueIsFilled(ExchangeDirectory) And Not StrEndsWith(ExchangeDirectory, Separator) Then
		ExchangeDirectory = ExchangeDirectory + Separator;
	EndIf;
	
	Return ExchangeDirectory;

EndFunction

Function FileNamePart(InitialString, MaxLength)

	Result = "";
	ResultLength = 0;
	For CharacterNumber = 1 To StrLen(InitialString) Do
		Code = CharCode(InitialString, CharacterNumber);
		If (Code >= 48 And Code <= 57)
			Or (Code >= 65 And Code <= 90)
			Or (Code >= 97 And Code <= 122) Then
			Result = Result + Char(Code);
			ResultLength = ResultLength + 1;
			If ResultLength > MaxLength Then
				Break;
			EndIf;
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

Function TemporaryStorageFileDataArea(FileName)
	
	Query = New Query;
	Query.SetParameter("FileName", FileName);
	Query.Text =
	"SELECT TOP 1
	|	TemporaryStorageFiles.DataAreaAuxiliaryData AS DataArea
	|FROM
	|	InformationRegister.TemporaryStorageFiles AS TemporaryStorageFiles
	|WHERE
	|	TemporaryStorageFiles.FileName = &FileName";

	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.DataArea;
	EndIf;

	Return Undefined;

EndFunction

// Record manager of the temporary storage file.
// 
// Parameters:
//  FileName - String
//  DataArea - Number
// 
// Returns:
//  InformationRegisterRecordManager.TemporaryStorageFiles
Function TemporaryStorageFileManagerRecord(FileName, DataArea = Undefined)

	Record = InformationRegisters.TemporaryStorageFiles.CreateRecordManager();
	Record.FileName = FileName;

	If SaaSOperations.SeparatedDataUsageAvailable() Then
		Return Record;
	EndIf;

	If DataArea = Undefined Then
		DataArea = TemporaryStorageFileDataArea(FileName);
	EndIf;

	If ValueIsFilled(DataArea) Then
		Record.DataAreaAuxiliaryData = DataArea;
	EndIf;

	Return Record;

EndFunction

// Register record key of the temporary storage file.
// 
// Parameters:
//  FileName - String - File name
//  DataArea - Number, Undefined - Data area
// 
// Returns:
//  InformationRegisterRecordKey.TemporaryStorageFiles - Register record key of the temporary storage file.
Function TemporaryStorageFileEntryKey(FileName, DataArea = Undefined)
	
	KeyValues = New Structure;
	KeyValues.Insert("FileName", FileName);
	
	If DataArea = Undefined Then
		DataArea = TemporaryStorageFileDataArea(FileName);
	EndIf;
	If ValueIsFilled(DataArea) Then
		KeyValues.Insert("DataAreaAuxiliaryData", DataArea);
	EndIf;

	Return SaaSOperations.CreateAuxiliaryDataInformationRegisterEntryKey(
		InformationRegisters.TemporaryStorageFiles, KeyValues);

EndFunction

#EndRegion