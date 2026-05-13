#Region ProcessingRequests

#Region StorageAndID

Function StorageAndIDGETRequest(Query)
	
	Return StorageAndGetResponseID(Query);
	
EndFunction

Function StorageAndIDPOSTRequest(Query)
	
	Return StorageAndIDOfPOSTResponse(Query);
	
EndFunction

#EndRegion

#Region VolumeAndPathToFile

Function VolumeAndPathToFileGETRequest(Query)
	
	Return VolumeAndFilePathGetResponse(Query);
	
EndFunction

Function VolumeAndPathToFilePOSTRequest(Query)
	
	Return VolumeAndFilePathPOSTResponse(Query);
	
EndFunction

#EndRegion

#Region Get

Function GetGETRequest(Query)
	
	Return GetGETResponse(Query);
	
EndFunction

#EndRegion

#Region Send

Function SendPUTRequest(Query)
	
	Return SendPUTResponse(Query);

EndFunction

#EndRegion

#EndRegion

#Region GettingResponses

Function StorageAndGetResponseID(Query)
	
	Var Response;
	
	// Getting the parameters required for the method from the query.
	QueryOptions = MethodParametersFromRequest(StorageAndGETID(), Query);
	
	// Get a logical storage manager by storage name.
	StorageManager = LogicalStorageManager(QueryOptions.Storage, Response);
	
	// Checking if data with the specified ID exists in a logical storage.
	DataDetails = DescriptionOfLogicalStorageData(StorageManager, QueryOptions.Storage, QueryOptions.ID, Response);
	
	If Response = Undefined Then
		
		InformationRegisters.TemporaryQueriesIDs.DeleteExpiredRequests();
		Result = InformationRegisters.TemporaryQueriesIDs.RegisterRequest(Query, StorageAndGETID().FullName());
		Location = Query.BaseURL + "/download/" + Result.Id;
		
		Response = New HTTPServiceResponse(302);
		Response.Headers.Insert("Location", Location);
		Response.Headers.Insert("Accept-Ranges", "bytes");
		
		// Backward compatibility. Old customers will use the old address, new customers will use the new address.
		If StrStartsWith(DataDetails.Data, "https://") Or StrStartsWith(DataDetails.Data, "http://") Then
			Response.Headers.Insert("x-url-s3", DataDetails.Data);
		EndIf;
		
	EndIf;
	
	Return Response;
	
EndFunction

Function StorageAndIDOfPOSTResponse(Query)
	
	Var Response;
	
	// Getting the parameters required for the method from the query.
	QueryOptions = MethodParametersFromRequest(StorageAndPOSTID(), Query);
	
	// Get a logical storage manager by storage name.
	LogicalStorageManager(QueryOptions.Storage, Response);
	
	If Response = Undefined Then
		
		Body = Query.GetBodyAsString();
		If Not IsBlankString(Body) Then
			JSONReader = New JSONReader;
			JSONReader.SetString(Body);
			AdditionalParameters	= ReadJSON(JSONReader);
			JSONReader.Close();
		EndIf;
		
		InformationRegisters.TemporaryQueriesIDs.DeleteExpiredRequests();
		Result = InformationRegisters.TemporaryQueriesIDs.RegisterRequest(Query, StorageAndPOSTID().FullName(), AdditionalParameters);
		
		Response = New HTTPServiceResponse(200);
		Response.Headers.Insert("Location", Query.BaseURL + "/upload/" + Result.Id);
		Response.Headers.Insert("Accept-Ranges", "bytes");
		If ValueIsFilled(Result.S3Address) Then
			Response.Headers.Insert("x-url-s3", Result.S3Address);
			Response.Headers.Insert("x-file-id", Result.FileID);
		EndIf;
		
	EndIf;
	
	Return Response;
	
EndFunction

Function VolumeAndFilePathGetResponse(Query)
	
	Var Response;
	
	// Getting the parameters required for the method from the query.
	QueryOptions = MethodParametersFromRequest(VolumeAndGETFilePath(), Query);
	
	// Getting a physical storage manager by a storage ID.
	StorageManager = PhysicalStorageManager(QueryOptions.VolumeID, Response);
	
	// Checking if data with the specified ID exists in a physical storage.
	DescriptionOfPhysicalStorageData(StorageManager, QueryOptions.VolumeID, QueryOptions.PathAndFileName, Response);
	
	If Response = Undefined Then
		
		InformationRegisters.TemporaryQueriesIDs.DeleteExpiredRequests();
		Result = InformationRegisters.TemporaryQueriesIDs.RegisterRequest(Query, VolumeAndGETFilePath().FullName());
		Location = Query.BaseURL + "/download/" + Result.Id;
		
		Response = New HTTPServiceResponse(302);
		Response.Headers.Insert("Location", Location);
		Response.Headers.Insert("Accept-Ranges", "bytes");
		
	EndIf;
	
	Return Response;
	
EndFunction

Function VolumeAndFilePathPOSTResponse(Query)
	
	Var Response;
	
	// Getting the parameters required for the method from the query.
	QueryOptions = MethodParametersFromRequest(VolumeAndPathToPOSTFile(), Query);
	
	// Getting a physical storage manager by a storage ID.
	PhysicalStorageManager(QueryOptions.VolumeID, Response);
	
	If Response = Undefined Then
		
		InformationRegisters.TemporaryQueriesIDs.DeleteExpiredRequests();
		Result = InformationRegisters.TemporaryQueriesIDs.RegisterRequest(Query, VolumeAndPathToPOSTFile().FullName());
		Location = Query.BaseURL + "/upload/" + Result.Id;
		
		Response = New HTTPServiceResponse(200);
		Response.Headers.Insert("Location", Location);
		Response.Headers.Insert("Accept-Ranges", "bytes");
		
	EndIf;
	
	Return Response;
	
EndFunction

Function GetGETResponse(Query)
	
	Var Response;
	
	QueryOptions = MethodParametersFromRequest(GetGET(), Query);
	
	InitialQuery = InformationRegisters.TemporaryQueriesIDs.RequestByID(QueryOptions.ID);
	
	If InitialQuery = Undefined Then
		
		Response = New HTTPServiceResponse(404);
		
	EndIf;
	
	If Response = Undefined Then
		
		TypeOfOriginalRequest = Metadata.FindByFullName(InitialQuery["RequestType_"]);
		ParametersOfOriginalRequest = MethodParametersFromRequest(TypeOfOriginalRequest, InitialQuery);
		
		If TypeOfOriginalRequest = StorageAndGETID() Then
			
			StorageManager = LogicalStorageManager(ParametersOfOriginalRequest.Storage, Response);
			DataDetails = DescriptionOfLogicalStorageData(StorageManager, ParametersOfOriginalRequest.Storage, ParametersOfOriginalRequest.ID, Response);
			
		ElsIf TypeOfOriginalRequest = VolumeAndGETFilePath() Then
			
			StorageManager = PhysicalStorageManager(ParametersOfOriginalRequest.VolumeID, Response);
			DataDetails = DescriptionOfPhysicalStorageData(StorageManager, ParametersOfOriginalRequest.VolumeID, ParametersOfOriginalRequest.PathAndFileName, Response);
			
		EndIf;
		
		Span = RequestedRange_(QueryOptions.Range, Response);
		
		If DataDetails = Undefined Then
			
			Response = New HTTPServiceResponse(404);
			
		ElsIf Span = Undefined Then
			
			Response = New HTTPServiceResponse(200);
			Response.Headers.Insert("Content-Disposition", StrTemplate("attachment; filename=""%1""", DataDetails.FileName));
			Response.Headers.Insert("Content-Type", "application/octet-stream");
			
			Data = StorageManager.Data(DataDetails);
			
			If TypeOf(Data) = Type("String") And (StrStartsWith(Data, "https://") Or StrStartsWith(Data, "http://")) Then
				
				BinaryData = DataTransferInternal.GetBinaryDataFromS3(Data);
				Response.SetBodyFromBinaryData(BinaryData);
				
			ElsIf TypeOf(Data) = Type("String") Then
				
				Response.SetBodyFileName(Data);
				
			ElsIf TypeOf(Data) = Type("BinaryData") Then
				
				Response.SetBodyFromBinaryData(Data);
				
			EndIf;
			
		Else
			
			Data = StorageManager.Data(DataDetails);
			
			If TypeOf(Data) = Type("String") And (StrStartsWith(Data, "https://") Or StrStartsWith(Data, "http://")) Then
				BinaryData = DataTransferInternal.GetBinaryDataFromS3(Data, Span.Begin, Span.End);				
			Else
				DataReader = New DataReader(Data);
				DataReader.Skip(Span.Begin);
				ReadDataResult = DataReader.Read(Span.End - Span.Begin + 1);
				BinaryData = ReadDataResult.GetBinaryData();
				DataReader.Close();
			EndIf;
			
			Response = New HTTPServiceResponse(206);
			Response.Headers.Insert("Content-Disposition", StrTemplate("attachment; filename=""%1""", DataDetails.FileName));
			Response.Headers.Insert("Content-Type", "application/octet-stream");
			Response.SetBodyFromBinaryData(BinaryData);
			Response.Headers.Insert("Content-Range", StrTemplate("bytes %1-%2/%3", Format(Span.Begin, "NZ=0; NG=0"), Format(Span.Begin + BinaryData.Size() - 1, "NZ=0; NG=0"), Format(DataDetails.Size, "NZ=0; NG=0")));
			
			InformationRegisters.TemporaryQueriesIDs.ExtendTemporaryID(QueryOptions.ID);
			
		EndIf;
		
	EndIf;
	
	Return Response;
	
EndFunction

Function SendPUTResponse(Query)
	
	Var Response;
	
	QueryOptions = MethodParametersFromRequest(SendPUT(), Query);
	
	InitialQuery = InformationRegisters.TemporaryQueriesIDs.RequestByID(QueryOptions.ID);
	
	If InitialQuery = Undefined Then
		
		Response = New HTTPServiceResponse(404);
		
	EndIf;
	
	If Response = Undefined Then
		
		TypeOfOriginalRequest = Metadata.FindByFullName(InitialQuery["RequestType_"]);
		ParametersOfOriginalRequest = MethodParametersFromRequest(TypeOfOriginalRequest, InitialQuery);
		
		If TypeOfOriginalRequest = StorageAndPOSTID() Then
			
			StorageManager = LogicalStorageManager(ParametersOfOriginalRequest.Storage, Response);
			FileName = ParametersOfOriginalRequest.ID;
			
		ElsIf TypeOfOriginalRequest = VolumeAndPathToPOSTFile() Then
			
			StorageManager = PhysicalStorageManager(ParametersOfOriginalRequest.VolumeID, Response);
			FileName = ParametersOfOriginalRequest.PathAndFileName;
			
		EndIf;
		
		ResultingRange = DataTransferInternal.ResultingRange(Query);
		
		WriteStream = FileStreams.Open(InitialQuery["TempFileName"], FileOpenMode.OpenOrCreate, FileAccess.Write);
		
		If WriteStream = Undefined Then	
			
			Response = New HTTPServiceResponse(500);
			Response.SetBodyFromString(StrTemplate(NStr("ru = 'Не удалось открыть поток записи файла. Идентификатор запроса %1';
														|en = 'Cannot open a file write stream. Request ID %1';"), 
				QueryOptions.ID));
			Return Response;
			
		EndIf;
		
		If ValueIsFilled(ResultingRange) Then
			If WriteStream.Size() < ResultingRange.Begin Then
				Response = New HTTPServiceResponse(500);
				Response.SetBodyFromString(StrTemplate(NStr("ru = 'Размер файла %1 меньше ожидаемого %2. Идентификатор запроса %3';
															|en = 'The %1 file size is less than the expected size of %2. Request ID %3';"),
					WriteStream.Size(),
					ResultingRange.Begin,
					QueryOptions.ID));
				Return Response;
			EndIf;
			WriteStream.Seek(ResultingRange.Begin, PositionInStream.Begin);
		EndIf;

		
		DataStream = Query.GetBodyAsStream();
		DataStream.CopyTo(WriteStream);
		
		TemporaryFileSize = WriteStream.Size();
		
		WriteStream.Close();
		DataStream.Close();
		
		WriteStream = Undefined;
		DataStream = Undefined;
		
		If ValueIsFilled(ResultingRange) And ResultingRange.End < ResultingRange.Size - 1 Then
			
			Response = New HTTPServiceResponse(202);
			InformationRegisters.TemporaryQueriesIDs.ExtendTemporaryID(QueryOptions.ID);
			
		Else
			
			Response = New HTTPServiceResponse(201);
			Response.Headers.Insert("Content-Type", "application/json; charset=UTF-8");
			
			DataDetails = New Structure;
			DataDetails.Insert("FileName", FileName);
			DataDetails.Insert("Data", InitialQuery["TempFileName"]);
			DataDetails.Insert("DeleteDataFile", True);
			DataDetails.Insert("Size", ?(ResultingRange = Undefined, TemporaryFileSize, ResultingRange.Size));
			DataDetails.Insert("AdditionalParameters", InitialQuery["AdditionalParameters"]);
			
			Result = StorageManager.Load(DataDetails);
			
			If TypeOf(Result) = Type("String") Then
			
				ResponseData = New Structure("id", String(Result));
				
			Else
				
				ResponseData = Result;
				
			EndIf;
			
		    JSONWriter = New JSONWriter;
		    JSONWriter.SetString();
		    WriteJSON(JSONWriter, ResponseData);
		    Response.SetBodyFromString(JSONWriter.Close());
			
			If DataDetails.DeleteDataFile Then
				
				Try
					
					DeleteFiles(InitialQuery["TempFileName"]);
					
				Except
					
					WriteLogEvent(NStr("ru = 'ПередачаДанных';
													|en = 'DataTransfer';", Metadata.DefaultLanguage.LanguageCode), EventLogLevel.Error,,, DataTransferClientServer.DetailedErrorText(ErrorInfo()));
					
				EndTry;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return Response;
	
EndFunction

#EndRegion

#Region Utilities

Function MethodParametersFromRequest(Method, Query)
	
	MethodParameters = New Structure;
	
	If Method = StorageAndGETID() Then
		
		MethodParameters.Insert("Storage", Query["URLParameters"].Get("Storage"));
		MethodParameters.Insert("ID", Query["URLParameters"].Get("ID"));
		
	ElsIf Method = StorageAndPOSTID() Then
		
		MethodParameters.Insert("Storage", Query["URLParameters"].Get("Storage"));
		MethodParameters.Insert("ID", Query["URLParameters"].Get("ID"));
		
	ElsIf Method = VolumeAndGETFilePath() Then
		
		MethodParameters.Insert("VolumeID", Query["URLParameters"].Get("VolumeID"));
		MethodParameters.Insert("PathAndFileName", Query["URLParameters"].Get("*"));
		
	ElsIf Method = VolumeAndPathToPOSTFile() Then
		
		MethodParameters.Insert("VolumeID", Query["URLParameters"].Get("VolumeID"));
		MethodParameters.Insert("PathAndFileName", Query["URLParameters"].Get("*"));
		
	ElsIf Method = GetGET() Then
		
		MethodParameters.Insert("ID", Query["URLParameters"].Get("ID"));
		MethodParameters.Insert("Range", Query["Headers"].Get("Range"));
		
	ElsIf Method = SendPUT() Then
		
		MethodParameters.Insert("ID", Query["URLParameters"].Get("ID"));
		MethodParameters.Insert("Range", Query["Headers"].Get("Range"));
		
	EndIf;
	
	Return MethodParameters;
	
EndFunction

Function URLTemplates()
	
	Return Metadata.HTTPServices.DataTransfer.URLTemplates;
	
EndFunction

Function StorageAndGETID()
	
	GetMethod = URLTemplates().StorageAndID.Methods.GET; // MetadataObject
	Return GetMethod;
	
EndFunction

Function StorageAndPOSTID()
	
	PostMethod = URLTemplates().StorageAndID.Methods.POST; // MetadataObject
	Return PostMethod;
	
EndFunction

Function VolumeAndGETFilePath()
	
	GetMethod = URLTemplates().VolumeAndPathToFile.Methods.GET; // MetadataObject
	Return GetMethod; 
	
EndFunction

Function VolumeAndPathToPOSTFile()
	
	PostMethod = URLTemplates().VolumeAndPathToFile.Methods.POST; // MetadataObject
	Return PostMethod;
	
EndFunction

Function GetGET()
	
	Return URLTemplates().Get.Methods.GET;
	
EndFunction

Function SendPUT()
	
	Return URLTemplates().Send.Methods.PUT;
	
EndFunction

Function LogicalStorageManager(Val Storage, Response)
	
	If Response <> Undefined Then
		
		Return Undefined;
		
	EndIf;
	
	StorageManager = DataTransferServer.AllLogicalStorageManagers()[Storage];
	
	If StorageManager = Undefined Then
		
		Response = New HTTPServiceResponse(415);
			
	EndIf;
	
	Return StorageManager;
	
EndFunction

Function PhysicalStorageManager(Val VolumeID, Response)
	
	If Response <> Undefined Then
		
		Return Undefined;
		
	EndIf;
	
	StorageManager = DataTransferServer.AllPhysicalStorageManagers()[VolumeID];
	
	If StorageManager = Undefined Then
		
		Response = New HTTPServiceResponse(415);
			
	EndIf;
	
	Return StorageManager;
	
EndFunction

// Returns details of logical storage data.
// 
// Parameters:
// 	StorageManager - CommonModule - a storage manager.
// 	Storage - String - a name of an object storage.
// 	ID - String - an object ID.
// 	Response - HTTPServiceResponse - a response parameter to be returned if an error occurs.
//
// Returns:
// 	Structure - Details of data to get.:
// 	 * FileName - String - details file name.
// 	 * Size - Number - File size in bytes.
// 	 * Data - BinaryData - binary file data.
//
Function DescriptionOfLogicalStorageData(StorageManager, Val Storage, Val ID, Response)
	
	If Response <> Undefined Then
		
		Return Undefined;
		
	EndIf;
	
	Try
		
		LongDesc = StorageManager.LongDesc(Storage, ID);
		
	Except
		
		LongDesc = Undefined;
		
	EndTry;
	
	If LongDesc = Undefined Then
		
		Response = New HTTPServiceResponse(404);
		
	EndIf;
	
	Return LongDesc;
	
EndFunction

// Returns details of physical storage data.
// 
// Parameters:
// 	StorageManager - CommonModule - a storage manager.
// 	VolumeID - String - a name of a file storage.
// 	PathAndFileName - String - an address of a file storage.
// 	Response - HTTPServiceResponse - a response parameter to be returned if an error occurs.
//
// Returns:
// 	Structure - Details of data to get.:
// 	 * FileName - String - Filename.
// 	 * Size - Number - File size in bytes.
// 	 * Data - BinaryData - binary file data.
//
Function DescriptionOfPhysicalStorageData(StorageManager, Val VolumeID, Val PathAndFileName, Response)
	
	If Response <> Undefined Then
		
		Return Undefined;
		
	EndIf;
	
	Try
	
		LongDesc = StorageManager.LongDesc(VolumeID, PathAndFileName);
	
	Except
		
		LongDesc = Undefined;
		
	EndTry;
	
	If LongDesc = Undefined Then
		
		Response = New HTTPServiceResponse(404);
		
	EndIf;
	
	Return LongDesc;
	
EndFunction

// Returns the requested range.
//
// Parameters:
//  Range - String - in the following format "bytes=<Number>-<Number>"
//  Response - HTTPServiceResponse - a response parameter to be returned if an error occurs. 
// 
// Returns:
//  Structure - Range data.:
//	 * Begin - Number - the beginning of a range.
//	 * End - Number - the end of a range.
//
Function RequestedRange_(Val Range, Response)
	
	Span = Undefined;
	Range = TrimAll(Range);
	
	If Not IsBlankString(Range) And StrStartsWith(Range, "bytes=") Then
		
		Range = Right(Range, StrLen(Range) - StrLen("bytes="));
		SubstringsArray = StrSplit(Range, "-");
		
		Try
			
			Begin = Number(SubstringsArray[0]);
			End = Number(SubstringsArray[1]);
			
			Span = New Structure("Begin, End", Begin, End);
			
		Except
			
			Response = New HTTPServiceResponse(416);
			
		EndTry;
		
	EndIf;
		
	Return Span;
	
EndFunction

#EndRegion