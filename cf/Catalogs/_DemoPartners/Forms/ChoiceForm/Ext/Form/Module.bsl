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

	List.Parameters.SetParameterValue("ExternalAccessOnly", Parameters.ExternalAccessOnly);
	
	// StandardSubsystems.Users
	ExternalUsers.ShowExternalUsersListView(ThisObject);
	// End StandardSubsystems.Users

EndProcedure

&AtServerNoContext
Procedure ListOnGetDataAtServer(TagName, Settings, Rows)
	
	// StandardSubsystems.Users
	ExternalUsers.ExternalUserListOnRetrievingDataAtServer(TagName, Settings, Rows);
	// End StandardSubsystems.Users

EndProcedure

#EndRegion