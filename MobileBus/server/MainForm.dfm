object fmServer: TfmServer
  Left = 0
  Top = 0
  Caption = 'Hello Server'
  ClientHeight = 367
  ClientWidth = 448
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 24
    Top = 59
    Width = 94
    Height = 13
    Caption = 'Server Not Running'
  end
  object Button1: TButton
    Left = 200
    Top = 28
    Width = 75
    Height = 25
    Caption = 'Iniciar'
    TabOrder = 0
    OnClick = Button1Click
  end
  object Button2: TButton
    Left = 287
    Top = 28
    Width = 75
    Height = 25
    Caption = 'Parar'
    TabOrder = 1
    OnClick = Button2Click
  end
  object Memo1: TMemo
    Left = 8
    Top = 86
    Width = 432
    Height = 273
    Lines.Strings = (
      'Memo1')
    TabOrder = 3
  end
  object EdtServer: TEdit
    Left = 24
    Top = 30
    Width = 170
    Height = 21
    TabOrder = 2
  end
end
