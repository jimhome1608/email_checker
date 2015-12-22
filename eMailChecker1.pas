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
  Datasnap.DBClient, System.IOUtils, FMX.ListBox
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
    ClientDataSet1: TClientDataSet;
    lbxData: TListBox;
    lbxTop: TListBox;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
  private
    sl: TstringList;
    var data_file: string;
    LAST_MESSAGE_ID: integer;
    function write_client_dataset_lastfound(_filter: string; _lastfound: TdateTime; _MessageNumber: integer): string;
    function read_client_dataset(_filter, _FieldName: string): string;
    function read_hours_since_lastfound(_filter: string): string;
    function filter_dateset_on(_filter: string): integer;
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
    _progress: double;
begin
   write_client_dataset_lastfound('VERSION', Now, 0);
   IdPOP31.Connect;
   _CheckMessages:= IdPOP31.CheckMessages;
   if (_CheckMessages - LAST_MESSAGE_ID) > 1000 then begin
      LAST_MESSAGE_ID:= _CheckMessages - 1000;
   end;
   for _MessageNumber := LAST_MESSAGE_ID to _CheckMessages do begin
     IdPOP31.RetrieveHeader(_MessageNumber,IdMessage1);
     _header:= IdMessage1.Headers.Text;
     _header:= lowercase(_header);
     if pos('admin@ereal.com.au',_header) > 0 then begin
       write_client_dataset_lastfound('DIANA', IdMessage1.Date, _MessageNumber);
     end;
     if pos('log_websites@multilink.com.au',_header) > 0 then begin
       write_client_dataset_lastfound('REA', IdMessage1.Date, _MessageNumber);
     end;
     if pos('domain_emails@multilink.com.au',_header) > 0 then begin
       write_client_dataset_lastfound('DOMAIN', IdMessage1.Date, _MessageNumber);
     end;
     if pos('rca_emails@multilink.com.au',_header) > 0 then begin
       write_client_dataset_lastfound('RVW', IdMessage1.Date, _MessageNumber);
     end;
   end;
   IdPOP31.Disconnect;
   LAST_MESSAGE_ID:= _MessageNumber;
   filter_dateset_on('LAST_MESSAGE_ID');
   ClientDataSet1.Edit;
   ClientDataSet1.FieldByName('NUMBER').AsInteger:=  _MessageNumber;
   ClientDataSet1.Post;
   ClientDataSet1.SaveToFile(data_file);
   lbxTop.Items.clear;
   //lbxTop.Items.Add('Last ID: '+IntToStr(_MessageNumber));
   lbxTop.Items.Add(read_client_dataset('VERSION','LAST_FOUND'));
   lbxData.Items.Clear;
   lbxData.Items.Add('REA: '+read_client_dataset('REA','LAST_FOUND'));
   lbxData.Items.Add(read_hours_since_lastfound('REA'));
   lbxData.Items.Add('DOMAIN: '+read_client_dataset('DOMAIN','LAST_FOUND'));
   lbxData.Items.Add(read_hours_since_lastfound('DOMAIN'));
   lbxData.Items.Add('RVW: '+read_client_dataset('RVW','LAST_FOUND'));
   lbxData.Items.Add(read_hours_since_lastfound('RVW'));
   lbxData.Items.Add('DIANA: '+read_client_dataset('DIANA','LAST_FOUND'));
   lbxData.Items.Add(read_hours_since_lastfound('DIANA'));
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

function TfrmEmailChecker.read_client_dataset(_filter, _FieldName: string): string;
begin
    filter_dateset_on(_filter);
    result:=   ClientDataSet1.FieldByName(_FieldName).AsString;
end;


function TfrmEmailChecker.read_hours_since_lastfound(_filter: string): string;
var _LAST_FOUND: TDateTime;
    _Hours: double;
begin
     filter_dateset_on(_filter);
     _LAST_FOUND:=  ClientDataSet1.FieldByName('LAST_FOUND').AsDateTime;
     _Hours:= (now-_LAST_FOUND) *24;
     Result:= format('%f hour ago',[_Hours]);
end;

function TfrmEmailChecker.write_client_dataset_lastfound(_filter: string;
  _lastfound: TdateTime; _MessageNumber: integer): string;
begin
   filter_dateset_on(_filter);
   ClientDataSet1.Edit;
   ClientDataSet1.FieldByName('NUMBER').AsInteger:=  _MessageNumber;
   ClientDataSet1.FieldByName('LAST_FOUND').AsDateTime:=  _lastfound;
   ClientDataSet1.Post;
   ClientDataSet1.SaveToFile(data_file);
end;

function TfrmEmailChecker.filter_dateset_on(_filter: string): integer;
begin
   ClientDataSet1.IndexFieldNames := 'WHO';
   _filter:= UpperCase(_filter);
   ClientDataSet1.SetRange([_filter], [_filter]);
end;

procedure TfrmEmailChecker.FormCreate(Sender: TObject);

begin
  data_file := TPath.Combine(TPath.GetDocumentsPath, 'data_email_checker');
 //DELETEfILE(data_file);
  if NOT fileExists(data_file) then BEGIN;
      ClientDataSet1.FieldDefs.Add('WHO', ftString, 255);
      ClientDataSet1.FieldDefs.Add('WHEN', ftString, 255);
      ClientDataSet1.FieldDefs.Add('WHAT', ftString, 255);
      ClientDataSet1.FieldDefs.Add('TEXT', ftString, 255);
      ClientDataSet1.FieldDefs.Add('NUMBER', ftInteger);
      ClientDataSet1.FieldDefs.Add('LAST_CHECK', ftDatetime);
      ClientDataSet1.FieldDefs.Add('LAST_FOUND', ftDatetime);
      ClientDataSet1.CreateDataSet;
      ClientDataSet1.AppendRecord(['LAST_MESSAGE_ID', '', '', '',0]);
      ClientDataSet1.AppendRecord(['REA', '', '', '',0]);
      ClientDataSet1.AppendRecord(['DOMAIN', '', '', '',0]);
      ClientDataSet1.AppendRecord(['RVW', '', '', '',0]);
      ClientDataSet1.AppendRecord(['DIANA', '', '', '',0]);
      ClientDataSet1.AppendRecord(['BILL', '', '', '',0]);
      ClientDataSet1.AppendRecord(['VERSION', '', '', '',1]);
      ClientDataSet1.SaveToFile(data_file);
   end
   else
     ClientDataSet1.LoadFromFile(data_file);
   ClientDataSet1.Active := True;
   filter_dateset_on('LAST_MESSAGE_ID');
   LAST_MESSAGE_ID:= ClientDataSet1.FieldByName('NUMBER').AsInteger;
   lbxTop.Items.clear;
  // lbxTop.Items.Add('Last ID: '+IntToStr(LAST_MESSAGE_ID));
   lbxTop.Items.Add(read_client_dataset('VERSION','LAST_FOUND'));

   lbxData.Items.Add('REA: '+read_client_dataset('REA','LAST_FOUND'));
   lbxData.Items.Add(read_hours_since_lastfound('REA'));
   lbxData.Items.Add('DOMAIN: '+read_client_dataset('DOMAIN','LAST_FOUND'));
   lbxData.Items.Add(read_hours_since_lastfound('DOMAIN'));
   lbxData.Items.Add('RVW: '+read_client_dataset('RVW','LAST_FOUND'));
   lbxData.Items.Add(read_hours_since_lastfound('RVW'));
   lbxData.Items.Add('DIANA: '+read_client_dataset('DIANA','LAST_FOUND'));
   lbxData.Items.Add(read_hours_since_lastfound('DIANA'));
   //lbxData.Items.Add(data_file);


//    Edit1.Text:= intToSTr( ClientDataSet1.RecordCount);   sl:= TstringList.Create;
   //ClientDataSet1.Edit;
  // ClientDataSet1.FieldByName('NUMBER').AsInteger:=  ClientDataSet1.FieldByName('NUMBER').AsInteger+1;
   //ClientDataSet1.Post;
  // ClientDataSet1.SaveToFile(data_file);
end;

procedure TfrmEmailChecker.FormDestroy(Sender: TObject);
begin
   sl.Free;
end;




end.

