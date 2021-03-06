unit EditConfig;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  FMX.Controls.Presentation, FMX.StdCtrls, FMX.ListBox, FMX.Edit,
  Configs, DBConnection, Aurelius.Engine.ObjectManager,
  Aurelius.Criteria.Linq, Aurelius.Criteria.Projections, Generics.Collections;

type
  TEditConfigForm = class(TForm)
    ToolBar1: TToolBar;
    btnSair: TSpeedButton;
    lbServerURL: TLabel;
    edtServerURL: TEdit;
    BtnConfirmar: TButton;
    procedure FormCreate(Sender: TObject);
    procedure btnSairClick(Sender: TObject);
    procedure BtnConfirmarClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  EditConfigForm: TEditConfigForm;

implementation

uses
  Main, Utils;

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}

procedure TEditConfigForm.BtnConfirmarClick(Sender: TObject);
begin
  IPServer := edtServerURL.Text;
  TDBConnection.GetInstance.UnloadConnection;
//  TDBConnection.GetInstance.CreateConnection;
  if TDBConnection.GetInstance.Connection.IsConnected then
    MainForm.CarregarParadasMapa;
  Close;
end;

procedure TEditConfigForm.btnSairClick(Sender: TObject);
begin
  Close;
end;

procedure TEditConfigForm.FormCreate(Sender: TObject);
begin
  edtServerURL.Text := IPServer;
end;

end.
