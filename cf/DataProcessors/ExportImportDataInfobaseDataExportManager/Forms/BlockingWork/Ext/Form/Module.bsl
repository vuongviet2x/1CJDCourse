
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetPrivilegedMode(True);
	Job = BackgroundJobs.FindByUUID(Parameters.JobID);
	If Job <> Undefined
		And StrStartsWith(Job.MethodName, "JobsQueue") Then
		Title = NStr("ru = 'Резервное копирование';
						|en = 'Backup';");
		Items.LabelDecoration.Title = 
			NStr("ru = 'Подождите, выполняется резервное копирование, работа временно невозможна';
				|en = 'Please wait, backup is in progress. Operations are temporarily unavailable';");
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("WaitHandler", 3);

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Return;
	EndIf;
	
	If Not IsJobCompleted Then
		Cancel = True;
	EndIf;

EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure WaitHandler()
	
	If Not TaskIsRunning(Parameters.JobID) Then
		DetachIdleHandler("WaitHandler");
		IsJobCompleted = True;
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function TaskIsRunning(JobID)
	SetPrivilegedMode(True);
	Job = BackgroundJobs.FindByUUID(JobID);
	Return Job <> Undefined And Job.State = BackgroundJobState.Active;
EndFunction

#EndRegion
