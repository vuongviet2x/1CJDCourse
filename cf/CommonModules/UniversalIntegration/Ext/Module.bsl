
#Region Public

// Returns object data from Service Manager by the translation rule.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters: 
//  RuleID - String - a translation rule ID with the Read type.
//  ObjectKey - String, Number - an object key defined in the rule.
// 
// Returns: 
//  Structure -- Object data or Undefined if data is not obtained.:
// * Field - Arbitrary - Arbitrary list of fields.
Function GetObjectDataByRule(RuleID, ObjectKey) Export
EndFunction 

// Sends data to Service Manager.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  RuleID - String - a translation rule ID with the Import type. 
//  Data - Structure - Data to send to the Service Manager:
//   * Field - Arbitrary - Arbitrary field list determined in the universal object.
// 
// Returns:
//  Structure - Query result.:
//  * StatusCode - Number - a response status code.
//  * ResponseBody - String - a response body as a string.
//  * ResponseData - Undefined, Structure - Object data, or Undefined if data is not obtained:
//    ** Field - Arbitrary - - Arbitrary list of fields.
//    						   If the response title is "Content-Type: application/json", returns Structure.
Function SendObjectDataByRule(RuleID, Data = Undefined) Export
EndFunction

// Changes an object in Service Manager by the translation rule.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  RuleID - String - a translation rule ID with the Import type. 
//  ObjectKey - String, Number - an object key defined in the rule.
//  Data - Structure - Data to send to the Service Manager. 
//   * Field - Arbitrary - Arbitrary field list determined in the universal object.
// 
// Returns:
//  Structure - Response data.:
//  * StatusCode - Number - a response status code.
//  * ResponseBody - String - response body.
//  * ResponseData - Undefined, Structure - Object data or Undefined if data is not obtained:
//    ** Field - Arbitrary - - Arbitrary list of fields.
//    						   If the response title is "Content-Type: application/json", returns Structure.
Function ChangeObjectDataByRule(RuleID, ObjectKey, Data = Undefined) Export
EndFunction

// The method allows subscribing to notifications about Service Manager objects being changed by translation rules.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  RuleID - String - a translation rule ID. 
//  ObjectKey - String - an integration object key to which updates you are subscribing.
//
Procedure SubscribeToChangeAlerts(RuleID, ObjectKey) Export
EndProcedure

// The method allows unsubscribing from notifications about Service Manager objects being changed by translation rules.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  RuleID - String - a translation rule ID
//  ObjectKey - String - an object key, by which you unsubscribe from notifications about updates.
//
Procedure UnsubscribeFromChangeNotifications(RuleID, ObjectKey) Export
EndProcedure

// The function allows to read received object data by the key of the received data.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  RuleID - String - a translation rule ID.
//  ObjectKey - String - an object key.
// 
// Returns:
//   Structure - Read received object data.:
//   * Field - Arbitrary - Arbitrary field list determined in the universal object.
//
Function ReadReceivedObjectData(RuleID, ObjectKey) Export
EndFunction

// The method allows subscribing to notifications about Service Manager objects being changed.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  ObjectType - String 
//  ObjectID - UUID
Procedure SubscribeToNotificationsAboutObjectChanges(ObjectType, ObjectID) Export
EndProcedure

// The method allows unsubscribing from notifications about Service Manager objects being changed by translation rules.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  ObjectType - String
//  ObjectID - UUID
Procedure UnsubscribeFromObjectChangeNotifications(ObjectType, ObjectID) Export
EndProcedure            

// The function allows checking the object modification flag by an object type or ID.
// @skip-warning EmptyMethod - implementation feature.
//
// Parameters:
//  ObjectType - String
//  ObjectID - UUID
//
// Returns:
//  Boolean - Flag indicating whether the object was changed during the last change subscription.
Function ReceivedNotificationAboutObjectChanges(ObjectType, ObjectID) Export
EndFunction
 
#EndRegion

#Region Internal

// The procedure allows to write or initialize received object data in advance
// by the key of the received data.
// @skip-warning EmptyMethod - Implementation feature.
//
// Parameters:
//  RuleID - String -a translation rule ID
//  ObjectKey - String - an object key.
//  Data - Structure - received object data to save.
//
Procedure RecordReceivedObjectData(RuleID, ObjectKey, Data) Export
EndProcedure

#EndRegion 
