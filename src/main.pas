unit main;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  ExtCtrls,
  DateUtils,
  Registry,
  Crypt;

type
  TLocStr = record
    Ident: AnsiString;
    Data:  AnsiString;
  end;
  TKeyEdit = class(TCustomEdit)
    constructor Create(AOwner: TComponent); override;
  private
    lNextControl: TWinControl;
    lPrevControl: TWinControl;
    procedure KEditChange(Sender: TObject);
    procedure KEditKeyPress(Sender: TObject; var Key: Char);
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  published
    property NextControl: TWinControl read lNextControl write lNextControl;
    property PrevControl: TWinControl read lPrevControl write lPrevControl;
  end;
  TMainForm = class(TForm)
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  private
    BF2142Key:     String;
    BF2142NSKey:   String;
    procedure edt1keyChange(Sender: TObject);
    procedure edt2keyChange(Sender: TObject);
    procedure btnApplyClick(Sender: TObject);
    procedure btnRandClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  public
    Image:      TImage;
    Group:      TPanel;
    btnApply:   TButton;
    btnRand:    TButton;
    btnClose:   TButton;
    edt1Key1p:  TKeyEdit;
    edt1Key2p:  TKeyEdit;
    edt1Key3p:  TKeyEdit;
    edt1Key4p:  TKeyEdit;
    edt1Key5p:  TKeyEdit;
    edt2Key1p:  TKeyEdit;
    edt2Key2p:  TKeyEdit;
    edt2Key3p:  TKeyEdit;
    edt2Key4p:  TKeyEdit;
    edt2Key5p:  TKeyEdit;
    lblTitle:   TLabel;
    lblTitleSh: TLabel;
    lblStatic1: TLabel;
    lblStatic2: TLabel;
    lblStatic3: TLabel;
    lblStatic4: TLabel;
    lblStatic5: TLabel;
    lbl1Key12:  TLabel;
    lbl1Key23:  TLabel;
    lbl1Key34:  TLabel;
    lbl1Key45:  TLabel;
    lbl2Key12:  TLabel;
    lbl2Key23:  TLabel;
    lbl2Key34:  TLabel;
    lbl2Key45:  TLabel;
    procedure SetTitle(Title: String);
    function GenKeys: Byte;
    function ChkKeys: Byte;
    function GetKeys: Byte;
    function SetKeys: Byte;
  end;

var
  IDL: array[0..127] of TLocStr;
  MainForm: TMainForm;

const
  c_identhash     = 'x9392';
  c_bfkeysize     = 20; {4 char x 5 parts}
  {c_app_name      = 'Battlefield 2 :: Key Manager';
  c_app_title     = '%s %s';
  c_app_ver       = 'v1.0';
  c_btn_apply     = 'Apply';
  c_btn_rand      = 'Random';
  c_btn_close     = 'Close';
  c_txt_title     = 'Battlefield 2 :: Key Manager';
  c_txt_desc      = 'Hello, i''ll provide you some features to enter'#13#10'your license CD-KEY or key that you bought in Origin/Steam store.'#13#10#13#10'If you don''t have a license key then press ''Random'','#13#10'this allow you playing on non-ranked servers.';
  c_txt_bf2142key    = 'Please enter your Battlefield 2 license key below';
  c_txt_bf2142nskey  = 'Please enter your Battlefield 2 Special Forces license key below';
  c_txt_bf2142unk    = 'The key state is unknown';
  c_txt_bf2142act    = 'This key is already active';
  c_txt_bf2142new    = 'You need to press ''Apply'' to actualize this key';
  c_txt_bf2142nope   = 'The key you have entered is invalid';}

procedure InitLocalization;

implementation

 { Simple MsgBox function }

function MsgBox(Text: string; Caption: string = ''; Buttons: integer = 0): integer;
begin
  if (Caption = '') then
  begin
    Caption := Application.Title;
  end;
  Result := MessageBox(Application.Handle, PAnsiChar(Text), PAnsiChar(Caption), Buttons);
end;

 { Localization }

function L_GET(Ident: String): String;
var
  i: Integer;
  id: String;
begin
  i := 0;
  Result := Ident;
  id := LowerCase(Ident);
  while (i < 128) do
  begin
    if (LowerCase(IDL[i].Ident) = id) then
    begin
      Result := IDL[i].Data;
    end;
    Inc(i);
  end;
end;

function L_SET(Ident, Data: String): Byte;
var
  i: Integer;
  id: String;
begin
  i := 0;
  Result := 0;
  id := LowerCase(Ident);
  while (i < 128) do
  begin
    if (IDL[i].Ident = '') or (LowerCase(IDL[i].Ident) = id) then
    begin
      IDL[i].Ident := id;
      IDL[i].Data  := Data;
      Exit;
    end;
    Inc(i);
  end;
  Result := 1;
end;

function GetLanguageID: Cardinal;
begin
  Result := GetUserDefaultLangID;
end;

function GetLanguageName: String;
var
  ID: LangID;
  Language: array [0..255] of Char;
begin
  ID := GetUserDefaultLangID;
  VerLanguageName(ID, Language, SizeOf(Language));
  Result:=String(Language);
end;

function GetResStr(LangID: Cardinal; StringIdx: Cardinal): String;
var
  UID: Cardinal;
  Buf: array [0..1024] of Char;
begin
  Result := '';
  try
    UID := ((LangID-1)*16) + StringIdx;
    LoadString(HInstance, UID, Buf, SizeOf(Buf));
    Result := String(Buf);
  except end;
end;

procedure LocalizationFromResource(ID: Cardinal);
begin
  if (FindResource(hInstance, Pointer(ID), RT_STRING) <> 0) then
  begin
    L_SET('app.name',      GetResStr(ID, 0));
    L_SET('app.title',     GetResStr(ID, 1));
    L_SET('app.ver',       GetResStr(ID, 2));
    L_SET('btn.apply',     GetResStr(ID, 3));
    L_SET('btn.rand',      GetResStr(ID, 4));
    L_SET('btn.close',     GetResStr(ID, 5));
    L_SET('txt.title',     GetResStr(ID, 6));
    L_SET('txt.desc',      GetResStr(ID, 7));
    L_SET('txt.bf2142key',    GetResStr(ID, 8));
    L_SET('txt.bf2142nskey',  GetResStr(ID, 9));
    L_SET('txt.bf2142unk',    GetResStr(ID, 10));
    L_SET('txt.bf2142act',    GetResStr(ID, 11));
    L_SET('txt.bf2142new',    GetResStr(ID, 12));
    L_SET('txt.bf2142inv',    GetResStr(ID, 13));
    L_SET('txt.bf2142nope',   GetResStr(ID, 14));
  end;
end;

procedure InitLocalization;
const
  ID = 1033;
begin
  // Default localization
  L_SET('app.name',      GetResStr(ID, 0));
  L_SET('app.title',     GetResStr(ID, 1));
  L_SET('app.ver',       GetResStr(ID, 2));
  L_SET('btn.apply',     GetResStr(ID, 3));
  L_SET('btn.rand',      GetResStr(ID, 4));
  L_SET('btn.close',     GetResStr(ID, 5));
  L_SET('txt.title',     GetResStr(ID, 6));
  L_SET('txt.desc',      GetResStr(ID, 7));
  L_SET('txt.bf2142key',    GetResStr(ID, 8));
  L_SET('txt.bf2142nskey',  GetResStr(ID, 9));
  L_SET('txt.bf2142unk',    GetResStr(ID, 10));
  L_SET('txt.bf2142act',    GetResStr(ID, 11));
  L_SET('txt.bf2142new',    GetResStr(ID, 12));
  L_SET('txt.bf2142inv',    GetResStr(ID, 13));
  L_SET('txt.bf2142nope',   GetResStr(ID, 14));
  // Get Localized strings from resources
  LocalizationFromResource( GetLanguageID );
end;

 { Registry Calls functions }

function GetRegistryData(RootKey: HKEY; Key, Value: string): variant;
var
  Reg: TRegistry;
  RegDataType: TRegDataType;
  DataSize, Len: integer;
  s: string;
  label cantread;
begin
  Reg := nil;
  try
    Reg := TRegistry.Create(KEY_QUERY_VALUE);
    Reg.RootKey := RootKey;
    if Reg.OpenKeyReadOnly(Key) then begin
      try
        RegDataType := Reg.GetDataType(Value);
        if (RegDataType = rdString) or
           (RegDataType = rdExpandString) then
          Result := Reg.ReadString(Value)
        else if RegDataType = rdInteger then
          Result := Reg.ReadInteger(Value)
        else if RegDataType = rdBinary then begin
          DataSize := Reg.GetDataSize(Value);
          if DataSize = -1 then goto cantread;
          SetLength(s, DataSize);
          Len := Reg.ReadBinaryData(Value, PChar(s)^, DataSize);
          if Len <> DataSize then goto cantread;
          Result := s;
        end else
      cantread:
        raise Exception.Create(SysErrorMessage(ERROR_CANTREAD));
      except
        s := ''; // Deallocates memory if allocated
        Reg.CloseKey;
        raise;
      end;
      Reg.CloseKey;
    end else
      raise Exception.Create(SysErrorMessage(GetLastError));
  except
    Reg.Free;
    raise;
  end;
  Reg.Free;
end;

procedure SetRegistryData(RootKey: HKEY; Key, Value: string;
  RegDataType: TRegDataType; Data: variant);
var
  Reg: TRegistry;
  s: string;
begin
  Reg := TRegistry.Create(KEY_WRITE);
  try
    Reg.RootKey := RootKey;
    if Reg.OpenKey(Key, True) then begin
      try
        if RegDataType = rdUnknown then
          RegDataType := Reg.GetDataType(Value);
        if RegDataType = rdString then
          Reg.WriteString(Value, Data)
        else if RegDataType = rdExpandString then
          Reg.WriteExpandString(Value, Data)
        else if RegDataType = rdInteger then
          Reg.WriteInteger(Value, Data)
        else if RegDataType = rdBinary then begin
          s := Data;
          Reg.WriteBinaryData(Value, PChar(s)^, Length(s));
        end else
          raise Exception.Create(SysErrorMessage(ERROR_CANTWRITE));
      except
        Reg.CloseKey;
        raise;
      end;
      Reg.CloseKey;
    end else
      raise Exception.Create(SysErrorMessage(GetLastError));
  finally
    Reg.Free;
  end;
end;

 { Better font antialising }
procedure SetFontSmoothing(AFont: TFont);
var
  tagLOGFONT: TLogFont;
begin
  GetObject(
    AFont.Handle,
    SizeOf(TLogFont),
    @tagLOGFONT);
  tagLOGFONT.lfQuality  := ANTIALIASED_QUALITY;
  AFont.Handle := CreateFontIndirect(tagLOGFONT);
end;

 { Key from Random + Timestamp }

function BuildRandomKey(Size: Integer = c_bfkeysize): String;
const
  Chars = '0123456789ABCDEFGHJKLMNPQRSTUVWXYZ';
var
  i, n: integer;
begin
  Randomize;
  Result := '';
  for i := 1 to Size do begin
    n := Random(Length(Chars)) + 1;
    Result := Result + Chars[n];
  end;
end;

function BuildPseudoRandomKey(Size: Integer = c_bfkeysize): String;
var
  Unix: Integer;
  Rand: Int64;
  Hash: String;
begin
  Randomize;
  Hash := '';
  while (Length(Hash) <= Size) do
  begin
    Unix := DateTimeToUnix(Date + Time);
    Rand := Random(Unix) + Unix;
    Hash := Hash + EncodeBase64(IntToStr(Rand) + EncodeBase64(IntToStr(Rand)));
    Hash := StringReplace(Hash, '+', '', [rfReplaceAll, rfIgnoreCase]);
    Hash := StringReplace(Hash, '-', '', [rfReplaceAll, rfIgnoreCase]);
    Hash := StringReplace(Hash, '/', '', [rfReplaceAll, rfIgnoreCase]);
    Hash := StringReplace(Hash, '=', '', [rfReplaceAll, rfIgnoreCase]);
  end;
  Result := Copy(Hash, 1, Size);
end;

 { Battlefield 2 Decryption }

function GetBF2142Key(RegKey: String = ''): String;
var
  s: String;
begin
  Result := '';
  if (RegKey = '') then
  begin
    RegKey := 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2\ergc';
  end;
  try
    s := GetRegistryData(HKEY_LOCAL_MACHINE, RegKey, '');
    s := StringReplace(s, c_identhash, '', [rfReplaceAll, rfIgnoreCase]);
    s := DecryptDataBF2142(s);
    Result := UpperCase(s);
  except
  end;
end;

function GetBF2142NSKey(RegKey: String = ''): String;
var
  s: String;
begin
  Result := '';
  if (RegKey = '') then
  begin
    RegKey := 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2 Special Forces\ergc';
  end;
  try
    s := GetRegistryData(HKEY_LOCAL_MACHINE, RegKey, '');
    s := StringReplace(s, c_identhash, '', [rfReplaceAll, rfIgnoreCase]);
    s := DecryptDataBF2142(s);
    Result := UpperCase(s);
  except
  end;
end;

 { Battlefield 2 Encryption }

function SetBF2142Key(RegKey: String = ''; Key: String = ''): Byte;
var
  Hash: String;
begin
  Result := 0;
  if (RegKey = '') then
  begin
    RegKey := 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2\ergc';
  end;
  if (Key = '') then
  begin
    Key := BuildRandomKey;
  end;
  try
    Hash := c_identhash + EncryptDataBF2142(Key);
    SetRegistryData(HKEY_LOCAL_MACHINE, RegKey, '', rdString, Hash);
  except
    Result := 1;
  end;
end;

function SetBF2142NSKey(RegKey: String = ''; Key: String = ''): Byte;
var
  Hash: String;
begin
  Result := 0;
  if (RegKey = '') then
  begin
    RegKey := 'SOFTWARE\Electronic Arts\EA Games\Battlefield 2 Special Forces\ergc';
  end;
  if (Key = '') then
  begin
    Key := BuildRandomKey;
  end;
  try
    Hash := c_identhash + EncryptDataBF2142(Key);
    SetRegistryData(HKEY_LOCAL_MACHINE, RegKey, '', rdString, Hash);
  except
    Result := 1;
  end;
end;

 { TKeyEdit Class }

constructor TKeyEdit.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Self.OnChange := KEditChange;
  Self.OnKeyPress := KEditKeyPress;
  Self.AutoSize := False;
  Self.CharCase := ecUpperCase;
  Self.Font.Name := 'Tahoma';
  Self.Font.Style := [fsBold];
  Self.Font.Color := clWindowText;
  Self.Font.Size := 10;
  Self.Height := 23;
  Self.MaxLength := 4;
  Self.NextControl := nil;
  Self.Width := 60;
end;

procedure TKeyEdit.CreateParams(var Params: TCreateParams);
const
  Alignments: array[TAlignment] of Longint = (ES_LEFT, ES_RIGHT, ES_CENTER);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style or ES_MULTILINE or ES_CENTER;
end;

procedure TKeyEdit.KEditChange(Sender: TObject);
begin
  if (Length(Self.Caption) >= Self.MaxLength) then
  begin
    Self.Color := $00f6fff4;
  end else
  begin
    Self.Color := $00f4f8ff;
  end;
end;

procedure TKeyEdit.KEditKeyPress(Sender: TObject; var Key: Char);
begin
  if not (Key in [#8, '0'..'9', 'A'..'z']) then
  begin
    //MsgBox('Key: 0x'+IntToHex(Ord(Key), 2));
    Key := #0;
    Exit;
  end else
  begin
    if (Key = #8) then
    begin
      if (Length(Self.Caption) <= 0) then
      begin
        if (PrevControl <> nil) then
        begin
          PrevControl.SetFocus;
          try
            TEdit(PrevControl).SelStart := Self.MaxLength;
          except end;
        end;
      end;
      Exit;
    end;
  end;
  if (Length(Self.Caption)+1 >= Self.MaxLength) then
  begin
    if (NextControl <> nil) then
    begin
      NextControl.SetFocus;
    end;
  end;
end;

 { MainForm Class }

constructor TMainForm.Create(AOwner: TComponent);
const
  ek1t = 160;
  ek2t = 250;
  ekdw = 17;
  eklw = 11;
  eklm = 5;
var
  i: Integer;
begin
  { Creating form }
  inherited CreateNew(nil, 0);
  SetTitle( Format(L_GET('app.title')+' � Tema567', [L_GET('app.name'), L_GET('app.ver')]) );
  Self.BorderStyle := bsDialog;
  Self.BorderIcons := [];
  Self.Position := poDesktopCenter;
  Self.DefaultMonitor := dmPrimary;
  Self.Width := 645;
  Self.Height := 391;
  { Fix incorrect language }
  if (GetLanguageID = 1049) then
  begin // Russian
    Self.Font.Charset := RUSSIAN_CHARSET;
  end;  // Another else ?
  { Creating image bar }
  Image := TImage.Create(Self);
  with Image do
  begin
    Parent := Self;
    Left := 11;
    Top := 11;
    Height := 335;
    Width := 219;
    try
      Canvas.Brush.Color := clWhite;
      Canvas.FillRect(Rect(11, 11, 335, 219));
      Picture.Bitmap.LoadFromResourceName(hInstance, 'BG');
    except end;
    Canvas.Brush.Color := clBlack;
    Canvas.FrameRect( Canvas.ClipRect );
  end;
  { Creating group bar }
  Group := TPanel.Create(Self);
  with Group do
  begin
    BevelInner := bvRaised;
    BevelOuter := bvLowered;
    Parent := Self;
    Left := 239;
    Top := 11;
    Height := 308;
    Width := 390;
  end;
  { Creating static text }
  lblTitleSh := TLabel.Create(Group);
  with lblTitleSh do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 1;
    Top := 11;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clGray;
    //Font.Name := 'Comic Sans MS';
    Font.Name := 'Segoe Print';
    Font.Size := 11;
    Font.Style := [fsBold];
    Transparent := True;
    Caption := L_GET('txt.title');
  end;
  lblTitle := TLabel.Create(Group);
  with lblTitle do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 10;
    Height := 23;
    Width := Parent.Width;
    Font.Color := $000202B9;
    //Font.Name := 'Comic Sans MS';
    Font.Name := 'Segoe Print';
    Font.Size := 11;
    Font.Style := [fsBold, fsUnderline];
    Transparent := True;
    Caption := L_GET('txt.title');
  end;
  lblStatic1 := TLabel.Create(Group);
  with lblStatic1 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 20;
    Top := 40;
    Height := 83;
    Width := Parent.Width-40;
    Font.Color := clGray;
    Font.Name  := 'Tahoma';
    Font.Style := [fsItalic];
    WordWrap := True;
    Transparent := True;
    Caption := L_GET('txt.desc');
  end;
  lblStatic2 := TLabel.Create(Group);
  with lblStatic2 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 138;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [fsBold];
    Transparent := True;
    Caption := L_GET('txt.bf2142key');
  end;
  lblStatic3 := TLabel.Create(Group);
  with lblStatic3 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 190;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    Transparent := True;
    Caption := L_GET('txt.bf2142stat');
  end;
  lblStatic4 := TLabel.Create(Group);
  with lblStatic4 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 228;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [fsBold];
    Transparent := True;
    Caption := L_GET('txt.bf2142nskey');
  end;
  lblStatic5 := TLabel.Create(Group);
  with lblStatic5 do
  begin
    Parent := Group;
    Alignment := taCenter;
    AutoSize := False;
    Left := 0;
    Top := 280;
    Height := 23;
    Width := Parent.Width;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    Transparent := True;
    Caption := L_GET('txt.bf2142unk');
  end;
  { Creating 'apply' button }
  btnApply := TButton.Create(Self);
  with btnApply do
  begin
    Parent := Self;
    Caption := L_GET('btn.apply');
    Left := 324;
    Top := 327;
    Height := 23;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    OnClick := btnApplyClick;
  end;
  { Creating 'random' button }
  btnRand := TButton.Create(Self);
  with btnRand do
  begin
    Parent := Self;
    Caption := L_GET('btn.rand');
    Left := 410;
    Top := 327;
    Height := 23;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    OnClick := btnRandClick;
  end;
  { Creating 'close' button }
  btnClose := TButton.Create(Self);
  with btnClose do
  begin
    Parent := Self;
    Caption := L_GET('btn.close');
    Left := 496;
    Top := 327;
    Height := 23;
    Font.Color := clWindowText;
    Font.Name  := 'Tahoma';
    Font.Style := [];
    OnClick := btnCloseClick;
  end;
  { Creating key fields }
  edt1Key1p := TKeyEdit.Create(Group);
  edt1Key1p.Parent := Group;
  edt1Key1p.Left := eklw;
  edt1Key1p.Top := ek1t;
  edt1Key1p.OnChange := edt1keyChange;
  edt1Key2p := TKeyEdit.Create(Group);
  edt1Key2p.Parent := Group;
  edt1Key2p.Left := edt1Key1p.Left+edt1Key1p.Width+ekdw;
  edt1Key2p.Top := ek1t;
  edt1Key2p.OnChange := edt1keyChange;
  edt1Key3p := TKeyEdit.Create(Group);
  edt1Key3p.Parent := Group;
  edt1Key3p.Left := edt1Key2p.Left+edt1Key2p.Width+ekdw;
  edt1Key3p.Top := ek1t;
  edt1Key3p.OnChange := edt1keyChange;
  edt1Key4p := TKeyEdit.Create(Group);
  edt1Key4p.Parent := Group;
  edt1Key4p.Left := edt1Key3p.Left+edt1Key3p.Width+ekdw;
  edt1Key4p.Top := ek1t;
  edt1Key4p.OnChange := edt1keyChange;
  edt1Key5p := TKeyEdit.Create(Group);
  edt1Key5p.Parent := Group;
  edt1Key5p.Left := edt1Key4p.Left+edt1Key4p.Width+ekdw;
  edt1Key5p.Top := ek1t;
  edt1Key5p.OnChange := edt1keyChange;
  edt2Key1p := TKeyEdit.Create(Group);
  edt2Key1p.Parent := Group;
  edt2Key1p.Left := eklw;
  edt2Key1p.Top := ek2t;
  edt2Key1p.OnChange := edt2keyChange;
  edt2Key2p := TKeyEdit.Create(Group);
  edt2Key2p.Parent := Group;
  edt2Key2p.Left := edt2Key1p.Left+edt2Key1p.Width+ekdw;
  edt2Key2p.Top := ek2t;
  edt2Key2p.OnChange := edt2keyChange;
  edt2Key3p := TKeyEdit.Create(Group);
  edt2Key3p.Parent := Group;
  edt2Key3p.Left := edt2Key2p.Left+edt2Key2p.Width+ekdw;
  edt2Key3p.Top := ek2t;
  edt2Key3p.OnChange := edt2keyChange;
  edt2Key4p := TKeyEdit.Create(Group);
  edt2Key4p.Parent := Group;
  edt2Key4p.Left := edt2Key3p.Left+edt2Key3p.Width+ekdw;;
  edt2Key4p.Top := ek2t;
  edt2Key4p.OnChange := edt2keyChange;
  edt2Key5p := TKeyEdit.Create(Group);
  edt2Key5p.Parent := Group;
  edt2Key5p.Left := edt2Key4p.Left+edt2Key4p.Width+ekdw;;
  edt2Key5p.Top := ek2t;
  edt2Key5p.OnChange := edt2keyChange;
  { Linking Next Edits }
  edt1Key1p.NextControl := edt1Key2p;
  edt1Key2p.NextControl := edt1Key3p;
  edt1Key3p.NextControl := edt1Key4p;
  edt1Key4p.NextControl := edt1Key5p;
  edt1Key5p.NextControl := edt2Key1p;
  edt2Key1p.NextControl := edt2Key2p;
  edt2Key2p.NextControl := edt2Key3p;
  edt2Key3p.NextControl := edt2Key4p;
  edt2Key4p.NextControl := edt2Key5p;
  { Linking Prev Edits }
  edt1Key2p.PrevControl := edt1Key1p;
  edt1Key3p.PrevControl := edt1Key2p;
  edt1Key4p.PrevControl := edt1Key3p;
  edt1Key5p.PrevControl := edt1Key4p;
  edt2Key2p.PrevControl := edt2Key1p;
  edt2Key3p.PrevControl := edt2Key2p;
  edt2Key4p.PrevControl := edt2Key3p;
  edt2Key5p.PrevControl := edt2Key4p;
  { Creating - caps }
  lbl1Key12 := TLabel.Create(Self);
  with lbl1Key12 do
  begin
    Parent := Group;
    Top := edt1Key1p.Top;
    Left := edt1Key1p.Left + edt1Key1p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl1Key23 := TLabel.Create(Self);
  with lbl1Key23 do
  begin
    Parent := Group;
    Top := edt1Key2p.Top;
    Left := edt1Key2p.Left + edt1Key2p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl1Key34 := TLabel.Create(Self);
  with lbl1Key34 do
  begin
    Parent := Group;
    Top := edt1Key3p.Top;
    Left := edt1Key3p.Left + edt1Key3p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl1Key45 := TLabel.Create(Self);
  with lbl1Key45 do
  begin
    Parent := Group;
    Top := edt1Key4p.Top;
    Left := edt1Key4p.Left + edt1Key4p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl2Key12 := TLabel.Create(Self);
  with lbl2Key12 do
  begin
    Parent := Group;
    Top := edt2Key1p.Top;
    Left := edt2Key1p.Left + edt2Key1p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl2Key23 := TLabel.Create(Self);
  with lbl2Key23 do
  begin
    Parent := Group;
    Top := edt2Key2p.Top;
    Left := edt2Key2p.Left + edt2Key2p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl2Key34 := TLabel.Create(Self);
  with lbl2Key34 do
  begin
    Parent := Group;
    Top := edt2Key3p.Top;
    Left := edt2Key3p.Left + edt2Key3p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  lbl2Key45 := TLabel.Create(Self);
  with lbl2Key45 do
  begin
    Parent := Group;
    Top := edt2Key4p.Top;
    Left := edt2Key4p.Left + edt2Key4p.Width + eklm;
    Font.Size := 12;
    Font.Style := [];
    Font.Name := 'Tahoma';
    Caption := '-';
  end;
  { Fix ugly fonts }
  {for i := 0 to ComponentCount-1 do
  begin
    if Components[i] is TLabel
    then SetFontSmoothing(TLabel(Components[i]).Font);
    if Components[i] is TButton
    then SetFontSmoothing(TButton(Components[i]).Font);
    if Components[i] is TKeyEdit
    then SetFontSmoothing(TKeyEdit(Components[i]).Font);
  end;}
  { Get Keys }
  GetKeys;
  { Check Keys }
  ChkKeys;
end;

procedure TMainForm.SetTitle(Title: String);
begin
  Application.Title := Title;
  Self.Caption := Title;
end;

function TMainForm.GenKeys: Byte;
var
  Key: String;
begin
  Result := 0;
  try
    Key := UpperCase(BuildRandomKey);
    edt1Key1p.Caption := Copy(Key, 1, 4);
    edt1Key2p.Caption := Copy(Key, 5, 4);
    edt1Key3p.Caption := Copy(Key, 9, 4);
    edt1Key4p.Caption := Copy(Key, 13, 4);
    edt1Key5p.Caption := Copy(Key, 17, 4);
  except
    Result := 1;
  end;
  // Get BF2142NS
  try
    Key := UpperCase(BuildRandomKey);
    edt2Key1p.Caption := Copy(Key, 1, 4);
    edt2Key2p.Caption := Copy(Key, 5, 4);
    edt2Key3p.Caption := Copy(Key, 9, 4);
    edt2Key4p.Caption := Copy(Key, 13, 4);
    edt2Key5p.Caption := Copy(Key, 17, 4);
  except
    Result := 2;
  end;
end;

function TMainForm.ChkKeys: Byte;
var
  ChKey: String;
begin
  Result := 0;
  try
    ChKey := '';
    ChKey := ChKey + edt1Key1p.Caption;
    ChKey := ChKey + edt1Key2p.Caption;
    ChKey := ChKey + edt1Key3p.Caption;
    ChKey := ChKey + edt1Key4p.Caption;
    ChKey := ChKey + edt1Key5p.Caption;
    if (Length(ChKey) = c_bfkeysize) then
    begin
      if (ChKey = Self.BF2142Key) then
      begin
        lblStatic3.Font.Color := clLime;
        lblStatic3.Caption := L_GET('txt.bf2142act');
      end else
      begin
        lblStatic3.Font.Color := clBlue;
        lblStatic3.Caption := L_GET('txt.bf2142new');
      end;
    end else
    begin
      if (Length(ChKey) < 1) then
      begin
        lblStatic3.Font.Color := clDkGray;
        lblStatic3.Caption := L_GET('txt.bf2142nope');
        Result := Result + 1;
      end else
      begin
        lblStatic3.Font.Color := clRed;
        lblStatic3.Caption := L_GET('txt.bf2142inv');
        Result := Result + 1;
      end;
    end;
  except
    Result := Result + 1;
  end;
  try
    ChKey := '';
    ChKey := ChKey + edt2Key1p.Caption;
    ChKey := ChKey + edt2Key2p.Caption;
    ChKey := ChKey + edt2Key3p.Caption;
    ChKey := ChKey + edt2Key4p.Caption;
    ChKey := ChKey + edt2Key5p.Caption;
    if (Length(ChKey) = c_bfkeysize) then
    begin
      if (ChKey = Self.BF2142NSKey) then
      begin
        lblStatic5.Font.Color := clLime;
        lblStatic5.Caption := L_GET('txt.bf2142act');
      end else
      begin
        lblStatic5.Font.Color := clBlue;
        lblStatic5.Caption := L_GET('txt.bf2142new');
      end;
    end else
    begin
      if (Length(ChKey) < 1) then
      begin
        lblStatic5.Font.Color := clDkGray;
        lblStatic5.Caption := L_GET('txt.bf2142nope');
        Result := Result + 2;
      end else
      begin
        lblStatic5.Font.Color := clRed;
        lblStatic5.Caption := L_GET('txt.bf2142inv');
        Result := Result + 2;
      end;
    end;
  except
    Result := Result + 2;
  end;
end;


function TMainForm.GetKeys: Byte;
var
  KeyBF2142, KeyBF2142NS: String;
begin
  Result := 0;
  // Get BF2142
  try
    KeyBF2142 := GetBF2142Key;
    if (Length(KeyBF2142) < c_bfkeysize) then
    begin
      Result := 1;
    end else
    begin
      SetLength(KeyBF2142, c_bfkeysize);
      Self.BF2142Key := KeyBF2142;
      edt1Key1p.Caption := Copy(KeyBF2142, 1, 4);
      edt1Key2p.Caption := Copy(KeyBF2142, 5, 4);
      edt1Key3p.Caption := Copy(KeyBF2142, 9, 4);
      edt1Key4p.Caption := Copy(KeyBF2142, 13, 4);
      edt1Key5p.Caption := Copy(KeyBF2142, 17, 4);
    end;
  except
    Result := 1;
  end;
  // Get BF2142NS
  try
    KeyBF2142NS := GetBF2142NSKey;
    if (Length(KeyBF2142NS) < c_bfkeysize) then
    begin
      Result := 2;
    end else
    begin
      SetLength(KeyBF2142NS, c_bfkeysize);
      Self.BF2142NSKey := KeyBF2142NS;
      edt2Key1p.Caption := Copy(KeyBF2142NS, 1, 4);
      edt2Key2p.Caption := Copy(KeyBF2142NS, 5, 4);
      edt2Key3p.Caption := Copy(KeyBF2142NS, 9, 4);
      edt2Key4p.Caption := Copy(KeyBF2142NS, 13, 4);
      edt2Key5p.Caption := Copy(KeyBF2142NS, 17, 4);
    end;
  except
    Result := 2;
  end;
end;

function TMainForm.SetKeys: Byte;
var
  KeyBF2142, KeyBF2142NS: String;
begin
  Result := 0;
  // Set BF2142
  KeyBF2142 := '';
  try
    KeyBF2142 := KeyBF2142 + edt1Key1p.Caption;
    KeyBF2142 := KeyBF2142 + edt1Key2p.Caption;
    KeyBF2142 := KeyBF2142 + edt1Key3p.Caption;
    KeyBF2142 := KeyBF2142 + edt1Key4p.Caption;
    KeyBF2142 := KeyBF2142 + edt1Key5p.Caption;
    if (Length(KeyBF2142) = c_bfkeysize) then
    begin
      if (SetBF2142Key('', KeyBF2142+#0) > 0)
      then Result := Result + 1
      else BF2142Key := KeyBF2142;
    end else
    begin
      Result := Result + 1;
    end;
  except
    Result := Result + 1;
  end;
  // Set BF2142NS
  KeyBF2142NS := '';
  try
    KeyBF2142NS := KeyBF2142NS + edt2Key1p.Caption;
    KeyBF2142NS := KeyBF2142NS + edt2Key2p.Caption;
    KeyBF2142NS := KeyBF2142NS + edt2Key3p.Caption;
    KeyBF2142NS := KeyBF2142NS + edt2Key4p.Caption;
    KeyBF2142NS := KeyBF2142NS + edt2Key5p.Caption;
    if (Length(KeyBF2142NS) = c_bfkeysize) then
    begin
      if (SetBF2142NSKey('', KeyBF2142NS+#0) > 0)
      then Result := Result + 2
      else BF2142NSKey := KeyBF2142NS;
    end else
    begin
      Result := Result + 2;
    end;
  except
    Result := Result + 2;
  end;
end;

procedure TMainForm.edt1keyChange(Sender: TObject);
begin
  { Check Keys }
  ChkKeys;
end;

procedure TMainForm.edt2keyChange(Sender: TObject);
begin
  { Check Keys }
  ChkKeys;
end;

procedure TMainForm.btnApplyClick(Sender: TObject);
begin
  { Set Keys }
  SetKeys;
  ChkKeys;
end;

procedure TMainForm.btnRandClick(Sender: TObject);
begin
  { Random Keys }
  GenKeys;
end;

procedure TMainForm.btnCloseClick(Sender: TObject);
begin
  { Terminate }
  Application.Terminate;
end;

destructor TMainForm.Destroy;
begin
  inherited Destroy;
end;

end.
