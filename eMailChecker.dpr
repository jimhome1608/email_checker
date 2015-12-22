program eMailChecker;

uses
  System.StartUpCopy,
  FMX.Forms,
  eMailChecker1 in 'eMailChecker1.pas' {frmEmailChecker};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmEmailChecker, frmEmailChecker);
  Application.Run;
end.
