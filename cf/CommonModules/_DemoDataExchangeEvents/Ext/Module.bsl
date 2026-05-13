///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Private

//////////////////////////////////////////////////////////////////////////////
// Subscription handlers for exchange plan _DemoDistributedInfobaseExchange.

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWrite.
//
Procedure _DemoExchangeInDistributedInfobaseRegisterChange(Source, Cancel) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWrite("_DemoDistributedInfobaseExchange", Source, Cancel);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteDocument.
//
Procedure _DemoExchangeInDistributedInfobaseRecordDocumentChange(Source, Cancel, WriteMode, PostingMode) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteDocument("_DemoDistributedInfobaseExchange", Source, Cancel, WriteMode, PostingMode);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteConstant.
//
Procedure _DemoExchangeInDistributedInfobaseRecordConstantChange(Source, Cancel) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteConstant("_DemoDistributedInfobaseExchange", Source, Cancel);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister.
//
Procedure _DemoExchangeInDistributedInfobaseRecordRecordSetChange(Source, Cancel, Replacing) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister("_DemoDistributedInfobaseExchange", Source, Cancel, Replacing);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister.
//
Procedure _DemoExchangeInDistributedInfobaseRegisterCalculationRecordSetChangeBeforeWrite(Source, Cancel, Replacing, WriteOnly, WriteActualActionPeriod, WriteRecalculations) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister("_DemoDistributedInfobaseExchange", Source, Cancel, Replacing);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeDelete.
//
Procedure _DemoExchangeInDistributedInfobaseRegisterDeletion(Source, Cancel) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeDelete("_DemoDistributedInfobaseExchange", Source, Cancel);
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////
// "_DemoStandaloneMode" exchange plan subscription handlers.

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWrite.
//
Procedure _DemoStandaloneModeRecordChange(Source, Cancel) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWrite("_DemoStandaloneMode", Source, Cancel);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteDocument.
//
Procedure _DemoStandaloneModeRecordDocumentChange(Source, Cancel, WriteMode, PostingMode) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteDocument("_DemoStandaloneMode", Source, Cancel, WriteMode, PostingMode);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteConstant.
//
Procedure _DemoStandaloneModeRecordConstantChange(Source, Cancel) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteConstant("_DemoStandaloneMode", Source, Cancel);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister.
//
Procedure _DemoStandaloneModeRecordRecordsSetChange(Source, Cancel, Replacing) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister("_DemoStandaloneMode", Source, Cancel, Replacing);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister.
//
Procedure _DemoStandaloneModeRecordCalculationRecordsSetChangeBeforeWrite(Source, Cancel, Replacing, WriteOnly, WriteActualActionPeriod, WriteRecalculations) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeWriteRegister("_DemoStandaloneMode", Source, Cancel, Replacing);
	
EndProcedure

// See details in DataExchangeEvents.ObjectsRegistrationMechanismBeforeDelete.
//
Procedure _DemoStandaloneModeRecordDeletion(Source, Cancel) Export
	
	// No need to check "DataExchange.Load" as the subscription is used in the data exchange mechanism.
	// The mechanism registers data imported to the infobase for importing to other exchange plan nodes.
	DataExchangeEvents.ObjectsRegistrationMechanismBeforeDelete("_DemoStandaloneMode", Source, Cancel);
	
EndProcedure

//////////////////////////////////////////////////////////////////////////////
// Utility procedures to auto-test data exchange.

#EndRegion
