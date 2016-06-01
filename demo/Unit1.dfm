object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Demo -- Delphi wrapper for V8 JavaScript Engine'
  ClientHeight = 371
  ClientWidth = 653
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Memo1: TMemo
    Left = 0
    Top = 0
    Width = 653
    Height = 330
    Align = alClient
    ImeName = #20013#25991'('#31616#20307') - '#24517#24212' Bing '#36755#20837#27861
    Lines.Strings = (
      'alert('#39'1+2='#39' + (1+2))'
      
        'alert2({text:'#39'1+2='#39' + hostexe.add(1,2.3), caption:'#39'add 2 numbers' +
        #39'})'
      'raiseException()'
      'console.log('#39'console log message'#39')'
      'hostexe.httpEncode('#39'/~!f234'#39')')
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 330
    Width = 653
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    object SpeedButton1: TSpeedButton
      Left = 592
      Top = 0
      Width = 61
      Height = 41
      Align = alRight
      Caption = 'exec'
      OnClick = SpeedButton1Click
    end
    object Memo2: TMemo
      Left = 0
      Top = 0
      Width = 592
      Height = 41
      Align = alClient
      ImeName = #20013#25991'('#31616#20307') - '#24517#24212' Bing '#36755#20837#27861
      Lines.Strings = (
        'Memo2')
      ScrollBars = ssVertical
      TabOrder = 0
    end
  end
end
