{ Xolmis Bands Balance dialog

  Copyright (C) 2023 Christian Beier <hello@christianbeier.studio>

  This source is free software; you can redistribute it and/or modify it under the terms of the GNU General
  Public License as published by the Free Software Foundation; either version 3 of the License, or (at your
  option) any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied
  warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  You should have received a copy of the GNU General Public License along with this program.  If not,
  see <https://www.gnu.org/licenses/>.
}

unit udlg_bandsbalance;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, DB, SQLDB, fpcsvexport, atshapelinebgra,
  BCPanel, Grids, DBGrids, Menus, StdCtrls;

type

  { TdlgBandsBalance }

  TdlgBandsBalance = class(TForm)
    CSVExporter1: TCSVExporter;
    dbgSaldo: TDBGrid;
    iPopup: TImageList;
    lineBottom: TShapeLineBGRA;
    pMsg: TBCPanel;
    pmgRefresh: TMenuItem;
    pmgSavesAs: TMenuItem;
    pBottom: TPanel;
    pmGrid: TPopupMenu;
    SaveDlg: TSaveDialog;
    sbClose: TButton;
    Separator1: TMenuItem;
    TimerLoad: TTimer;
    procedure dbgSaldoPrepareCanvas(sender: TObject; DataCol: Integer; Column: TColumn;
      AState: TGridDrawState);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure pmgRefreshClick(Sender: TObject);
    procedure pmgSavesAsClick(Sender: TObject);
    procedure TimerLoadTimer(Sender: TObject);
  private
    MediaDiasExpedicao: Integer;
  public

  end;

var
  dlgBandsBalance: TdlgBandsBalance;

implementation

uses cbs_global, cbs_themes, udm_main, udm_client;

{$R *.lfm}

{ TdlgBandsBalance }

procedure TdlgBandsBalance.TimerLoadTimer(Sender: TObject);
begin
  TimerLoad.Enabled := False;
  pMsg.Visible := True;

  with TSQLQuery.Create(DMM.sqlCon) do
  try
    Database := DMM.sqlCon;
    SQL.Add('SELECT media_dias_expedicao FROM get_average_expedition_duration');
    Open;
    MediaDiasExpedicao := Fields[0].AsInteger;
    Close;
  finally
    Free;
  end;

  if DMC.qBandsBalance.Active then
    DMC.qBandsBalance.Refresh
  else
    DMC.qBandsBalance.Open;

  pMsg.Visible := False;
end;

procedure TdlgBandsBalance.FormDestroy(Sender: TObject);
begin
  TimerLoad.Enabled := False;

  DMC.qBandsBalance.Close;
end;

procedure TdlgBandsBalance.dbgSaldoPrepareCanvas(sender: TObject; DataCol: Integer;
  Column: TColumn; AState: TGridDrawState);
var
  BandAvgPerDay: Integer;
  vSaldo: Integer;
begin
  //vSaldo := 0;
  //if Column.FieldName = 'saldo' then
  //begin
    vSaldo := dbgSaldo.Columns[1].Field.AsInteger;
    BandAvgPerDay := Round(DMC.qBandsBalance.FieldByName('media_dia').AsFloat * MediaDiasExpedicao);
    if vSaldo < BandAvgPerDay then
    begin
      with (Sender as TDBGrid) do
      begin
        Canvas.Font.Style := Canvas.Font.Style + [fsBold];
        if vSaldo = 0 then
        begin
          Canvas.Font.Color := clSystemCriticalFGLight;
          Canvas.Brush.Color := clSystemCriticalBGLight;
        end else
        begin
          Canvas.Font.Color := clSystemCautionFGLight;
          Canvas.Brush.Color := clSystemCautionBGLight
        end;
      end;
    end;
  //end;
end;

procedure TdlgBandsBalance.FormShow(Sender: TObject);
begin
  TimerLoad.Enabled := True;
end;

procedure TdlgBandsBalance.pmgRefreshClick(Sender: TObject);
begin
  TimerLoad.Enabled := True;
end;

procedure TdlgBandsBalance.pmgSavesAsClick(Sender: TObject);
begin
  SaveDlg.InitialDir := XSettings.LastPathUsed;
  if SaveDlg.Execute then
  begin
    CSVExporter1.FileName := SaveDlg.FileName;
    CSVExporter1.Execute;
    //dbgSaldo.SaveToFile(SaveDlg.FileName);
  end;
end;

end.

