///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns a flag indicating if there are any common separators in the configuration.
//
// Returns:
//   Boolean - True if the configuration is separated.
//
Function IsSeparatedConfiguration() Export
	
	HasSeparators = False;
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			HasSeparators = True;
			Break;
		EndIf;
	EndDo;
	
	Return HasSeparators;
	
EndFunction

// Returns a flag that shows whether the metadata object is used in common separators.
//
// Parameters:
//   FullMetadataObjectName - String - metadata object name.
//   Separator - String - a name of the common separator attribute that is checked if it separates the metadata object.
//
// Returns:
//   Boolean - True if the object is separated.
//
Function IsSeparatedMetadataObject(Val FullMetadataObjectName, Val Separator = Undefined) Export
	
	If Separator = Undefined Then
		SeparationByMainProps = SaaSOperations.SeparatedMetadataObjects(SaaSOperations.MainDataSeparator());
		SeparationByAuxiliaryProps = SaaSOperations.SeparatedMetadataObjects(SaaSOperations.AuxiliaryDataSeparator());
		Result = SeparationByMainProps.Get(FullMetadataObjectName) <> Undefined
			Or SeparationByAuxiliaryProps.Get(FullMetadataObjectName) <> Undefined;
		Return Result;
	Else
		SeparatedMetadataObjects = SaaSOperations.SeparatedMetadataObjects(Separator);
		Return SeparatedMetadataObjects.Get(FullMetadataObjectName) <> Undefined;
	EndIf;
	
EndFunction

// Returns the data separation mode flag
// (conditional separation).
// 
// Returns False if the configuration does not support data separation mode
// (does not contain attributes to share).
//
// Returns:
//  Boolean - If True, separation is enabled.
//  Boolean - False is separation is disabled or not supported.
//
Function DataSeparationEnabled() Export
	
	If Not IsSeparatedConfiguration() Then
		Return False;
	EndIf;
	
	If Not GetFunctionalOption("SaaSOperations") Then
		Return False;
	EndIf;
	
	Return True;
	
EndFunction

// Returns an array of serialized structural types currently supported.
//
// Returns:
//   FixedArray of Type - Type items.
//
Function SerializableStructuralTypes() Export
	
	TypesArray = New Array;
	
	TypesArray.Add(Type("Structure"));
	TypesArray.Add(Type("FixedStructure"));
	TypesArray.Add(Type("Array"));
	TypesArray.Add(Type("FixedArray"));
	TypesArray.Add(Type("Map"));
	TypesArray.Add(Type("FixedMap"));
	TypesArray.Add(Type("KeyAndValue"));
	TypesArray.Add(Type("ValueTable"));
	
	Return New FixedArray(TypesArray);
	
EndFunction

// Returns the endpoint for sending messages to the Service Manager.
//
// Returns:
//  ExchangePlanRef.MessagesExchange - node matching the service manager.
//
Function ServiceManagerEndpoint() Export
	
	Return SaaSOperationsCTL.ServiceManagerEndpoint();
	
EndFunction

// Returns mapping between user contact information kinds and kinds.
// Contact information used in the XDTO SaaS.
//
// Returns:
//  FixedMap of KeyAndValue - Contact information kind mapping.:
//  * Key - CatalogRef.ContactInformationKinds
//  * Value - String
//
Function MatchingUserSAITypesToXDTO() Export
	
	Map = New Map;
	Map.Insert(Catalogs.ContactInformationKinds.UserEmail, "UserEMail");
	Map.Insert(Catalogs.ContactInformationKinds.UserPhone, "UserPhone");
	
	Return New FixedMap(Map);
	
EndFunction

// Returns mapping between user contact information kinds and XDTO kinds.
// User CI.
//
// Returns:
//  FixedMap of KeyAndValue - Contact information kind mapping.:
//  * Key - String
//  * Value - CatalogRef.ContactInformationKinds
//
Function ComplianceOfKixdtoTypesWithUserKiTypes() Export
	
	Map = New Map;
	For Each KeyAndValue In MatchingUserSAITypesToXDTO() Do
		Map.Insert(KeyAndValue.Value, KeyAndValue.Key);
	EndDo;
	
	Return New FixedMap(Map);
	
EndFunction

// Returns mapping between XDTO rights used in SaaS and possible
// actions with SaaS user.
// 
// Returns:
//  FixedMap of KeyAndValue - Mapping between rights and actions:
//  * Key - String
//  * Value - String
//
Function ComplianceOfXDTORightsWithActionsWithServiceUser() Export
	
	Map = New Map;
	Map.Insert("ChangePassword", "EditPassword");
	Map.Insert("ChangeName", "ChangeName");
	Map.Insert("ChangeFullName", "ChangeFullName");
	Map.Insert("ChangeAccess", "ChangeAccess");
	Map.Insert("ChangeAdmininstrativeAccess", "ChangeAdministrativeAccess");
	
	Return New FixedMap(Map);
	
EndFunction

// Returns data model details of data area.
//
// Returns:
//  FixedMap of KeyAndValue - Area data model.:
//    * Key - MetadataObject - a metadata object.
//    * Value - String - a name of the common attribute separator.
//
Function GetAreaDataModel() Export
	
	Result = New Map();
	
	MainDataSeparator = SaaSOperations.MainDataSeparator();
	CoreAreaData = SeparatedMetadataObjects(
		MainDataSeparator);
	For Each AreaMasterDataElement In CoreAreaData Do
		Result.Insert(AreaMasterDataElement.Key, AreaMasterDataElement.Value);
	EndDo;
	
	AuxiliaryDataSeparator = SaaSOperations.AuxiliaryDataSeparator();
	SupportingAreaData = SaaSOperations.SeparatedMetadataObjects(
		AuxiliaryDataSeparator);
	For Each AreaAuxiliaryDataElement In SupportingAreaData Do
		Result.Insert(AreaAuxiliaryDataElement.Key, AreaAuxiliaryDataElement.Value);
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns an array of the separators that are in the configuration.
//
// Returns:
//   FixedArray of String - an array of names of common attributes which
//     serve as separators.
//
Function ConfigurationSeparators() Export
	
	SeparatorArray = New Array;
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
			SeparatorArray.Add(CommonAttribute.Name);
		EndIf;
	EndDo;
	
	Return New FixedArray(SeparatorArray);
	
EndFunction

// Returns the common attribute content by the passed name.
//
// Parameters:
//   Name - String - Name of a common attribute.
//
// Returns:
//   CommonAttributeContent - list of metadata objects that include the common attribute.
//
Function CommonAttributeContent(Val Name) Export
	
	Return Metadata.CommonAttributes[Name].Content;
	
EndFunction

// Returns a list of full names of all metadata objects used in the common separator attribute
//  (whose name is passed in the Separator parameter) and values of object metadata properties
//  that can be required for further processing in universal algorithms.
// In case of sequences and document journals the function determines whether they are separated by included documents: any one from the sequence or journal.
//
// Parameters:
//  Separator - String - a name of a common attribute.
//
// Returns:
// FixedMap of KeyAndValue:
//  * Key - String - a full name of a metadata object,
//  * Value - FixedStructure - with the following fields::
//    ** Name - String - a metadata object name
//    ** Separator - String - a name of the separator that separates the metadata object,
//    ** ConditionalSeparation - String - a full name of the metadata object that shows whether the metadata object data
//      separation is enabled.
//
Function SeparatedMetadataObjects(Val Separator) Export
	
	Result = New Map;
	
	// i. Loop through all common attributes.
	
	MetadataOfCommonProps = Metadata.CommonAttributes.Find(Separator);
	If MetadataOfCommonProps = Undefined Then
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Общий реквизит %1 не обнаружен в конфигурации.';
																						|en = 'Common attribute %1 is not found in the configuration.';"), Separator);
	EndIf;
	
	If MetadataOfCommonProps.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate Then
		
		CommonAttributeContent = CommonAttributeContent(MetadataOfCommonProps.Name);
		
		DataSeparationEnabled = SaaSOperations.DataSeparationEnabled();
		NotUseCommonAttribute = (MetadataOfCommonProps.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.DontUse);
		Auto = Metadata.ObjectProperties.CommonAttributeUse.Auto;
		DontUse = Metadata.ObjectProperties.CommonAttributeUse.DontUse;
		
		For Each CompositionItem In CommonAttributeContent Do
			
			Use = CompositionItem.Use;
			
			// When separation is disabled, the Auto common attribute is used for all extension objects.
			If Not DataSeparationEnabled
				And CompositionItem.Metadata.ConfigurationExtension() <> Undefined Then
				
				Use = Auto;
				
			EndIf;
			
			If NotUseCommonAttribute And Use = Auto Or Use = DontUse Then
				
				Continue;
				
			EndIf;
			
			AdditionalData = NewAdditionalData(CompositionItem.Metadata.Name, Separator, Undefined);
			If CompositionItem.ConditionalSeparation <> Undefined Then
				AdditionalData.ConditionalSeparation = CompositionItem.ConditionalSeparation.FullName();
			EndIf;
			
			Result.Insert(CompositionItem.Metadata.FullName(), New FixedStructure(AdditionalData));
			
			// Recalculation separation is determined by the calculation register where it belongs.
			If Common.IsCalculationRegister(CompositionItem.Metadata) Then
				
				Перерасчеты = CompositionItem.Metadata.Recalculations;
				For Each Recalculation In Перерасчеты Do
					
					AdditionalData.Name = Recalculation.Name;
					Result.Insert(Recalculation.FullName(), New FixedStructure(AdditionalData));
					
				EndDo;
				
			EndIf;
				
		EndDo;
		
	Else
		
		Raise StringFunctionsClientServer.SubstituteParametersToString(NStr("ru = 'Для общего реквизита %1 не используется разделение данных.';
																						|en = 'Data separation is not used for the %1 common attribute.';"), Separator);
		
	EndIf;
	
	// ii. For sequences and journals, define their separation by the incoming documents.
	
	// 1. Loop through Sequences and check for the first document. If no document is found, the journal is assumed to be separated.
	For Each MetadataSequences In Metadata.Sequences Do
		
		AdditionalData = NewAdditionalData(MetadataSequences.Name, Separator, Undefined);
		
		If MetadataSequences.Documents.Count() = 0 Then
			
			MessageTemplate = NStr("ru = 'В последовательность %1 не включено ни одного документа.';
									|en = 'Sequence %1 does not include any documents.';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, MetadataSequences.Name);
			WriteLogEvent(NStr("ru = 'Получение разделенных объектов метаданных';
											|en = 'Getting separated metadata objects';", 
				Common.DefaultLanguageCode()), EventLogLevel.Error, 
				MetadataSequences, , MessageText);
			
			Result.Insert(MetadataSequences.FullName(), New FixedStructure(AdditionalData));
			
		Else
			
			For Each MetadataOfDocument In MetadataSequences.Documents Do
				
				AdditionalDataFromDocument = Result.Get(MetadataOfDocument.FullName());
				
				If AdditionalDataFromDocument <> Undefined Then
					FillPropertyValues(AdditionalData, AdditionalDataFromDocument, "Separator,ConditionalSeparation");
					Result.Insert(MetadataSequences.FullName(), New FixedStructure(AdditionalData));
				EndIf;
				
				Break;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	// 2. Loop through Journals and check for the first document. If no document is found, the journal is assumed to be separated.
	For Each DocumentLogMetadata In Metadata.DocumentJournals Do
		
		AdditionalData = NewAdditionalData(DocumentLogMetadata.Name, Separator, Undefined);
		
		If DocumentLogMetadata.RegisteredDocuments.Count() = 0 Then
			
			MessageTemplate = NStr("ru = 'В журнал %1 не включено ни одного документа.';
									|en = 'Journal %1 does not contain any documents.';");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, DocumentLogMetadata.Name);
			WriteLogEvent(NStr("ru = 'Получение разделенных объектов метаданных';
											|en = 'Getting separated metadata objects';", 
				Common.DefaultLanguageCode()), EventLogLevel.Error, 
				DocumentLogMetadata, , MessageText);
			
			Result.Insert(DocumentLogMetadata.FullName(), New FixedStructure(AdditionalData));
			
		Else
			
			For Each MetadataOfDocument In DocumentLogMetadata.RegisteredDocuments Do
				
				AdditionalDataFromDocument = Result.Get(MetadataOfDocument.FullName());
				
				If AdditionalDataFromDocument <> Undefined Then
					FillPropertyValues(AdditionalData, AdditionalDataFromDocument, "Separator,ConditionalSeparation");
					Result.Insert(DocumentLogMetadata.FullName(), New FixedStructure(AdditionalData));
				EndIf;
				
				Break;
				
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return New FixedMap(Result);
	
EndFunction

// Returns the flag indicating whether the Service Manager has a configured endpoint.
//
// Returns:
//  Boolean - If True, the endpoint is configured and the username is assigned a value in the transport settings.
//
Function ServiceManagerEndpointConfigured() Export
	
	Return SaaSOperations.ServiceManagerEndpointConfigured()
	
EndFunction

#EndRegion

#Region Private

// New additional data.
// 
// Parameters:
//  Name - String
//  Separator - Number
//  ConditionalSeparation - String
// 
// Returns:
//  Structure:
// * Name - String
// * Separator - Number
// * ConditionalSeparation - String
Function NewAdditionalData(Name, Separator, ConditionalSeparation = Undefined)
	
	AdditionalData = New Structure;
	AdditionalData.Insert("Name", Name);
	AdditionalData.Insert("Separator", Separator);
	AdditionalData.Insert("ConditionalSeparation", ConditionalSeparation);
	
	Return AdditionalData;
	
EndFunction

#EndRegion
