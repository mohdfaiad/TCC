unit EditSong;

interface

uses
  Generics.Collections, System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.Layouts, FMX.Objects,
  FMX.Edit, FMX.ListBox,
  EditSongController,
  Song;

type
  TfrmEditSong = class(TForm)
    TopLabel: TLabel;
    ButtonLayout: TLayout;
    btCancel: TButton;
    btSave: TButton;
    BottomLayout: TLayout;
    CenterLayout: TLayout;
    NameLayout: TLayout;
    edName: TEdit;
    lbName: TLabel;
    CenterLayout2: TLayout;
    edFileLocation: TEdit;
    lbFileLocation: TLabel;
    btFile: TSpeedButton;
    Image1: TImage;
    Layout1: TLayout;
    cbFormat: TComboBox;
    lbFormat: TLabel;
    btNewFormat: TSpeedButton;
    Layout2: TLayout;
    cbAlbum: TComboBox;
    lbAlbum: TLabel;
    btNewAlbum: TSpeedButton;
    Layout3: TLayout;
    cbArtist: TComboBox;
    lbArtist: TLabel;
    btNewArtist: TSpeedButton;
    Layout4: TLayout;
    edDurationMinutes: TEdit;
    lbDuration: TLabel;
    edDurationSeconds: TEdit;
    Label1: TLabel;
    procedure btSaveClick(Sender: TObject);
    procedure btFileClick(Sender: TObject);
    procedure btNewFormatClick(Sender: TObject);
    procedure btNewArtistClick(Sender: TObject);
    procedure btNewAlbumClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btCancelClick(Sender: TObject);
  private
    FController: TEditSongController;
  public
    procedure LoadSongFormats;
    procedure LoadArtists;
    procedure LoadAlbums;
    procedure SetSong(SongId: Variant);
  end;

implementation
uses
  Aurelius.Engine.ObjectManager,
  Artist, DBConnection, SongFormat,
  VideoFormat, EditSongFormat, EditArtist, EditAlbum,
  MediaFile;

{$R *.fmx}

procedure TfrmEditSong.btCancelClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmEditSong.btFileClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(Self);
  try
    OpenDlg.Options := [TOpenOption.ofFileMustExist];

    if OpenDlg.Execute then
      edFileLocation.Text := OpenDlg.FileName;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmEditSong.btNewAlbumClick(Sender: TObject);
var
  frmEditAlbum: TfrmEditAlbum;
begin
  frmEditAlbum := TfrmEditAlbum.Create(Self);
  try
    frmEditAlbum.ShowModal;

    if frmEditAlbum.ModalResult = mrOk then
    begin
      LoadAlbums;
      CbAlbum.ItemIndex := CbAlbum.Items.Count - 1;
    end;
  finally
    frmEditAlbum.Free;
  end;
end;

procedure TfrmEditSong.btNewArtistClick(Sender: TObject);
var
  frmEditArtist: TfrmEditArtist;
begin
  frmEditArtist := TfrmEditArtist.Create(Self);
  try
    frmEditArtist.ShowModal;

    if frmEditArtist.ModalResult = mrOk then
    begin
      LoadArtists;
      cbArtist.ItemIndex := cbArtist.Items.Count - 1;
    end;
  finally
    frmEditArtist.Free;
  end;
end;

procedure TfrmEditSong.btNewFormatClick(Sender: TObject);
var
  frmEditSongFormat: TfrmEditSongFormat;
begin
  frmEditSongFormat := TfrmEditSongFormat.Create(Self);
  try
    frmEditSongFormat.ShowModal;

    if frmEditSongFormat.ModalResult = mrOk then
    begin
      LoadSongFormats;
      cbFormat.ItemIndex := cbFormat.Items.Count - 1;
    end;
  finally
    frmEditSongFormat.Free;
  end;
end;

procedure TfrmEditSong.btSaveClick(Sender: TObject);
var
  Song: TSong;
  Album: TAlbum;
  Min, Sec: Word;
begin
  Song := FController.Song;

  Song.MediaName := edName.Text;
  Song.FileLocation := edFileLocation.Text;

  if cbFormat.ItemIndex >= 0 then
    Song.SongFormat := TSongFormat(cbFormat.Items.Objects[cbFormat.ItemIndex]);

  if cbArtist.ItemIndex >= 0 then
    Song.Artist := TArtist(cbArtist.Items.Objects[cbArtist.ItemIndex]);

  if CbAlbum.ItemIndex >= 0 then
  begin
    Album := TAlbum(CbAlbum.Items.Objects[CbAlbum.ItemIndex]);
    Song.Album := Album;
  end;

  if (edDurationMinutes.Text <> '') and (edDurationSeconds.Text <> '') then
  begin
    Min := StrToInt(edDurationMinutes.Text);
    Sec := StrToInt(edDurationSeconds.Text);
    Song.Duration := Min * 60 + Sec;
  end;

  FController.SaveSong(Song);

  ModalResult := mrOk;
end;

procedure TfrmEditSong.FormCreate(Sender: TObject);
begin
  FController := TEditSongController.Create;
  LoadSongFormats;
  LoadArtists;
  LoadAlbums;
end;

procedure TfrmEditSong.FormDestroy(Sender: TObject);
begin
  FController.Free;
end;

procedure TfrmEditSong.LoadAlbums;
var
  Albums: TList<TAlbum>;
  Al: TAlbum;
begin
  cbAlbum.Items.Clear;
  Albums := FController.GetAlbums;
  try
    for Al in Albums do
      CbAlbum.Items.AddObject(Al.AlbumName, Al);
  finally
    Albums.Free;
  end;
end;

procedure TfrmEditSong.LoadArtists;
var
  Artists: TList<TArtist>;
  A: TArtist;
begin
  cbArtist.Items.Clear;
  Artists := FController.GetArtists;
  try
    for A in Artists do
      cbArtist.Items.AddObject(A.ArtistName, A);
  finally
    Artists.Free;
  end;
end;

procedure TfrmEditSong.LoadSongFormats;
var
  SongFormats: TList<TSongFormat>;
  F: TSongFormat;
begin
  cbFormat.Items.Clear;
  SongFormats := FController.GetSongFormats;
  try
    for F in SongFormats do
      cbFormat.Items.AddObject(F.FormatName, F);
  finally
    SongFormats.Free;
  end;
end;

procedure TfrmEditSong.SetSong(SongId: Variant);
var
  Song: TSong;
begin
  FController.Load(SongId);
  Song := FController.Song;

  edName.Text := Song.MediaName;
  edFileLocation.Text := Song.FileLocation;

  cbFormat.ItemIndex := cbFormat.Items.IndexOfObject(Song.SongFormat);
  cbArtist.ItemIndex := cbArtist.Items.IndexOfObject(Song.Artist);
  CbAlbum.ItemIndex := CbAlbum.Items.IndexOfObject(Song.Album);

  if Song.Duration.HasValue then
  begin
    edDurationMinutes.Text := FormatFloat('#0', Song.Duration.Value div 60);
    edDurationSeconds.Text := FormatFloat('00', Song.Duration.Value mod 60);
  end;
end;

end.
