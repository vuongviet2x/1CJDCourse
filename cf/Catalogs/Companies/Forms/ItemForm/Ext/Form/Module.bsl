
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ResponsiblePersons = ResponsiblePersons(CurrentSessionDate(), Object.Ref);
	
	FillPropertyValues(ThisObject, ResponsiblePersons);
	
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	Try
	
		UpdateResponsiblePersons(CurrentObject.Ref);
	
	Except
		
		Cancel = True;
		ErrorText = StrTemplate(
			"Failed to update responsible persons with the error: %1",
			ErrorProcessing.BriefErrorDescription(ErrorInfo())
		);
		Message(ErrorText);

	EndTry;
	
EndProcedure

&AtServer
Procedure UpdateResponsiblePersons(Company)

	Period = CurrentSessionDate();
	
	ResponsiblePersons = ResponsiblePersons(Period, Company);
	
	If ResponsiblePersons.CEO <> CEO
		Or ResponsiblePersons.ChiefAccountant <> ChiefAccountant
		Or ResponsiblePersons.CTO <> CTO Then
				
		RecordManager = InformationRegisters.CompaniesResponsiblePersons.CreateRecordManager();
		
		RecordManager.Company = Company;
		RecordManager.Period = Period;
		
		RecordManager.CEO = CEO;
		RecordManager.ChiefAccountant = ChiefAccountant;
		RecordManager.CTO = CTO;
		
		RecordManager.Write(True);
		
	EndIf;

EndProcedure

&AtServerNoContext
Function ResponsiblePersons(Period, Company)

	Filter = New Structure("Company", Company);
	
	Return InformationRegisters.CompaniesResponsiblePersons.GetLast(
		Period,
		Filter
	);
	
EndFunction


