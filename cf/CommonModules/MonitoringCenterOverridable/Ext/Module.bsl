///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region Public

// It is executed upon starting a scheduled job.
//
Procedure OnCollectConfigurationStatisticsParameters() Export
	
	// _Demo Example Start
	
	// Gather the statistics on the product quantities:
	// Catalog._DemoProducts.Product1	Quantity1
	// Catalog._DemoProducts.Product1	Quantity2
	// …
	MetadataNamesMap = New Map;
	
	QueryText = 
		"SELECT
		|	_DemoProducts.ProductKind AS ProductKind,
		|	COUNT(*) AS Count
		|FROM
		|	Catalog._DemoProducts AS _DemoProducts
		|WHERE
		|	_DemoProducts.IsFolder = FALSE
		|
		|GROUP BY
		|	_DemoProducts.ProductKind";
	MetadataNamesMap.Insert("Catalog._DemoProducts", QueryText);
	
	MonitoringCenter.WriteConfigurationStatistics(MetadataNamesMap);
	// _Demo Example End
	
	// _Demo Example Start
	
	// Gather the statistics on the quantities of the exchange rate sources:
	// Catalog.Currencies.Source1		Quantity1
	//
	// Catalog.Currencies.Source1		Quantity2
	// …
	// 
	MetadataNamesMap = New Map;
	
	QueryText = 
		"SELECT
		|	Currencies.RateSource AS RateSource,
		|	COUNT(*) AS Count
		|FROM
		|	Catalog.Currencies AS Currencies
		|
		|GROUP BY
		|	Currencies.RateSource";
	MetadataNamesMap.Insert("Catalog.Currencies", QueryText);
	
	MonitoringCenter.WriteConfigurationStatistics(MetadataNamesMap);
	// _Demo Example End
	
	// _Demo Example Start
	
	// Gather the statistics on the number of currencies whose exchange rate is imported from the internet.
	// The following record will be added to the "ConfigurationStatistics" information register:
	// Catalog.Currencies.ImportingFromInternet		Quantity.
	Query = New Query;
	Query.Text = 
		"SELECT
		|	COUNT(*) AS Count
		|FROM
		|	Catalog.Currencies AS Currencies
		|WHERE
		|	Currencies.RateSource = &RateSource";
	
	Query.SetParameter("RateSource", Enums.RateSources.DownloadFromInternet);
	Result = Query.Execute();
	Selection = Result.Select();
	Selection.Next();
	
	MonitoringCenter.WriteConfigurationObjectStatistics("Catalog.Currencies.ImportingFromInternet", Selection.Count);
	// _Demo Example End
	
EndProcedure

// This procedure defines default settings applied to subsystem objects.
//
// Parameters:
//   Settings - Structure - Collection of subsystem settings. Has the following attributes:
//       * EnableNotifications - Boolean - a default value for user notifications:
//           True - by default, the system administrator is notified, for example, if there is no "To do list" subsystem.
//           False - by default, the system administrator is not notified.
//           The default value depends on availability of the "To do list" subsystem.                              
//
Procedure OnDefineSettings(Settings) Export
	
	// _Demo Example Start
	Settings.EnableNotifications = True;
	// _Demo Example End
	
EndProcedure

#EndRegion
