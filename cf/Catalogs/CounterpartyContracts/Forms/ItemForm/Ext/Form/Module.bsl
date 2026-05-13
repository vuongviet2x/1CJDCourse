
&AtClient
Procedure OnOpen(Cancel)

	CalculateDaysLeft();
	ChangeDaysLeftVisibility();

EndProcedure

&AtClient
Procedure ValudUntilOnChange(Item)
	
	CalculateDaysLeft();
	ChangeDaysLeftVisibility();
	
EndProcedure

&AtServer
Procedure CalculateDaysLeft()

	CurrentDate = CurrentSessionDate();
	
	If ValueIsFilled(Object.ValidUntil) Then
		DaysLeft = Round((Object.ValidUntil - CurrentDate) / 86400);
	Else
		DaysLeft = 0;
	EndIf;
	
	
EndProcedure

&AtClient
Procedure ChangeDaysLeftVisibility()

	Items.DaysLeft.Visible = ValueIsFilled(Object.ValidUntil);
	
EndProcedure
