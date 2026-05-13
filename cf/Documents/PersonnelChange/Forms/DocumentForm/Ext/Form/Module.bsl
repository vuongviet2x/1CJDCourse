
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Month = "January 2024";
	
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

&AtClient
Procedure ChangesEmployeeStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Object.OperationKind = PredefinedValue("Enum.OperationKindsPersonnelChange.Dismissal") Then
		StandardProcessing = False;
		
		OpenParameters = New Structure("Filter", New Structure("Date, Company", Object.Date, Object.Company));
		
		OpenForm("Catalog.Employees.Form.WorkingEmployees", OpenParameters, Item);
	EndIf;

	//FillChoiceData(ChoiceData);

EndProcedure

&AtServerNoContext
Procedure FillChoiceData(ChoiceData)

	ChoiceData = New ValueList;
	Selection = Catalogs.Employees.Select();
	Counter = 0;
	While Selection.Next() Do
		Counter = Counter + 1;
		NewElement = ChoiceData.Add(Selection.Ref, Selection.Description);
	EndDo;
	
EndProcedure



