///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2018, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

////////////////////////////////////////////////////////////////////////////////
// Procedures and functions intended for the "SuppliedData" subsystem.
// Common module "SuppliedDataOverridable".
//

// Register the default master data handlers.
// @skip-warning EmptyMethod - Overridable method.
//
// When receiving a notification that new shared data is available, the
// NewDataAvailable procedure is called from modules registered with GetSuppliedDataHandlers.
// XDTODataObject Descriptor is passed to the procedure.
// 
// If NewDataAvailable sets Import to True, 
// the data is imported, the descriptor and the data file path are passed to the
// ProcessNewData procedure. The file is automatically deleted once the procedure is executed.
// If a file is not specified in the Service Manager - the argument value is Undefined.
//
// Parameters: 
//   Handlers - ValueTable - Table for adding handlers. Has the following columns:
//     * DataKind - String - Code of the data kind being processed by the handler.
//     * HandlerCode - String - Intended for recovery after a data processing error.
//     * Handler - CommonModule - Module that contains the following procedures:
//		  	NewDataAvailable(Descriptor, Import) Export  
//			ProcessNewData(Descriptor, PathToFile) Export
//			DataProcessingCanceled(Descriptor) Export
//
Procedure GetHandlersForSuppliedData(Handlers) Export
EndProcedure

#EndRegion
