////////////////////////////////////////////////////////////////////////////////
// Subsystem QualityControlCenter.
//
////////////////////////////////////////////////////////////////////////////////
// 
//@strict-types

#Region Public

// The procedure addends the issue list TypesList.
// @skip-warning EmptyMethod - Overridable method.
//
// Parameters:
//  TypesList	 - Map of KeyAndValue:
//	 * Key - String - Type name.
//	 * Value - Structure:
//		** IncidentLevel - String
//		** Subsystem - String
//		** Tags - String
//		** CheckProcedure - String
// Example: 
//	Define applied issue types, and methods that check their relevance. 
//	See details:
// 	Details = QMCIncidentsServer.CreateIncidentTypeDetails("WebsiteExchangeQueueStopped");
// 	QMCIncidentsServer.CreateTypeRecord(TypesList, Details);
//
Procedure ListOfIncidentTypesRedefined(TypesList) Export
EndProcedure

// The procedure allows to call all the applied checks related to the periodic monitoring of the applied configuration.
// The procedure is called with the scheduled QMCMonitoring procedure once a minute if the QMCAddress constant is filled in.
// @skip-warning EmptyMethod - Overridable method.
//
Procedure ExecuteQCCMonitoringTasks() Export
EndProcedure

#EndRegion

