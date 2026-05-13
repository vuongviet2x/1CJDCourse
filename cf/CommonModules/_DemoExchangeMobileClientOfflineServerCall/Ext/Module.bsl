#If MobileStandaloneServer Then

#Region Private

// Returns:
//	Structure:
//		* Accepted - Number
//		* Sent - Number
//
Function NewEntriesAcceptedSent() Export
	
	Result = New Structure();
	Result.Insert("Accepted", Constants._DemoRecordsReceived.Get());
	Result.Insert("Sent", Constants._DemoRecordsSent.Get());
	Return Result;
	
EndFunction

// Syncs data with the master infobase via the published web service.
//
Procedure ExecuteDataExchange() Export
	
	NodeDescription = NStr("ru = 'Автономный узел';
							|en = 'Standalone node';");
	
	CentralExchangeHub = ExchangePlans._DemoMobileClient.FindByCode("001");
	If CentralExchangeHub.IsEmpty() Then
		
		NewNode = ExchangePlans._DemoMobileClient.CreateNode();
		NewNode.Code = "001";
		NewNode.Description = NStr("ru = 'Центральный';
										|en = 'Central';");
		NewNode.Write();
		CentralExchangeHub = NewNode.Ref;
		
	EndIf;
	
	Node = ExchangePlans._DemoMobileClient.ThisNode();
	// Initialize an exchange and check if the required node is present in the plan.
	NodeCode = Common.ObjectAttributeValue(Node, "Code");
	CentralNodeProperties = Common.ObjectAttributesValues(CentralExchangeHub, "ReceivedNo,SentNo");
	NewCode = MainServer._DemoExchangeMobileClientServerCall.StartSync(NodeCode, NodeDescription,
		CentralNodeProperties.ReceivedNo, CentralNodeProperties.SentNo);
	
	If NodeCode <> NewCode Then

		BeginTransaction();

		Try
			Block = New DataLock;
			LockItem = Block.Add("ExchangePlan._DemoMobileClient");
			LockItem.SetValue("Ref", Node);
			Block.Lock();

			NodeObject = Node.GetObject();
			NodeObject.Code = NewCode;
			NodeObject.Description = NodeDescription;
			NodeObject.Write();
			CommitTransaction();
		Except
			RollbackTransaction();
			Raise;
		EndTry;

	EndIf;

	Constants._DemoRecordsSent.Set(0);
	Constants._DemoRecordsReceived.Set(0);
	ExchangeData = _DemoExchangeMobileClient.GenerateExchangeBatch(CentralExchangeHub);
	ExchangeData = MainServer._DemoExchangeMobileClientServerCall.ExecuteDataExchange(NodeCode, ExchangeData);
	_DemoExchangeMobileClient.ReceiveExchangeBatch(CentralExchangeHub, ExchangeData);

EndProcedure

// Checks if the background job that syncs data is completed.
//
// Parameters:
//  Id - UUID - a background job ID.
//  ErrorText - String - Output parameter that stores error details.
//
// Returns:
//  Boolean - "True" if the job is completed.
//
Function DataExchangeIsOver(Val Id, ErrorText) Export
	
	ErrorText = "";
	Job = BackgroundJobs.FindByUUID(Id);
	If Job = Undefined Then
		Return True;
	EndIf;
	If Job.State = BackgroundJobState.Active Then
		Return False;
	EndIf;
	If Job.State = BackgroundJobState.Failed Then
		ErrorText = Job.ErrorInfo.Description;
	EndIf;
	Return True;
	
EndFunction

// Runs a background job that syncs data.
//
// Returns:
//  UUID
//
Function PerformDataExchangeInBackground() Export
	
	Job = BackgroundJobs.Execute("_DemoExchangeMobileClientOfflineServerCall.ExecuteDataExchange",,, 
		"Synchronization");
	Return Job.UUID;
	
EndFunction

#EndRegion
#EndIf

