#Region Public

// Called when determining the service payment currency presentation.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
// 
// Parameters:
//  PresentationOfPaymentCurrency - String - Payment currency presentation.
//
Procedure OnSetPaymentCurrencyPresentation(PresentationOfPaymentCurrency) Export
EndProcedure

// Called when the name of the response processing form to a payment invoice request is received.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
// 
// Parameters:
//  ResponseProcessingFormName - String - Name of the response processing form.
//
Procedure OnGetResponseProcessingFormName(ResponseProcessingFormName) Export
EndProcedure

// Called when setting service payment settings.
// @skip-check module-empty-method 
//
// Parameters:
//  SubscriberCode - Number - Accounting system owner subscriber code.
//  ProcessingResult - Structure - Method processing result (return data).:
//   * Error - Boolean - Processing error flag.
//   * Message - String - Processing error message.
//
Procedure AtSettingServicePaymentSettings(SubscriberCode, ProcessingResult) Export
	
	
EndProcedure

// Called when deleting service payment settings.
// @skip-check module-empty-method 
//
// Parameters:
//  SubscriberCode - Number - Accounting system owner subscriber code.
//  ProcessingResult - Structure - Method processing result (return data).:
//   * Error - Boolean - Processing error flag.
//   * Message - String - Processing error message.
//
Procedure AtDeletingServicePaymentSettings(SubscriberCode, ProcessingResult) Export
	
	
EndProcedure

// Runs to define whether service plans can be imported.
// @skip-warning EmptyMethod - Overridable method.
// @skip-check module-empty-method 
//   
// Parameters:
//  Result - Boolean - Import availability.
//  
Procedure OnDefineServicePlansImportSupport(Result) Export

	
EndProcedure

// Runs during the export of service plans into the infobase.
// The method is idempotent. Can be called twice with the same result.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  RawData - Structure:
//   * ProviderRates - See ServiceProgrammingInterface.ServiceRates
//   * ServiceOrganizationRates - See ServiceProgrammingInterface.ServiceOrganizationRates
//  ProcessingResult - Structure - Method processing result (return data).:
//   * Error - Boolean - Processing error flag.
//   * Message - String - Processing error message.
//
Procedure OnImportServicePlans(RawData, ProcessingResult) Export
	
	
EndProcedure

// Called when creating a subscriber information form on the server if the subscriber needs to fill this information.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method
//  
//  Parameters:
//   RequiredInformation - Structure:
//   * HasErrors - Boolean - Invalid entry flag.
//   * Attributes - ValueTable - Additional subscriber attributes:
//     ** Key - String - Additional attribute's name.
//     ** Title - String - Additional attribute's title.
//     ** Type - String - Value type. 
//     ** Value - String, Number, Date, Boolean - Additional attribute's value.
//     ** RequiredToFill - Boolean - Required value flag. 
//     ** ToolTip - String - Entry field tooltip.
//     ** Error - Boolean - Invalid value flag.
//     ** Message - String - Error message.
//     ** Visible - Boolean - Flag of display on the filling form.
//   * Properties - ValueTable - Additional subscriber properties.:
//     ** Key - String - Additional property name.
//     ** Title - String - Additional attribute's title.
//     ** Type - String - Value type.
//     ** Value - String, Number, Date, Boolean - Additional property value.
//     ** RequiredToFill - Boolean - Required value flag. 
//     ** ToolTip - String - Entry field tooltip.
//     ** Error - Boolean - Invalid value flag.
//     ** Message - String - Error message.
//     ** Visible - Boolean - Flag of display on the filling form.
//   Subscriber - See ServiceProgrammingInterface.SubscriberOfThisApplication
Procedure AtFillingInRequiredInformationForSubscribing(RequiredInformation, Subscriber) Export
	
	
EndProcedure

// Runs when a proforma invoice is created following a Service Manager request.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  QueryData - See ServicePayment.InvoiceRequestData
//  ProformaInvoice - DocumentRef - Created proforma invoice (return data).
//  ProcessingResult - Structure - Method processing result (return data).:
//   * Error - Boolean - Processing error flag.
//   * Message - String - Processing error message.
//
Procedure OnCreateProformaInvoice(QueryData, ProformaInvoice, ProcessingResult) Export

	
EndProcedure

// Sets the print account form for payment.
// @skip-warning - Backwards compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  QueryData - See ServicePayment.InvoiceRequestData
//  ProformaInvoice - DocumentRef - Proforma invoice.
//  PrintForm - SpreadsheetDocument - Proforma invoice print form (return data).
//  ProcessingResult - Structure - Method processing result (return data).:
//   * Error - Boolean - Processing error flag.
//   * Message - String - Processing error message.
//
Procedure OnGetProformaInvoicePrintForm(QueryData, ProformaInvoice, PrintForm, ProcessingResult) Export


EndProcedure

// Sets the binary proforma invoice data.
// @skip-warning - Backwards compatibility.
// @skip-check module-empty-method 
//  
// Parameters:
//  QueryData - See ServicePayment.InvoiceRequestData
//  ProformaInvoice - DocumentRef - Proforma invoice.
//  Data - BinaryData - Proforma invoice data (return data).
//  ProcessingResult - Structure - Method processing result (return data):
//   * Error - Boolean - Processing error flag.
//   * Message - String - Processing error message.
//
Procedure OnGetProformaInvoiceDetails(QueryData, ProformaInvoice, Data, ProcessingResult) Export
	
	
EndProcedure

// Sets proforma invoice payment link.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  QueryData - See ServicePayment.InvoiceRequestData
//  ProformaInvoice - DocumentRef - Proforma invoice.
//  PaymentURL - String - Payment link (return data).
//  ProcessingResult - Structure - Method processing result (return data).:
//   * Error - Boolean - Processing error flag.
//   * Message - String - Processing error message.
//
Procedure OnGetPaymentURL(QueryData, ProformaInvoice, PaymentURL, ProcessingResult) Export
	
	
EndProcedure

#EndRegion