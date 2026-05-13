#Region Internal

#Region UserCodeEncryption_ServiceProgrammingInterface
// The methods of the region "UserCodeEncryption_ServiceProgrammingInterface" are imported from the 
// "IntegrationWith1CDocumentManagementSubsystem" subsystem of the "EnterpriseManagement" (1C:ERP) configuration.

// Splits user code into two shares. Then, reconstructs the original code with the CollectUserCode function.
//
// Parameters:
//   UserCode - String - User code to be split.
//
// Returns:
//   Array of String - Array of two strings containing the hexadecimal presentation of the user code.
//
Function SplitUserCode(UserCode) Export
	
	Result = New Array;
	Result.Add("");
	Result.Add("");
	Generator = Undefined;
	
	// Decompose the code into an array of number pairs.
	ArrayOfNumbers = New Array;
	IndexOf = 1;
	While IndexOf <= StrLen(UserCode) Do
		Number = CharCode(UserCode, IndexOf);
		IndexOf = IndexOf + 1;
		If IndexOf <= StrLen(UserCode) Then
			Number = Number * 65536 + CharCode(UserCode, IndexOf);
			IndexOf = IndexOf + 1;
		EndIf;
		ArrayOfNumbers.Add(Number);
	EndDo;
	
	// Divide each of the numbers.
	For Each Number In ArrayOfNumbers Do
		SplitNumber = DivideNumber(Number, Generator); // ((1, NNN), (2, MMM))
		Result[0] = Result[0] + HexadecimalPresentationOfNumber(SplitNumber[0][1], 8);
		Result[1] = Result[1] + HexadecimalPresentationOfNumber(SplitNumber[1][1], 8);
	EndDo;
	
	Return Result;
	
EndFunction

// Reconstructs the user code from the two shares split by the SplitUserCode function.
// Returns Undefined if strings are corrupted.
//
// Parameters:
//   SplitCode - Array - Two strings that contain the split-up user code.
//
// Returns:
//   String - Merged user code.
//   Undefined if strings are corrupted.
//
Function CollectUserCode(Val SplitCode) Export
	
	If SplitCode.Count() <> 2 Then
		Return Undefined;
	EndIf;
	SplitCode[0] = TrimAll(SplitCode[0]);
	SplitCode[1] = TrimAll(SplitCode[1]);
	If StrLen(SplitCode[0]) <> StrLen(SplitCode[1]) Then
		Return Undefined;
	EndIf;
	If StrLen(SplitCode[0]) % 8 <> 0 Then
		Return Undefined;
	EndIf;
	Result = "";
	Numbers_ = Int(StrLen(SplitCode[0])) / 8;
	For NNumbers = 1 To Numbers_ Do
		SplitNumber = New Array;
		For NParts = 0 To 1 Do
			Pair = New Array;
			Pair.Add(NParts + 1);
			Presentation = Mid(SplitCode[NParts], 1 + (NNumbers - 1) * 8, 8);
			Pair.Add(NumberFromHexadecimalPresentation_(Presentation));
			SplitNumber.Add(Pair);
		EndDo;
		CollectedNumber = CollectNumber(SplitNumber);
		If CollectedNumber >= 65536 Then
			Result = Result + Char(Int(CollectedNumber / 65536));
		EndIf;
		Result = Result + Char(CollectedNumber % 65536);
	EndDo;
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region UserCodeEncryption_ServiceProceduresAndFunctions
// The methods of the region "UserCodeEncryption_ServiceProceduresAndFunctions" are imported from the 
// "IntegrationWith1CDocumentManagementSubsystem" subsystem of the "EnterpriseManagement" (1C:ERP) configuration.

// Returns the hexadecimal presentation of the number.
//
// Parameters:
//   Number - Number - Integer number.
//   Discharges - Number - Minimal result width.
//            - Undefined - Do not add zeros.
//
// Returns:
//   String - Hexadecimal number presentation.
//   Might have leading zeros.
//
Function HexadecimalPresentationOfNumber(Val Number, Discharges = Undefined)
	
	If Number = 0 And Discharges = Undefined Then
		Return "0";
	EndIf;
	
	Result = "";
	NDischarge = 0;
	While True Do
		NDischarge = NDischarge + 1;
		If Number = 0 Then // Probably, need to complement to the given number of digits.
			If Discharges = Undefined Then
				Break;
			ElsIf NDischarge > Discharges Then
				Break;
			EndIf;
		EndIf;
		RightDischarge = Number % 16;
		Number = Int(Number / 16);
		If RightDischarge > 9 Then
			Result = Char(CharCode("A") + RightDischarge - 10) + Result;
		Else
			Result = Char(CharCode("0") + RightDischarge) + Result;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Recovers the number split by Shamir's algorithm.
//
// Parameters:
//   SplitNumber - Array - Array of number pairs. For example: (1, 123), (2, 234), ...
//
// Returns:
//   Number - Original number.
//
Function CollectNumber(SplitNumber)
	
	Result = 0;
	Module = ModulusOfResidueRing();
	For String = 0 To SplitNumber.Count() - 1 Do
		Numerator = 1; 
		Divisor = 1;
		For Column = 0 To SplitNumber.Count() - 1 Do
			If String = Column Then
				Continue;
			EndIf;
			dated = SplitNumber[String][0];
			Before  = SplitNumber[Column][0];
			Numerator = (Numerator * -Before) % Module;
			Divisor = (Divisor * (dated - Before)) % Module;
		EndDo;
		Value = SplitNumber[String][1];
		Result = (Module + Result + (Value * Numerator * ReverseModule(Divisor))) % Module;
	EndDo;
	
	Return Result;
	
EndFunction

// Calculates the reverse module.
//
// Parameters:
//   NumberK - Number
//
// Returns:
//   Number - So that (NumberK * InverseModulo(NumberK)) % Module = 1 for all 
//   positive NumberK < Module.
//
Function ReverseModule(Val NumberK)
	
	Module = ModulusOfResidueRing();
	NumberK = NumberK % Module;
	
	If NumberK < 0 Then
		Decomposition = DecomposeNode(Module, -NumberK);
		Factorization = -Decomposition[2];
	Else
		Decomposition = DecomposeNode(Module, NumberK);
		Factorization = Decomposition[2];
	EndIf;
	
	Return (Module + Factorization) % Module;
	
EndFunction

// Divides the greatest common divisor of the A—B number pair.
//
// Parameters:
//   NumberA - Number
//   NumberB - Number
//
// Returns:
//   Array - (X, Y, Z) where::
//     X is the greatest common divisor of NumberA and NumberB
//     X = NumberA * Y + NumberB * Z.
//
Function DecomposeNode(Val NumberA, Val NumberB)
	
	Result = New Array;
	
	If NumberB = 0 Then
		Result.Add(NumberA);
		Result.Add(1);
		Result.Add(0);
	Else
		Quotient = Int(NumberA / NumberB);
		Module = NumberA % NumberB;
		Decomposition = DecomposeNode(NumberB, Module);
		Result.Add(Decomposition[0]);
		Result.Add(Decomposition[2]);
		Result.Add(Decomposition[1] - Decomposition[2] * Quotient);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns a large prime used as the modulus of the residue class ring.
// Must be greater than any of the encoded numbers.
//
Function ModulusOfResidueRing()
	Return 4294967291; // The number is greater than any of the possible combinations of two password characters.
EndFunction

// Gets a number from its hexadecimal representation. May cause an exception.
//
// Parameters:
//   Presentation - String - Hexadecimal number.
//
// Returns:
//   Number - Converted number.
//
Function NumberFromHexadecimalPresentation_(Val Presentation)
	
	If Presentation = "" Then
		Return 0;
	EndIf;
	Presentation = Upper(Presentation);
	
	Result = 0;
	While Presentation <> "" Do
		Digit = Left(Presentation, 1);
		Presentation = Mid(Presentation, 2);
		If Digit >= "0" And Digit <= "9" Then
			Result = Result * 16 + CharCode(Digit, 1) - CharCode("0");
		ElsIf Digit >= "A" And Digit <= "F" Then
			Result = Result * 16 + 10 + CharCode(Digit, 1) - CharCode("A");
		Else
			Raise NStr("ru = 'Ошибочный символ в шестнадцатиричной строке.';
									|en = 'Wrong character in a hexadecimal string.';");
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

// Uses Shamir's algorithm to divide the secret number into the given number of shares.
//
// Parameters:
//   Number - Number - Number to be divided. Within the range from 0 to 2^32 - 1.
//   Generator - RandomNumberGenerator - Random number generator. We recommend that you save it between calls.
//   Parts_ - Number - Defines into how many shares to divide the number.
//   Mandatory - Number - Number of shares required for reconstruction.
//
// Returns:
//   Array - Array of number pairs required for recovery. For example: (1, 123), (2, 234), (3, 345).
//
Function DivideNumber(Number, Generator = Undefined, Parts_ = 2, Mandatory = 2)
	
	#If Not WebClient Then
		
	If Generator = Undefined Then
		Generator = New RandomNumberGenerator(CurrentDate() - Date(1, 1, 1)); // Usage justified: RNG.
	EndIf;
	Module = ModulusOfResidueRing();
	
	While True Do
		Result = New Array;
		Coefficients = New Array;
		Coefficients.Add(Number);
		Coefficients.Add(Int(Generator.RandomNumber(0, Module - 1)));
		Coefficients.Add(Int(Generator.RandomNumber(0, Module - 1)));
		For Term = 1 To Parts_ Do
			Value = Number;
			For Power = 1 To Mandatory - 1 Do
				Value = (
					Value + (Coefficients[Power] * (Pow(Term, Power) % Module)) % Module
				) % Module;
			EndDo;
			Pair = New Array;
			Pair.Add(Term);
			Pair.Add(Value);
			Result.Add(Pair);
		EndDo;
		If CollectNumber(Result) = Number Then
			Break;
		EndIf;
	EndDo;
	
	Return Result;
	
	#Else
		
	Raise NStr("ru = 'Функция не поддерживается в веб-клиенте.';
							|en = 'Function is not supported in web client.';")
	
	#EndIf
	
EndFunction

#EndRegion

#EndRegion
