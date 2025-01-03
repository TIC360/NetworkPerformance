unit NPServer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Memo.Types, IdBaseComponent,
  IdComponent, IdCustomTCPServer, IdTCPServer, FMX.ScrollBox, FMX.Memo, IdContext, IdGlobal,
  System.Rtti, FMX.Grid.Style, FMX.Grid, System.Diagnostics;

type
  TFormServer = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    Image1: TImage;
    BtnStartServer: TButton;
    StringGridResults: TStringGrid;
    StringColumn1: TStringColumn;
    StringColumn2: TStringColumn;
    StringColumn3: TStringColumn;
    StringColumn4: TStringColumn;
    StringColumn5: TStringColumn;
    LabelEstatus: TLabel;
    procedure BtnStartServerClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    TCPServer: TIdTCPServer;
    ProcedureCount: Integer;
    procedure StartServer;
    procedure StopServer;
    procedure ServerExecute(AContext: TIdContext);
    procedure AddResultToGrid(Num: Integer; ClientIP: string;
      DataSize: Int64; Bandwidth: Double; Duration: Double);
  public
    { Public declarations }
  end;

var
  FormServer: TFormServer;

implementation

{$R *.fmx}

procedure TFormServer.FormCreate(Sender: TObject);
begin
  ProcedureCount := 0;

  // Configurar StringGrid
  StringGridResults.RowCount := 0; // Inicializa con una fila para encabezados
  StringGridResults.Columns[0].Header := 'N�';
  StringGridResults.Columns[1].Header := 'IP del Cliente';
  StringGridResults.Columns[2].Header := 'Datos (MB)';
  StringGridResults.Columns[3].Header := 'BW (Mbps)';
  StringGridResults.Columns[4].Header := 'Tiempo (Seg)';
end;

procedure TFormServer.BtnStartServerClick(Sender: TObject);
begin
  if TCPServer = nil then
    StartServer
  else
    StopServer;
end;

procedure TFormServer.StartServer;
begin
  TCPServer := TIdTCPServer.Create(nil);
  TCPServer.DefaultPort := 5201;
  TCPServer.OnExecute := ServerExecute;
  TCPServer.Active := True;
  LabelEstatus.Text := 'Servidor iniciado en el puerto 5201.';
  BtnStartServer.Text := 'Detener';
end;

procedure TFormServer.StopServer;
begin
  TCPServer.Active := False;
  FreeAndNil(TCPServer);
  LabelEstatus.Text := 'Servidor detenido.';
  BtnStartServer.Text := 'Iniciar';
end;

procedure TFormServer.ServerExecute(AContext: TIdContext);
var
  Buffer: TIdBytes;
  TotalBytes: Int64;
  BytesRead: Int64;
  Stopwatch: TStopwatch;
  FirstPacket: Boolean;
  Duration, Bandwidth: Double;
begin
  TotalBytes := 0;
  FirstPacket := True;
  Stopwatch := TStopwatch.Create;

  while AContext.Connection.Connected do
  begin
    try
      BytesRead := 0;
      AContext.Connection.IOHandler.ReadBytes(Buffer, -1, False);
      BytesRead := Length(Buffer);

      if BytesRead > 0 then
      begin
        // Inicia el temporizador despu�s del primer paquete recibido
        if FirstPacket then
        begin
          Stopwatch := TStopwatch.StartNew;
          FirstPacket := False;
        end;

        Inc(TotalBytes, BytesRead); // Sumar la cantidad de datos recibidos
      end;
    except
      Break; // Salir si ocurre un error
    end;
  end;

  // Detener el temporizador al finalizar
  if not FirstPacket then
    Stopwatch.Stop;

  Duration := Stopwatch.Elapsed.TotalSeconds; // Duraci�n en segundos
  if Duration > 0 then
    Bandwidth := (TotalBytes * 8) / (Duration * 1_000_000) // Calcular Mbps
  else
    Bandwidth := 0;

  // Actualizar StringGrid con los resultados
  TThread.Synchronize(nil, procedure
  begin
    Inc(ProcedureCount);
    AddResultToGrid(ProcedureCount, AContext.Binding.PeerIP,
      TotalBytes, Bandwidth, Duration);
  end);
end;


procedure TFormServer.AddResultToGrid(Num: Integer; ClientIP: string;
  DataSize: Int64; Bandwidth: Double; Duration: Double);
begin
  StringGridResults.RowCount := StringGridResults.RowCount + 1;
  StringGridResults.Cells[0, StringGridResults.RowCount - 1] := IntToStr(Num);
  StringGridResults.Cells[1, StringGridResults.RowCount - 1] := ClientIP;
  StringGridResults.Cells[2, StringGridResults.RowCount - 1] := FormatFloat('#,##0', DataSize / 1_000_000);
  StringGridResults.Cells[3, StringGridResults.RowCount - 1] := FormatFloat('#,##0', Bandwidth);
  StringGridResults.Cells[4, StringGridResults.RowCount - 1] := FormatFloat('0.00', Duration);
end;

end.
