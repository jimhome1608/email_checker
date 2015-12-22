unit eMailChecker1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdMessageClient, IdPOP3,
  FMX.Controls.Presentation, FMX.StdCtrls, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdIMAP4, FMX.Edit, FMX.ScrollBox,
  FMX.Memo, IdMessage, FMX.Layouts, IdText, FMX.TabControl, Data.DB,
  Datasnap.DBClient, System.IOUtils
  {$IFDEF ANDROID}
    ,Androidapi.JNI.Os,
    Androidapi.JNI.GraphicsContentViewText,
    Androidapi.Helpers,
    Androidapi.JNIBridge
  {$ENDIF};

type
  TfrmEmailChecker = class(TForm)
    IdPOP31: TIdPOP3;
    IdMessage1: TIdMessage;
    ToolBar1: TToolBar;
    Layout1: TLayout;
    Button1: TButton;
    Layout2: TLayout;
    lblMessageCount: TLabel;
    lblReadingMessageNumber: TLabel;
    tlcDiana: TTabControl;
    tiSummary: TTabItem;
    TabItem2: TTabItem;
    Memo1: TMemo;
    tiData: TTabItem;
    Edit1: TEdit;
    ClientDataSet1: TClientDataSet;
    Button2: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    sl: TstringList;
  public
    { Public declarations }
  end;

var
  frmEmailChecker: TfrmEmailChecker;

implementation

{$R *.fmx}

procedure TfrmEmailChecker.Button1Click(Sender: TObject);
var _CheckMessages: integer;
    _MessageNumber: integer;
    _header: string;
    _partsIdx: integer;
    _partType:string;
    _rawMessage: string;
     //admin@ereal.com.au
begin
   IdPOP31.Connect;
   _CheckMessages:= IdPOP31.CheckMessages;
   lblMessageCount.Text := 'Message Count: '+ IntTOSTr(_CheckMessages);
   for _MessageNumber := _CheckMessages downto _CheckMessages-1000 do begin
     lblReadingMessageNumber.Text:= IntTOSTr(_MessageNumber);
     IdPOP31.RetrieveHeader(_MessageNumber,IdMessage1);
     _header:= IdMessage1.Headers.Text;
     _header:= lowercase(_header);
     if pos('admin@ereal.com.au',_header) > 0 then begin
       //memo1.Lines.Add(_header);
      // IdPOP31.Retrieve(_MessageNumber,IdMessage1);
       IdPOP31.Top(_MessageNumber,sl,100);
//       IdPOP31.RetrieveRaw(_MessageNumber,sl);
       _rawMessage:= sl.Text;
       memo1.Lines.Add(_rawMessage);
       break;
     end;
   end;
  // IdPOP31.RetrieveRaw(_CheckMessages,sl);
   IdPOP31.Disconnect;

end;





procedure TfrmEmailChecker.Button2Click(Sender: TObject);
{$IFDEF ANDROID}
Var Vibrator: JVibrator;
{$ENDIF}
begin
    {$IFDEF ANDROID}
    Vibrator:=TJVibrator.Wrap((SharedActivityContext.getSystemService(TJContext.JavaClass.VIBRATOR_SERVICE) as ILocalObject).GetObjectID);
    Vibrator.vibrate(500);
    {$ENDIF}
end;

procedure TfrmEmailChecker.FormCreate(Sender: TObject);
var data_file: string;
begin
  data_file := TPath.Combine(TPath.GetDocumentsPath, 'data_email_checker');
  if fileExists(data_file) then
    ClientDataSet1.LoadFromFile(data_file)
   else begin
      ClientDataSet1.FieldDefs.Add('FirstName', ftString, 20);
      ClientDataSet1.FieldDefs.Add('LastName', ftString, 20);
      ClientDataSet1.CreateDataSet;
   end;
   ClientDataSet1.Active := True;
   ClientDataSet1.AppendRecord(['John', 'Smith']);
   ClientDataSet1.AppendRecord(['Jane', 'Doe']);
   ClientDataSet1.SaveToFile(data_file);
   Edit1.Text:= intToSTr( ClientDataSet1.RecordCount);   sl:= TstringList.Create;
end;

procedure TfrmEmailChecker.FormDestroy(Sender: TObject);
begin
   sl.Free;
end;

end.
