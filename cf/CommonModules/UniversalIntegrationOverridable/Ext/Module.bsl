#Region Public

// Allows to append and modify a dataset before sending it to the Service Manager.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  RuleID - String - rule ID. 
//  Data - Structure - data to be sent. 
//
Procedure ProcessDataBeforeSending(RuleID, Data) Export
EndProcedure

// A procedure that processes a notification about the object change by the translation rules. 
// Called after the object data is received, before the object is saved to a temporary storage.
// @skip-warning EmptyMethod - overridable method.
//
// Parameters:
//  RuleID - String - a translation rule ID.
//  ObjectKey - String - an object key. 
//  Data - Structure - object data.
//
Procedure ProcessChangeNotification(RuleID, ObjectKey, Data) Export
EndProcedure

// A procedure that processes a notification about the object change.
// Called after the notification is received, before the object is saved to secure storage.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  ObjectType - String - Object type.
//  ObjectKey - String - Object key. 
//
Procedure ProcessObjectChangeNotification(ObjectType, ObjectKey) Export
EndProcedure
 
#EndRegion 
