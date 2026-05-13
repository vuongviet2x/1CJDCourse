
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() Then
	
		
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangesEmployeeOnChange(Item)
	
	CurrentData = Items.Changes.CurrentData;
	
	If ValueIsFilled(CurrentData.Employee) And Not EmployeeIsOldEnough(CurrentData.Employee, Object.Date) Then
		CurrentData.Employee = Undefined;
		MessageText = StrTemplate(
			"Employee %1 is under 16 years old on a document's date. You can't hire him",
			CurrentData.Employee
		);
		Message(MessageText);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function EmployeeIsOldEnough(Employee, Date)

	DateOfBirth = Employee.DateOfBirth;
	
	Return DateOfBirth <= AddMonth(Date, -16 * 12);
	
EndFunction
