unit NPClient;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Objects, IdTCPClient, FMX.Edit, IdGlobal,
  System.Diagnostics, FMX.Grid.Style, FMX.Grid, System.Rtti, FMX.ScrollBox;

type
  TFormClient = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    Image1: TImage;
    Label1: TLabel;
    Label2: TLabel;
    EditServerIP: TEdit;
    EditDataSize: TEdit;
    BtnRunTest: TButton;
    Panel1: TPanel;
    StringGridResults: TStringGrid;
    StringColumn1: TStringColumn;
    StringColumn2: TStringColumn;
    StringColumn3: TStringColumn;
    StringColumn4: TStringColumn;
    EditLoop: TEdit;
    Label3: TLabel; // Nuevo campo para el n�mero de repeticiones
    procedure BtnRunTestClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
    ProcedureCount: Integer;
    procedure RunClient(ServerIP: string; DataSizeMB: Integer);
    procedure AddResultToGrid(Num: Integer; DataSize: Int64; Bandwidth: Double; Duration: Double);
  public
    { Public declarations }
  end;

var
  FormClient: TFormClient;

implementation

{$R *.fmx}

procedure TFormClient.FormCreate(Sender: TObject);
begin
  ProcedureCount := 0;
  // Configurar StringGrid
  StringGridResults.RowCount := 0; // Inicializa con una fila para encabezados
  StringGridResults.Columns[0].Header := 'N�';
  StringGridResults.Columns[1].Header := 'Datos (Mb)';
  StringGridResults.Columns[2].Header := 'BW (Mbps)';
  StringGridResults.Columns[3].Header := 'Tiempo (Seg)';
end;

procedure TFormClient.BtnRunTestClick(Sender: TObject);
var
  ServerIP: string;
  DataSizeMB, LoopCount, i: Integer;
begin
  // Validar entradas
  if not TryStrToInt(EditDataSize.Text, DataSizeMB) then
  begin
    ShowMessage('El tama�o de datos debe ser un n�mero v�lido.');
    Exit;
  end;

  if not TryStrToInt(EditLoop.Text, LoopCount) then
  begin
    ShowMessage('El n�mero de repeticiones debe ser un n�mero v�lido.');
    Exit;
  end;

  ServerIP := EditServerIP.Text;

  for i := 1 to LoopCount do
  begin
    RunClient(ServerIP, DataSizeMB); // Ejecutar la prueba de env�o
  end;
end;

procedure TFormClient.RunClient(ServerIP: string; DataSizeMB: Integer);
var
  TCPClient: TIdTCPClient;
  DataToSend: TIdBytes; // Buffer de datos
  Stopwatch: TStopwatch;
  TotalBytes: Int64;
  BufferSize: Integer;
  Duration, Bandwidth: Double;
begin
  TCPClient := TIdTCPClient.Create(nil);
  try
    TCPClient.Host := ServerIP;
    TCPClient.Port := 5201;

    try
      TCPClient.Connect;
    except
      on E: Exception do
      begin
        ShowMessage('Error al conectar con el servidor: ' + E.Message);
        Exit;
      end;
    end;

    // Crear un buffer de 1 MB
    BufferSize := 1000 * 1000; // 1 MB (decimal est�ndar)
    SetLength(DataToSend, BufferSize);
    FillChar(DataToSend[0], BufferSize, 0); // Rellenar con ceros

    TotalBytes := DataSizeMB * BufferSize;

    // **Enviar el tama�o total del paquete primero**
    TCPClient.IOHandler.WriteLn(IntToStr(TotalBytes)); // Enviar tama�o total al servidor

    Stopwatch := TStopwatch.StartNew;

    // Enviar datos en bloques hasta alcanzar el tama�o especificado
    while TotalBytes > 0 do
    begin
      // Asegurarse de no enviar m�s datos de los que restan
      if TotalBytes >= BufferSize then
      begin
        TCPClient.IOHandler.Write(DataToSend, BufferSize); // Enviar bloque completo
        Dec(TotalBytes, BufferSize);
      end
      else
      begin
        SetLength(DataToSend, TotalBytes); // Ajustar el �ltimo bloque
        TCPClient.IOHandler.Write(DataToSend, TotalBytes);
        TotalBytes := 0;
      end;
    end;

    Stopwatch.Stop;

    // Calcular duraci�n y ancho de banda
    Duration := Stopwatch.Elapsed.TotalSeconds; // Duraci�n en segundos
    if Duration > 0 then
      Bandwidth := (DataSizeMB * 8) / Duration // Calcular Mbps
    else
      Bandwidth := 0;

    // Mostrar estad�sticas en el StringGrid
    Inc(ProcedureCount);
    AddResultToGrid(ProcedureCount, DataSizeMB * BufferSize, Bandwidth, Duration);
  finally
    TCPClient.Disconnect;
    TCPClient.Free;
  end;
end;


procedure TFormClient.AddResultToGrid(Num: Integer; DataSize: Int64; Bandwidth: Double; Duration: Double);
begin
  StringGridResults.RowCount := StringGridResults.RowCount + 1;
  StringGridResults.Cells[0, StringGridResults.RowCount - 1] := IntToStr(Num);
  StringGridResults.Cells[1, StringGridResults.RowCount - 1] := FormatFloat('#,##0', DataSize / 1_000_000);
  StringGridResults.Cells[2, StringGridResults.RowCount - 1] := FormatFloat('#,##0.00', Bandwidth);
  StringGridResults.Cells[3, StringGridResults.RowCount - 1] := FormatFloat('0.00', Duration);
end;

end.

