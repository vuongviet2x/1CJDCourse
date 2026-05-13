////////////////////////////////////////////////////////////////////////////////
// "Data import and export" subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

// Returns metadata objects separated by separators in the "Independent and shared" mode of data
//  separation.
//
// Returns:
//   FixedStructure:
//     * Key - String - a separator name,
//     * Value - FixedStructure:
//       ** Constants - Array of String - an array of full constant names, separated by a separator,
//       ** Objects - Array of String - an array of full object names, separated by a separator,
//       ** RecordSets - Array of String - an array of full record set names, separated by a separator.
//
Function SharedMetadataObjects_() Export
	
	Cache = New Structure();
	
	Separators = SeparatorsWithSplitTypeIndependentlyAndJointly(); // Array of MetadataObjectCommonAttribute
	
	For Each Separator In Separators Do
		
		StructureOfSeparatedObjects = New Structure("Constants,Objects,RecordSets", New Array(), New Array(), New Array());
		
		AutoUse = (Separator.AutoUse = Metadata.ObjectProperties.CommonAttributeAutoUse.Use);
		
		For Each CompositionItem In Separator.Content Do
			
			If CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Use
					Or (AutoUse And CompositionItem.Use = Metadata.ObjectProperties.CommonAttributeUse.Auto) Then
				
				If CommonCTL.IsConstant(CompositionItem.Metadata) Then
					StructureOfSeparatedObjects.Constants.Add(CompositionItem.Metadata.FullName());
				ElsIf CommonCTL.IsRefData(CompositionItem.Metadata) Then
					StructureOfSeparatedObjects.Objects.Add(CompositionItem.Metadata.FullName());
				ElsIf CommonCTL.IsRecordSet(CompositionItem.Metadata) Then
					StructureOfSeparatedObjects.RecordSets.Add(CompositionItem.Metadata.FullName());
				EndIf;
				
			EndIf;
			
			Cache.Insert(Separator.Name, New FixedStructure(StructureOfSeparatedObjects));
			
		EndDo;
		
	EndDo;
	
	Return New FixedStructure(Cache);
	
EndFunction

#EndRegion

#Region Private

Function SeparatorsWithSplitTypeIndependentlyAndJointly()
	
	Result = New Array();
	
	For Each CommonAttribute In Metadata.CommonAttributes Do
		
		If CommonAttribute.DataSeparation = Metadata.ObjectProperties.CommonAttributeDataSeparation.Separate
				And CommonAttribute.SeparatedDataUse = Metadata.ObjectProperties.CommonAttributeSeparatedDataUse.IndependentlyAndSimultaneously Then
			
			Result.Add(CommonAttribute);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion