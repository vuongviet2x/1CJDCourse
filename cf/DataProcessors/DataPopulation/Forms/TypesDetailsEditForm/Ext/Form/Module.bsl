///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TypeDescription = Parameters.TypeDescription;
	MetadataObject = Parameters.MetadataObject;
	ObjectMetadata = Common.MetadataObjectByFullName(MetadataObject);
	
	Items.TypeDescription.AvailableTypes = New TypeDescription(ObjectMetadata.Type);
	
EndProcedure

&AtClient
Procedure Select(Command)
	
	Close(TypeDescription);
	
EndProcedure

#EndRegion
