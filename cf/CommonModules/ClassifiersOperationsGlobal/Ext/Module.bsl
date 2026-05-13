///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2023, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

////////////////////////////////////////////////////////////////////////////////
// The "OnlineUserSupport.ClassifiersOperations" subsystem.
// CommonModule.ClassifiersOperationsGlobal.
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Private

// At a startup, notifies the user if they should enable the automatic classifier update.
// 
//
Procedure NotificationOnClassifiersUpdateEnabled() Export
	
	ShowUserNotification(
		NStr("ru = 'Работа с классификаторами';
			|en = 'Classifiers';"),
		"e1cib/app/DataProcessor.UpdateClassifiers.Form.UpdatesDownloadSettings",
		NStr("ru = 'Рекомендуется включить автоматическое обновление классификаторов.';
			|en = 'Enable automatic classifier update.';"),
		PictureLib.DialogExclamation,
		UserNotificationStatus.Important);
	
EndProcedure

#EndRegion
