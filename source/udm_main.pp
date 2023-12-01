unit udm_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Dialogs, ExtDlgs, Controls, DB, BufDataset, SdfData, SQLDB,
  SQLDBLib, IBConnection, SQLite3Conn, fpjson, eventlog,
  cbs_system, SQLScript;

type

  { TDMM }

  TDMM = class(TDataModule)
    evLog: TEventLog;
    iLogos: TImageList;
    iBandTypes: TImageList;
    iTrees: TImageList;
    iCheckbox: TImageList;
    qsConnconnection_id: TLongintField;
    qsConnconnection_name: TStringField;
    qsConndatabase_name: TStringField;
    qsConndatabase_port: TLongintField;
    qsConndatabase_server: TStringField;
    qsConndatabase_type: TLongintField;
    qsConninsert_date: TDateTimeField;
    qsConnupdate_date: TDateTimeField;
    qsConnuser_name: TStringField;
    qsConnuser_password: TMemoField;
    qsUsageDatacontrol: TStringField;
    qsUsageDataevent: TStringField;
    qsUsageDatamodule: TStringField;
    qsUsageDatarun_tally: TLongintField;
    qsUsageDatausage_id: TLongintField;
    qUsersuuid: TStringField;
    scriptUserDBInit: TSQLScript;
    sqlCon: TSQLConnector;
    sysCon: TSQLConnector;
    sqliteLibLoader: TSQLDBLibraryLoader;
    scriptNewUserDB: TSQLScript;
    qsConn: TSQLQuery;
    qsUsageData: TSQLQuery;
    scriptTablesMap: TSQLScript;
    scriptFieldsMap: TSQLScript;
    sqlTrans: TSQLTransaction;
    batchCsvRead: TSdfDataSet;
    dsUsers: TDataSource;
    qUsers: TSQLQuery;
    qUsersactive_status: TBooleanField;
    qUsersallow_collection_edit: TBooleanField;
    qUsersallow_export: TBooleanField;
    qUsersallow_import: TBooleanField;
    qUsersallow_print: TBooleanField;
    qUsersexported_status: TBooleanField;
    qUsersfull_name: TStringField;
    qUsersinsert_date: TDateTimeField;
    qUsersmarked_status: TBooleanField;
    qUsersupdate_date: TDateTimeField;
    qUsersuser_id: TLongintField;
    qUsersuser_inserted: TLongintField;
    qUsersuser_name: TStringField;
    qUsersuser_password: TMemoField;
    qUsersuser_rank: TStringField;
    qUsersuser_updated: TLongintField;
    sysTrans: TSQLTransaction;
    OpenCsvDlg: TOpenDialog;
    OpenImgs: TOpenPictureDialog;
    tabGeoBank: TBufDataset;
    tabGeoBankaltitude: TFloatField;
    tabGeoBankcoordinate_id: TAutoIncField;
    tabGeoBankcoordinate_name: TStringField;
    tabGeoBanklatitude: TFloatField;
    tabGeoBanklongitude: TFloatField;
    TaskDlg: TTaskDialog;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
    procedure qsConnAfterInsert(DataSet: TDataSet);
    procedure qsConnBeforePost(DataSet: TDataSet);
    procedure qsConndatabase_typeGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure qsConndatabase_typeSetText(Sender: TField; const aText: string);
    procedure qUsersAfterInsert(DataSet: TDataSet);
    procedure qUsersAfterPost(DataSet: TDataSet);
    procedure qUsersBeforeEdit(DataSet: TDataSet);
    procedure qUsersBeforePost(DataSet: TDataSet);
    procedure qUsersuser_rankGetText(Sender: TField; var aText: string; DisplayText: Boolean);
    procedure qUsersuser_rankSetText(Sender: TField; const aText: string);
    procedure sqlConBeforeConnect(Sender: TObject);
    procedure sysConBeforeConnect(Sender: TObject);
  private
    UID: TGUID;
    OldUser: TUser;
    procedure OpenSystemDatabase;
  public

  end;

var
  DMM: TDMM;

implementation

uses cbs_locale, cbs_global, cbs_datatypes, cbs_data, cbs_dialogs;

{$R *.lfm}

{ TDMM }

procedure TDMM.DataModuleCreate(Sender: TObject);
var
  logFull: Boolean;
begin
  sysCon.DatabaseName := EmptyStr;
  sqlCon.DatabaseName := EmptyStr;

  { >> Create active user and settings objects }
  ActiveUser := TUser.Create;
  XSettings := TXolmisSettings.Create;
  XSettings.LoadFromFile;

  { >> Log file }
  logFull := CheckLogsFull;

  evLog.FileName := ConcatPaths([AppDataDir, LogFile]);
  evLog.Active := True;

  LogInfo('STARTING... =========================================');
  if logFull then
    LogWarning('Log file reached the max size');

  { >> SQLite3 library}
  sqliteLibLoader.ConnectionType := 'SQLite3';
  sqliteLibLoader.LibraryName := ConcatPaths([InstallDir, 'sqlite3.dll']);
  sqliteLibLoader.Enabled := True;
  sqliteLibLoader.LoadLibrary;
  {$IFDEF DEBUG}
  LogDebug('SQLite library loaded: ' + sqliteLibLoader.LibraryName);
  {$ENDIF}

  OpenSystemDatabase;
end;

procedure TDMM.DataModuleDestroy(Sender: TObject);
begin
  sqlCon.Close;
  sysCon.Close;

  evLog.Active := False;
end;

procedure TDMM.qsConnAfterInsert(DataSet: TDataSet);
begin
  DataSet.FieldByName('database_type').AsInteger := 0;
end;

procedure TDMM.qsConnBeforePost(DataSet: TDataSet);
begin
  if DataSet.State = dsInsert then
    DataSet.FieldByName('insert_date').AsDateTime := Now
  else
    DataSet.FieldByName('update_date').AsDateTime := Now;
end;

procedure TDMM.qsConndatabase_typeGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  if Sender.IsNull then
    Exit;

  case Sender.AsInteger of
    0: aText := 'SQLite';
    1: aText := 'Firebird';
    2: aText := 'PostgreSQL';
    3: aText := 'MariaDB';
  end;

  DisplayText := True;
end;

procedure TDMM.qsConndatabase_typeSetText(Sender: TField; const aText: string);
begin
  if aText = EmptyStr then
    Exit;

  case aText of
    'SQLite':     Sender.AsInteger := 0;
    'Firebird':   Sender.AsInteger := 1;
    'PostgreSQL': Sender.AsInteger := 2;
    'MariaDB':    Sender.AsInteger := 3;
  end;
end;

procedure TDMM.qUsersAfterInsert(DataSet: TDataSet);
begin
  DataSet.FieldByName('user_rank').AsString := 'S';
end;

procedure TDMM.qUsersAfterPost(DataSet: TDataSet);
var
  lstDiff: TStrings;
  NewUser: TUser;
  i: Integer;
begin
  { Save changes to the record history }
  if Assigned(OldUser) then
  begin
    NewUser := TUser.Create(OldUser.Id);
    lstDiff := TStringList.Create;
    try
      if NewUser.Diff(OldUser, lstDiff) then
      begin
        for i := 0 to lstDiff.Count - 1 do
        begin
          WriteRecHistory(tbUsers, haEdited, OldUser.Id,
            ExtractDelimited(1, lstDiff[i], [';']),
            ExtractDelimited(2, lstDiff[i], [';']),
            ExtractDelimited(3, lstDiff[i], [';']), rsEditedByForm);
        end;
      end;
    finally
      FreeAndNil(NewUser);
      FreeAndNil(OldUser);
      FreeAndNil(lstDiff);
    end;
  end
  else
    WriteRecHistory(tbUsers, haCreated, 0, '', '', '', rsInsertedByForm);
end;

procedure TDMM.qUsersBeforeEdit(DataSet: TDataSet);
begin
  OldUser := TUser.Create(DataSet.FieldByName('user_id').AsInteger);
end;

procedure TDMM.qUsersBeforePost(DataSet: TDataSet);
begin
  SetRecordDateUser(DataSet);
end;

procedure TDMM.qUsersuser_rankGetText(Sender: TField; var aText: string; DisplayText: Boolean);
begin
  if Sender.AsString = EmptyStr then
    Exit;

  case Sender.AsString of
    'S': aText := rsStandardUser;
    'A': aText := rsAdminUser;
    'V': aText := rsGuestUser;
  end;

  DisplayText := True;
end;

procedure TDMM.qUsersuser_rankSetText(Sender: TField; const aText: string);
begin
  if aText = EmptyStr then
    Exit;

  if aText = rsStandardUser then
    Sender.AsString := 'S'
  else
  if aText = rsAdminUser then
    Sender.AsString := 'A'
  else
  if aText = rsGuestUser then
    Sender.AsString := 'V';
end;

procedure TDMM.sqlConBeforeConnect(Sender: TObject);
begin
  sqlCon.DatabaseName := ConexaoDB.Database;
end;

procedure TDMM.sysConBeforeConnect(Sender: TObject);
begin
  sysCon.DatabaseName := ConcatPaths([AppDataDir, 'systemdb.sqlite3']);
end;

procedure TDMM.OpenSystemDatabase;
begin
  sysCon.Close;
  sysCon.DatabaseName := ConcatPaths([AppDataDir, 'systemdb.sqlite3']);

  if not (FileExists(sysCon.DatabaseName)) then
    if not CreateSystemDatabase(sysCon.DatabaseName) then
    begin
      MsgDlg('', rsErrorCreatingSystemDatabase, mtError);
      Application.Terminate;
    end;

  if not Application.Terminated then
  begin
    sysCon.Open;
    {$IFDEF DEBUG}
    LogDebug('System database connected: ' + sysCon.DatabaseName);
    {$ENDIF}
  end;
end;

end.
