object DataModule1: TDataModule1
  OldCreateOrder = False
  Height = 338
  Width = 540
  object empCon: TADOConnection
    Connected = True
    ConnectionString = 
      'Provider=SQLNCLI11.1;Integrated Security=SSPI;Persist Security I' +
      'nfo=False;User ID="";Initial Catalog=DelphiTestDb;Data Source=""' +
      ';Initial File Name="";Server SPN=""'
    LoginPrompt = False
    Provider = 'SQLNCLI11.1'
    Left = 32
    Top = 40
  end
  object empDs: TADODataSet
    Connection = empCon
    Parameters = <>
    Left = 104
    Top = 40
  end
  object empQr: TADOQuery
    Connection = empCon
    Parameters = <>
    Left = 104
    Top = 104
  end
end
