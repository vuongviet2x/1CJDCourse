
Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	If ValueIsFilled(FillingData) Then
	
		
	
	EndIf;
	
EndProcedure

Procedure Posting(Cancel, Mode)

	// register Employees
	RegisterRecords.Employees.Write = True;
	For Each CurrentRowChanges In Changes Do
		Record = RegisterRecords.Employees.Add();
		Record.Period 		= CurrentRowChanges.StartDate;
		Record.Company 		= Company;
		Record.Employee 	= CurrentRowChanges.Employee;
		Record.Position 	= CurrentRowChanges.Position;
		Record.Department 	= CurrentRowChanges.StructuralUnit;
		Record.Works 		= OperationKind <> Enums.OperationKindsPersonnelChange.Dismissal;
	EndDo;

EndProcedure
