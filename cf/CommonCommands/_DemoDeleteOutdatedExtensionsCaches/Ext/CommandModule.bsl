///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright © 2021, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region EventHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	DeleteObsoleteExtensionsCachesAtServer();
	ShowMessageBox(, NStr("ru = 'Выполнено удаление устаревших версий параметров работы расширений.';
									|en = 'Obsolete versions of extension parameters are deleted.';"));
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DeleteObsoleteExtensionsCachesAtServer()
	
	SetPrivilegedMode(True);
	// ACC:278-off - No.644.2.1. It's acceptable to call the internal API as the call and
	// the command are intended for testing purposes.
	// ACC:1443-off - No.644.3.5. It's acceptable to access the metadata objects as the call and
	// the command are intended for testing purposes.
	Catalogs.ExtensionsVersions.DeleteObsoleteParametersVersions();
	// ACC:1443-on,
	//  ACC:278-on.
	
EndProcedure

#EndRegion
