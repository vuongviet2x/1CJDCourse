////////////////////////////////////////////////////////////////////////////////
// Remote administration subsystem.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// Called upon session termination using the UsersSessions subsystem.
//
// Parameters:
//  OwnerForm - ClientApplicationForm - used to terminate the session,
//  SessionsNumbers - Number - a number of the session to be terminated,
//  StandardProcessing - Boolean - indicates whether standard session termination processing is executed
//    (connection to the server agent via COM connection or administration server
//    requesting cluster connection parameters from the current user). Can be
//    set to False in the event handler. In this case, standard
//    session termination processing is not performed,
//  NotificationAfterTerminateSession - NotifyDescription - the procedure
//    called after the session is terminated (to automatically refresh the active
//    user list). If the StandardProcessing parameter value is set to False,
//    once the session is terminated, use the ExecuteNotificationProcessing method
//    to execute a data processor for the passed notification details. Pass DialogReturnCode.OK
//    as the Result parameter value if the session
//    is terminated successfully). You can omit the parameter and skip
//    the notification processing.
//
Procedure OnEndSessions(OwnerForm, Val SessionsNumbers, StandardProcessing, Val NotificationAfterTerminateSession = Undefined) Export
	
	If CommonClient.DataSeparationEnabled() Then
		
		If CommonClient.SeparatedDataUsageAvailable() Then
			
			StandardProcessing = False;
			
			FormParameters = New Structure();
			FormParameters.Insert("SessionsNumbers", SessionsNumbers);
			
			NotifyDescription = New NotifyDescription(
				"AfterSessionTermination", ThisObject, New Structure("NotifyDescription", NotificationAfterTerminateSession));
			
			OpenForm("CommonForm.SessionsTerminationSaaS",
				FormParameters,
				OwnerForm,
				SessionsNumbers,
				,
				,
				NotifyDescription,
				FormWindowOpeningMode.LockOwnerWindow);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

// Called after the session is closed. Provides source details of a notification from the
// ActiveUsers processing form to update a list of active users after the session is closed.
//
// Parameters:
//  Result - Arbitrary - not analyzed in this procedure. It is to be passed to the source notification details.
//  Context - Structure - with the following fields::
//   * NotifyDescription - NotifyDescription - source notification details.
//
Procedure AfterSessionTermination(Result, Context) Export
	
	If Context.NotifyDescription <> Undefined Then
		
		ExecuteNotifyProcessing(Context.NotifyDescription, Result);
		
	EndIf;
	
EndProcedure

#EndRegion

