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
  Datasnap.DBClient, System.IOUtils, FMX.ListBox, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, FMX.ListView,
  FMX.Objects ,MIDASLib // MIGHT NEED AFTER DELPHI 7 INSTALL.
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
    btnRefresh: TButton;
    ClientDataSet1: TClientDataSet;
    lbxData: TListView;
    imgGreenTick: TImage;
    imgDiana: TImage;
    imgCross: TImage;
    imgREA: TImage;
    imgDOMAIN: TImage;
    Rectangle1: TRectangle;
    Label1: TLabel;
    Layout2: TLayout;
    Rectangle3: TRectangle;
    lblLastCheck: TLabel;
    imgArrow: TImage;
    procedure btnRefreshClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure refresListView;
    procedure FormActivate(Sender: TObject);
  private
    onActivateDone: boolean;
    sl: TstringList;
    var data_file: string;
    LAST_MESSAGE_ID: integer;
    function write_client_dataset_lastfound(_filter: string; _lastfound: TdateTime; _MessageNumber: integer): string;
    function read_client_dataset(_filter, _FieldName: string): string;
    function read_hours_since_lastfound(_filter: string): double;
    function read_time_lastfound(_filter: string): string;
    function filter_dateset_on(_filter: string): integer;
  public
    { Public declarations }
  end;

var
  frmEmailChecker: TfrmEmailChecker;

const
  sThumbNailName = 'TI';
  sCaption = 'CA';

implementation

{$R *.fmx}

procedure TfrmEmailChecker.btnRefreshClick(Sender: TObject);
var _CheckMessages: integer;
    _MessageNumber: integer;
    _header: string;
    _partsIdx: integer;
    _partType:string;
    _rawMessage: string;
    _progress: double;
    _LItem: TListViewItem;
    _ListItemImage: TListItemImage;
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
   refresListView;
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


function TfrmEmailChecker.read_hours_since_lastfound(_filter: string): double;
var _LAST_FOUND: TDateTime;
    _Hours: double;
begin
     filter_dateset_on(_filter);
     _LAST_FOUND:=  ClientDataSet1.FieldByName('LAST_FOUND').AsDateTime;
     Result:= (now-_LAST_FOUND) *24;
end;

function TfrmEmailChecker.read_time_lastfound(_filter: string): string;
var _LAST_FOUND: TDateTime;
    _Hours: double;
     H, M, S, MS: Word;
begin
     filter_dateset_on(_filter);
     _LAST_FOUND:=  ClientDataSet1.FieldByName('LAST_FOUND').AsDateTime;
     _Hours:= (now-_LAST_FOUND) *24;
     if _Hours  < 12 then
        result:= formatDateTime('hh:nnam/pm',_LAST_FOUND)
     else
        result:= formatDateTime('dd/mm hh:nnam/pm',_LAST_FOUND);
end;

procedure TfrmEmailChecker.refresListView;
var _LItem: TListViewItem;
    _ListItemImage: TListItemImage;
    _Image: TImage;
    _HoursAgo_REA,_HoursAgo_DOMAIN,_HoursAgo_RVW, _HoursAgo_VERSION: double;
    H, M, S, MS: Word;
begin
    DecodeTime(Now, H, M, S, MS);

    _HoursAgo_VERSION:= read_hours_since_lastfound('VERSION');
    _HoursAgo_REA:= read_hours_since_lastfound('REA');
    _HoursAgo_DOMAIN:= read_hours_since_lastfound('DOMAIN');
    _HoursAgo_RVW:= read_hours_since_lastfound('RVW');

    lblLastCheck.Text:=   format('Last check: %f hour ago',[_HoursAgo_VERSION]);

    lbxData.Items.Clear;

   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text := 'REALESTATE  '+read_time_lastfound('REA');
   _LItem.BitmapRef := imgArrow.Bitmap;
   _ListItemImage:=  (_LItem.Objects.FindDrawable(sThumbNailName) as TListItemImage);
   if _ListItemImage <> Nil then begin
      _ListItemImage.OwnsBitmap := False;
      _ListItemImage.Bitmap := imgArrow.Bitmap;
   end;


   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text :=format('  %f hour ago',[_HoursAgo_REA]);
   _Image:=  imgGreenTick;
   if (_HoursAgo_REA - _HoursAgo_RVW) > 1   then begin
     _Image:=  imgCross; //imgGreenTick;
   end;
   if (_HoursAgo_REA > 24)   then begin
     _Image:=  imgCross; //imgGreenTick;
   end;
   if (_HoursAgo_REA > 4) and (H > 11) and ( H < 20)   then begin
     _Image:=  imgCross; //imgGreenTick;
   end;


   _LItem.BitmapRef := _Image.Bitmap;
   _ListItemImage:=  (_LItem.Objects.FindDrawable(sThumbNailName) as TListItemImage);
   if _ListItemImage <> Nil then begin
      _ListItemImage.OwnsBitmap := False;
      _ListItemImage.Bitmap := _Image.Bitmap;
   end;

   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text := 'DOMAIN  '+read_time_lastfound('DOMAIN');
   _LItem.BitmapRef := imgArrow.Bitmap;
   _ListItemImage:=  (_LItem.Objects.FindDrawable(sThumbNailName) as TListItemImage);
   if _ListItemImage <> Nil then begin
      _ListItemImage.OwnsBitmap := False;
      _ListItemImage.Bitmap := imgArrow.Bitmap;
   end;

   _Image:=  imgGreenTick;
   if (_HoursAgo_DOMAIN > 24)   then begin
     _Image:=  imgCross; //imgGreenTick;
   end;
   if (_HoursAgo_DOMAIN > 4) and (H > 11) and ( H < 20)   then begin
     _Image:=  imgCross; //imgGreenTick;
   end;
   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text := format('  %f hour ago',[_HoursAgo_DOMAIN]);
   _LItem.BitmapRef := _Image.Bitmap;
   _ListItemImage:=  (_LItem.Objects.FindDrawable(sThumbNailName) as TListItemImage);
   if _ListItemImage <> Nil then begin
      _ListItemImage.OwnsBitmap := False;
      _ListItemImage.Bitmap := _Image.Bitmap;
   end;

   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text := 'REALESTATEVIEW '+read_time_lastfound('RVW');
   _LItem.BitmapRef := imgArrow.Bitmap;
   _ListItemImage:=  (_LItem.Objects.FindDrawable(sThumbNailName) as TListItemImage);
   if _ListItemImage <> Nil then begin
      _ListItemImage.OwnsBitmap := False;
      _ListItemImage.Bitmap := imgArrow.Bitmap;
   end;

   _Image:=  imgGreenTick;
   if (_HoursAgo_RVW > 24)   then begin
     _Image:=  imgCross; //imgGreenTick;
   end;
   if (_HoursAgo_RVW > 4) and (H > 11) and ( H < 20)   then begin
     _Image:=  imgCross; //imgGreenTick;
   end;
   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text :=format('  %f hour ago',[_HoursAgo_RVW]);
   _LItem.BitmapRef := _Image.Bitmap;
   _ListItemImage:=  (_LItem.Objects.FindDrawable(sThumbNailName) as TListItemImage);
   if _ListItemImage <> Nil then begin
      _ListItemImage.OwnsBitmap := False;
      _ListItemImage.Bitmap := _Image.Bitmap;
   end;
   {$IFDEF ANDROID}
   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text :='______________________';

   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text := 'DIANA: '+read_time_lastfound('DIANA');
   _LItem.BitmapRef := imgDiana.Bitmap;
   _ListItemImage:=  (_LItem.Objects.FindDrawable(sThumbNailName) as TListItemImage);
   if _ListItemImage <> Nil then begin
      _ListItemImage.OwnsBitmap := False;
      _ListItemImage.Bitmap := imgDiana.Bitmap;
   end;

   _LItem := lbxData.Items.Add;
   _LItem.Objects.AccessoryObject.Visible := False;
   _LItem.Text :=format('%f hour ago',[read_hours_since_lastfound('DIANA')]);
   {$ENDIF}


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

procedure TfrmEmailChecker.FormActivate(Sender: TObject);
begin
    if onActivateDone then
      exit;
    onActivateDone:= True;

    MessageDlg('Refresh XML Last sent now?', System.UITypes.TMsgDlgType.mtInformation,
    [
      System.UITypes.TMsgDlgBtn.mbYes,
      System.UITypes.TMsgDlgBtn.mbNo
    ], 0,
    procedure(const AResult: System.UITypes.TModalResult)
    begin
      case AResult of
        mrYES:
          btnRefreshClick(Sender);
      end;
    end);
end;

procedure TfrmEmailChecker.FormCreate(Sender: TObject);

begin
  onActivateDone:= False;
  {$IFDEF ANDROID}
  lbxData.Scale.X:= 1;
  lbxData.Scale.Y:= 1;
  {$ENDIF}
  data_file := System.IOUtils.TPath.Combine(System.IOUtils.TPath.GetDocumentsPath, 'data_email_checker');
//  DELETEfILE(data_file);
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
   refresListView;

end;

procedure TfrmEmailChecker.FormDestroy(Sender: TObject);
begin
   sl.Free;
end;




end.

