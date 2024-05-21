{ Xolmis project

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

program Xolmis;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads, clocale,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  sdflaz,
  tachartlazaruspkg, lazdbexport, tachartbgra,
  rxnew,
  virtualdbgrid_package,
  FrameViewer09,
  { CBS }
  cbs_autoupdate,
  cbs_backup,
  cbs_birds,
  cbs_blobs,
  cbs_botany,
  cbs_breeding,
  cbs_conversions,
  cbs_count,
  cbs_data,
  cbs_datasearch,
  cbs_datatypes,
  cbs_dialogs,
  cbs_editdialogs,
  cbs_entities,
  cbs_export,
  cbs_filters,
  cbs_finddialogs,
  cbs_fullnames,
  cbs_getvalue,
  cbs_gis,
  cbs_global,
  cbs_graphics,
  cbs_import,
  cbs_locale,
  cbs_permissions,
  cbs_record_types,
  cbs_sampling,
  cbs_system,
  cbs_taxonomy,
  cbs_themes,
  cbs_validations,
  {$IFDEF DEBUG}
  cbs_debug,
  {$ENDIF}
  { Main form and Data modules }
  udm_main,
  udm_client,
  udm_lookup,
  udm_grid,
  udm_individuals,
  ufrm_main,
  { Dialogs }
  udlg_about,
  udlg_authorship,
  udlg_bandhistory,
  udlg_bandsbalance,
  udlg_calendar,
  udlg_changepassword,
  udlg_colorbands,
  udlg_connect,
  udlg_find,
  udlg_findtaxon,
  udlg_geoeditor,
  udlg_importnests,
  udlg_login,
  udlg_plantminer,
  udlg_progress,
  udlg_rechistory,
  udlg_validate,
  ulst_breedingstatus,
  ulst_cyclecode,
  ulst_detectiontype,
  ulst_howsexedaged,
  ulst_moltlimits,
  { Edit dialogs }
  ubatch_bands,
  ubatch_neteffort,
  uedt_bands,
  uedt_botanictaxon,
  uedt_capture,
  uedt_database,
  uedt_egg,
  uedt_expedition,
  uedt_imageinfo,
  uedt_individual,
  uedt_institution,
  uedt_molt,
  uedt_nest,
  uedt_nestrevision,
  uedt_neteffort,
  uedt_netstation,
  uedt_permanentnet,
  uedt_person,
  uedt_sighting,
  uedt_site,
  uedt_survey,
  uedt_user,
  { Configuration dialogs }
  ucfg_database,
  ucfg_delimiters,
  ucfg_options,
  ucfg_users,
  { Other forms }
  ufrm_customgrid,
  ufrm_dashboard,
  ufrm_geoconverter,
  ufrm_maintenance, udm_breeding, uedt_method, udm_sampling, uedt_weatherlog, uedt_project, uedt_permit, 
uedt_sampleprep, uedt_specimen, uedt_nestowner, udlg_firstconfig, udlg_export, cbs_datacolumns;

{$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TDMM, DMM);
  {$IFDEF WINDOWS}
  Application.MainFormOnTaskBar := True;
  {$ENDIF}
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.

