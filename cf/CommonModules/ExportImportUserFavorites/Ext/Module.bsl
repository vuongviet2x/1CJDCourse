////////////////////////////////////////////////////////////////////////////////
// "Data import and export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

#Region RegisteringDataUploadAndDownloadHandlers

// Called upon registration of arbitrary data export handlers.
//
// Parameters:
//  HandlersTable - ValueTable - in this procedure, it is necessary
//    to complete this value table with information about arbitrary
//    data export handlers to register. 
//    Columns:
//    * MetadataObject - MetadataObject - Handler is called after the object data is exported.
//      
//    * Handler - CommonModule - a common module implementing an arbitrary
//      data export handler. The set of export procedures
//      to be implemented in the handler depends on the values of the following
//      value table columns,
//    * Version - String - a number of the interface version of data export/import handlers
//      supported by the handler,
//    * BeforeUnloadingType - Boolean -  a flag specifying whether the handler must be called
//      before exporting all infobase objects associated with this metadata
//      object. If set to True, the common module of the handler must include
//      the exportable procedure BeforeExportType()
//      supporting the following parameters:
//      * Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          manager used for data export. For more information, see the comment
//          to ExportImportDataContainerManager handler interface,
//      * Serializer - XDTOSerializer - Serializer initialized with reference annotation support.
//          If an arbitrary export handler requires additional data export,
//          use XDTOSerializer passed to the BeforeExportType() procedure as the Serializer parameter value,
//          not obtained using the XDTOSerializer global context property,
//          
//          
//      * MetadataObject - MetadataObject - Handler is called after the object data is exported.
//          
//      * Cancel - Boolean - If the parameter value is set to True in the BeforeExportObject()
//          procedure, the corresponding object
//          is not exported.
//    * BeforeExportObject - Boolean - a flag specifying whether the handler must be called
//      before exporting a specific infobase object. If set to True,
//      the common module of the handler must include the exportable procedure
//      BeforeExportType() supporting the following parameters:
//      * Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          manager used for data export. For more information, see the comment
//          to ExportImportDataContainerManager handler interface,
//      * ObjectExportManager - DataProcessorObject.ExportImportDataInfobaseDataExportManager -
//          Export manager of the current object.
//          For more information, see the comment to ExportImportDataInfobaseDataExportManager data processor API.
//          Parameter is passed only if procedures of handlers with versions not earlier than 1.0.0.1 specified upon registration are called.
//      * Serializer - XDTOSerializer - Serializer initialized with reference annotation support.
//          If an arbitrary export handler requires additional data export,
//          use XDTOSerializer passed to the BeforeExportType() procedure as the Serializer parameter value,
//          not obtained using the XDTOSerializer global context property,
//          
//          
//      * Object - ConstantValueManager, CatalogObject, DocumentObject -
//               - BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject -
//               - ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet -
//               - AccumulationRegisterRecordSet, AccountingRegisterRecordSet - 
//               - CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          Infobase data object exported after calling the handler.
//          Value passed to the BeforeExportObject() procedure.
//          It can be changed as the
//          Object parameter value in the BeforeExportObject() handler.
//          The changes will be reflected in the object serialization in export files, not in the infobase.
//      * Artifacts - Array of XDTODataObject - Set of additional information logically
//          associated with the object but not contained in it (object artifacts). Artifacts must be created
//          in the BeforeExportObject() handler and added to the array
//          passed as the Artifacts parameter value. Each artifact must be an XDTO data object,
//          for whose type an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type
//          is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem. The artifacts generated
//          in the BeforeExportObject() procedure will be available in the data import handler procedures
//          (see the comment to the OnRegisterDataImportHandlers() procedure).
//      * Cancel - Boolean - If the parameter value is set to True in the BeforeExportObject()
//           procedure, the corresponding object
//           is not exported.
//    * AfterUnloadingType - Boolean - a flag specifying whether the handler is called after all
//      infobase objects associated with this metadata object are exported. If set to True,
//      the common module of the handler must include the exportable procedure
//      BeforeExportType() supporting the following parameters:
//      * Container - DataProcessorObject.ExportImportDataContainerManager - a container
//          manager used for data export. For more information, see the comment
//          to ExportImportDataContainerManager handler interface,
//      * Serializer - XDTOSerializer - Serializer initialized with reference annotation support.
//          If an arbitrary export handler requires additional data export,
//          use XDTOSerializer passed to the BeforeExportType() procedure as the Serializer parameter value,
//          not obtained using the XDTOSerializer global context property,
//          
//          
//      * MetadataObject - MetadataObject - Handler is called after the object data is exported.
//
Procedure OnRegisterDataExportHandlers(HandlersTable) Export
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportUserFavorites;
	NewHandler.BeforeUploadingSettings = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

// Called upon registration of arbitrary data import handlers.
//
// Parameters:
//  HandlersTable - ValueTable - This procedure requires
//  that you add information on the arbitrary data import handlers being registered
//  to the value table. Columns::
//    MetadataObject - MetadataObject - Handler to be registered
//      is called when the object data is imported.
//    Handler - CommonModule - Common module implementing an arbitrary
//      data import handler. The set of export procedures to be implemented
//      in the handler depends on the values of the following
//      value table columns:
//    Version - String - Number of the interface version of data export/import handlers
//      supported by the handler.
//    BeforeMapRefs - Boolean - Flag specifying whether the handler must be called
//      before mapping the source infobase references and the current infobase references associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the BeforeMapRefs() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager handler interface.
//        MetadataObject - MetadataObject - Handler is called
//          before the object references are mapped.
//        StandardProcessing - Boolean - If set to False in BeforeMapRefs(),
//          the MapRefs() function of the corresponding
//          common module will be called instead of the standard reference mapping (searching the current infobase
//          for objects with the natural key values identical
//          to the values exported from the source infobase) in the
//          BeforeMapRefs() procedure whose StandardProcessing parameter value
//          was set to False.
//          MapRefs() function parameters:
//            Container - DataProcessorObject.ExportImportDataContainerManager - Container
//              manager used for data import. For more information, see the comment
//              to the ExportImportDataContainerManager handler interface.
//            SourceRefsTable - ValueTable - Contains details on references
//              exported from the original infobase. Columns:
//                SourceRef - AnyRef - Source infobase object reference
//                  to be mapped to the current infobase reference.
//                The other columns are identical to the object's natural key fields
//                  that were passed to the
//                  ExportImportInfobaseData.MustMapRefOnImport() function.
//          MapRefs function returns ValueTable. Columns:
//            SourceRef - AnyRef - Object reference exported from the source infobase.
//            Ref - AnyRef - Reference mapped the original reference in the current infobase.
//        Cancel - Boolean - If set to True in BeforeMapRefs(),
//          references matching the current metadata object
//          are not mapped.
//    BeforeImportType - Boolean - Flag that indicates whether to call the handler
//      before importing all data objects related to this metadata
//      object. If set to True, the common module of the handler must include
//      the BeforeExportType() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject -ExportImportContainerManagerData - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager handler interface.
//        MetadataObject - MetadataObject - Handler is called
//          before object data is imported.
//        Cancel - Boolean - If set to True in the BeforeImportType()
//          procedure, the data objects matching
//          the current metadata object are not imported.
//    BeforeImportObject - Boolean - Flag specifying whether the handler must be called
//      before importing the data object associated with this metadata
//      object. If set to True, the common module of the handler must
//      include the BeforeImportObject() exportable procedure
//      supporting the following parameters:
//        Container - DataProcessorObject.ExportImportDataContainerManager - Container
//          manager used for data import. For more information, see the comment
//          to the ExportImportDataContainerManager handler interface.
//        Object - Manager OfConstantValue, CatalogObject, DocumentObject, BusinessProcessObject, TaskObject,
//          ChartOfAccountsObject, ExchangePlanObject, ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject,
//          InformationRegisterRecordSet, AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet - Infobase data object
//          imported after the handler is called. Value passed to the BeforeImportObject() procedure as the Object parameter value
//          can be modified inside the BeforeImportObject() handler procedure.
//          Artifacts - Array of XDTODataObject - Additional data logically associated with the data object
//          but not contained in it. Generated in exportable procedures BeforeExportObject() of data export
//        handlers (see the comment to the OnRegisterDataExportHandlers() procedure). Each artifact
//          must be an XDTO object with an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type used as a base type
//          . You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//          Cancel - Boolean - If set this
//          parameter to True in the AImportObject() procedure, the data object is not imported.
//          AfterImportObject - Boolean - Flag specifying whether the handler must be called after
//        importing a data object associated with this metadata
//          object. If set to True, the common module of the handler must
//    include the AfterImportObject() exportable procedure 
//      supporting the following parameters:
//      Container - DataProcessorObject -ExportImportDataContainerManager - Container
//      manager used for data import. For more information, see the comment
//      to the ExportImportDataContainerManager handler interface.
//        Object - ManagerOfConstantValue, CatalogObject, DocumentObject,
//          BusinessProcessObject, TaskObject, ChartOfAccountsObject, ExchangePlanObject,
//          ChartOfCharacteristicTypesObject, ChartOfCalculationTypesObject, InformationRegisterRecordSet,
//        AccumulationRegisterRecordSet, AccountingRegisterRecordSet,
//          CalculationRegisterRecordSet, SequenceRecordSet, RecalculationRecordSet -
//          Infobase data object imported before the handler is called.
//          Artifacts - Array of XDTODataObject - Additional data logically associated
//          with the data object but not contained in it. Generated in the
//          BeforeExportObject() of data export handlers (see the comment to the
//        OnRegisterDataExportHandlers() procedure). Each artifact must be an XDTO data object,
//          for whose type an abstract {http://www.1c.ru/1cFresh/Data/Dump/1.0.2.1}Artefact XDTO type
//          is used as the base type. You can use XDTO packages
//          that are not included in the ExportImportData subsystem.
//          AfterImportType - Boolean - Flag specifying whether the handler must be called
//          after importing all data objects associated with this metadata
//          object. If set to True, the common module of the handler
//    must include the AfterImportType() exportable procedure
//      supporting the following parameters:
//      Container - DataProcessorObject.ExportImportDataContainerManager - Container
//      manager used for data import. For more information, see the comment
//      to the ExportImportDataContainerManager data processor API.
//        MetadataObject - MetadataObject - Handler is called after all its objects
//          are imported.
//          
//        
//          
//
Procedure OnRegisterDataImportHandlers(HandlersTable) Export
	
	NewHandler = HandlersTable.Add();
	NewHandler.Handler = ExportImportUserFavorites;
	NewHandler.BeforeDownloadingSettings = True;
	NewHandler.Version = ExportImportDataInternalEvents.HandlerVersion1_0_0_1();
	
EndProcedure

#EndRegion

#EndRegion


#Region Private

#Region DataUploadAndDownloadHandlers


// It is performed before importing settings.
// 
// Parameters:
// 	Container - DataProcessorObject.ExportImportDataUserSettingsImportManager -
// 	Serializer - XDTOSerializer - 
// 	NameOfSettingsStore - String - 
// 	SettingsKey - String - See the Syntax Assistant.
// 	ObjectKey - String - See the Syntax Assistant.
// 	Settings - ValueStorage - 
// 	User - InfoBaseUser - 
// 	Presentation - String - 
// 	Artifacts - Array of XDTODataObject - additional data.
// 	Cancel - Boolean - indicates that processing is canceled.
Procedure BeforeUploadingSettings(Container, Serializer, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	If TypeOf(Settings) = Type("UserWorkFavorites") Then
		
		For Each FavoritesElement In Settings Do
			
			NewArtifact = XDTOFactory.Create(ArtifactTypeFavoritesItem());
			NewArtifact.Important = FavoritesElement.Important;
			NewArtifact.URL = MappingNavigationLinkToArtifact(FavoritesElement.URL);
			NewArtifact.Presentation = FavoritesElement.Presentation;
			
			Artifacts.Add(NewArtifact);
			
		EndDo;
		
		Settings = New UserWorkFavorites();
		
	EndIf;
	
EndProcedure

Procedure BeforeDownloadingSettings(Container, NameOfSettingsStore, SettingsKey, ObjectKey, Settings, User, Presentation, Artifacts, Cancel) Export
	
	If TypeOf(Settings) = Type("UserWorkFavorites") Then
		
		For Each Artifact In Artifacts Do
			
			If Artifact.Type() = ArtifactTypeFavoritesItem() Then
				
				NewItem = New UserWorkFavoritesItem();
				NewItem.Important = Artifact.Important;
				NewItem.URL = NavigationLinkForMappingToArtifact(Artifact.URL);
				NewItem.Presentation = Artifact.Presentation;
				
				Settings.Add(NewItem);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

#EndRegion

Function NavigationLinkForMappingToArtifact(Val Representation)
	
	Result = Representation.Template;
	
	If Representation.MainRef <> Undefined Then
		
		Var_Key = Representation.MainRef.Key;
		Ref = Representation.MainRef.Value;
		
		Result = StrReplace(Result, String(Var_Key) + ".Type", Ref.Metadata().FullName());
		Result = StrReplace(Result, String(Var_Key) + ".UUID",
			MappingUniqueIdentifierToNavigationLinkFormat(Ref.UUID()));
		
	EndIf;
	
	For Each DisplayingAdditionalLink In Representation.AdditionalRef Do
		
		Var_Key = DisplayingAdditionalLink.Key;
		Ref = DisplayingAdditionalLink.Value;
		
		TypeRow = Common.TypePresentationString(TypeOf(Ref));
		Id_String = MappingUniqueIdentifierToNavigationLinkFormat(Ref.UUID());
		
		If DisplayingAdditionalLink.RequreTypeAnnotition Then
			
			SubstitutionString = TypeRow + ":" + Id_String;
			
		Else
			
			SubstitutionString = Id_String;
			
		EndIf;
		
		SubstitutionString = EncodeString(SubstitutionString, StringEncodingMethod.URLEncoding);
		
		Result = StrReplace(Result, String(Var_Key) + ".UUID", SubstitutionString);
		
	EndDo;
	
	RefStructure = NavigationLinkStructure_(Result);
	
	Result = RefStructure.Protocol + "/" + RefStructure.Type;
	
	If ValueIsFilled(RefStructure.Path) Then
		Result = Result + "/" + RefStructure.Path;
	EndIf;
	
	If ValueIsFilled(RefStructure.Parameters) Then
		Result = Result + "?" + RefStructure.Parameters;
	EndIf;
	
	Return Result;
	
EndFunction

Function MappingNavigationLinkToArtifact(Val URL)
	
	Representation = XDTOFactory.Create(TypeMappingNavigationLinkToArtifact());
	Representation.Template = URL;
	
	RefStructure = NavigationLinkStructure_(URL);
	
	If ThisIsNavigationLinkToInformationBaseObject(RefStructure) Then
		
		MetadataObject = MetadataObjectAlongPathInNavigationLink(RefStructure.Path);
		
		If MetadataObject <> Undefined Then
			
			If CommonCTL.IsRefData(MetadataObject) Then
				
				Var_Key = New UUID();
				
				Representation.MainRef = XDTOFactory.Create(TypeMappingLinkToArtifact());
				Representation.MainRef.Key = Var_Key;
				
				Representation.Template = StrReplace(Representation.Template, MetadataObject.FullName(), String(Var_Key) + ".Type");
				
			EndIf;
			
			LinksInParameters = LinksInNavigationLinkParameters(RefStructure.Parameters, MetadataObject);
			
			For Each String In LinksInParameters Do
				
				Representation.Template = StrReplace(Representation.Template, String.OriginalSubstring, String.DecodedSubstring);
				
				If String.ParameterName = "ref" Then
					
					Representation.MainRef.Value = XDTOSerializer.WriteXDTO(String.Ref);
					Representation.MainRef.RequreTypeAnnotition = String.RequiresTypeAnnotationInNavigationLink;
					Representation.Template = StrReplace(Representation.Template, String.SubstringLinks, String(Var_Key) + ".UUID");
					
				Else
					
					Var_Key = New UUID();
					
					DisplayingAdditionalLink = XDTOFactory.Create(TypeMappingLinkToArtifact());
					DisplayingAdditionalLink.Key = Var_Key;
					DisplayingAdditionalLink.Value = XDTOSerializer.WriteXDTO(String.Ref);
					DisplayingAdditionalLink.RequreTypeAnnotition = String.RequiresTypeAnnotationInNavigationLink;
					
					AdditionalLinks = Representation.AdditionalRef; // XDTOList
					AdditionalLinks.Add(DisplayingAdditionalLink);
					
					Representation.Template = StrReplace(Representation.Template, String.SubstringLinks, String(Var_Key) + ".UUID");
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Return Representation;
	
EndFunction

Function ThisIsNavigationLinkToInformationBaseObject(Val NavigationLinkStructure_)
	
	If NavigationLinkStructure_.Protocol = "e1cib"
		And NavigationLinkStructure_.Type = "data"
		And Not IsBlankString(NavigationLinkStructure_.Parameters) Then // Not localizable.
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function NavigationLinkStructure_(Val URL)
	
	Result = New Structure;
	Result.Insert("Protocol", "");
	Result.Insert("Type", "");
	Result.Insert("Path", "");
	Result.Insert("Parameters", "");
	
	SubstringsOfLink = StrSplit(URL, "/");
	
	If SubstringsOfLink.Count() >= 1 Then
		Result.Protocol = SubstringsOfLink[0];
	EndIf;
	
	If SubstringsOfLink.Count() >= 2 Then
		Result.Type = SubstringsOfLink[1];
	EndIf;
	
	If SubstringsOfLink.Count() >= 3 Then
		
		Body = SubstringsOfLink[2];
		
		SeparatorPosition = StrFind(Body, "?");
		
		If SeparatorPosition = 0 Then
			
			Result.Path = Body;
			Result.Parameters = "";
			
		Else
			
			Result.Path = Left(Body, SeparatorPosition - 1);
			Result.Parameters = StrReplace(Body, Result.Path + "?", "");
			
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function MetadataObjectAlongPathInNavigationLink(Val PathString)
	
	PathStructure = StrSplit(PathString, ".");
	
	If PathStructure.Count() >= 2 Then
		
		Return Metadata.FindByFullName(PathStructure[0] + "." + PathStructure[1]);
		
	EndIf;
	
	Return Undefined;
	
EndFunction

Function LinksInNavigationLinkParameters(Val ParametersString1, Val MetadataObject)
	
	Result = New ValueTable();
	Result.Columns.Add("OriginalSubstring", New TypeDescription("String"));
	Result.Columns.Add("DecodedSubstring", New TypeDescription("String"));
	Result.Columns.Add("ParameterName", New TypeDescription("String"));
	Result.Columns.Add("Ref", CommonCTLCached.RefTypesDetails());
	Result.Columns.Add("SubstringLinks", New TypeDescription("String"));
	Result.Columns.Add("RequiresTypeAnnotationInNavigationLink", New TypeDescription("Boolean"));
	
	Substrings = StrSplit(ParametersString1, "&");
	
	For Each Substring In Substrings Do
		
		SeparatorPosition = StrFind(Substring, "=");
		
		FieldName = Left(Substring, SeparatorPosition - 1);
		Simple = StrReplace(Substring, FieldName + "=", "");
		
		If Not CommonCTL.IsEnum(MetadataObject)
			And CommonCTL.IsRefData(MetadataObject) 
			And FieldName = "ref" Then
			
			Manager = Common.ObjectManagerByFullName(MetadataObject.FullName());
			RefUUID = UniqueIDFromDisplayInNavigationLinkFormat(Simple);

			If RefUUID <> Undefined Then
			
				Ref = Manager.GetRef(RefUUID);
				
				ResultString1 = Result.Add();
				ResultString1.OriginalSubstring = Substring;
				ResultString1.DecodedSubstring = Substring;
				ResultString1.ParameterName = "ref";
				ResultString1.Ref = Ref;
				ResultString1.SubstringLinks = Simple;
				ResultString1.RequiresTypeAnnotationInNavigationLink = False;
				
			EndIf;

		ElsIf CommonCTL.IsRecordSet(MetadataObject) Then
			
			OriginalFieldValue = Simple;
			Simple = DecodeString(Simple, StringEncodingMethod.URLEncoding);
			
			MeasurementField = MetadataObject.Dimensions.Find(FieldName);
			
			If MeasurementField = Undefined Then
				
				NumberOfPossibleTypes = 0;
				
			Else
				
				NumberOfPossibleTypes = NumberOfReferenceTypesInTypeDescription(MeasurementField.Type);
				
			EndIf;
			
			If NumberOfPossibleTypes = 1 Then
				
				RequiresTypeAnnotationInNavigationLink = False;
				Id_String = IdStringFromDisplayInNavigationLinkFormat(Simple);
				
				If Not StringFunctionsClientServer.IsUUID(Id_String) Then
					Continue;
				EndIf;
					
				EmptyRef = New(MeasurementField.Type.Types()[0]);
				
				If CommonCTL.IsEnum(EmptyRef.Metadata()) Then
					Continue;
				EndIf;
				
				Manager = Common.ObjectManagerByFullName(EmptyRef.Metadata().FullName());
				RefUUID = New UUID(Id_String);
				Ref = Manager.GetRef(RefUUID);
				
			ElsIf NumberOfPossibleTypes > 1 Then
				
				RequiresTypeAnnotationInNavigationLink = True;
				PositionOfTypeSeparator = StrFind(Simple, ":");
				
				If PositionOfTypeSeparator > 0 Then
					
					TypeName = Left(Simple, PositionOfTypeSeparator - 1);
					Id_String = IdStringFromDisplayInNavigationLinkFormat(
						StrReplace(Simple, TypeName + ":", ""));
					
					If Not StringFunctionsClientServer.IsUUID(Id_String) Then
						Continue;
					EndIf;
					
					EmptyRef = New(Type(TypeName));
					
					If CommonCTL.IsEnum(EmptyRef.Metadata()) Then
						Continue;
					EndIf;
				
					Manager = Common.ObjectManagerByFullName(EmptyRef.Metadata().FullName());
					RefUUID = New UUID(Id_String);
					Ref = Manager.GetRef(RefUUID);
					
				Else
					
					Continue;
					
				EndIf;
				
			Else
				
				Continue;
				
			EndIf;
			
			ResultString1 = Result.Add();
			ResultString1.OriginalSubstring = Substring;
			ResultString1.DecodedSubstring = StrReplace(Substring, OriginalFieldValue, Simple);
			ResultString1.ParameterName = FieldName;
			ResultString1.Ref = Ref;
			ResultString1.SubstringLinks = Simple;
			ResultString1.RequiresTypeAnnotationInNavigationLink = RequiresTypeAnnotationInNavigationLink;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function NumberOfReferenceTypesInTypeDescription(Val TypeDescription)
	
	Result = 0;
	
	For Each Type In TypeDescription.Types() Do
		
		If Not CommonCTL.IsPrimitiveType(Type) Then
			
			Result = Result + 1;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

Function MappingUniqueIdentifierToNavigationLinkFormat(Val Id)
	
	LinkID = String(Id);
	
	Return Mid(LinkID, 20, 4)
		+ Mid(LinkID, 25)
		+ Mid(LinkID, 15, 4)
		+ Mid(LinkID, 10, 4)
		+ Mid(LinkID, 1, 8);
	
EndFunction

Function UniqueIDFromDisplayInNavigationLinkFormat(Val Representation)
	
	Id_String = IdStringFromDisplayInNavigationLinkFormat(Representation);
	If StringFunctionsClientServer.IsUUID(Id_String) Then
		Return New UUID(Id_String);
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function IdStringFromDisplayInNavigationLinkFormat(Val Representation)
	
	FirstPart    = Mid(Representation, 25, 8);
	SecondPart    = Mid(Representation, 21, 4);
	ThirdPart    = Mid(Representation, 17, 4);
	FourthPart = Mid(Representation, 1,  4);
	FifthPart     = Mid(Representation, 5,  12);
	
	Return FirstPart + "-" + SecondPart + "-" + ThirdPart + "-" + FourthPart + "-" + FifthPart;
	
EndFunction

Function ArtifactTypeFavoritesItem()
	
	Return XDTOFactory.Type(Package(), "FavoriteItemArtefact");
	
EndFunction

Function TypeMappingNavigationLinkToArtifact()
	
	Return XDTOFactory.Type(Package(), "URL");
	
EndFunction

Function TypeMappingLinkToArtifact()
	
	Return XDTOFactory.Type(Package(), "URLRef");
	
EndFunction

Function Package()
	
	Return "http://www.1c.ru/1cFresh/Data/Artefacts/UserWorkFavorites/1.0.0.1";
	
EndFunction

#EndRegion
