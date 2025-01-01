program TIC360NPServer;

uses
  System.StartUpCopy,
  FMX.Forms,
  NPServer in 'NPServer.pas' {FormServer};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormServer, FormServer);
  Application.Run;
end.
