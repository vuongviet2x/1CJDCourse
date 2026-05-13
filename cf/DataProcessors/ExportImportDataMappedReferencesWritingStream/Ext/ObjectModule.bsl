#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

Var CurContainer; // DataProcessorObject.ExportImportDataContainerManager
Var CurNameOfColumnWithOriginalReference;
Var CurLinks;
Var CurSerializer;
Var CurrentMetadataObject1;
Var PreviousLink;
Var PreviousMetadataObject;

#EndRegion

#Region Internal

// Initialize.
// 
// Parameters:
//  Container - DataProcessorObject.ExportImportDataContainerManager
//  Serializer - XDTOSerializer
//  InitializationParameters - See GetInitialParametersInThread
Procedure Initialize(Container, Serializer, InitializationParameters = Undefined) Export
	
	CurContainer = Container;
	CurSerializer = Serializer;
	
	CurNameOfColumnWithOriginalReference = ?(CurContainer.IsChildThread(),
		InitializationParameters.ColumnWithOriginalLinkName,
		NewNameOfSourceLinkColumn());
	
EndProcedure

Procedure MatchLinkWhenUploading(Val Ref, Val NaturalKey) Export
	
	If Ref.Metadata() <> PreviousMetadataObject Then
		WhenChangingMetadataObject(Ref.Metadata());
	EndIf;
	
	If Ref = PreviousLink Then
		
		MappedLink = CurLinks.Find(Ref, CurNameOfColumnWithOriginalReference);
		
	Else
		
		If CurLinks.Count() > FileLinkLimit() Then
			WriteMappedLinks();
		EndIf;
		
		MappedLink = CurLinks.Add();
		
	EndIf;
	
	MappedLink[CurNameOfColumnWithOriginalReference] = Ref;
	For Each KeyAndValue In NaturalKey Do
		
		If CurLinks.Columns.Find(KeyAndValue.Key) = Undefined Then
			
			TypesArray = New Array();
			TypesArray.Add(TypeOf(KeyAndValue.Value));
			TypeDescription = New TypeDescription(TypesArray, , New StringQualifiers(1024));
			
			CurLinks.Columns.Add(KeyAndValue.Key, TypeDescription);
			
		EndIf;
		
		MappedLink[KeyAndValue.Key] = KeyAndValue.Value;
		
	EndDo;
	
	PreviousLink = Ref;
	
EndProcedure

Procedure Close() Export
	
	WriteMappedLinks();
	
	If Not CurContainer.IsChildThread() Then
		WriteNameOfSourceLinkColumn();
	EndIf;
	
EndProcedure

// Get initialization parameters in the stream.
// 
// Returns:
//  FixedStructure - Get initialization parameters in the stream.:
// * ColumnWithOriginalLinkName - String 
Function GetInitialParametersInThread() Export
	
	InitializationParameters = New Structure();
	InitializationParameters.Insert("ColumnWithOriginalLinkName", CurNameOfColumnWithOriginalReference);
	
	Return New FixedStructure(InitializationParameters);
	
EndFunction

#EndRegion

#Region Private

Procedure WhenChangingMetadataObject(Val NewMetadataObject)
	
	If CurrentMetadataObject1 <> Undefined Then
		WriteMappedLinks();
	EndIf;
	
	PreviousMetadataObject = CurrentMetadataObject1;
	CurrentMetadataObject1 = NewMetadataObject;
	
	FillInColumnsOfSourceLinkTable();
	
	PreviousLink = Undefined;
	
EndProcedure

Procedure FillInColumnsOfSourceLinkTable()
	
	CurLinks = New ValueTable();
	CurLinks.Columns.Add(CurNameOfColumnWithOriginalReference, CommonCTLCached.RefTypesDetails());
	
	TypesOfSharedData = ExportImportDataInternalEvents.GetSharedDataTypesThatSupportLinkMappingWhenLoading();
	If TypesOfSharedData.Find(CurrentMetadataObject1) <> Undefined Then
		NaturalKeyFields = Common.ObjectManagerByFullName(CurrentMetadataObject1.FullName()).NaturalKeyFields();
		For Each NaturalKeyField In NaturalKeyFields Do
			FieldTypesDetails = DescriptionOfObjectFieldTypes(CurrentMetadataObject1, NaturalKeyField);
			ReferenceTypesOnly = True;
			For Each PossibleType In FieldTypesDetails.Types() Do
				If CommonCTL.IsPrimitiveType(PossibleType) Or PossibleType = Type("ValueStorage") Then
					ReferenceTypesOnly = False;
					Break;
				EndIf;
			EndDo;
			If ReferenceTypesOnly Then
				FieldTypesDetails = CommonCTLCached.RefTypesDetails();
			EndIf;
			CurLinks.Columns.Add(NaturalKeyField, FieldTypesDetails);
		EndDo;
	EndIf;
	
	CurLinks.Indexes.Add(CurNameOfColumnWithOriginalReference);
	
EndProcedure

// Returns TypeDescription for a metadata object attribute.
//
// Parameters:
//	MetadataObject - MetadataObject - Metadata object.
//	FieldName - String - Attribute name.
//
// Returns:
//	TypeDescription - Attribute type details.
//
Function DescriptionOfObjectFieldTypes(MetadataObject, FieldName)
	
	// Check for standard attributes
	For Each StandardAttribute In MetadataObject.StandardAttributes Do 
		
		If StandardAttribute.Name = FieldName Then 
			 Return StandardAttribute.Type;
		EndIf;
		
	EndDo;
	
	// Attribute check.
	For Each Attribute In MetadataObject.Attributes Do 
		
		If Attribute.Name = FieldName Then 
			 Return Attribute.Type;
		EndIf;
		
	EndDo;
	
	// Check for common attributes
	NumberOfCommonDetails = Metadata.CommonAttributes.Count();
	For Iteration = 0 To NumberOfCommonDetails - 1 Do 
		
		CommonAttribute = Metadata.CommonAttributes.Get(Iteration);
		If CommonAttribute.Name <> FieldName Then 
			
			Continue;
			
		EndIf;
		
		CommonAttributeContent = CommonAttribute.Content;
		CommonPropsFound = CommonAttributeContent.Find(MetadataObject);
		If CommonPropsFound <> Undefined Then 
			
			Return CommonAttribute.Type;
			
		EndIf;
		
	EndDo;
	
	Raise StrTemplate(NStr("ru = 'Не определен тип поля %1 объекта %2.';
									|en = 'The %1 field type of the %2 object is not defined.';"), 
		FieldName, MetadataObject.FullName());
	
EndFunction

Function FileLinkLimit()
	
	Return 17000;
	
EndFunction

// New name of the original reference column.
// 
// Returns:
//  String - New name of the original reference column.
Function NewNameOfSourceLinkColumn()
	
	ColumnName = New UUID();
	ColumnName = String(ColumnName);
	ColumnName = "a" + StrReplace(ColumnName, "-", "");
	
	Return ColumnName;
	
EndFunction

Procedure WriteNameOfSourceLinkColumn()
	
	FileName = CurContainer.CreateCustomFile("xml", ExportImportDataInternal.DataTypeForColumnNameOfValueTable());
	ExportImportData.WriteObjectToFile(CurNameOfColumnWithOriginalReference, FileName);
	
EndProcedure

Procedure WriteMappedLinks()
	
	If CurLinks = Undefined
		Or CurLinks.Count() = 0 Then
		
		Return;
		
	EndIf;
	
	FileName = CurContainer.CreateFile(ExportImportDataInternal.ReferenceMapping(), CurrentMetadataObject1.FullName());
	ExportImportData.WriteObjectToFile(CurLinks, FileName, CurSerializer);
	
	CurLinks.Clear();
	
EndProcedure

#EndRegion

#EndIf
