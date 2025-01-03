program TIC360NPClient;

uses
  System.StartUpCopy,
  FMX.Forms,
  NPClient in 'NPClient.pas' {FormClient};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormClient, FormClient);
  Application.Run;
end.
