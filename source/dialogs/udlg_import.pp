unit udlg_import;

{$mode ObjFPC}{$H+}

interface

uses
  BCPanel, Classes, SysUtils, SdfData, fpjson, fpjsondataset, ExtJSDataSet,
  memds, dbf, csvdataset, DB, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, Grids, Buttons, EditBtn, ComCtrls, Menus, fpsDataset,
  atshapelinebgra;

type

  { TdlgImport }

  TdlgImport = class(TForm)
    btnHelp: TBitBtn;
    btnOptions: TBitBtn;
    cbTarget: TComboBox;
    dsDbf: TDbf;
    eSourceFile: TEditButton;
    gridConfirm: TStringGrid;
    iButtons: TImageList;
    iButtonsDark: TImageList;
    icoImportFinished: TImage;
    imgFinished: TImageList;
    imgFinishedDark: TImageList;
    lblProgressInstruction: TLabel;
    lblFieldsInstruction: TLabel;
    lblConfirmInstruction: TLabel;
    lblSourceInstruction: TLabel;
    lblSourceFile: TLabel;
    lblSubtitleImportFinished: TLabel;
    lblTarget: TLabel;
    lblTitleImportFinished: TLabel;
    lblTitleProgress: TLabel;
    lblTitleFields: TLabel;
    lblTitleConfirm: TLabel;
    lblTitleSource: TLabel;
    lineBottom: TShapeLineBGRA;
    dsMem: TMemDataset;
    pContentFinished: TBCPanel;
    pgFinished: TPage;
    pmfSelectAll: TMenuItem;
    pmfDeselectAll: TMenuItem;
    mProgress: TMemo;
    nbPages: TNotebook;
    OpenDlg: TOpenDialog;
    pContentProgress: TPanel;
    pgProgress: TPage;
    pContentConfirm: TPanel;
    pgConfirm: TPage;
    pBottom: TPanel;
    pContentFields: TPanel;
    pContentSource: TPanel;
    pgFields: TPage;
    pgSource: TPage;
    PBar: TProgressBar;
    pmFields: TPopupMenu;
    pRetry: TBCPanel;
    pSourceOptions: TPanel;
    pTitleProgress: TPanel;
    pTitleFields: TPanel;
    pTitleConfirm: TPanel;
    pTitleSource: TPanel;
    SaveDlg: TSaveDialog;
    sbCancel: TButton;
    sbNext: TButton;
    sbPrior: TButton;
    gridFields: TStringGrid;
    dsSdf: TSdfDataSet;
    dsWorksheet: TsWorksheetDataset;
    sbRetry: TBitBtn;
    sbSaveLog: TBitBtn;
    procedure btnOptionsClick(Sender: TObject);
    procedure eSourceFileButtonClick(Sender: TObject);
    procedure eSourceFileChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure sbCancelClick(Sender: TObject);
    procedure sbNextClick(Sender: TObject);
    procedure sbPriorClick(Sender: TObject);
    procedure sbSaveLogClick(Sender: TObject);
  private
    FDataSet: TDataSet;
    dsJSON: TExtJSJSONObjectDataSet;
    procedure ApplyDarkMode;
    function IsRequiredFilledSource: Boolean;
    procedure LoadFields;
    procedure LoadTargetTables;
  public

  end;

var
  dlgImport: TdlgImport;

implementation

uses
  cbs_locale, cbs_import, ucfg_delimiters, uDarkStyleParams;

{$R *.lfm}

{ TdlgImport }

procedure TdlgImport.ApplyDarkMode;
begin
  btnOptions.Images := iButtonsDark;
  btnHelp.Images := iButtonsDark;
  eSourceFile.Images := iButtonsDark;
  pmFields.Images := iButtonsDark;
  sbRetry.Images := iButtonsDark;
  sbSaveLog.Images := iButtonsDark;
  icoImportFinished.Images := imgFinishedDark;
end;

procedure TdlgImport.btnOptionsClick(Sender: TObject);
begin
  cfgDelimiters := TcfgDelimiters.Create(nil);
  with cfgDelimiters do
  try
    //QuotedAsText := dsSdf.QuoteChar = '"';
    Delimiter := dsSdf.Delimiter;
    //DecimalSeparator := dsSdf.DecimalSeparator;
    HaveHeader := dsSdf.FirstLineAsSchema;
    if ShowModal = mrOk then
    begin
      //if QuotedAsText then
      //  dsSdf.QuoteChar := '"'
      //else
      //  dsSdf.QuoteChar := #0;
      dsSdf.Delimiter := Delimiter;
      //dsSdf.DecimalSeparator := DecimalSeparator;
      dsSdf.FirstLineAsSchema := HaveHeader;
    end;
  finally
    FreeAndNil(cfgDelimiters);
  end;
end;

procedure TdlgImport.eSourceFileButtonClick(Sender: TObject);
begin
  if OpenDlg.Execute then
  begin
    eSourceFile.Text := OpenDlg.FileName;
  end;
end;

procedure TdlgImport.eSourceFileChange(Sender: TObject);
var
  jData: TJSONArray;
begin
  sbPrior.Enabled := False;
  sbNext.Enabled := IsRequiredFilledSource;

  if not FileExists(eSourceFile.Text) then
    Exit;

  if eSourceFile.Text <> EmptyStr then
    case ExtractFileExt(eSourceFile.Text) of
      '.csv', '.tsv':
      begin
        FDataSet := dsSdf;
        dsSdf.FileName := eSourceFile.Text;
      end;
      '.xlsx', '.xls', '.ods':
      begin
        FDataSet := dsWorksheet;
        dsWorksheet.FileName := eSourceFile.Text;
      end;
      '.json':
      begin
        dsJSON := TExtJSJSONObjectDataSet.Create(nil);
        FDataSet := dsJSON;
        dsJSON.LoadFromFile(eSourceFile.Text);
      end;
      '.dbf':
      begin
        FDataSet := dsDbf;
        dsDbf.FilePathFull := eSourceFile.Text;
      end;
      '.kml', '.kmz': ;
      '.gpx': ;
      '.geojson': ;
    else
      FDataSet := dsMem;
    end;
end;

procedure TdlgImport.FormDestroy(Sender: TObject);
begin
  if Assigned(dsJSON) then
  begin
    dsJSON.Close;
    dsJSON.Free;
  end;
end;

procedure TdlgImport.FormShow(Sender: TObject);
begin
  if IsDarkModeEnabled then
    ApplyDarkMode;
end;

function TdlgImport.IsRequiredFilledSource: Boolean;
begin
  Result := False;

  if (eSourceFile.Text <> EmptyStr) and (cbTarget.ItemIndex >= 0) then
    Result := True;
end;

procedure TdlgImport.LoadFields;
var
  i: Integer;
begin
  if not FDataSet.Active then
    FDataSet.Open;

  gridFields.ColWidths[0] := 40;
  gridFields.RowCount := 1; // Clear rows
  gridFields.RowCount := FDataSet.FieldCount + 1;
  // Target field picklist
  // Search table picklist
  for i := 0 to FDataSet.FieldCount - 1 do
  begin
    gridFields.Cells[1, i+1] := FDataSet.Fields[i].DisplayName;
  end;
end;

procedure TdlgImport.LoadTargetTables;
begin
  with cbTarget.Items do
  begin
    Add(rsCaptionExpeditions);
    Add(rsTitleSurveys);
    Add('Survey team');
    Add(rsTitleNetsEffort);
    Add(rsTitleWeather);
    Add(rsTitleVegetation);
    Add(rsTitleMethods);
    Add(rsTitleSightings);
    Add(rsTitleSpecimens);
    Add(rsTitleSamplePreps);
    Add(rsTitleCollectors);
    Add(rsTitleBands);
    Add(rsTitleIndividuals);
    Add(rsTitleCaptures);
    Add(rsTitleMolts);
    Add(rsTitleNests);
    Add(rsTitleNestOwners);
    Add(rsTitleNestRevisions);
    Add(rsTitleEggs);
    Add(rsTitleInstitutions);
    Add(rsTitleResearchers);
    Add(rsTitleProjects);
    Add('Project members');
    Add(rsTitlePermits);
    Add(rsTitleGazetteer);
    Add(rsTitleSamplingPlots);
    Add(rsTitlePermanentNets);
    Add(rsTitleBotanicTaxa);
  end;
end;

procedure TdlgImport.sbCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TdlgImport.sbNextClick(Sender: TObject);
begin
  nbPages.PageIndex := nbPages.PageIndex + 1;

  sbPrior.Enabled := nbPages.PageIndex > 0;
  sbNext.Enabled := nbPages.PageIndex < (nbPages.PageCount - 1);
end;

procedure TdlgImport.sbPriorClick(Sender: TObject);
begin
  nbPages.PageIndex := nbPages.PageIndex - 1;

  sbPrior.Enabled := nbPages.PageIndex > 0;
  sbNext.Enabled := nbPages.PageIndex < (nbPages.PageCount - 1);
end;

procedure TdlgImport.sbSaveLogClick(Sender: TObject);
begin
  if SaveDlg.Execute then
    mProgress.Lines.SaveToFile(SaveDlg.FileName);
end;

end.

