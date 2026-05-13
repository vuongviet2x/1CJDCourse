///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2024, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//
//

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Barcode     = "(01)04600822901507(11)161109(30)2434"; // "46120441";
	CanvasRotation = 0;
	BarcodeTypeVal = 1;
	QRErrorCorrectionLevel = 1;
	GS1DatabarRowsCount = 2;
	VerticalAlignment  = 1;
	GenerationPasses = 3;
	LogoSizePercentFromBarcode = 10;
	ShowText   = True;
	
	AddIn = BarcodeGeneration.ToConnectAComponentGeneratingAnImageOfTheBarcode();
	VersionComponents  = AddIn.Version;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	UpdateBase64Barcode();
	
EndProcedure

&AtClient
Procedure BarcodeOnChange(Item)
	
	UpdateBase64Barcode();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ActionGenerate(Command)
	
	ClearMessages();
	GenerateOnServer();
	
EndProcedure

&AtClient
Procedure Print(Command)
	
	Result.Print(PrintDialogUseMode.Use);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function GetBarcode(TheWidthOfTheBarcode, TheHeightOfTheBarcode, EnterBarcode, BarcodeType)
	
	BarcodeParameters = BarcodeGeneration.BarcodeGenerationParameters();
	BarcodeParameters.Width = TheWidthOfTheBarcode;
	BarcodeParameters.Height = TheHeightOfTheBarcode;
	BarcodeParameters.CodeType = BarcodeType;
	BarcodeParameters.CanvasRotation = Number(CanvasRotation);
	BarcodeParameters.Barcode = EnterBarcode;
	BarcodeParameters.BgTransparent = Transparent;
	BarcodeParameters.QRErrorCorrectionLevel = QRErrorCorrectionLevel;
	BarcodeParameters.ShowText = ShowText;
	BarcodeParameters.Zoomable = Zoomable;
	BarcodeParameters.MaintainAspectRatio = MaintainAspectRatio;
	BarcodeParameters.VerticalAlignment  = VerticalAlignment; 
	BarcodeParameters.GS1DatabarRowsCount = GS1DatabarRowsCount;
	BarcodeParameters.InputDataType = ?(InputDataInBase64, 1, 0);
	BarcodeParameters.RemoveExtraBackgroud = RemoveExtraBackgroud;
	BarcodeParameters.LogoImage = PictureBase64;
	BarcodeParameters.LogoSizePercentFromBarcode = LogoSizePercentFromBarcode;
	
	ResultBarcode = BarcodeGeneration.TheImageOfTheBarcode(BarcodeParameters);
	If Not ResultBarcode.Result Then
		Common.MessageToUser(NStr("ru = 'Штрихкод не сформирован.';
													|en = 'Barcode is not generated.';"));
	EndIf;
	
	Return ResultBarcode.Picture;
	
EndFunction

&AtServer
Procedure GenerateOnServer()
	
	Result.Clear();
	
	TimeObject = FormAttributeToValue("Object");
	Template = TimeObject.GetTemplate("Template");
	
	Area = Template.GetArea("String|Column");
	Drawing = Area.Drawings.Barcode;
	
	Etalon = DataProcessors._DemoBarcodeGeneration.GetTemplate("LayoutForDeterminingTheCoefficientsOfUnitsOfMeasurement");
	
	NumberOfMillimetersPerPixelHeight = Etalon.Drawings.Square100Pixels.Height / 100;
	NumberOfMillimetersPerPixelWidth = Etalon.Drawings.Square100Pixels.Width / 100;
	TheWidthOfTheBarcode = Round(Drawing.Width / NumberOfMillimetersPerPixelWidth);
	TheHeightOfTheBarcode = Round(Drawing.Height / NumberOfMillimetersPerPixelHeight);
	
	If InputDataInBase64 Then 
		InputData = BarcodeBASE64
	Else
		InputData = Barcode
	EndIf;
	
	Picture = GetBarcode(TheWidthOfTheBarcode, TheHeightOfTheBarcode, InputData, BarcodeTypeVal);
	
	Drawing.Picture = Picture;
	Result.Put(Area);
	
EndProcedure

&AtClient
Procedure UpdateBase64Barcode()
	
	RowBinaryData = GetBinaryDataFromString(Barcode);
	BarcodeBASE64 = Base64String(RowBinaryData);
	
EndProcedure

&AtClient
Procedure UploadImageFileSelection(SelectedFiles, AdditionalParameters) Export
	
	If SelectedFiles <> Undefined Then
		Maps = New Picture(SelectedFiles[0]);
		PictureBase64 = Base64String(Maps.GetBinaryData());
		LogoImage = PutToTempStorage(Maps);
	EndIf;
	
EndProcedure

&AtClient
Procedure UploadPicture(Command)
	
	Handler = New NotifyDescription("UploadImageFileSelection", ThisObject);
	
	Dialog = New FileDialog(FileDialogMode.Open);
	Dialog.Title = NStr("ru = 'Выбор файла картинки';
							|en = 'Select picture file';");
	Filter =  NStr("ru = 'PNG (*.png)|*.png';
					|en = 'PNG (*.png)|*.png';");
	Dialog.Filter = Filter;
	Dialog.Multiselect = False;
	FileSystemClient.ShowSelectionDialog(Handler, Dialog);
	
EndProcedure

#EndRegion