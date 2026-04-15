
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	CompositionSettings = SettingsComposer.GetSettings();

	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(
		DataCompositionSchema,
		CompositionSettings,
		DetailsData
	);
	
	ExternalDataSets = New Structure;
	ExternalDataSets.Insert("GoodsRequiredBalance", IntegrationWithWarehouseManagementSystem.ProductsRequiredMinimum());
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData, True);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure
