unit Aurelius.Schema.SQLite;

{$I Aurelius.Inc}

interface

uses
  Generics.Collections,
  Aurelius.Drivers.Interfaces,
  Aurelius.Schema.AbstractImporter,
  Aurelius.Sql.Metadata;

type
  TSQLiteSchemaImporter = class(TAbstractSchemaImporter)
  strict protected
    procedure GetDatabaseMetadata(Connection: IDBConnection; Database: TDatabaseMetadata); override;
  end;

  TSQLiteSchemaRetriever = class(TSchemaRetriever)
  strict private
    function AreSameColumns(OldCols, NewCols: TList<TColumnMetadata>): boolean;
    procedure GetTables;
    procedure GetColumns(Table: TTableMetadata; const SQL: string);
    procedure GetUniqueKeys(Table: TTableMetadata);
    procedure GetUniqueKeyColumns(UniqueKey: TUniqueKeyMetadata);
    procedure GetForeignKeys;
  public
    constructor Create(AConnection: IDBConnection; ADatabase: TDatabaseMetadata); override;
    procedure RetrieveDatabase; override;
  end;

implementation

uses
  SysUtils,
  Aurelius.Schema.Register,
  Aurelius.Schema.Utils;

{ TSQLiteSchemaImporter }

procedure TSQLiteSchemaImporter.GetDatabaseMetadata(Connection: IDBConnection;
  Database: TDatabaseMetadata);
var
  Retriever: TSchemaRetriever;
begin
  Retriever := TSQLiteSchemaRetriever.Create(Connection, Database);
  try
    Retriever.RetrieveDatabase;
  finally
    Retriever.Free;
  end;
end;

{ TSQLiteSchemaRetriever }

function TSQLiteSchemaRetriever.AreSameColumns(OldCols, NewCols: TList<TColumnMetadata>): boolean;
var
  OldCol, NewCol: TColumnMetadata;
  Found: boolean;
begin
  if OldCols.Count <> NewCols.Count then
    Exit(false);

  for OldCol in OldCols do
  begin
    Found := false;
    for NewCol in NewCols do
      if SameText(NewCol.Name, OldCol.Name) then
      begin
        Found := true;
        break;
      end;
    if not Found then Exit(false);
  end;
  Result := true;
end;

constructor TSQLiteSchemaRetriever.Create(AConnection: IDBConnection;
  ADatabase: TDatabaseMetadata);
begin
  inherited Create(AConnection, ADatabase);
end;

procedure TSQLiteSchemaRetriever.GetColumns(Table: TTableMetadata; const SQL: string);
var
  ResultSet: IDBResultSet;
  Column: TColumnMetadata;
begin
  ResultSet := Open(Format('pragma table_info("%s")', [Table.Name]));
  while ResultSet.Next do
  begin
    Column := TColumnMetadata.Create(Table);
    Table.Columns.Add(Column);
    Column.Name := AsString(ResultSet.GetFieldValue('name'));
    Column.NotNull := AsInteger(ResultSet.GetFieldValue('notnull')) <> 0;
    Column.DataType := AsString(ResultSet.GetFieldValue('type'));

    // If column is primary key, add it to IdColumns
    if AsInteger(ResultSet.GetFieldValue('pk')) <> 0 then
      Table.IdColumns.Add(Column);
  end;

  // Set autoincrement in a quick and dirty way. We could parse the SQL or use sqlite3_table_column_metadata but
  // this way should work fine for Aurelius usage
  if (Table.IdColumns.Count = 1) and (Pos('autoincrement', Lowercase(SQL)) > 0) then
    Table.IdColumns[0].AutoGenerated := true;
end;

procedure TSQLiteSchemaRetriever.GetForeignKeys;
var
  Table: TTableMetadata;
  ResultSet: IDBResultSet;
  ForeignKey: TForeignKeyMetadata;
  LastId: integer;
begin
  for Table in Database.Tables do
  begin
    ResultSet := Open(Format('pragma foreign_key_list("%s")', [Table.Name]));
    ForeignKey := nil;
    LastId := -1;
    while ResultSet.Next do
    begin
      if (ForeignKey = nil) or (LastId <> AsInteger(ResultSet.GetFieldValue('id'))) then
      begin
        ForeignKey := TForeignKeyMetadata.Create(Table);
        Table.ForeignKeys.Add(ForeignKey);
        ForeignKey.Name := Format('FK_%s_%s', [AsString(ResultSet.GetFieldValue('id')), Table.Name]);
        ForeignKey.ToTable := TSchemaUtils.GetTable(Database, AsString(ResultSet.GetFieldValue('table')), '');
        LastId := AsInteger(ResultSet.GetFieldValue('id'));
      end;

      ForeignKey.FromColumns.Add(TSchemaUtils.GetColumn(ForeignKey.FromTable, AsString(ResultSet.GetFieldValue('from'))));
      ForeignKey.ToColumns.Add(TSchemaUtils.GetColumn(ForeignKey.ToTable, AsString(ResultSet.GetFieldValue('to'))));
    end;
  end;
end;

procedure TSQLiteSchemaRetriever.GetTables;
var
  ResultSet: IDBResultSet;
  Table: TTableMetadata;
  SQL: string;
begin
  ResultSet := Open(
    'SELECT tbl_name as TABLE_NAME, '+
    'sql as TABLE_SQL '+
    'FROM sqlite_master '+
    'WHERE type = ''table'' '+
    'AND tbl_name NOT LIKE ''sqlite_%'' '+
    'ORDER BY tbl_name'
  );
  while ResultSet.Next do
  begin
    Table := TTableMetadata.Create(Database);
    Database.Tables.Add(Table);
    Table.Name := AsString(ResultSet.GetFieldValue('TABLE_NAME'));
    SQL := AsString(ResultSet.GetFieldValue('TABLE_SQL'));
    GetColumns(Table, SQL);
    GetUniqueKeys(Table);
  end;
end;

procedure TSQLiteSchemaRetriever.GetUniqueKeyColumns(UniqueKey: TUniqueKeyMetadata);
var
  ResultSet: IDBResultSet;
begin
  ResultSet := Open(Format('pragma index_info("%s")', [UniqueKey.Name]));
  while ResultSet.Next do
    UniqueKey.Columns.Add(TSchemaUtils.GetColumn(UniqueKey.Table, AsString(ResultSet.GetFieldValue('name'))));
end;

procedure TSQLiteSchemaRetriever.GetUniqueKeys(Table: TTableMetadata);
var
  ResultSet: IDBResultSet;
  UniqueKey: TUniqueKeyMetadata;
  Column: TColumnMetadata;
begin
  ResultSet := Open(Format('pragma index_list("%s")', [Table.Name]));
  while ResultSet.Next do
    if AsInteger(ResultSet.GetFieldValue('unique')) <> 0 then
    begin
      UniqueKey := TUniqueKeyMetadata.Create(Table);
      Table.UniqueKeys.Add(UniqueKey);
      UniqueKey.Name := AsString(ResultSet.GetFieldValue('name'));
      GetUniqueKeyColumns(UniqueKey);

      // If unique key relates to primary key, then now we have the correct
      // order for the primary key. We should then set the correct column order
      // in primary key, then remove the unique key
      if AreSameColumns(UniqueKey.Columns, Table.IdColumns) then
      begin
        Table.IdColumns.Clear;
        for Column in UniqueKey.Columns do
          Table.IdColumns.Add(Column);
        Table.UniqueKeys.Remove(UniqueKey);
      end;
    end;
end;

procedure TSQLiteSchemaRetriever.RetrieveDatabase;
begin
  Database.Clear;
  GetTables;
  GetForeignKeys;
end;

initialization
  TSchemaImporterRegister.GetInstance.RegisterImporter('SQLite', TSQLiteSchemaImporter.Create);

end.

