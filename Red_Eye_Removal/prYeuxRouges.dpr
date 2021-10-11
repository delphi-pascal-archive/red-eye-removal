program prYeuxRouges;

uses
  Forms,
  uYeuxRouges in 'uYeuxRouges.pas' {Form1},
  uManipBMP in 'uManipBMP.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.
