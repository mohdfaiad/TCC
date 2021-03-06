unit Aurelius.Mapping.Metadata;

{$I Aurelius.inc}

interface

uses
  DB, Generics.Collections, TypInfo, Rtti,
  Aurelius.Mapping.Optimization;

type
  TMetaTable = class
  private
    FName: string;
    FSchema: string;
  public
    property Name: string read FName write FName;
    property Schema: string read FSchema write FSchema;
    function Clone: TMetaTable;
  end;

  TColumnProp = (Unique, Required, NoInsert, NoUpdate, Lazy);
  TColumnProps = set of TColumnProp;

  TColumn = class
  private
    FDeclaringClass: TClass;
    FName: string;
    FFieldType: TFieldType;
    FProperties: TColumnProps;
    FLength: Integer;
    FPrecision: Integer;
    FScale: Integer;
    FIsDiscriminator: Boolean;
    FReferencedClass: TClass;
    FReferencedColumn: TColumn;
    FIsForeign: Boolean;
    FForeignClass: TClass;
    FIsPrimaryJoin: Boolean;
    FIsLazy: Boolean;
    FOptimization: TRttiOptimization;
    FReferencedColumnIsId: boolean;
    procedure SetOptimization(const Value: TRttiOptimization);
  public
    constructor Create;
    destructor Destroy; override;
    property DeclaringClass: TClass read FDeclaringClass write FDeclaringClass;
    property Name: string read FName write FName;
    property FieldType: TFieldType read FFieldType write FFieldType;
    property Properties: TColumnProps read FProperties write FProperties;
    property Length: Integer read FLength write FLength;
    property Precision: Integer read FPrecision write FPrecision;
    property Scale: Integer read FScale write FScale;
    property IsDiscriminator: Boolean read FIsDiscriminator write FIsDiscriminator;
    property ReferencedClass: TClass read FReferencedClass write FReferencedClass;
    property ReferencedColumn: TColumn read FReferencedColumn write FReferencedColumn;
    property ReferencedColumnIsId: boolean read FReferencedColumnIsId write FReferencedColumnIsId;
    property IsForeign: Boolean read FIsForeign write FIsForeign;
    property ForeignClass: TClass read FForeignClass write FForeignClass;
    property IsPrimaryJoin: Boolean read FIsPrimaryJoin write FIsPrimaryJoin;
    property IsLazy: Boolean read FIsLazy write FIsLazy;

    // Optimization properties
    property Optimization: TRttiOptimization read FOptimization write SetOptimization;

    function Clone: TColumn;
  end;

  TIdGenerator = (None, IdentityOrSequence, Guid, Uuid38, Uuid36, Uuid32);

  TMetaId = class
  private
    FIdGenerator: TIdGenerator;
    FColumns: TArray<TColumn>;
    function GetIsAutoGenerated: boolean;
    function GetColumnCount: integer;
    function GetIsUserAssignedId: boolean;
    property ColumnCount: integer read GetColumnCount;
  public
    function Clone: TMetaId;
    property IsAutoGenerated: boolean read GetIsAutoGenerated;
    property IsUserAssignedId: boolean read GetIsUserAssignedId;
    property Columns: TArray<TColumn> read FColumns write FColumns;
    property IdGenerator: TIdGenerator read FIdGenerator write FIdGenerator;
  end;

  TInheritanceStrategy = (SingleTable, JoinedTables);

  TMetaInheritance = class
  private
    FStrategy: TInheritanceStrategy;
  public
    property Strategy: TInheritanceStrategy read FStrategy write FStrategy;
  end;

  TSequence = class
  private
    FSequenceName: string;
    FInitialValue: Integer;
    FIncrement: Integer;
  public
    property SequenceName: string read FSequenceName write FSequenceName;
    property InitialValue: Integer read FInitialValue write FInitialValue;
    property Increment: Integer read FIncrement write FIncrement;

    function Clone: TSequence;
  end;

  TUniqueConstraint = class
  private
    FFieldNames: TList<string>;
  public
    property FieldNames: TList<string> read FFieldNames write FFieldNames;
    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TCascadeType = (SaveUpdate, Merge, Remove);
  TCascadeTypes = set of TCascadeType;
  TAssociationProp = (Lazy, Required);
  TAssociationProps = set of TAssociationProp;

const
  CascadeTypeAll = [TCascadeType.SaveUpdate, TCascadeType.Merge, TCascadeType.Remove];

type
  TAssociationKind = (SingleValued, ManyValued);

  TAssociation = class
  private
    FClassMemberName: string;
    FTarget: TClass;
    FCascade: TCascadeTypes;
    FJoinColumns: TList<TColumn>;
    FKind: TAssociationKind;
    FMappedBy: string;
    FOptimization: TRttiOptimization;
    FRelatedAssociation: TAssociation;
    FProperties: TAssociationProps;
    procedure SetOptimization(const Value: TRttiOptimization);
    function GetLazy: boolean;
    function GetRequired: boolean;
    procedure SetLazy(const Value: boolean);
    procedure SetRequired(const Value: boolean);
  public
    property ClassMemberName: string read FClassMemberName write FClassMemberName;
    property Target: TClass read FTarget write FTarget;
    property Properties: TAssociationProps read FProperties write FProperties;
    property Required: boolean read GetRequired write SetRequired;
    property Lazy: boolean read GetLazy write SetLazy;
    property Cascade: TCascadeTypes read FCascade write FCascade;
    property JoinColumns: TList<TColumn> read FJoinColumns write FJoinColumns;
    property Kind: TAssociationKind read FKind write FKind;
    property MappedBy: string read FMappedBy write FMappedBy;
    property RelatedAssociation: TAssociation read FRelatedAssociation write FRelatedAssociation;

    property Optimization: TRttiOptimization read FOptimization write SetOptimization;

    constructor Create; virtual;
    destructor Destroy; override;
  end;

  TEnumMappingType = (emChar, emInteger, emString);

  TEnumeration = class
  private
    FOrdinalType: TRttiOrdinalType;
    FMappedType: TEnumMappingType;
    FMappedValues: TList<string>;
    FMinLength: Integer;
    function GetMinLength: Integer;
    function GetMappedValues: TList<string>;
    procedure SetMappedValues(const Value: TList<string>);
  public
    property OrdinalType: TRttiOrdinalType read FOrdinalType write FOrdinalType;
    property MappedType: TEnumMappingType read FMappedType write FMappedType;
    property MappedValues: TList<string> read GetMappedValues write SetMappedValues;
    property MinLength: Integer read GetMinLength;
    constructor Create; virtual;
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils, Math,
  Aurelius.Mapping.Exceptions;

{ TUniqueConstraint }

constructor TUniqueConstraint.Create;
begin
  FFieldNames := TList<string>.Create;
end;

destructor TUniqueConstraint.Destroy;
begin
  FFieldNames.Free;
  inherited;
end;

{ TAssociation }

constructor TAssociation.Create;
begin
  FJoinColumns := TList<TColumn>.Create;
end;

destructor TAssociation.Destroy;
begin
  FreeAndNil(FOptimization);
  FJoinColumns.Free;
  inherited;
end;

function TAssociation.GetLazy: boolean;
begin
  Result := TAssociationProp.Lazy in Properties;
end;

function TAssociation.GetRequired: boolean;
begin
  Result := TAssociationProp.Required in Properties;
end;

procedure TAssociation.SetLazy(const Value: boolean);
begin
  if Value then
    Properties := Properties + [TAssociationProp.Lazy]
  else
    Properties := Properties - [TAssociationProp.Lazy];
end;

procedure TAssociation.SetOptimization(const Value: TRttiOptimization);
begin
  FreeAndNil(FOptimization);
  FOptimization := Value;
end;

procedure TAssociation.SetRequired(const Value: boolean);
begin
  if Value then
    Properties := Properties + [TAssociationProp.Required]
  else
    Properties := Properties - [TAssociationProp.Required];
end;

{ TColumn }

function TColumn.Clone: TColumn;
begin
  Result := TColumn.Create;

  Result.FDeclaringClass := FDeclaringClass;
  if Optimization <> nil then
    Result.Optimization := Optimization.Clone;
  Result.FName := FName;
  Result.FFieldType := FFieldType;
  Result.FProperties := FProperties;
  Result.FLength := FLength;
  Result.FPrecision := FPrecision;
  Result.FScale := FScale;
  Result.FIsDiscriminator := FIsDiscriminator;
  Result.FReferencedClass := FReferencedClass;
  Result.FReferencedColumn := FReferencedColumn;
  Result.FReferencedColumnIsId := FReferencedColumnIsId;
  Result.FIsForeign := FIsForeign;
  Result.FForeignClass := FForeignClass;
  Result.FIsLazy := FIsLazy;
end;

constructor TColumn.Create;
begin
end;

destructor TColumn.Destroy;
begin
  FreeAndNil(FOptimization);
  inherited;
end;

procedure TColumn.SetOptimization(const Value: TRttiOptimization);
begin
  FreeAndNil(FOptimization);
  FOptimization := Value;
end;

{ TSequence }

function TSequence.Clone: TSequence;
begin
  Result := TSequence.Create;
  Result.FSequenceName := FSequenceName;
  Result.FInitialValue := FInitialValue;
  Result.FIncrement := FIncrement;
end;

{ TEnumeration }

constructor TEnumeration.Create;
begin
  FMappedValues := TList<string>.Create;
  FMinLength := -1;
end;

destructor TEnumeration.Destroy;
begin
  FMappedValues.Free;
  inherited;
end;

function TEnumeration.GetMappedValues: TList<string>;
var
  I: Integer;
begin
  Result := FMappedValues;

  if (FMappedType = TEnumMappingType.emString) then
  begin
    if (Result.Count = 0) then
    begin
      for I := OrdinalType.MinValue to OrdinalType.MaxValue do
        Result.Add(GetEnumName(OrdinalType.Handle, I));
    end;
    if (Result.Count <> OrdinalType.MaxValue - OrdinalType.MinValue + 1) then
    begin
      raise EInvalidEnumMapping.CreateFmt('Count of enum mapping values does not ' +
        'match count of enum constants at type %s.', [OrdinalType.ToString]);
    end;
  end;
end;

function TEnumeration.GetMinLength: Integer;
var
  S: string;
begin
  if FMinLength = -1 then
  begin
    case FMappedType of
      TEnumMappingType.emChar:    FMinLength := 1;
      TEnumMappingType.emInteger: FMinLength := 0;
      TEnumMappingType.emString:
        begin
          FMinLength := 0;
          for S in MappedValues do
            FMinLength := Max(FMinLength, Length(S));
        end;
    end;
  end;
  Result := FMinLength;
end;

procedure TEnumeration.SetMappedValues(const Value: TList<string>);
begin
  FMappedValues.AddRange(Value);
end;

{ TMetaTable }

function TMetaTable.Clone: TMetaTable;
begin
  Result := TMetaTable.Create;
  Result.FName := FName;
  Result.FSchema := FSchema;
end;

{ TMetaId }

function TMetaId.Clone: TMetaId;
var
  c: Integer;
begin
  Result := TMetaId.Create;
  Result.FIdGenerator := FIdGenerator;
  SetLength(Result.FColumns, Length(FColumns));
  for c := 0 to Length(FColumns) - 1 do
    Result.FColumns[c] := FColumns[c];
end;

function TMetaId.GetColumnCount: integer;
begin
  Result := Length(Columns);
end;

function TMetaId.GetIsAutoGenerated: boolean;
begin
  Result := (ColumnCount = 1) and (IdGenerator = TIdGenerator.IdentityOrSequence);
end;

function TMetaId.GetIsUserAssignedId: boolean;
begin
  { if IdGenerator.None or composite id, then user must manually assign Id }
  Result := (IdGenerator = TIdGenerator.None) or (ColumnCount > 1);
end;

end.
