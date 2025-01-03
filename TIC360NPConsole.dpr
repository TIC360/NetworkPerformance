program TIC360NPConsole;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils, IdTCPServer, IdContext, IdGlobal, System.Diagnostics, System.SyncObjs, IdStack;

type
  TServer = class
  private
    TCPServer: TIdTCPServer;
    ProcedureCount: Integer;
    ConsoleLock: TCriticalSection; // Sincronización del acceso a la consola
    procedure ServerExecute(AContext: TIdContext);
    procedure AddResultToConsole(Num: Integer; ClientIP: string; DataSize: Int64; Bandwidth: Double; Duration: Double);
  public
    constructor Create;
    destructor Destroy; override;
    procedure StartServer;
    function GetLocalIPAddress: string;
  end;

{ TServer }

constructor TServer.Create;
begin
  inherited Create;
  ConsoleLock := TCriticalSection.Create;
end;

destructor TServer.Destroy;
begin
  ConsoleLock.Free;
  inherited Destroy;
end;

procedure TServer.AddResultToConsole(Num: Integer; ClientIP: string; DataSize: Int64; Bandwidth: Double; Duration: Double);
begin
  ConsoleLock.Acquire; // Bloquear el acceso a la consola
  try
    Writeln(Format('N°: %d | IP: %s | Datos: %.2f MB | BW: %.2f Mbps | Tiempo: %.2f seg',
      [Num, ClientIP, DataSize / 1_000_000, Bandwidth, Duration]));
  finally
    ConsoleLock.Release; // Liberar el bloqueo
  end;
end;

procedure TServer.ServerExecute(AContext: TIdContext);
var
  Buffer, TempBuffer: TIdBytes;
  TotalBytes, ExpectedBytes, BytesRead: Int64;
  Stopwatch: TStopwatch;
  Duration, Bandwidth: Double;
begin
  TotalBytes := 0;
  Stopwatch := TStopwatch.StartNew; // Siempre inicia el temporizador antes de procesar los datos

  try
    // Leer la longitud esperada del paquete como encabezado
    ExpectedBytes := AContext.Connection.IOHandler.ReadLn.ToInt64;
    SetLength(Buffer, 0); // Inicializa el buffer principal

    // Leer los datos completos
    while TotalBytes < ExpectedBytes do
    begin
      SetLength(TempBuffer, ExpectedBytes - TotalBytes);
      AContext.Connection.IOHandler.ReadBytes(TempBuffer, Length(TempBuffer), False);
      BytesRead := Length(TempBuffer);

      if BytesRead > 0 then
      begin
        Buffer := Buffer + TempBuffer; // Acumula los datos en el buffer principal
        Inc(TotalBytes, BytesRead);   // Incrementa los bytes totales leídos
      end
      else
        Break; // Salir si no se leen más datos
    end;

    // Detener el temporizador después de completar la recepción
    Stopwatch.Stop;

    Duration := Stopwatch.Elapsed.TotalSeconds; // Duración en segundos
    if Duration = 0 then
      Duration := Stopwatch.Elapsed.TotalMilliseconds / 1000; // Usar milisegundos si es demasiado pequeño

    if Duration > 0 then
      Bandwidth := (TotalBytes * 8) / (Duration * 1_000_000) // Calcular Mbps
    else
      Bandwidth := 0;

    // Mostrar resultados en la consola
    Inc(ProcedureCount);
    AddResultToConsole(ProcedureCount, AContext.Binding.PeerIP, TotalBytes, Bandwidth, Duration);

  except
    on E: Exception do
    begin
      ConsoleLock.Acquire;
      try
        Writeln('Error al procesar los datos: ' + E.Message);
      finally
        ConsoleLock.Release;
      end;
    end;
  end;
end;

function TServer.GetLocalIPAddress: string;
begin
  try
    TIdStack.IncUsage; // Asegurar que GStack esté inicializado
    Result := GStack.LocalAddress; // Obtener la dirección IP local
  finally
    TIdStack.DecUsage; // Liberar el uso de GStack
  end;
end;

procedure TServer.StartServer;
var
  LocalIP: string;
begin
  try
    LocalIP := GetLocalIPAddress; // Obtener la IP del servidor
    Writeln('TIC360 Network Performance Monitor');
    Writeln(Format('Dirección IP del servidor: %s', [LocalIP]));
    Writeln('Iniciando servidor en el puerto 5201...');
    TCPServer := TIdTCPServer.Create(nil);
    try
      TCPServer.DefaultPort := 5201;
      TCPServer.OnExecute := ServerExecute;
      TCPServer.Active := True;
      Writeln('Servidor iniciado. Presiona Ctrl+C para detener.');
      Readln; // Mantener el programa corriendo
    finally
      TCPServer.Active := False;
      FreeAndNil(TCPServer);
      Writeln('Servidor detenido.');
    end;
  except
    on E: Exception do
      Writeln('Error al iniciar el servidor: ' + E.Message);
  end;
end;

{ Programa Principal }
var
  Server: TServer;

begin
  try
    Server := TServer.Create;
    try
      Server.StartServer;
    finally
      Server.Free;
    end;
  except
    on E: Exception do
      Writeln('Error: ' + E.ClassName + ' - ' + E.Message);
  end;
end.

