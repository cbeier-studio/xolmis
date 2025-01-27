{ Xolmis Zoological Taxonomy and Data library

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

unit cbs_taxonomy;

{$mode objfpc}{$H+}
{$modeSwitch advancedRecords}

interface

uses
  Classes, SysUtils, Forms, StrUtils, ComCtrls, DB, SQLDB, RegExpr, laz.VirtualTrees, CheckLst,
  cbs_record_types;

const
  TaxonomyName: array [0 .. 2] of String = ('Clements/eBird', 'IOC', 'CBRO');

type
  TBirdTaxonomy = (btClements, btIoc, btCbro);
  TBirdTaxonomies = set of TBirdTaxonomy;

  TTaxonomyAction = (taNew, taSplit, taLump, taMove, taUpdate);

type
  TZooRank = ({Domain} trDomain, trSubDomain,
    {Kingdom}
    trHyperkingdom, trSuperkingdom, trKingdom, trSubkingdom, trInfrakingdom, trParvkingdom,
    {Phylum}
    trSuperphylum, trPhylum, trSubphylum, trInfraphylum, trMicrophylum,
    {Class}
    trSuperclass, trClass, trSubclass, trInfraclass, trSubterclass, trParvclass,
    {Division}
    trSuperdivision, trDivision, trSubdivision, trInfradivision,
    {Legion}
    trSuperlegion, trLegion, trSublegion, trInfralegion,
    {Cohort}
    trSupercohort, trCohort, trSubcohort, trInfracohort,
    {Order}
    trGigaorder, trMegaorder, trGrandorder, trHyperorder, trSuperorder, trSeriesOrder,
    trOrder, trNanorder, trHypoorder, trMinorder, trSuborder, trInfraorder, trParvorder,
    {Section}
    trSection, trSubsection,
    {Family}
    trGigafamily, trMegafamily, trGrandfamily, trHyperfamily, trSuperfamily, trEpifamily,
    trSeriesFamily, trGroupFamily, trFamily, trSubfamily, trInfrafamily,
    {Tribe}
    trSupertribe, trTribe, trSubtribe, trInfratribe,
    {Genus}
    trSupergenus, trGenus, trSubgenus,
    {Species}
    trSuperspecies, trSpecies,
    {Subspecies}
    trSubspecies, trMonotypicGroup, trPolitypicGroup,
    {eBird special taxa}
    trForm, trSpuh, trHybrid, trIntergrade, trDomestic, trSlash);

type
  TEbirdRank = (erSpuh, erHybrid, erIntergrade, erDomestic, erSlash, erForm);

const
  ZooRanks: array of String = ('D.', 'SD.', 'HK.', 'SK.', 'K.', 'sk.', 'ik.', 'pk.', 'SPh.', 'ph.',
    'subph.', 'infraph.', 'microph.', 'sc.', 'c.', 'subc.', 'infrac.', 'stc.', 'parvc.', 'sdiv.',
    'div.', 'subdiv.', 'infradiv.', 'sleg.', 'leg.', 'subleg.', 'infraleg.', 'scoh.', 'coh.',
    'subcoh.', 'infracoh.', 'Gord.', 'Mord.', 'grandord.', 'Hord.', 'superod.', 'seriesord.',
    'ord.', 'nord.', 'hypoord.', 'minord.', 'subord.', 'infraord.', 'parvord.', 'sect.', 'subsect.',
    'Gfam.', 'Mfam.', 'grandfam.', 'hyperfam.', 'superfam.', 'epifam.', 'seriesfam.', 'groupfam.',
    'fam.', 'subfam.', 'infrafam.', 'supertr.', 'tr.', 'subtr.', 'infratr.', 'superg.', 'g.',
    'subg.', 'supersp.', 'sp.', 'ssp.', 'grp. (mono)', 'grp. (poli)', 'f.', 'spuh', 'hybrid',
    'intergrade', 'domest.', 'slash');

type
  TTaxonFilter = (tfAll, tfMain, {tfKingdoms, tfPhyla, tfClasses,} tfOrders, tfFamilies, tfTribes,
    tfGenera, tfSpecies, tfSubspecies, tfSubspeciesGroups, tfSpuhs, tfSlashes, tfForms, tfDomestics,
    tfHybrids, tfIntergrades);
  TTaxonFilters = set of TTaxonFilter;

type

  { TRank }

  TRank = class(TXolmisRecord)
  protected
    FName: String;
    FAcronym: String;
    FRankIndex: Integer;
    FMainRank: Boolean;
    FSubrank: Boolean;
    FInfrarank: Boolean;
    FInfraspecific: Boolean;
    FZoologicalCode: Boolean;
    FBotanicalCode: Boolean;
  public
    constructor Create(aValue: Integer = 0);
    procedure Clear; override;
    procedure GetData(aKey: Integer); overload;
    procedure GetData(aDataSet: TDataSet); overload;
  published
    property Name: String read FName write FName;
    property Acronym: String read FAcronym write FAcronym;
    property RankIndex: Integer read FRankIndex write FRankIndex;
    property MainRank: Boolean read FMainRank write FMainRank;
    property Subrank: Boolean read FSubrank write FSubrank;
    property Infrarank: Boolean read FInfrarank write FInfrarank;
    property Infraspecific: Boolean read FInfraspecific write FInfraspecific;
    property ZoologicalCode: Boolean read FZoologicalCode write FZoologicalCode;
    property BotanicalCode: Boolean read FBotanicalCode write FBotanicalCode;
  end;

type

  { TTaxon }

  TTaxon = class(TCustomTaxon)
  protected
    FEnglishName: String;
    FPortugueseName: String;
    FSpanishName: String;
    FSortNum: Double;
    FQuickCode: String;
    FIucnStatus: String;
    FExtinct: Boolean;
    FExtinctionYear: String;
    FDistribution: String;
    FEbirdCode: String;
    FClementsTaxonomy: Boolean;
    FSubfamilyId: Integer;
    //FGenusEpithet: String;
    //FSpeciesEpithet: String;
    FSubspeciesGroupId: Integer;
    FSubspeciesGroupEpithet: String;
    //FSubspeciesEpithet: String;
    FIncertaeSedis: Integer;
    FIocTaxonomy: Boolean;
    FIocEnglishName: String;
    FIocParentTaxonId: Integer;
    FIocRankId: Integer;
    FIocValidId: Integer;
    FIocDistribution: String;
    FIocSortNum: Double;
    FCbroTaxonomy: Boolean;
    FOtherPortugueseNames: String;
    //FCbroParentTaxonId: Integer;
    //FCbroRankId: Integer;
    //FCbroValidId: Integer;
    //FCbroSortNum: Double;
  public
    constructor Create(aValue: Integer = 0);
    procedure Clear; override;
    procedure GetData(aKey: Integer); overload;
    procedure GetData(aDataSet: TDataSet); overload;
    function Diff(aOld: TTaxon; var aList: TStrings): Boolean;
  published
    property EnglishName: String read FEnglishName write FEnglishName;
    property PortugueseName: String read FPortugueseName write FPortugueseName;
    property SpanishName: String read FSpanishName write FSpanishName;
    property SortNum: Double read FSortNum write FSortNum;
    property QuickCode: String read FQuickCode write FQuickCode;
    property IucnStatus: String read FIucnStatus write FIucnStatus;
    property Extinct: Boolean read FExtinct write FExtinct;
    property ExtinctionYear: String read FExtinctionYear write FExtinctionYear;
    property Distribution: String read FDistribution write FDistribution;
    property EbirdCode: String read FEbirdCode write FEbirdCode;
    property ClementsTaxonomy: Boolean read FClementsTaxonomy write FClementsTaxonomy;
    property SubfamilyId: Integer read FSubfamilyId write FSubfamilyId;
    //property GenusEpithet: String read FGenusEpithet write FGenusEpithet;
    //property SpeciesEpithet: String read FSpeciesEpithet write FSpeciesEpithet;
    property SubspeciesGroupId: Integer read FSubspeciesGroupId write FSubspeciesGroupId;
    property SubspeciesGroupEpithet: String read FSubspeciesGroupEpithet write FSubspeciesGroupEpithet;
    //property SubspeciesEpithet: String read FSubspeciesEpithet write FSubspeciesEpithet;
    property IncertaeSedis: Integer read FIncertaeSedis write FIncertaeSedis;
    property IocTaxonomy: Boolean read FIocTaxonomy write FIocTaxonomy;
    property IocEnglishName: String read FIocEnglishName write FIocEnglishName;
    property IocParentTaxonId: Integer read FIocParentTaxonId write FIocParentTaxonId;
    property IocRankId: Integer read FIocRankId write FIocRankId;
    property IocValidId: Integer read FIocValidId write FIocValidId;
    property IocDistribution: String read FIocDistribution write FIocDistribution;
    property IocSortNum: Double read FIocSortNum write FIocSortNum;
    property CbroTaxonomy: Boolean read FCbroTaxonomy write FCbroTaxonomy;
    property OtherPortugueseNames: String read FOtherPortugueseNames write FOtherPortugueseNames;
    //property CbroParentTaxonId: Integer read FCbroParentTaxonId write FCbroParentTaxonId;
    //property CbroRankId: Integer read FCbroRankId write FCbroRankId;
    //property CbroValidId: Integer read FCbroValidId write FCbroValidId;
    //property CbroSortNum: Double read FCbroSortNum write FCbroSortNum;
  end;

  function GetRankType(aKey: Integer): TZooRank;

  function FormattedBirdName(aName: String; aRank: Integer; aAuthor: String = ''): String;

  procedure LoadTaxaRanks(aConnection: TSQLConnection; aList: TCheckListBox);

  { Taxonomies management }
  procedure RewriteTaxonHierarchy;

  procedure SplitTaxon(aSubspecies: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
    ExecNow: Boolean = True);
  procedure LumpTaxon(aSpecies, ToSpecies: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
    ExecNow: Boolean = True);

  procedure MoveToSpecies(aSubspecies, ToSpecies: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
    ExecNow: Boolean = True);
  procedure MoveToGenus(aSpecies, ToGenus: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
    ExecNow: Boolean = True);
  procedure MoveToFamily(aFamily: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
    ExecNow: Boolean = True);
  procedure MoveToOrder(aOrder: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
    ExecNow: Boolean = True);

  procedure UpdateScientificName(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery;
    ExecNow: Boolean = True);
  procedure UpdateEnglishName(aTaxon: Integer; aNewName: String; aTaxonomy: TBirdTaxonomies;
    aDataset: TSQLQuery; ExecNow: Boolean = True);
  procedure UpdatePortuguesName(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery;
    ExecNow: Boolean = True);
  procedure UpdateOutrosPortugues(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery;
    ExecNow: Boolean = True);
  procedure UpdateSpanishName(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery; ExecNow: Boolean = True);
  procedure UpdateAuthorship(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery; ExecNow: Boolean = True);
  procedure UpdateDistribution(aTaxon: Integer; aDist: String; aTaxonomy: TBirdTaxonomies;
    aDataset: TSQLQuery; ExecNow: Boolean = True);
  procedure UpdateExtinction(aTaxon: Integer; IsExtinct: Boolean; aYear: String; aDataset: TSQLQuery;
    ExecNow: Boolean = True);

implementation

uses
  cbs_locale, cbs_global, cbs_datatypes, cbs_data, cbs_datacolumns, cbs_getvalue, cbs_validations, cbs_system,
  udm_main, udlg_progress;

function GetRankType(aKey: Integer): TZooRank;
var
  aRank: TRank;
  i: Integer;
begin
  Result := trDomain;
  aRank := TRank.Create(aKey);
  try
    for i := 0 to High(ZooRanks) do
      if aRank.Acronym = ZooRanks[i] then
        Result := TZooRank(i);
  finally
    FreeAndNil(aRank);
  end;
end;

function FormattedBirdName(aName: String; aRank: Integer; aAuthor: String = ''): String;
const
  colorGroup: String      = 'clGreen';
  colorSlash: String      = 'clMaroon';
  colorSpuh: String       = 'clPurple';
  colorEnglish: String    = 'clTeal';
  colorDomestic: String   = '$00FF870F';
  colorForm: String       = '$00CCA400';
  colorHybrid: String     = '$00D2003F';
  colorIntergrade: String = '$0000D2D2';
  colorAuthorship: String = 'clGray';
  //colorGroup: String      = 'green';
  //colorSlash: String      = 'maroon';
  //colorSpuh: String       = 'purple';
  //colorEnglish: String    = 'teal';
  //colorDomestic: String   = 'cornflowerblue';
  //colorForm: String       = 'cadetblue';
  //colorHybrid: String     = 'darkslateblue';
  //colorIntergrade: String = 'goldenrod';
  //colorAuthorship: String = 'gray';
  Bracks: array of String = ('(', ')', '[', ']');
var
  b: Integer;
  nome, aBracket, outBrackets, Parent1, Parent2: String;
  RankType: TZooRank;
begin
  Result := EmptyStr;
  nome := EmptyStr;
  aBracket := EmptyStr;
  outBrackets := EmptyStr;
  b := 0;

  RankType := GetRankType(aRank);
  case RankType of
    trDomain..trInfratribe:
      begin
        nome := aName;
      end;
    trSupergenus..trSubspecies:
      begin
        nome := '<i>' + aName + '</i>';
      end;
    trMonotypicGroup:
      begin
        nome := Format('<i>%s %s <font color="%s">%s</font></i>', [ExtractWord(1, aName, [' ']),
          ExtractWord(2, aName, [' ']), colorGroup, ExtractWord(3, aName, [' '])]);
      end;
    trPolitypicGroup:
      begin
        if (Pos('/', aName) > 0) then
          nome := Format('<i>%s %s <font color="%s">%s</font></i>', [ExtractWord(1, aName, [' ']),
            ExtractWord(2, aName, [' ']), colorGroup, ExtractWord(3, aName, [' '])])
        else
        if (Pos('[', aName) > 0) then
        begin
          aBracket := Trim(ExtractDelimited(2, aName, ['[',']']));
          nome := Format('<i>%s %s</i> <font color="%s">[<i>%s</i> %s]</font>',
            [ExtractWord(1, aName, [' ']), ExtractWord(2, aName, [' ']), colorGroup,
            ExtractWord(1, aBracket, [' ']), ExtractWord(2, aBracket, [' '])]);
        end;
      end;
    trSpuh:
      begin
        if (Pos('(', aName) > 0) then
        begin
          outBrackets := Trim(ExtractDelimited(1, aName, Brackets));
          aBracket := Trim(ExtractDelimited(2, aName, Brackets));

          if IsWordPresent('Domestic', aBracket, [' ']) then
            aBracket := Format('<font color="%s">(%s)</font>', [colorDomestic, aBracket])
          else
          if ExecRegExpr('^[a-z].+ complex$', aBracket) then
            aBracket := Format('<font color="%s">(<i>%s</i> complex)</font>', [colorEnglish,
              ExtractWord(1, aBracket, [' '])])
          else
          if ExecRegExpr('^former .+ sp.$', aBracket) then
            aBracket := Format('<font color="%s">(former <i>%s</i> sp.)</font>', [colorEnglish,
              ExtractWord(2, aBracket, [' '])])
          else
            aBracket := Format('<font color="%s">(%s)</font>', [colorEnglish, aBracket])
        end
        else
          outBrackets := aName;

        if (Pos('/', outBrackets) > 0) then
        begin
          if not IsWordPresent('sp.', outBrackets, [' ']) then
          begin
            nome := Format('<font color="%s"><i>%s</i></font>', [colorSpuh, outBrackets]);
          end
          else
          begin
            if ExecRegExpr('.+(formes|idae|inae).*', outBrackets) then
            begin
              nome := Format('<font color="%s">%s</font> <b>sp.</b>', [colorSpuh,
                ExtractWord(1, outBrackets, [' '])]);
            end
            else
            if IsWordPresent('eagle', outBrackets, ['/', ' ']) then
            begin
              nome := Format('<font color="%s"><i>%s</i>/%s</font> <b>sp.</b>', [colorSpuh,
                ExtractWord(1, outBrackets, ['/', ' ']), ExtractWord(2, outBrackets, ['/', ' '])]);
            end
            else
            begin
              nome := Format('<font color="%s"><i>%s</i></font> <b>sp.</b>',
                [colorSpuh, ExtractWord(1, outBrackets, [' '])]);
            end;
          end;
        end
        else
        begin
          if ExecRegExpr('.+(formes|idae|inae).*', outBrackets) then
          begin
            nome := Format('<font color="%s">%s</font> <b>sp.</b>', [colorSpuh,
              ExtractWord(1, outBrackets, [' '])]);
          end
          else
          begin
            nome := Format('<font color="%s"><i>%s</i></font> <b>sp.</b>',
              [colorSpuh, ExtractWord(1, outBrackets, [' '])]);
          end;
        end;

        if (aBracket <> EmptyStr) then
          nome := nome + ' ' + aBracket;
      end;
    trSlash:
      begin
        if (Pos('(', aName) > 0) then
        begin
          outBrackets := Trim(ExtractDelimited(1, aName, Brackets));
          aBracket := Format('<font color="%s">(%s)</font>', [colorEnglish,
            Trim(ExtractDelimited(2, aName, Brackets))]);
        end
        else
          outBrackets := aName;

        if (Pos('sp.', outBrackets) > 0) then
        begin
          if ExecRegExpr('.+ sp.\/.+', outBrackets) then
          begin
            nome := Format('<font color="%s"><i>%s</i></font> <b>sp.</b><font color="%s">/<i>%s</i></font>',
              [colorSlash, ExtractWord(1, outBrackets, [' ']), colorSlash,
              ExtractWord(2, outBrackets, ['/'])]);
          end
          else
          begin
            outBrackets := StringReplace(outBrackets, ' sp.', '', []);
            nome := Format('<font color="%s"><i>%s</i></font> <b>sp.</b>',
              [colorSlash, outBrackets]);
          end;
        end
        else
        if ExecRegExpr('.+\/[A-Z].+', outBrackets) then
          nome := Format('<font color="%s"><i>%s</i></font>',
              [colorSlash, outBrackets])
        else
        if (WordCount(outBrackets, [' ']) = 2) then
          nome := Format('<i>%s <font color="%s">%s</font></i>',
              [ExtractWord(1, outBrackets, [' ']), colorSlash, ExtractWord(2, outBrackets, [' '])]);

        if (aBracket <> EmptyStr) then
          nome := nome + ' ' + aBracket;
      end;
    trHybrid:
      begin
        if (Pos(' x ', aName) > 0) then
        begin
          aName := StringReplace(aName, ' x ', ' | ', [rfReplaceAll]);
          Parent1 := Trim(ExtractDelimited(1, aName, ['|']));
          Parent2 := Trim(ExtractDelimited(2, aName, ['|']));
        end
        else
        begin
          Parent1 := aName;
          Parent2 := EmptyStr;
        end;

        if (Pos('(', Parent1) > 0) then
        begin
          if IsWordPresent('Domestic', Parent1, [' '] + Brackets) then
            aBracket := Format('<font color="%s">(%s)</font>', [colorDomestic,
              Trim(ExtractDelimited(2, Parent1, Brackets))])
          else
          if IsWordPresent('hybrid', Parent1, [' '] + Brackets) then
            aBracket := Format('<font color="%s">(%s)</font>', [colorHybrid,
              Trim(ExtractDelimited(2, Parent1, Brackets))]);
          Parent1 := Trim(ExtractDelimited(1, Parent1, Brackets));
        end;

        if (Pos('sp.', Parent1) > 0) then
          Parent1 := Format('<i>%s</i> <b>sp.</b>', [ExtractDelimited(1, Parent1, [' '])])
        else
          Parent1 := Format('<i>%s</i>', [Parent1]);

        if (aBracket <> EmptyStr) then
          Parent1 := Parent1 + ' ' + aBracket;

        aBracket := EmptyStr;
        if (Parent2 <> EmptyStr) then
        begin
          if (Pos('(', Parent2) > 0) then
          begin
            if IsWordPresent('Domestic', Parent2, [' '] + Brackets) then
              aBracket := Format('<font color="%s">(%s)</font>', [colorDomestic,
                Trim(ExtractDelimited(2, Parent2, Brackets))])
            else
            if IsWordPresent('hybrid', Parent2, [' '] + Brackets) then
              aBracket := Format('<font color="%s">(%s)</font>', [colorHybrid,
                Trim(ExtractDelimited(2, Parent2, Brackets))])
            else
              aBracket := Format('<font color="%s">(%s)</font>', [colorEnglish,
                Trim(ExtractDelimited(2, Parent2, Brackets))]);
            Parent2 := Trim(ExtractDelimited(1, Parent2, Brackets));
          end;

          if (Pos('sp.', Parent2) > 0) then
          begin
            if ExecRegExpr('.+(formes|idae|inae)', ExtractDelimited(1, Parent2, [' '])) then
              Parent2 := Format('%s <b>sp.</b>', [Trim(ExtractDelimited(1, Parent2, [' ']))])
            else
              Parent2 := Format('<i>%s</i> <b>sp.</b>', [Trim(ExtractDelimited(1, Parent2, [' ']))]);
          end
          else
            Parent2 := Format('<i>%s</i>', [Parent2]);

          if (aBracket <> EmptyStr) then
            Parent2 := Parent2 + ' ' + aBracket;
        end;

        if (Parent2 <> EmptyStr) then
          nome := Format('%s <font color="%s"><b>×</b></font> %s', [Parent1, colorHybrid, Parent2])
        else
          nome := Parent1;
      end;
    trIntergrade:
      begin
        aBracket := Trim(ExtractDelimited(2, aName, Brackets));
        if (aBracket <> EmptyStr) then
        begin
          if (Pos(' x ', aBracket) > 0) then
            aBracket := Format('<font color="%s">[<i>%s</i> Group <font color="%s"><b>×</b></font> <i>%s</i> Group]</font>',
              [colorGroup, ExtractWord(1, aBracket, [' ']), colorIntergrade, ExtractWord(4, aBracket, [' '])])
          else
          if IsWordPresent('intergrade', aBracket, [' ']) then
            aBracket := Format('<font color="%s">(<i>%s</i> intergrade)</font>', [colorIntergrade,
              ExtractWord(1, aBracket, [' '])])
          else
          if IsWordPresent('Group', aBracket, [' ']) then
            aBracket := Format('<font color="%s">[<i>%s</i> Group]</font>', [colorGroup,
              ExtractWord(1, aBracket, [' '])]);
        end;

        if (Pos(' x ', aName) = 0) then
        begin
          nome := Format('<i>%s</i> %s', [Trim(ExtractDelimited(1, aName, Brackets)), aBracket]);
        end
        else
        begin
          if ExecRegExpr('.+ \[.+ x .+\]', aName) then
          begin
            nome := Format('<i>%s</i> %s', [Trim(ExtractDelimited(1, aName, Brackets)), aBracket]);
          end
          else
          begin
            if (Pos(' x ', aName) > 0) then
            begin
              aName := StringReplace(aName, ' x ', ' | ', [rfReplaceAll]);
              Parent1 := Trim(ExtractDelimited(1, aName, ['|']));
              Parent2 := Trim(ExtractDelimited(2, aName, ['|']));
            end
            else
            begin
              Parent1 := aName;
              Parent2 := EmptyStr;
            end;

            if (Pos(']', Parent1) > 0) then
              Parent1 := Format('<i>%s</i> %s', [Trim(ExtractDelimited(1, Parent1, Brackets)), aBracket])
            else
            if (Pos('/', Parent1) > 0) then
              Parent1 := Format('<i>%s %s <font color="%s">%s</font></i>', [ExtractWord(1, Parent1, [' ']),
                ExtractWord(2, Parent1, [' ']), colorGroup, ExtractWord(3, Parent1, [' '])])
            else
              Parent1 := Format('<i>%s</i>', [Parent1]);

            if (Pos('[', Parent2) > 0) then
              Parent2 := aBracket
            else
            if (Pos('/', Parent2) > 0) then
              Parent2 := Format('<font color="%s"><i>%s</i></font>', [colorGroup, Parent2])
            else
              Parent2 := Format('<i>%s</i>', [Parent2]);

            nome := Format('%s <font color="%s"><b>×</b></font> %s', [Parent1, colorIntergrade,
              Parent2]);
          end;
        end;
      end;
    trForm:
      begin
        if (Pos('(', aName) > 0) or (Pos('[', aName) > 0) then
        begin
          if (Pos('(', aName) > 0) then
            b := 0
          else
          if (Pos('[', aName) > 0) then
            b := 2;

          if ExecRegExpr('.+(formes|idae|inae)', ExtractDelimited(1, aName, Brackets)) then
            nome := Format('%s <font color="%s">%s%s%s</font>', [Trim(ExtractDelimited(1, aName, Brackets)),
              colorForm, Bracks[b], Trim(ExtractDelimited(2, aName, Brackets)), Bracks[b + 1]])
          else
            nome := Format('<i>%s</i> <font color="%s">%s%s%s</font>', [Trim(ExtractDelimited(1, aName, Brackets)),
              colorForm, Bracks[b], Trim(ExtractDelimited(2, aName, Brackets)), Bracks[b + 1]]);
        end
        else
        if (WordCount(aName, [' ']) = 3) then
          nome := Format('<i>%s %s <font color="%s">%s</font></i>', [ExtractWord(1, aName, [' ']),
            ExtractWord(2, aName, [' ']), colorForm, ExtractWord(3, aName, [' '])]);
      end;
    trDomestic:
      begin
        if (Pos('(', aName) > 0) then
          nome := Format('<i>%s</i> <font color="%s">(%s)</font>', [Trim(ExtractDelimited(1, aName, Brackets)),
            colorDomestic, Trim(ExtractDelimited(2, aName, Brackets))]);
      end;
  end;
  { Authorship }
  if aAuthor <> EmptyStr then
    nome := Format('%s <font color="%s">%s</font>', [nome, colorAuthorship, aAuthor]);

  Result := nome;
end;

procedure LoadTaxaRanks(aConnection: TSQLConnection; aList: TCheckListBox);
var
  nome: String;
  // i: Integer;
  Qry: TSQLQuery;
  Lista: TStrings;
  // STree: TMemoryStream;
begin
  Lista := TStringList.Create;
  // STree:= TMemoryStream.Create;
  // STree.Position:= 0;
  Qry := TSQLQuery.Create(aConnection);
  Qry.Database := aConnection;
  with Qry do
  try
    SQL.Clear;

    SQL.Add('SELECT t.rank_id,');
    SQL.Add('   r.rank_name AS rank_name,');
    SQL.Add('   r.rank_seq AS sort_num');
    SQL.Add('FROM zoo_taxa AS t');
    SQL.Add('LEFT JOIN taxon_ranks AS r ON t.rank_id = r.rank_id');
    SQL.Add('WHERE (t.rank_id > 0) AND (t.active_status = 1)');
    SQL.Add('GROUP BY t.rank_id');
    SQL.Add('ORDER BY sort_num ASC');

    Open;
    if RecordCount > 0 then
    begin
      // PBar.Max:= RecordCount;
      // PBar.Position:= 0;
      // PBar.Visible:= True;
      aList.Items.BeginUpdate;
      aList.Items.Clear;
      nome := '';

      // Cria lista para arvore
      First;
      repeat
        nome := FieldByName('rank_name').AsString;
        Lista.Add(nome);

        // PBar.Position:= RecNo;
        Next;
      until EOF;
      // Lista.SaveToFile('TaxonTree.txt');
      // Lista.SaveToStream(STree);
      // STree.SaveToFile('TaxonTreeStream.txt');
      // STree.Position:= 0;
      aList.Items.Assign(Lista);
      aList.Items.EndUpdate;
      // PBar.Visible:= False;
      // PBar.Position:= 0;
    end;
    Close;
  finally
    FreeAndNil(Qry);
    Lista.Free;
    // STree.Free;
  end;
end;

procedure RewriteTaxonHierarchy;
var
  Qry: TSQLQuery;
  iOrder, iFamily, iSubfamily, iGenus, iSpecies, iMonoGroup, iPoliGroup, iSubspecies: Integer;
begin
  dlgProgress := TdlgProgress.Create(nil);
  try
    dlgProgress.lblTitle.Caption := rsTitleTaxonHierarchy;
    dlgProgress.lStatus.Caption := rsProgressPreparing;
    dlgProgress.PBar.Style := pbstMarquee;
    dlgProgress.Show;
    Qry := TSQLQuery.Create(DMM.sqlCon);
    with Qry, SQL do
    try
      DataBase := DMM.sqlCon;
      Transaction := DMM.sqlTrans;
      MacroCheck := True;
      dlgProgress.PBar.Position := 0;

      iOrder := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'ord.');
      iFamily := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'fam.');
      iSubfamily := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'subfam.');
      iGenus := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'g.');
      iSpecies := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'sp.');
      iMonoGroup := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'grp. (mono)');
      iPoliGroup := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'grp. (poli)');
      iSubspecies := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'ssp.');

      DMM.sqlTrans.StartTransaction;
      try
        { Order }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionOrder)]);
        Clear;
        Add('UPDATE zoo_taxa SET');
        Add('  order_id = taxon_id');
        Add('WHERE zoo_taxa.rank_id = :rank_id');
        ParamByName('RANK_ID').AsInteger := iOrder;
        ExecSQL;
        Application.ProcessMessages;

        { Family }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionFamily)]);
        Clear;
        Add('UPDATE zoo_taxa SET');
        Add('  family_id = zoo_taxa.taxon_id,');
        Add('  order_id = parent.order_id');
        Add('FROM (SELECT taxon_id, order_id FROM zoo_taxa) AS parent');
        Add('WHERE (zoo_taxa.rank_id = :rank_id) OR (zoo_taxa.parent_taxon_id = parent.taxon_id)');
        ParamByName('RANK_ID').AsInteger := iFamily;
        ExecSQL;
        Application.ProcessMessages;

        { Subfamily }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionSubfamily)]);
        Clear;
        Add('UPDATE zoo_taxa SET');
        Add('  subfamily_id = zoo_taxa.taxon_id,');
        Add('  family_id = parent.family_id,');
        Add('  order_id = parent.order_id');
        Add('FROM (SELECT taxon_id, order_id, family_id FROM zoo_taxa) AS parent');
        Add('WHERE (zoo_taxa.rank_id = :rank_id) OR (zoo_taxa.parent_taxon_id = parent.taxon_id)');
        ParamByName('RANK_ID').AsInteger := iSubfamily;
        ExecSQL;
        Application.ProcessMessages;

        { Genus }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionGenus)]);
        Clear;
        Add('UPDATE zoo_taxa SET');
        Add('  genus_id = zoo_taxa.taxon_id,');
        Add('  subfamily_id = parent.subfamily_id,');
        Add('  family_id = parent.family_id,');
        Add('  order_id = parent.order_id');
        Add('FROM (SELECT taxon_id, order_id, family_id, subfamily_id FROM zoo_taxa) AS parent');
        Add('WHERE (zoo_taxa.rank_id = :rank_id) OR (zoo_taxa.parent_taxon_id = parent.taxon_id)');
        ParamByName('RANK_ID').AsInteger := iGenus;
        ExecSQL;
        Application.ProcessMessages;

        { Species }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionSpecies)]);
        Clear;
        Add('UPDATE zoo_taxa SET');
        Add('  species_id = zoo_taxa.taxon_id,');
        Add('  genus_id = parent.genus_id,');
        Add('  subfamily_id = parent.subfamily_id,');
        Add('  family_id = parent.family_id,');
        Add('  order_id = parent.order_id');
        Add('FROM (SELECT taxon_id, order_id, family_id, subfamily_id, genus_id FROM zoo_taxa) AS parent');
        Add('WHERE (zoo_taxa.rank_id = :rank_id) OR (zoo_taxa.parent_taxon_id = parent.taxon_id)');
        ParamByName('RANK_ID').AsInteger := iSpecies;
        ExecSQL;
        Application.ProcessMessages;

        { Mono and politypic groups }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionSspGroup)]);
        Clear;
        Add('UPDATE zoo_taxa SET');
        Add('  subspecies_group_id = zoo_taxa.taxon_id,');
        Add('  species_id = parent.species_id,');
        Add('  genus_id = parent.genus_id,');
        Add('  subfamily_id = parent.subfamily_id,');
        Add('  family_id = parent.family_id,');
        Add('  order_id = parent.order_id');
        Add('FROM (SELECT taxon_id, order_id, family_id, subfamily_id, genus_id, species_id FROM zoo_taxa) AS parent');
        Add('WHERE (zoo_taxa.rank_id = :rank_id) OR (zoo_taxa.parent_taxon_id = parent.taxon_id)');
        ParamByName('RANK_ID').AsInteger := iMonoGroup;
        ExecSQL;
        Application.ProcessMessages;
        ParamByName('RANK_ID').AsInteger := iPoliGroup;
        ExecSQL;
        Application.ProcessMessages;

        { Subspecies, domestic, form }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionSubspecificTaxa)]);
        Clear;
        Add('UPDATE zoo_taxa SET');
        Add('  subspecies_group_id = parent.subspecies_group_id,');
        Add('  species_id = parent.species_id,');
        Add('  genus_id = parent.genus_id,');
        Add('  subfamily_id = parent.subfamily_id,');
        Add('  family_id = parent.family_id,');
        Add('  order_id = parent.order_id');
        Add('FROM (SELECT taxon_id, order_id, family_id, subfamily_id, genus_id, species_id, ' +
          'subspecies_group_id FROM zoo_taxa) AS parent');
        Add('WHERE (zoo_taxa.rank_id = :rank_id) OR (zoo_taxa.parent_taxon_id = parent.taxon_id)');
        ParamByName('RANK_ID').AsInteger := iSubspecies;
        ExecSQL;
        Application.ProcessMessages;

        { Update taxon hierarchy in other tables }
        Clear;
        Add('UPDATE %table_id SET');
        Add('  species_id = parent.species_id,');
        Add('  genus_id = parent.genus_id,');
        Add('  family_id = parent.family_id,');
        Add('  order_id = parent.order_id');
        Add('FROM (SELECT taxon_id, order_id, family_id, genus_id, species_id FROM zoo_taxa) AS parent');
        Add('WHERE (%table_id.taxon_id = parent.taxon_id)');
        { Update Individuals }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsTitleIndividuals)]);
        MacroByName('TABLE_ID').Value := 'individuals';
        ExecSQL;
        Application.ProcessMessages;
        { Update Captures }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsTitleCaptures)]);
        MacroByName('TABLE_ID').Value := 'captures';
        ExecSQL;
        Application.ProcessMessages;
        { Update Sightings }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsTitleSightings)]);
        MacroByName('TABLE_ID').Value := 'sightings';
        ExecSQL;
        Application.ProcessMessages;
        { Update Nests }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsTitleNests)]);
        MacroByName('TABLE_ID').Value := 'nests';
        ExecSQL;
        Application.ProcessMessages;
        { Update Eggs }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsTitleEggs)]);
        MacroByName('TABLE_ID').Value := 'eggs';
        ExecSQL;
        Application.ProcessMessages;
        { Update Specimens }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsTitleSpecimens)]);
        MacroByName('TABLE_ID').Value := 'specimens';
        ExecSQL;
        Application.ProcessMessages;
        { Update Sample preps }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsTitleSamplePreps)]);
        MacroByName('TABLE_ID').Value := 'sample_preps';
        ExecSQL;
        Application.ProcessMessages;
        { Update Images }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionImages)]);
        MacroByName('TABLE_ID').Value := 'images';
        ExecSQL;
        Application.ProcessMessages;
        { Update Audio library }
        dlgProgress.lStatus.Caption := Format(rsProgressRewritingHierarchy,
            [AnsiLowerCase(rsCaptionAudioLibrary)]);
        MacroByName('TABLE_ID').Value := 'audio_library';
        ExecSQL;
        Application.ProcessMessages;

        dlgProgress.lStatus.Caption := rsProgressFinishing;
        DMM.sqlTrans.CommitRetaining;
      except
        DMM.sqlTrans.RollbackRetaining;
        raise Exception.Create(rsErrorRewritingHierarchy);
      end;
    finally
      FreeAndNil(Qry);
    end;
  finally
    dlgProgress.Close;
    FreeAndNil(dlgProgress);
  end;
end;

procedure SplitTaxon(aSubspecies: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
  ExecNow: Boolean);
var
  OldName, NewName: String;
  SpRank, ParentGenus, ValidSp, ExistingId: Integer;
  Ssp: TTaxon;
begin
  ExistingId := 0;
  OldName := GetName('zoo_taxa', 'full_name', 'taxon_id', aSubspecies);
  NewName := ExtractWord(1, OldName, [' ']) + ' ' + ExtractWord(3, OldName, [' ']);
  SpRank := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'sp.');
  ParentGenus := GetKey('zoo_taxa', 'taxon_id', 'full_name', ExtractWord(1, OldName, [' ']));
  Ssp := TTaxon.Create(aSubspecies);

  try
    // If taxon exists
    if RecordExists(tbZooTaxa, 'full_name', NewName) = True then
    begin
      ExistingId := GetKey('zoo_taxa', 'taxon_id', 'full_name', NewName);
      with aDataset do
      begin
        if ExecNow then
          SQL.Clear;

        SQL.Add('UPDATE zoo_taxa SET ');
        if (btClements in aTaxonomy) then { Clementes/eBird }
        begin
          SQL.Add('clements_taxonomy = 1,');
          SQL.Add('valid_id = null,');
          // SQL.Add('TAX_ENGLISH = '+QuotedStr(Ssp.NomeEnglish)+',');
          SQL.Add('distribution = :geodist,');
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.Distribution;
        end;
        if (btIOC in aTaxonomy) then { IOC }
        begin
          SQL.Add('ioc_taxonomy = 1,');
          SQL.Add('ioc_rank_id = :nivel_ioc,');
          SQL.Add('ioc_parent_raxon_id = :sup_ioc,');
          SQL.Add('ioc_distribution = :geodist_ioc,');
          ParamByName('NIVEL_IOC').AsInteger := SpRank;
          ParamByName('SUP_IOC').AsInteger := ParentGenus;
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.IocDistribution;
        end;
        if (btCBRO in aTaxonomy) then { CBRO }
        begin
          SQL.Add('cbro_taxonomy = 1,');
          SQL.Add('cbro_rank_id = :nivel_cbro,');
          SQL.Add('cbro_parent_taxon_id = :sup_cbro,');
          ParamByName('NIVEL_CBRO').AsInteger := SpRank;
          ParamByName('SUP_CBRO').AsInteger := ParentGenus;
        end;
        SQL.Add('update_date = datetime(''now'',''localtime''), user_updated = :auser');
        SQL.Add('WHERE taxon_id = :ataxon;');
        ParamByName('AUSER').AsInteger := ActiveUser.Id;
        ParamByName('ATAXON').AsInteger := ExistingId;

        if ExecNow then
          ExecSQL;
      end;
    end
    else

    // If taxon does not exist
    begin
      with aDataset do
      begin
        if ExecNow then
          SQL.Clear;
        // List fields
        SQL.Add('INSERT INTO zoo_taxa (full_name, formatted_name, authorship, english_name,');
        SQL.Add('rank_id, parent_taxon_id, extinct, extinction_year, species_id, genus_id,');
        SQL.Add('subfamily_id, family_id, order_id, subspecies_group_id, genus_name, species_epithet,');
        if (btClements in aTaxonomy) then
          SQL.Add('clements_taxonomy, distribution, ebird_code,');
        if (btIOC in aTaxonomy) then
          SQL.Add('ioc_taxonomy, ioc_rank_id, ioc_parent_taxon_id, ioc_english_name, ioc_distribution,');
        if (btCBRO in aTaxonomy) then
          SQL.Add('cbro_taxonomy, cbro_rank_id, cbro_parent_taxon_id,');
        SQL.Add('insert_date, user_inserted) ');
        // List values
        SQL.Add('VALUES (:aname, :aformattedname, :autoria, :aenglish, :anivel, :asup,');
        SQL.Add(':aextinto, :anoextinto, :aspecies, :agenus, :asubfamily, :afamily, :aorder, 0,');
        SQL.Add(':agenusname, :aepithet,');
        if (btClements in aTaxonomy) then
        begin
          SQL.Add('1, :geodist, :aebirdcode,');
        end;
        if (btIOC in aTaxonomy) then
        begin
          SQL.Add('1, :anivelioc, :asupioc, :aenglishioc, :geodistioc,');
        end;
        if (btCBRO in aTaxonomy) then
        begin
          SQL.Add('1, :anivelcbro, :asupcbro,');
        end;
        SQL.Add('datetime(''now'',''localtime''), :auser);');
        ParamByName('ANAME').AsString := NewName;
        ParamByName('AFORMATTEDNAME').AsString := FormattedBirdName(NewName, SpRank);
        ParamByName('AUTORIA').AsString := Ssp.Authorship;
        ParamByName('AENGLISH').AsString := Ssp.EnglishName;
        ParamByName('ANIVEL').AsInteger := SpRank;
        ParamByName('ASUP').AsInteger := ParentGenus;
        ParamByName('AEXTINTO').AsInteger := Integer(Ssp.Extinct);
        ParamByName('ANOEXTINTO').AsString := Ssp.ExtinctionYear;
        ParamByName('ASPECIES').AsInteger := GetLastInsertedKey('zoo_taxa') + 1;
        ParamByName('AGENUS').AsInteger := ParentGenus;
        ParamByName('ASUBFAMILY').AsInteger := Ssp.SubfamilyId;
        ParamByName('AFAMILY').AsInteger := Ssp.FamilyId;
        ParamByName('AORDER').AsInteger := Ssp.OrderId;
        ParamByName('AGENUSNAME').AsString := ExtractWord(1, OldName, [' ']);
        ParamByName('AEPITHET').AsString := ExtractWord(3, OldName, [' ']);
        if (btClements in aTaxonomy) then
        begin
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.Distribution;
          ParamByName('AEBIRDCODE').AsString := Ssp.EbirdCode;
        end;
        if (btIOC in aTaxonomy) then
        begin
          ParamByName('ANIVELIOC').AsInteger := SpRank;
          ParamByName('ASUPIOC').AsInteger := ParentGenus;
          ParamByName('AENGLISHIOC').AsString := Ssp.IocEnglishName;
          ParamByName('GEODISTIOC').DataType := ftMemo;
          ParamByName('GEODISTIOC').AsString := Ssp.IocDistribution;
        end;
        if (btCBRO in aTaxonomy) then
        begin
          ParamByName('ANIVELCBRO').AsInteger := SpRank;
          ParamByName('ASUPCBRO').AsInteger := ParentGenus;
        end;
        ParamByName('AUSER').AsInteger := ActiveUser.Id;

        if ExecNow then
          ExecSQL;
      end;
    end;

    // Update subspecies
    if ExistingId > 0 then
      ValidSp := ExistingId
    else
      ValidSp := GetLastInsertedKey('zoo_taxa');
    with aDataset do
    begin
      if ExecNow then
        SQL.Clear;
      SQL.Add('UPDATE zoo_taxa SET ');
      if (btClements in aTaxonomy) then { Clementes/eBird }
      begin
        SQL.Add('clements_taxonomy = 0,');
        SQL.Add('valid_id = :aval,');
      end;
      if (btIOC in aTaxonomy) then { IOC }
      begin
        SQL.Add('ioc_taxonomy = 0,');
        SQL.Add('ioc_rank_id = :arank,');
        SQL.Add('ioc_valid_id = :aval,');
      end;
      if (btCBRO in aTaxonomy) then { CBRO }
      begin
        SQL.Add('cbro_taxonomy = 0,');
        SQL.Add('cbro_rank_id = :arank,');
        SQL.Add('cbro_valid_id = :aval,');
      end;
      SQL.Add('update_date = datetime(''now'',''localtime''), user_updated = :auser');
      SQL.Add('WHERE taxon_id = :ataxon;');
      if (Params.FindParam('ARANK') <> nil) then
      begin
        ParamByName('ARANK').AsInteger := SpRank;
      end;
      ParamByName('AVAL').AsInteger := ValidSp;
      ParamByName('AUSER').AsInteger := ActiveUser.Id;
      ParamByName('ATAXON').AsInteger := aSubspecies;
      if ExecNow then
        ExecSQL;
    end;

  finally
    FreeAndNil(Ssp);
  end;

end;

procedure LumpTaxon(aSpecies, ToSpecies: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
  ExecNow: Boolean);
var
  OldName, LumpToName, NewName: String;
  SspRank, ParentSp, ValidSp, ExistingId: Integer;
  Ssp, LumpToSp: TTaxon;
begin
  ExistingId := 0;
  OldName := GetName('zoo_taxa', 'full_name', 'taxon_id', aSpecies);
  LumpToName := GetName('zoo_taxa', 'full_name', 'taxon_id', ToSpecies);
  NewName := LumpToName + ' ' + ExtractWord(2, OldName, [' ']);
  SspRank := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'ssp.');
  ParentSp := ToSpecies;
  Ssp := TTaxon.Create(aSpecies);
  LumpToSp := TTaxon.Create(ToSpecies);

  try
    // If taxon exists
    if RecordExists(tbZooTaxa, 'full_name', NewName) = True then
    begin
      ExistingId := GetKey('zoo_taxa', 'taxon_id', 'full_name', NewName);
      with aDataset do
      begin
        if ExecNow then
          SQL.Clear;
        SQL.Add('UPDATE zoo_taxa SET ');
        if (btClements in aTaxonomy) then { Clementes/eBird }
        begin
          SQL.Add('clements_taxonomy = 1,');
          SQL.Add('valid_id = null,');
          SQL.Add('distribution = :geodist,');
        end;
        if (btIOC in aTaxonomy) then { IOC }
        begin
          SQL.Add('ioc_taxonomy = 1,');
          SQL.Add('ioc_rank_id = :arank,');
          SQL.Add('ioc_parent_taxon_id = :asup,');
          SQL.Add('ioc_distribution = :geodistioc,');
        end;
        if (btCBRO in aTaxonomy) then { CBRO }
        begin
          SQL.Add('cbro_taxonomy = 1,');
          SQL.Add('cbro_rank_id = :arank,');
          SQL.Add('cbro_parent_taxon_id = :asup,');
        end;
        SQL.Add('update_date = datetime(''now'',''localtime''), user_updated = :auser');
        SQL.Add('WHERE taxon_id = :ataxon;');
        if (Params.FindParam('ARANK') <> nil) then
        begin
          ParamByName('ARANK').AsInteger := SspRank;
        end;
        if (Params.FindParam('ASUP') <> nil) then
        begin
          ParamByName('ASUP').AsInteger := ParentSp;
        end;
        if (Params.FindParam('GEODIST') <> nil) then
        begin
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.Distribution;
        end;
        if (Params.FindParam('GEODISTIOC') <> nil) then
        begin
          ParamByName('GEODISTIOC').DataType := ftMemo;
          ParamByName('GEODISTIOC').AsString := Ssp.IocDistribution;
        end;
        ParamByName('AUSER').AsInteger := ActiveUser.Id;
        ParamByName('ATAXON').AsInteger := ExistingId;
        if ExecNow then
          ExecSQL;
      end;
    end
    else

    // If taxon does not exist
    begin
      with aDataset do
      begin
        if ExecNow then
          SQL.Clear;
        // List fields
        SQL.Add('INSERT INTO zoo_taxa (full_name, formatted_name, authorship, english_name,');
        SQL.Add('rank_id, parent_taxon_id, extinct, extinction_year, species_id, genus_id,');
        SQL.Add('subfamily_id, family_id, order_id, subspecies_group_id, genus_name, species_epithet,');
        if (btClements in aTaxonomy) then
          SQL.Add('clements_taxonomy, distribution, ebird_code,');
        if (btIOC in aTaxonomy) then
          SQL.Add('ioc_taxonomy, ioc_rank_id, ioc_parent_taxon_id, ioc_english_name, ioc_distribution,');
        if (btCBRO in aTaxonomy) then
          SQL.Add('cbro_taxonomy, cbro_rank_id, cbro_parent_taxon_id,');
        SQL.Add('insert_date, user_inserted) ');
        // List values
        SQL.Add('VALUES (:aname, :aformattedname, :autoria, :aenglish, :anivel, :asup,');
        SQL.Add(':aextinto, :anoextinto, :aspecies, :agenus, :asubfamily, :afamily, :aorder, 0,');
        SQL.Add(':agenusname, :aepithet,');
        if (btClements in aTaxonomy) then
        begin
          SQL.Add('1, :geodist, :aebirdcode,');
        end;
        if (btIOC in aTaxonomy) then
        begin
          SQL.Add('1, :anivelioc, :asupioc, :aenglishioc, :geodistioc,');
        end;
        if (btCBRO in aTaxonomy) then
        begin
          SQL.Add('1, :anivelcbro, :asupcbro,');
        end;
        SQL.Add('datetime(''now'',''localtime''), :auser);');
        ParamByName('ANAME').AsString := NewName;
        ParamByName('AFORMATTEDNAME').AsString := FormattedBirdName(NewName, SspRank);
        ParamByName('AUTORIA').AsString := Ssp.Authorship;
        ParamByName('AENGLISH').AsString := Ssp.EnglishName;
        ParamByName('ANIVEL').AsInteger := SspRank;
        ParamByName('ASUP').AsInteger := ParentSp;
        ParamByName('AEXTINTO').AsInteger := Integer(Ssp.Extinct);
        ParamByName('ANOEXTINTO').AsString := Ssp.ExtinctionYear;
        ParamByName('ASPECIES').AsInteger := LumpToSp.SpeciesId;
        ParamByName('AGENUS').AsInteger := LumpToSp.GenusId;
        ParamByName('ASUBFAMILY').AsInteger := LumpToSp.SubfamilyId;
        ParamByName('AFAMILY').AsInteger := LumpToSp.FamilyId;
        ParamByName('AORDER').AsInteger := LumpToSp.OrderId;
        ParamByName('AGENUSNAME').AsString := ExtractWord(1, NewName, [' ']);
        ParamByName('AEPITHET').AsString := ExtractWord(2, NewName, [' ']);
        if (btClements in aTaxonomy) then
        begin
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.Distribution;
          ParamByName('AEBIRDCODE').AsString := Ssp.EbirdCode;
        end;
        if (btIOC in aTaxonomy) then
        begin
          ParamByName('ANIVELIOC').AsInteger := SspRank;
          ParamByName('ASUPIOC').AsInteger := ParentSp;
          ParamByName('AENGLISHIOC').AsString := Ssp.IocEnglishName;
          ParamByName('GEODISTIOC').DataType := ftMemo;
          ParamByName('GEODISTIOC').AsString := Ssp.IocDistribution;
        end;
        if (btCBRO in aTaxonomy) then
        begin
          ParamByName('ANIVELCBRO').AsInteger := SspRank;
          ParamByName('ASUPCBRO').AsInteger := ParentSp;
        end;
        ParamByName('AUSER').AsInteger := ActiveUser.Id;

        if ExecNow then
          ExecSQL;
      end;
    end;

    // Update subspecies
    if ExistingId > 0 then
      ValidSp := ExistingId
    else
      ValidSp := GetLastInsertedKey('zoo_taxa');
    with aDataset do
    begin
      if ExecNow then
        SQL.Clear;
      SQL.Add('UPDATE zoo_taxa SET ');
      if (btClements in aTaxonomy) then { Clementes/eBird }
      begin
        SQL.Add('clements_taxonomy = 0,');
        SQL.Add('valid_id = :avalid,');
      end;
      if (btIOC in aTaxonomy) then { IOC }
      begin
        SQL.Add('ioc_taxonomy = 0,');
        SQL.Add('ioc_rank_id = :arank,');
        SQL.Add('ioc_valid_id = :avalid,');
      end;
      if (btCBRO in aTaxonomy) then { CBRO }
      begin
        SQL.Add('cbro_taxonomy = 0,');
        SQL.Add('cbro_rank_id = :arank,');
        SQL.Add('cbro_valid_id = :avalid,');
      end;
      SQL.Add('update_date = datetime(''now'',''localtime''), user_updated = :auser');
      SQL.Add('WHERE taxon_id = :ataxon;');
      if (Params.FindParam('ARANK') <> nil) then
      begin
        ParamByName('ARANK').AsInteger := SspRank;
      end;
      if (Params.FindParam('AVALID') <> nil) then
      begin
        ParamByName('AVALID').AsInteger := ValidSp;
      end;
      ParamByName('AUSER').AsInteger := ActiveUser.Id;
      ParamByName('ATAXON').AsInteger := aSpecies;

      if ExecNow then
        ExecSQL;
    end;

  finally
    FreeAndNil(Ssp);
    FreeAndNil(LumpToSp);
  end;

end;

procedure MoveToSpecies(aSubspecies, ToSpecies: Integer; aTaxonomy: TBirdTaxonomies;
  aDataset: TSQLQuery; ExecNow: Boolean);
var
  OldName, MoveToName, NewName: String;
  OldRankId, ParentSp, ValidSsp, ExistingId: Integer;
  Ssp, MoveToSp: TTaxon;
  OldRank: TZooRank;
begin
  ExistingId := 0;
  OldRankId := GetRankFromTaxon(aSubspecies);
  OldRank := GetRankType(OldRankId);
  OldName := GetName('zoo_taxa', 'full_name', 'taxon_id', aSubspecies);
  MoveToName := GetName('zoo_taxa', 'full_name', 'taxon_id', ToSpecies);
  if OldRank = trPolitypicGroup then
    NewName := MoveToName + ' ' + Trim(ExtractWord(2, OldName, Brackets))
  else
    NewName := MoveToName + ' ' + ExtractWord(3, OldName, [' ']);
  ParentSp := ToSpecies;
  Ssp := TTaxon.Create(aSubspecies);
  MoveToSp := TTaxon.Create(ToSpecies);
  //GravaLog('MOVE TO SPECIES', OldName + ' -> ' + MoveToName + ' = ' + NewName);

  try
    // If taxon exists
    if RecordExists(tbZooTaxa, 'full_name', NewName) = True then
    begin
      ExistingId := GetKey('zoo_taxa', 'taxon_id', 'full_name', NewName);
      with aDataset do
      begin
        if ExecNow then
          SQL.Clear;
        SQL.Add('UPDATE zoo_taxa SET ');
        if (btClements in aTaxonomy) then { Clementes/eBird }
        begin
          SQL.Add('clements_taxonomy = 1,');
          case OldRank of
            trMonotypicGroup:
              begin
                SQL.Add('rank_id = :arankmono,');
                SQL.Add('formatted_name = :aformattedmono,');
              end;
            trPolitypicGroup:
              begin
                SQL.Add('rank_id = :arankpoli,');
                SQL.Add('formatted_name = :aformattedpoli,');
              end;
          else
            SQL.Add('rank_id = :arank,');
            SQL.Add('formatted_name = :aformattedname,');
          end;
          SQL.Add('valid_id = null,');
          // SQL.Add('TAX_ENGLISH = '+QuotedStr(Ssp.NomeEnglish)+',');
          SQL.Add('distribution = :geodist,');
        end;
        if (btIOC in aTaxonomy) then { IOC }
        begin
          SQL.Add('ioc_taxonomy = 1,');
          SQL.Add('ioc_rank_id = :arank,');
          SQL.Add('ioc_parent_taxon_id = :asup,');
          SQL.Add('ioc_distribution = :geodistioc,');
        end;
        if (btCBRO in aTaxonomy) then { CBRO }
        begin
          SQL.Add('cbro_taxonomy = 1,');
          SQL.Add('cbro_rank_id = :arank,');
          SQL.Add('cbro_parent_taxon_id = :asup,');
        end;
        SQL.Add('update_date = datetime(''now'',''localtime''), user_updated = :auser');
        SQL.Add('WHERE taxon_id = :ataxon;');
        if (Params.FindParam('ASUP') <> nil) then
        begin
          ParamByName('ASUP').AsInteger := ParentSp;
        end;
        if (Params.FindParam('GEODIST') <> nil) then
        begin
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.Distribution;
        end;
        if (Params.FindParam('GEODISTIOC') <> nil) then
        begin
          ParamByName('GEODISTIOC').DataType := ftMemo;
          ParamByName('GEODISTIOC').AsString := Ssp.IocDistribution;
        end;
        case OldRank of
          trMonotypicGroup:
            begin
              ParamByName('ARANKMONO').AsInteger := OldRankId;
              ParamByName('AFORMATTEDMONO').AsString := FormattedBirdName(NewName, OldRankId);
            end;
          trPolitypicGroup:
            begin
              ParamByName('ARANKPOLI').AsInteger := OldRankId;
              ParamByName('AFORMATTEDPOLI').AsString := FormattedBirdName(NewName, OldRankId);
            end;
        else
          ParamByName('ARANK').AsInteger := Ssp.RankId;
          ParamByName('AFORMATTEDNAME').AsString := FormattedBirdName(NewName, Ssp.RankId);
        end;
        ParamByName('AUSER').AsInteger := ActiveUser.Id;
        ParamByName('ATAXON').AsInteger := ExistingId;

        if ExecNow then
          ExecSQL;
      end;
    end
    else

    // If taxon does not exist
    begin
      with aDataset do
      begin
        if ExecNow then
          SQL.Clear;
        // List fields
        SQL.Add('INSERT INTO zoo_taxa (full_name, formatted_name, authorship, english_name,');
        SQL.Add('rank_id, parent_taxon_id, extinct, extinction_year, species_id, genus_id, subfamily_id,');
        SQL.Add('family_id, order_id, subspecies_group_id, genus_name, species_epithet, subspecies_epithet,');
        if (btClements in aTaxonomy) then
          SQL.Add('clements_taxonomy, distribution, ebird_code,');
        if (btIOC in aTaxonomy) then
          SQL.Add('ioc_taxonomy, ioc_rank_id, ioc_parent_taxon_id, ioc_english_name, ioc_distribution,');
        if (btCBRO in aTaxonomy) then
          SQL.Add('cbro_taxonomy, cbro_rank_id, cbro_parent_taxon_id,');
        SQL.Add('insert_date, user_inserted) ');
        // List values
        SQL.Add('VALUES (:aname, :aformattedname, :autoria, :aenglish, :anivel, :asup,');
        SQL.Add(':aextinto, :anoextinto, :aspecies, :agenus, :asubfamily, :afamily, :aorder, 0,');
        SQL.Add(':agenusname, :aepithet, :asspepithet,');
        if (btClements in aTaxonomy) then
        begin
          SQL.Add('1, :geodist, :aebirdcode,');
        end;
        if (btIOC in aTaxonomy) then
        begin
          SQL.Add('1, :anivelioc, :asupioc, :aenglishioc, :geodistioc,');
        end;
        if (btCBRO in aTaxonomy) then
        begin
          SQL.Add('1, :anivelcbro, :asupcbro,');
        end;
        SQL.Add('datetime(''now'',''localtime''), :auser);');
        ParamByName('ANAME').AsString := NewName;
        ParamByName('AFORMATTEDNAME').AsString := FormattedBirdName(NewName, OldRankId);
        ParamByName('AUTORIA').AsString := Ssp.Authorship;
        ParamByName('AENGLISH').AsString := Ssp.EnglishName;
        ParamByName('ANIVEL').AsInteger := OldRankId;
        ParamByName('ASUP').AsInteger := ParentSp;
        ParamByName('AEXTINTO').AsInteger := Integer(Ssp.Extinct);
        ParamByName('ANOEXTINTO').AsString := Ssp.ExtinctionYear;
        ParamByName('ASPECIES').AsInteger := MoveToSp.SpeciesId;
        ParamByName('AGENUS').AsInteger := MoveToSp.GenusId;
        ParamByName('ASUBFAMILY').AsInteger := MoveToSp.SubfamilyId;
        ParamByName('AFAMILY').AsInteger := MoveToSp.FamilyId;
        ParamByName('AORDER').AsInteger := MoveToSp.OrderId;
        //ParamByName('AGENUSNAME').AsString := MoveToSp.GenusEpithet;
        //ParamByName('AEPITHET').AsString := MoveToSp.SpeciesEpithet;
        //ParamByName('ASSPEPITHET').AsString := ExtractWord(3, NewName, [' ']);
        if (btClements in aTaxonomy) then
        begin
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.Distribution;
          ParamByName('AEBIRDCODE').AsString := Ssp.EbirdCode;
        end;
        if (btIOC in aTaxonomy) then
        begin
          ParamByName('ANIVELIOC').AsInteger := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'ssp.');
          ParamByName('ASUPIOC').AsInteger := ParentSp;
          ParamByName('AENGLISHIOC').AsString := Ssp.IocEnglishName;
          ParamByName('GEODISTIOC').DataType := ftMemo;
          ParamByName('GEODISTIOC').AsString := Ssp.IocDistribution;
        end;
        if (btCBRO in aTaxonomy) then
        begin
          ParamByName('ANIVELCBRO').AsInteger := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'ssp.');
          ParamByName('ASUPCBRO').AsInteger := ParentSp;
        end;
        ParamByName('AUSER').AsInteger := ActiveUser.Id;

        if ExecNow then
          ExecSQL;
      end;
    end;

    // Update subspecies
    if ExistingId > 0 then
      ValidSsp := ExistingId
    else
      ValidSsp := GetLastInsertedKey('zoo_taxa');
    with aDataset do
    begin
      if ExecNow then
        SQL.Clear;
      SQL.Add('UPDATE zoo_taxa SET ');
      if (btClements in aTaxonomy) then { Clementes/eBird }
      begin
        SQL.Add('clements_taxonomy = 0,');
        SQL.Add('valid_id = :avalid,');
      end;
      if (btIOC in aTaxonomy) then { IOC }
      begin
        SQL.Add('ioc_taxonomy = 0,');
        SQL.Add('ioc_rank_id = :arank,');
        SQL.Add('ioc_valid_id = :avalid,');
      end;
      if (btCBRO in aTaxonomy) then { CBRO }
      begin
        SQL.Add('cbro_taxonomy = 0,');
        SQL.Add('cbro_rank_id = :arank,');
        SQL.Add('cbro_valid_id = :avalid,');
      end;
      SQL.Add('update_date = datetime(''now'',''localtime''), user_updated = :auser');
      SQL.Add('WHERE taxon_id = :ataxon;');
      if (Params.FindParam('ARANK') <> nil) then
      begin
        ParamByName('ARANK').AsInteger := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'ssp.');
      end;
      if (Params.FindParam('AVALID') <> nil) then
      begin
        ParamByName('AVALID').AsInteger := ValidSsp;
      end;
      ParamByName('AUSER').AsInteger := ActiveUser.Id;
      ParamByName('ATAXON').AsInteger := aSubspecies;

      if ExecNow then
        ExecSQL;
    end;

  finally
    FreeAndNil(Ssp);
    FreeAndNil(MoveToSp);
  end;

end;

procedure MoveToGenus(aSpecies, ToGenus: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
  ExecNow: Boolean);
var
  OldName, MoveToName, NewName: String;
  SpRank, ParentGenus, ValidSp, ExistingId: Integer;
  Ssp, Gen: TTaxon;
begin
  ExistingId := 0;
  OldName := GetName('zoo_taxa', 'full_name', 'taxon_id', aSpecies);
  MoveToName := GetName('zoo_taxa', 'full_name', 'taxon_id', ToGenus);
  NewName := MoveToName + ' ' + ExtractWord(2, OldName, [' ']);
  SpRank := GetKey('taxon_ranks', 'rank_id', 'rank_acronym', 'sp.');
  ParentGenus := ToGenus;
  Ssp := TTaxon.Create(aSpecies);
  Gen := TTaxon.Create(ToGenus);

  try
    // If taxon exists
    if RecordExists(tbZooTaxa, 'full_name', NewName) = True then
    begin
      ExistingId := GetKey('zoo_taxa', 'taxon_id', 'full_name', NewName);
      with aDataset do
      begin
        if ExecNow then
          SQL.Clear;
        SQL.Add('UPDATE zoo_taxa SET ');
        if (btClements in aTaxonomy) then { Clementes/eBird }
        begin
          SQL.Add('clements_taxonomy = 1,');
          SQL.Add('valid_id = null,');
          // SQL.Add('TAX_ENGLISH = '+QuotedStr(Ssp.NomeEnglish)+',');
          SQL.Add('distribution = :geodist,');
        end;
        if (btIOC in aTaxonomy) then { IOC }
        begin
          SQL.Add('ioc_taxonomy = 1,');
          SQL.Add('ioc_rank_id = :arank,');
          SQL.Add('ioc_parent_taxon_id = :asup,');
          SQL.Add('ioc_distribution = :geodistioc,');
        end;
        if (btCBRO in aTaxonomy) then { CBRO }
        begin
          SQL.Add('cbro_taxonomy = 1,');
          SQL.Add('cbro_rank_id = :arank,');
          SQL.Add('cbro_parent_taxon_id = :asup,');
        end;
        SQL.Add('update_date = datetime(''now'',''localtime''), user_updated = :auser');
        SQL.Add('WHERE taxon_id = :ataxon;');

        if (Params.FindParam('ARANK') <> nil) then
        begin
          ParamByName('ARANK').AsInteger := SpRank;
        end;
        if (Params.FindParam('ASUP') <> nil) then
        begin
          ParamByName('ASUP').AsInteger := ParentGenus;
        end;
        if (Params.FindParam('GEODIST') <> nil) then
        begin
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.Distribution;
        end;
        if (Params.FindParam('GEODISTIOC') <> nil) then
        begin
          ParamByName('GEODISTIOC').DataType := ftMemo;
          ParamByName('GEODISTIOC').AsString := Ssp.IocDistribution;
        end;
        ParamByName('AUSER').AsInteger := ActiveUser.Id;
        ParamByName('ATAXON').AsInteger := ExistingId;

        if ExecNow then
          ExecSQL;
      end;
    end
    else
    // If taxon does not exist
    begin
      with aDataset do
      begin
        if ExecNow then
          SQL.Clear;
        // List fields
        SQL.Add('INSERT INTO zoo_taxa (full_name, formatted_name, authorship, english_name,');
        SQL.Add('rank_id, parent_taxon_id, extinct, extinction_year, species_id, genus_id, subfamily_id,');
        SQL.Add('family_id, order_id, subspecies_group_id, genus_name, species_epithet, subspecies_epithet,');
        if (btClements in aTaxonomy) then
          SQL.Add('clements_taxonomy, distribution, ebird_code,');
        if (btIOC in aTaxonomy) then
          SQL.Add('ioc_taxonomy, ioc_rank_id, ioc_parent_taxon_id, ioc_english_name, ioc_distribution,');
        if (btCBRO in aTaxonomy) then
          SQL.Add('cbro_taxonomy, cbro_rank_id, cbro_parent_taxon_id,');
        SQL.Add('insert_date, user_inserted) ');
        // List values
        SQL.Add('VALUES (:aname, :aformattedname, :autoria, :aenglish, :anivel, :asup,');
        SQL.Add(':aextinto, :anoextinto, :aspecies, :agenus, :asubfamily, :afamily, :aorder, 0,');
        SQL.Add(':agenusname, :aepithet, null,');
        if (btClements in aTaxonomy) then
        begin
          SQL.Add('1, :geodist, :aebirdcode,');
        end;
        if (btIOC in aTaxonomy) then
        begin
          SQL.Add('1, :anivelioc, :asupioc, :aenglishioc, :geodistioc,');
        end;
        if (btCBRO in aTaxonomy) then
        begin
          SQL.Add('1, :anivelcbro, :asupcbro,');
        end;
        SQL.Add('datetime(''now'',''localtime''), :auser);');
        ParamByName('ANAME').AsString := NewName;
        ParamByName('AFORMATTEDNAME').AsString := FormattedBirdName(NewName, SpRank);
        ParamByName('AUTORIA').AsString := Ssp.Authorship;
        ParamByName('AENGLISH').AsString := Ssp.EnglishName;
        ParamByName('ANIVEL').AsInteger := SpRank;
        ParamByName('ASUP').AsInteger := ParentGenus;
        ParamByName('AEXTINTO').AsInteger := Integer(Ssp.Extinct);
        ParamByName('ANOEXTINTO').AsString := Ssp.ExtinctionYear;
        ParamByName('ASPECIES').AsInteger := GetLastInsertedKey('zoo_taxa') + 1;
        ParamByName('AGENUS').AsInteger := ToGenus;
        ParamByName('ASUBFAMILY').AsInteger := Gen.SubfamilyId;
        ParamByName('AFAMILY').AsInteger := Gen.FamilyId;
        ParamByName('AORDER').AsInteger := Gen.OrderId;
        ParamByName('AGENUSNAME').AsString := Gen.FullName;
        ParamByName('AEPITHET').AsString := ExtractWord(2, NewName, [' ']);
        if (btClements in aTaxonomy) then
        begin
          ParamByName('GEODIST').DataType := ftMemo;
          ParamByName('GEODIST').AsString := Ssp.Distribution;
          ParamByName('AEBIRDCODE').AsString := Ssp.EbirdCode;
        end;
        if (btIOC in aTaxonomy) then
        begin
          ParamByName('ANIVELIOC').AsInteger := SpRank;
          ParamByName('ASUPIOC').AsInteger := ParentGenus;
          ParamByName('AENGLISHIOC').AsString := Ssp.IocEnglishName;
          ParamByName('GEODISTIOC').DataType := ftMemo;
          ParamByName('GEODISTIOC').AsString := Ssp.IocDistribution;
        end;
        if (btCBRO in aTaxonomy) then
        begin
          ParamByName('ANIVELCBRO').AsInteger := SpRank;
          ParamByName('ASUPCBRO').AsInteger := ParentGenus;
        end;
        ParamByName('AUSER').AsInteger := ActiveUser.Id;

        if ExecNow then
          ExecSQL;
      end;
    end;

    // Update subspecies
    if ExistingId > 0 then
      ValidSp := ExistingId
    else
      ValidSp := GetLastInsertedKey('zoo_taxa');
    with aDataset do
    begin
      if ExecNow then
        SQL.Clear;
      SQL.Add('UPDATE zoo_taxa SET ');
      if (btClements in aTaxonomy) then { Clementes/eBird }
      begin
        SQL.Add('clements_taxonomy = 0,');
        SQL.Add('valid_id = :avalid,');
      end;
      if (btIOC in aTaxonomy) then { IOC }
      begin
        SQL.Add('ioc_taxonomy = 0,');
        SQL.Add('ioc_rank_id = :arank,');
        SQL.Add('ioc_valid_id = :avalid,');
      end;
      if (btCBRO in aTaxonomy) then { CBRO }
      begin
        SQL.Add('cbro_taxonomy = 0,');
        SQL.Add('cbro_rank_id = :arank,');
        SQL.Add('cbro_valid_id = :avalid,');
      end;
      SQL.Add('update_date = datetime(''now'',''localtime''), user_updated = :auser');
      SQL.Add('WHERE taxon_id = :ataxon;');
      if (Params.FindParam('ARANK') <> nil) then
        begin
          ParamByName('ARANK').AsInteger := SpRank;
        end;
        if (Params.FindParam('AVALID') <> nil) then
        begin
          ParamByName('AVALID').AsInteger := ValidSp;
        end;
        ParamByName('AUSER').AsInteger := ActiveUser.Id;
        ParamByName('ATAXON').AsInteger := aSpecies;

      if ExecNow then
        ExecSQL;
    end;

  finally
    FreeAndNil(Ssp);
    FreeAndNil(Gen);
  end;

end;

procedure MoveToFamily(aFamily: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
  ExecNow: Boolean);
begin
  { #todo : Move taxon to family }
end;

procedure MoveToOrder(aOrder: Integer; aTaxonomy: TBirdTaxonomies; aDataset: TSQLQuery;
  ExecNow: Boolean);
begin
  { #todo : Move taxon to order }
end;

procedure UpdateScientificName(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery;
  ExecNow: Boolean);
var
  RankId: Integer;
begin
  RankId := GetRankFromTaxon(aTaxon);
  with aDataset, SQL do
  begin
    Clear;
    Add('UPDATE zoo_taxa SET full_name = :newname, formatted_name = :newhtml WHERE taxon_id = :ataxon;');
    ParamByName('NEWNAME').AsString := aNewName;
    ParamByName('NEWHTML').AsString := FormattedBirdName(aNewName, RankId);
    ParamByName('ATAXON').AsInteger := aTaxon;

    if ExecNow then
      ExecSQL;
  end;
end;

procedure UpdateEnglishName(aTaxon: Integer; aNewName: String; aTaxonomy: TBirdTaxonomies;
  aDataset: TSQLQuery; ExecNow: Boolean);
begin
  with aDataset, SQL do
  begin
    Clear;
    if (btClements in aTaxonomy) then
      Add('UPDATE zoo_taxa SET english_name = :newname WHERE taxon_id = :ataxon;');
    if (btIOC in aTaxonomy) then
      Add('UPDATE zoo_taxa SET ioc_english_name = :newname WHERE taxon_id = :ataxon;');
    ParamByName('NEWNAME').AsString := aNewName;
    ParamByName('ATAXON').AsInteger := aTaxon;

    if ExecNow then
      ExecSQL;
  end;
end;

procedure UpdatePortuguesName(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery;
  ExecNow: Boolean);
begin
  with aDataset, SQL do
  begin
    Clear;
    Add('UPDATE zoo_taxa SET portuguese_name = :newname WHERE taxon_id = :ataxon;');
    ParamByName('NEWNAME').AsString := aNewName;
    ParamByName('ATAXON').AsInteger := aTaxon;

    if ExecNow then
      ExecSQL;
  end;
end;

procedure UpdateOutrosPortugues(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery;
  ExecNow: Boolean);
begin
  with aDataset, SQL do
  begin
    Clear;
    Add('UPDATE zoo_taxa SET other_portuguese_names = :newname WHERE taxon_id = :ataxon;');
    ParamByName('NEWNAME').AsString := aNewName;
    ParamByName('ATAXON').AsInteger := aTaxon;

    if ExecNow then
      ExecSQL;
  end;
end;

procedure UpdateSpanishName(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery; ExecNow: Boolean
  );
begin
  with aDataset, SQL do
  begin
    Clear;
    Add('UPDATE zoo_taxa SET spanish_name = :newname WHERE taxon_id = :ataxon;');
    ParamByName('NEWNAME').AsString := aNewName;
    ParamByName('ATAXON').AsInteger := aTaxon;

    if ExecNow then
      ExecSQL;
  end;
end;

procedure UpdateAuthorship(aTaxon: Integer; aNewName: String; aDataset: TSQLQuery; ExecNow: Boolean);
begin
  with aDataset, SQL do
  begin
    Clear;
    Add('UPDATE zoo_taxa SET authorship = :autor WHERE taxon_id = :ataxon;');
    ParamByName('AUTOR').AsString := aNewName;
    ParamByName('ATAXON').AsInteger := aTaxon;

    if ExecNow then
      ExecSQL;
  end;
end;

procedure UpdateDistribution(aTaxon: Integer; aDist: String; aTaxonomy: TBirdTaxonomies;
  aDataset: TSQLQuery; ExecNow: Boolean);
begin
  with aDataset, SQL do
  begin
    Clear;
    if (btClements in aTaxonomy) then
      Add('UPDATE zoo_taxa SET distribution = :geodist WHERE taxon_id = :ataxon;');
    if (btIOC in aTaxonomy) then
      Add('UPDATE zoo_taxa SET ioc_distribution = :geodist WHERE taxon_id = :ataxon;');
    ParamByName('GEODIST').AsString := aDist;
    ParamByName('ATAXON').AsInteger := aTaxon;

    if ExecNow then
      ExecSQL;
  end;
end;

procedure UpdateExtinction(aTaxon: Integer; IsExtinct: Boolean; aYear: String; aDataset: TSQLQuery;
  ExecNow: Boolean);
begin
  with aDataset, SQL do
  begin
    Clear;
    if IsExtinct = True then
    begin
      Add('UPDATE zoo_taxa SET extinct = 1, extinction_year = :ayear WHERE taxon_id = :ataxon;');
      ParamByName('AYEAR').AsString := aYear;
    end
    else
      Add('UPDATE zoo_taxa SET extinct = 0 WHERE taxon_id = :ataxon;');
    ParamByName('ATAXON').AsInteger := aTaxon;

    if ExecNow then
      ExecSQL;
  end;
end;

{ TTaxon }

constructor TTaxon.Create(aValue: Integer);
begin
  if aValue > 0 then
    GetData(aValue)
  else
    Clear;
end;

procedure TTaxon.Clear;
begin
  inherited;
  FEnglishName := EmptyStr;
  FPortugueseName := EmptyStr;
  FSpanishName := EmptyStr;
  FSortNum := 0.0;
  FQuickCode := EmptyStr;
  FIucnStatus := EmptyStr;
  FExtinct := False;
  FExtinctionYear := EmptyStr;
  FDistribution := EmptyStr;
  FEbirdCode := EmptyStr;
  FClementsTaxonomy := False;
  FSubfamilyId := 0;
  //FGenusEpithet := EmptyStr;
  //FSpeciesEpithet := EmptyStr;
  FSubspeciesGroupId := 0;
  FSubspeciesGroupEpithet := EmptyStr;
  //FSubspeciesEpithet := EmptyStr;
  FIncertaeSedis := 0;
  FIocTaxonomy := False;
  FIocEnglishName := EmptyStr;
  FIocParentTaxonId := 0;
  FIocRankId := 0;
  FIocValidId := 0;
  FIocDistribution := EmptyStr;
  FIocSortNum := 0.0;
  FCbroTaxonomy := False;
  FOtherPortugueseNames := EmptyStr;
  //FCbroParentTaxonId := 0;
  //FCbroRankId := 0;
  //FCbroValidId := 0;
  //FCbroSortNum := 0.0;
end;

procedure TTaxon.GetData(aKey: Integer);
var
  Qry: TSQLQuery;
begin
  Qry := TSQLQuery.Create(DMM.sqlCon);
  with Qry, SQL do
  try
    DataBase := DMM.sqlCon;
    Clear;
    Add('SELECT * FROM zoo_taxa');
    Add('WHERE taxon_id = :cod');
    ParamByName('COD').AsInteger := aKey;
    Open;
    if RecordCount > 0 then
      GetData(Qry);
    Close;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TTaxon.GetData(aDataSet: TDataSet);
begin
  if not aDataSet.Active then
    Exit;

  with aDataSet do
  begin
    FId := FieldByName('taxon_id').AsInteger;
    FFullName := FieldByName('full_name').AsString;
    FFormattedName := FieldByName('formatted_name').AsString;
    FParentTaxonId := FieldByName('parent_taxon_id').AsInteger;
    FRankId := FieldByName('rank_id').AsInteger;
    FAuthorship := FieldByName('authorship').AsString;
    FSortNum := FieldByName('sort_num').AsFloat;
    FQuickCode := FieldByName('quick_code').AsString;
    FEnglishName := FieldByName('english_name').AsString;
    FPortugueseName := FieldByName('portuguese_name').AsString;
    FSpanishName := FieldByName('spanish_name').AsString;
    FValidId := FieldByName('valid_id').AsInteger;
    FIucnStatus := FieldByName('iucn_status').AsString;
    FExtinct := FieldByName('extinct').AsBoolean;
    FExtinctionYear := FieldByName('extinction_year').AsString;
    FDistribution := FieldByName('distribution').AsString;
    FEbirdCode := FieldByName('ebird_code').AsString;
    FClementsTaxonomy := FieldByName('clements_taxonomy').AsBoolean;
    FOrderId := FieldByName('order_id').AsInteger;
    FFamilyId := FieldByName('family_id').AsInteger;
    FSubfamilyId := FieldByName('subfamily_id').AsInteger;
    FGenusId := FieldByName('genus_id').AsInteger;
    //FGenusEpithet := FieldByName('genus_name').AsString;
    FSpeciesId := FieldByName('species_id').AsInteger;
    //FSpeciesEpithet := FieldByName('species_epithet').AsString;
    FSubspeciesGroupId := FieldByName('subspecies_group_id').AsInteger;
    FSubspeciesGroupEpithet := FieldByName('group_name').AsString;
    //FSubspeciesEpithet := FieldByName('subspecies_epithet').AsString;
    FIncertaeSedis := FieldByName('incertae_sedis').AsInteger;
    FIocTaxonomy := FieldByName('ioc_taxonomy').AsBoolean;
    FIocEnglishName := FieldByName('ioc_english_name').AsString;
    FIocParentTaxonId := FieldByName('ioc_parent_taxon_id').AsInteger;
    FIocRankId := FieldByName('ioc_rank_id').AsInteger;
    FIocValidId := FieldByName('ioc_valid_id').AsInteger;
    FIocDistribution := FieldByName('ioc_distribution').AsString;
    FIocSortNum := FieldByName('ioc_sort_num').AsFloat;
    FCbroTaxonomy := FieldByName('cbro_taxonomy').AsBoolean;
    FOtherPortugueseNames := FieldByName('other_portuguese_names').AsString;
    //FCbroParentTaxonId := FieldByName('cbro_parent_taxon_id').AsInteger;
    //FCbroRankId := FieldByName('cbro_rank_id').AsInteger;
    //FCbroValidId := FieldByName('cbro_valid_id').AsInteger;
    //FCbroSortNum := FieldByName('cbro_sort_num').AsFloat;
    FUserInserted := FieldByName('user_inserted').AsInteger;
    FUserUpdated := FieldByName('user_updated').AsInteger;
    FInsertDate := FieldByName('insert_date').AsDateTime;
    FUpdateDate := FieldByName('update_date').AsDateTime;
    FExported := FieldByName('exported_status').AsBoolean;
    FMarked := FieldByName('marked_status').AsBoolean;
    FActive := FieldByName('active_status').AsBoolean;
  end;
end;

function TTaxon.Diff(aOld: TTaxon; var aList: TStrings): Boolean;
var
  R: String;
begin
  Result := False;
  R := EmptyStr;

  if FieldValuesDiff(rscScientificName, aOld.FullName, FFullName, R) then
    aList.Add(R);
  if FieldValuesDiff(rscScientificName + ' (HTML)', aOld.FormattedName, FFormattedName, R) then
    aList.Add(R);
  if FieldValuesDiff(rscParentTaxonID, aOld.ParentTaxonId, FParentTaxonId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscTaxonomicRankID, aOld.RankId, FRankId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscAuthorship, aOld.Authorship, FAuthorship, R) then
    aList.Add(R);
  if FieldValuesDiff(rscTaxonomicSequence, aOld.SortNum, FSortNum, R) then
    aList.Add(R);
  if FieldValuesDiff(rscQuickCode, aOld.QuickCode, FQuickCode, R) then
    aList.Add(R);
  if FieldValuesDiff(rscEnglishName, aOld.EnglishName, FEnglishName, R) then
    aList.Add(R);
  if FieldValuesDiff(rscPortugueseName, aOld.PortugueseName, FPortugueseName, R) then
    aList.Add(R);
  if FieldValuesDiff(rscSpanishName, aOld.SpanishName, FSpanishName, R) then
    aList.Add(R);
  if FieldValuesDiff(rscValidNameID, aOld.ValidId, FValidId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscConservationStatus, aOld.IucnStatus, FIucnStatus, R) then
    aList.Add(R);
  if FieldValuesDiff(rscExtinct, aOld.Extinct, FExtinct, R) then
    aList.Add(R);
  if FieldValuesDiff(rscExtinctionYear, aOld.ExtinctionYear, FExtinctionYear, R) then
    aList.Add(R);
  if FieldValuesDiff(rscDistribution, aOld.Distribution, FDistribution, R) then
    aList.Add(R);
  if FieldValuesDiff(rscEbirdCode, aOld.EbirdCode, FEbirdCode, R) then
    aList.Add(R);
  if FieldValuesDiff(rscClements, aOld.ClementsTaxonomy, FClementsTaxonomy, R) then
    aList.Add(R);
  if FieldValuesDiff(rscOrderID, aOld.OrderId, FOrderId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscFamilyID, aOld.FamilyId, FFamilyId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscSubfamilyID, aOld.SubfamilyId, FSubfamilyId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscGenusID, aOld.GenusId, FGenusId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscSpeciesID, aOld.SpeciesId, FSpeciesId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscSubspeciesGroupID, aOld.SubspeciesGroupId, FSubspeciesGroupId, R) then
    aList.Add(R);
  //if FieldValuesDiff('Nome gênero', aOld.GenusEpithet, FGenusEpithet, R) then
  //  aList.Add(R);
  //if FieldValuesDiff('Epíteto específico', aOld.SpeciesEpithet, FSpeciesEpithet, R) then
  //  aList.Add(R);
  if FieldValuesDiff(rscSubspeciesGroup, aOld.SubspeciesGroupEpithet, FSubspeciesGroupEpithet, R) then
    aList.Add(R);
  //if FieldValuesDiff('Epíteto subespecífico', aOld.SubspeciesEpithet, FSubspeciesEpithet, R) then
  //  aList.Add(R);
  if FieldValuesDiff(rscIncertaeSedis, aOld.IncertaeSedis, FIncertaeSedis, R) then
    aList.Add(R);
  if FieldValuesDiff(rscIOC, aOld.IocTaxonomy, FIocTaxonomy, R) then
    aList.Add(R);
  if FieldValuesDiff(rscEnglishName + ' (IOC)', aOld.IocEnglishName, FIocEnglishName, R) then
    aList.Add(R);
  if FieldValuesDiff(rscParentTaxonID + ' (IOC)', aOld.IocParentTaxonId, FIocParentTaxonId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscTaxonomicRankID + ' (IOC)', aOld.IocRankId, FIocRankId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscValidNameID + ' (IOC)', aOld.IocValidId, FIocValidId, R) then
    aList.Add(R);
  if FieldValuesDiff(rscDistribution + ' (IOC)', aOld.IocDistribution, FIocDistribution, R) then
    aList.Add(R);
  if FieldValuesDiff(rscTaxonomicSequence + ' (IOC)', aOld.IocSortNum, FIocSortNum, R) then
    aList.Add(R);
  if FieldValuesDiff(rscCBRO, aOld.CbroTaxonomy, FCbroTaxonomy, R) then
    aList.Add(R);
  if FieldValuesDiff(rscOtherPortugueseNames, aOld.OtherPortugueseNames, FOtherPortugueseNames, R) then
    aList.Add(R);
  //if FieldValuesDiff('Nível superior (CBRO)', aOld.CbroParentTaxonId, FCbroParentTaxonId, R) then
  //  aList.Add(R);
  //if FieldValuesDiff('Nível (CBRO)', aOld.CbroRankId, FCbroRankId, R) then
  //  aList.Add(R);
  //if FieldValuesDiff('Nome válido (CBRO)', aOld.CbroValidId, FCbroValidId, R) then
  //  aList.Add(R);
  //if FieldValuesDiff('Ordenação (CBRO)', aOld.CbroSortNum, FCbroSortNum, R) then
  //  aList.Add(R);

  Result := aList.Count > 0;
end;

{ TRank }

constructor TRank.Create(aValue: Integer);
begin
  if aValue > 0 then
    GetData(aValue)
  else
    Clear;
end;

procedure TRank.Clear;
begin
  inherited Clear;
  FName := EmptyStr;
  FAcronym := EmptyStr;
  FRankIndex := 0;
  FMainRank := False;
  FSubrank := False;
  FInfrarank := False;
  FInfraspecific := False;
  FZoologicalCode := False;
  FBotanicalCode := False;
end;

procedure TRank.GetData(aKey: Integer);
var
  Qry: TSQLQuery;
begin
  Qry := TSQLQuery.Create(DMM.sqlCon);
  with Qry, SQL do
  try
    DataBase := DMM.sqlCon;
    Clear;
    Add('SELECT * FROM taxon_ranks');
    Add('WHERE rank_id = :cod');
    ParamByName('COD').AsInteger := aKey;
    Open;
    if RecordCount > 0 then
      GetData(Qry);
    Close;
  finally
    FreeAndNil(Qry);
  end;
end;

procedure TRank.GetData(aDataSet: TDataSet);
begin
  if not aDataSet.Active then
    Exit;

  with aDataSet do
  begin
    FId := FieldByName('rank_id').AsInteger;
    FName := FieldByName('rank_name').AsString;
    FAcronym := FieldByName('rank_acronym').AsString;
    FRankIndex := FieldByName('rank_seq').AsInteger;
    FMainRank := FieldByName('main_rank').AsBoolean;
    FSubrank := FieldByName('subrank').AsBoolean;
    FInfrarank := FieldByName('infrarank').AsBoolean;
    FInfraspecific := FieldByName('infraspecific').AsBoolean;
    FZoologicalCode := FieldByName('iczn').AsBoolean;
    FBotanicalCode := FieldByName('icbn').AsBoolean;
    FUserInserted := FieldByName('user_inserted').AsInteger;
    FUserUpdated := FieldByName('user_updated').AsInteger;
    FInsertDate := FieldByName('insert_date').AsDateTime;
    FUpdateDate := FieldByName('update_date').AsDateTime;
    FExported := FieldByName('exported_status').AsBoolean;
    FMarked := FieldByName('marked_status').AsBoolean;
    FActive := FieldByName('active_status').AsBoolean;
  end;
end;

end.

