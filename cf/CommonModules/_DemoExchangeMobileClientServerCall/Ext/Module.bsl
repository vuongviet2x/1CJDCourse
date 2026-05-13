#Region Private

// Starts synchronization between the main server and the standalone server is over.
// 
// Parameters:
//  NodeCode - String
//  MobileComputerName - String
//  SentNo - Number
//  ReceivedNo - Number
//
// Returns:
//  String - Code of the sync node.
//
Function StartSync(NodeCode, MobileComputerName, SentNo, ReceivedNo) Export
	
	If Not AccessRight("Read", Metadata.ExchangePlans._DemoMobileClient) Then
		Raise(NStr("ru = 'Недостаточно прав на синхронизацию данных с мобильным приложением.';
								|en = 'Insufficient rights to synchronize data with the mobile application.';"), 
			ErrorCategory.AccessViolation);
	EndIf;
	
	SetPrivilegedMode(True);
	
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add(Metadata.ExchangePlans._DemoMobileClient.FullName());
		LockItem.SetValue("Ref", ExchangePlans._DemoMobileClient.ThisNode());
		Block.Lock();

		ExchangeNode = ExchangePlans._DemoMobileClient.ThisNode().GetObject();
		If Not ValueIsFilled(ExchangeNode.Code) Then
			ExchangeNode.Code = "001";
			ExchangeNode.Description = NStr("ru = 'Центральный';
											|en = 'Central';");
			ExchangeNode.Write();
		EndIf;

		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	ExchangeNode = ExchangePlans._DemoMobileClient.FindByCode(NodeCode); 
	If ExchangeNode.IsEmpty() Then
		
		NewNode = ExchangePlans._DemoMobileClient.CreateNode();
		BeginTransaction();
		Try
			Block = New DataLock;
			Block.Add("Constant._DemoExchangePlanNewNodeCode");
			Block.Lock();
			
			NewNodeCode = Constants._DemoExchangePlanNewNodeCode.Get();
			If NewNodeCode = 0 Then 
				NewNodeCode = 2;
			EndIf;	
			Constants._DemoExchangePlanNewNodeCode.Set(NewNodeCode + 1);
			
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;
		
		If StrLen(NewNodeCode) < 3 Then
			NewNode.Code = Format(NewNodeCode, "ND=3; NLZ=");
		Else
			NewNode.Code = NewNodeCode;
		EndIf;
		NewNode.Description = MobileComputerName;
		NewNode.SentNo = SentNo;
		NewNode.ReceivedNo = ReceivedNo;
		NewNode.Write();
		
		_DemoExchangeMobileClient.RecordDataChanges(NewNode.Ref);
		Return NewNode.Code;
		
	EndIf;
		
	RecordDataChanges = False;
	BeginTransaction();
	Try
		Block = New DataLock;
		LockItem = Block.Add(Metadata.ExchangePlans._DemoMobileClient.FullName());
		LockItem.SetValue("Ref", ExchangeNode);
		Block.Lock();
		
		ExchangeNodeInfoRecords = Common.ObjectAttributesValues(ExchangeNode, 
			"Description,DeletionMark,SentNo,ReceivedNo");
		If ExchangeNodeInfoRecords.DeletionMark 
			Or ExchangeNodeInfoRecords.Description <> MobileComputerName Then
			
			Node = ExchangeNode.GetObject();
			Node.DeletionMark = False;
			Node.Description = MobileComputerName;
			Node.Write();
			
		EndIf;
		
		RecordDataChanges = ExchangeNodeInfoRecords.SentNo <> SentNo 
			Or ExchangeNodeInfoRecords.ReceivedNo <> ReceivedNo;
		If RecordDataChanges Then
			
			Node = ExchangeNode.GetObject();
			Node.SentNo = SentNo;
			Node.ReceivedNo = ReceivedNo;
			Node.Write();
			
		EndIf;
		
		CommitTransaction();
	Except
		RollbackTransaction();
		Raise;
	EndTry;
	
	If RecordDataChanges Then
		_DemoExchangeMobileClient.RecordDataChanges(ExchangeNode);
	EndIf;
		
	Return Node.Code;
	
EndFunction

// Data exchange operation gets a package of changes
// for the current node and writes the change package
// received from the current node.
//
// Parameters:
//  NodeCode - String - Code of the corresponding node.
//  MobileApplicationData - ValueStorage - Storage that stores the exchange package.
//
// Returns:
//  ValueStorage
//
Function ExecuteDataExchange(NodeCode, MobileApplicationData) Export
	
	ExchangeNode = ExchangePlans._DemoMobileClient.FindByCode(NodeCode); 
	
	If ExchangeNode.IsEmpty() Then
		ErrorText = NStr("ru = 'Невозможно выполнить синхронизацию данных с мобильным устройством, т.к. соответствующий ему узел с кодом %1 не существует.';
							|en = 'Cannot synchronize data with the mobile device as a required node with code %1 does not exist.';");
		Raise(StringFunctionsClientServer.SubstituteParametersToString(ErrorText, NodeCode));
	EndIf;
	
	_DemoExchangeMobileClient.ReceiveExchangeBatch(ExchangeNode, MobileApplicationData);
	Return _DemoExchangeMobileClient.GenerateExchangeBatch(ExchangeNode);
	
EndFunction

// Checks whether the user has the right to run synchronization between the main server and the standalone server.
//
// Returns:
//  Boolean - "True" if the user has the right to start synchronization.
//
Function RequiresDataExchangeWithStandaloneApplication() Export

	// ACC:336-off - Do not replace with "RolesAvailable". Roles are validated in standalone configuration mode.
	// @skip-check using-isinrole
	Return IsInRole("_DemoExchangeMobileClient");
	// ACC:336-on
	
EndFunction

#EndRegion