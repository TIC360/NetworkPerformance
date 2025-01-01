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
{$R *.Macintosh.fmx MACOS}
{$R *.Surface.fmx MSWINDOWS}
{$R *.iPhone55in.fmx IOS}
{$R *.LgXhdpiTb.fmx ANDROID}
{$R *.Windows.fmx MSWINDOWS}

procedure TFormClient.FormCreate(Sender: TObject);
begin
  ProcedureCount := 0;
  // Configurar StringGrid
  StringGridResults.RowCount := 0; // Inicializa con una fila para encabezados
  StringGridResults.Columns[0].Header := 'N�';
  StringGridResults.Columns[1].Header := 'Datos (MB)';
  StringGridResults.Columns[2].Header := 'BW (Mbps)';
  StringGridResults.Columns[3].Header := 'Tiempo (Seg)';
end;

procedure TFormClient.BtnRunTestClick(Sender: TObject);
var
  ServerIP: string;
  DataSizeMB, LoopCount, i: Integer;
begin
  ServerIP := EditServerIP.Text;
  DataSizeMB := StrToInt(EditDataSize.Text);
  LoopCount := StrToIntDef(EditLoop.Text, 1); // Obtener el n�mero de repeticiones (predeterminado: 1)

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

    TCPClient.Connect;

    // Crear un buffer de 1 MB
    BufferSize := 1024 * 1024; // 1 MB
    SetLength(DataToSend, BufferSize);
    FillChar(DataToSend[0], BufferSize, 0); // Rellenar con ceros

    TotalBytes := 0;
    Stopwatch := TStopwatch.StartNew;

    // Enviar datos en bloques hasta alcanzar el tama�o especificado
    while TotalBytes < DataSizeMB * BufferSize do
    begin
      TCPClient.IOHandler.Write(DataToSend, Length(DataToSend)); // Enviar buffer
      Inc(TotalBytes, Length(DataToSend)); // Acumular bytes enviados
    end;

    Stopwatch.Stop;

    // Calcular duraci�n y ancho de banda
    Duration := Stopwatch.Elapsed.TotalSeconds; // Duraci�n en segundos
    if Duration > 0 then
      Bandwidth := (TotalBytes * 8) / (Duration * 1_000_000) // Calcular Mbps
    else
      Bandwidth := 0;

    // Mostrar estad�sticas en el StringGrid
    Inc(ProcedureCount);
    AddResultToGrid(ProcedureCount, TotalBytes, Bandwidth, Duration);
  finally
    TCPClient.Disconnect;
    TCPClient.Free;
  end;
end;

procedure TFormClient.AddResultToGrid(Num: Integer; DataSize: Int64; Bandwidth: Double; Duration: Double);
begin
  StringGridResults.RowCount := StringGridResults.RowCount + 1;
  StringGridResults.Cells[0, StringGridResults.RowCount - 1] := IntToStr(Num);
  StringGridResults.Cells[1, StringGridResults.RowCount - 1] := FormatFloat('#,##0', DataSize / 1_048_576);
  StringGridResults.Cells[2, StringGridResults.RowCount - 1] := FormatFloat('#,##0', Bandwidth);
  StringGridResults.Cells[3, StringGridResults.RowCount - 1] := FormatFloat('0.00', Duration);
end;

end.
