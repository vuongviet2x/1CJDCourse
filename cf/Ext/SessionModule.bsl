
Procedure SessionParametersSetting(RequiredParameters)
	
	CurrentSession = GetCurrentInfoBaseSession();
	BackgroundJob = CurrentSession.GetBackgroundJob();
	If BackgroundJob <> Undefined Then
		// This session is started in a background job
	Else
		// This session is started not in a backgroung job
	EndIf;
	
EndProcedure
