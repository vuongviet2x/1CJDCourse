#Region Public

// Opens the service payment form.
// The method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
Procedure OpenServicePaymentForm() Export
EndProcedure

// Opens the service plan selection form.
// The method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method 
//
// Parameters:
//  ServiceProviderCode	 - Number - Intermediary code. 
//  Source -ClientApplicationForm - Form open source.
//  ClosingNotification1 - NotifyDescription - Notification following the choice form closing.
//
Procedure OpenFareSelectionForm(ServiceProviderCode, Source = Undefined, ClosingNotification1 = Undefined) Export
EndProcedure
 
#EndRegion

#Region Internal

// Method is overridden in the fresh extension.
// @skip-warning - Backward compatibility.
// @skip-check module-empty-method
// 
// Parameters:
// 	Parameters - See CommonClientOverridable.OnStart.Parameters
//
Procedure OnStart(Parameters) Export
EndProcedure

#EndRegion 
