
Procedure Posting(Cancel, Mode)

	RegisterRecords.BonusesFinesOfEmployees.Write = True;
	For Each CurRowBonusesFines In BonusesFines Do
		Record = RegisterRecords.BonusesFinesOfEmployees.Add();
		Record.Period = Date;
		Record.Employee = CurRowBonusesFines.Employee;
		Record.Company = Company;
		Record.Bonus = CurRowBonusesFines.Bonus;
		Record.Fine = CurRowBonusesFines.Fine;
	EndDo;

EndProcedure
