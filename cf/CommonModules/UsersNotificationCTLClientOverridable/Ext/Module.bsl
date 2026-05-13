
#Region Public

// When adding CTL user notification handlers.
// @skip-warning EmptyMethod - Implementation feature.
// 
// Parameters:
//  NotificationsHandlers - Map - Key, notification kind ID,
//  	Value, client module that contains the ProcessNotification 
//  	method with the UserNotification parameter. The method of this module will be called when a notification
//  	with the specified notification kind ID is received.
//  	
// Example:
//  HandlersModule = CommonClient.CommonModule("NotifyUsersOfNews");
//  NotificationsHandlers.Insert(
//		"NotificationOfNewSiteNews",
//		HandlersModule);
//		
//  The NotifyUsersOfNews module contains the following code:
//		The ProcessNotification(UserNotification) procedure Export
//	
//			If UserNotification.NotificationKind = "NotificationOfNewSiteNews" Then
//				ProcessNewNewsFromSite(UserNotification); - Procedure that implements the processing logic.
//			EndIf;
//			
//		EndProcedure.
//		
Procedure OnAddUserNotificationHandlersCTL(NotificationsHandlers) Export 
EndProcedure

#EndRegion