unit eMailChecker1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs,
  IdBaseComponent, IdComponent, IdTCPConnection, IdTCPClient,
  IdExplicitTLSClientServerBase, IdMessageClient, IdPOP3,
  FMX.Controls.Presentation, FMX.StdCtrls, IdIOHandler, IdIOHandlerSocket,
  IdIOHandlerStack, IdSSL, IdSSLOpenSSL, IdIMAP4, FMX.Edit, FMX.ScrollBox,
  FMX.Memo, IdMessage, FMX.Layouts;

type
  TfrmEmailChecker = class(TForm)
    IdPOP31: TIdPOP3;
    Memo1: TMemo;
    IdMessage1: TIdMessage;
    ToolBar1: TToolBar;
    Layout1: TLayout;
    Button1: TButton;
    Layout2: TLayout;
    lblMessageCount: TLabel;
    lblReadingMessageNumber: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
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
       memo1.Lines.Add(_header);
       Break;
     end;
   end;
  // IdPOP31.RetrieveRaw(_CheckMessages,sl);
   IdPOP31.Disconnect;

end;

procedure TfrmEmailChecker.FormCreate(Sender: TObject);
begin
   sl:= TstringList.Create;
end;

procedure TfrmEmailChecker.FormDestroy(Sender: TObject);
begin
   sl.Free;
end;

end.
