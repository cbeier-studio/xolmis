unit udm_lookup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DB, SQLDB;

type

  { TDML }

  TDML = class(TDataModule)
    dsLkBands: TDataSource;
    dsLkNetsEffort: TDataSource;
    dsLkNests: TDataSource;
    dsLkNetStations: TDataSource;
    dsLkMethods: TDataSource;
    dsLkEggs: TDataSource;
    dsLkSites: TDataSource;
    dsLkRanks: TDataSource;
    dsLkIndividuals: TDataSource;
    dsLkInstitutions: TDataSource;
    dsLkPeople: TDataSource;
    dsLkProjects: TDataSource;
    dsLkZooTaxa: TDataSource;
    dsLkBotanicTaxa: TDataSource;
    lkBandsband_id: TLongintField;
    lkBandsfull_name: TStringField;
    lkBandsshort_name: TStringField;
    lkBotanicTaxaformatted_name: TStringField;
    lkBotanicTaxataxon_id: TLongintField;
    lkBotanicTaxataxon_name: TStringField;
    lkEggsegg_id: TLongintField;
    lkEggsfull_name: TStringField;
    lkIndividuals: TSQLQuery;
    lkIndividualsformatted_name: TStringField;
    lkIndividualsfull_name: TStringField;
    lkIndividualsindividual_id: TLongintField;
    lkInstitutions: TSQLQuery;
    lkInstitutionsacronym: TStringField;
    lkInstitutionsfull_name: TStringField;
    lkInstitutionsinstitution_id: TLongintField;
    lkNetsEffort: TSQLQuery;
    lkMethodsmethod_acronym: TStringField;
    lkMethodsmethod_id: TLongintField;
    lkMethodsmethod_name: TStringField;
    lkNestsfull_name: TStringField;
    lkNestsnest_id: TLargeintField;
    lkMethods: TSQLQuery;
    lkNetsEffortfull_name: TStringField;
    lkNetsEffortnet_id: TLongintField;
    lkNetsEffortnet_number: TLongintField;
    lkNetStationsnet_station_id: TLargeintField;
    lkNetStationsstation_acronym: TStringField;
    lkNetStationsstation_name: TStringField;
    lkPeople: TSQLQuery;
    lkPeopleacronym: TStringField;
    lkPeoplecitation: TStringField;
    lkPeoplefull_name: TStringField;
    lkPeopleperson_id: TLongintField;
    lkProjects: TSQLQuery;
    lkBands: TSQLQuery;
    lkNests: TSQLQuery;
    lkNetStations: TSQLQuery;
    lkEggs: TSQLQuery;
    lkProjectsproject_id: TLongintField;
    lkProjectsproject_title: TStringField;
    lkProjectsshort_title: TStringField;
    lkRanks: TSQLQuery;
    lkRanksrank_id: TLongintField;
    lkRanksrank_name: TStringField;
    lkSites: TSQLQuery;
    lkSitessite_id: TLongintField;
    lkZooTaxa: TSQLQuery;
    lkSitesfull_name: TStringField;
    lkSitessite_acronym: TStringField;
    lkSitessite_name: TStringField;
    lkBotanicTaxa: TSQLQuery;
    lkZooTaxaformatted_name: TStringField;
    lkZooTaxafull_name: TStringField;
    lkZooTaxataxon_id: TLongintField;
  private

  public

  end;

var
  DML: TDML;

implementation

uses udm_main;

{$R *.lfm}

end.
