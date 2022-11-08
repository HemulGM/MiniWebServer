unit HTTP.Server;

interface

uses
  System.Classes, System.SysUtils, System.Threading, IdContext, System.Rtti,
  IdCustomHTTPServer, IdHTTPServer, IdSSLOpenSSL, System.IOUtils, HTTP.HTMLBuild,
  System.Generics.Collections;

type
  TOnRequest = reference to procedure(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);

  TOnRequestProc = procedure(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo) of object;

  THTTPCommandTypes = set of THTTPCommandType;

  TRoute = class
    URI: string;
    Proc: TOnRequest;
    Method: THTTPCommandTypes;
    function CheckURI(Request: TIdHTTPRequestInfo): Boolean;
    constructor Create; overload;
    constructor Create(const URI: string; Proc: TOnRequest); overload;
    constructor Create(Method: THTTPCommandTypes; const URI: string; Proc: TOnRequest); overload;
  end;

  RouteMethod = class(TCustomAttribute)
  private
    URI: string;
    Method: THTTPCommandTypes;
  public
    constructor Create(const URI: string; Method: THTTPCommandTypes = []);
  end;

  TRoutes = class(TObjectList<TRoute>)
  end;

  THTTPServer = class(TComponent)
  private
    FRoutes: TRoutes;
    FContentPath: string;
    Instance: TidHTTPServer;
    FAutoFileServer: Boolean;
    function GetFilePath(const FileName: string): string;
    procedure ResponseAsFile(const FileName: string; Response: TIdHTTPResponseInfo);
    function ProcRequest(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo): Boolean;
    procedure FillRoutes;
    procedure SetAutoFileServer(const Value: Boolean);
  protected
    procedure DoCommand(AContext: TIdContext; Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);
  public
    procedure AddMimeType(const Ext, MIMEType: string);
    procedure Run(const Ports: TArray<Word> = []); overload;
    constructor Create; reintroduce; overload;
    constructor Create(AOwner: TComponent); overload; override;
    destructor Destroy; override;
    property ContentPath: string read FContentPath write FContentPath;
    procedure Route(const URI: string; Proc: TOnRequest); overload;
    procedure Route(Method: THTTPCommandTypes; const URI: string; Proc: TOnRequest); overload;
    procedure Route(Method: THTTPCommandTypes; const URI: string; Proc: TRttiMethod); overload;
    property AutoFileServer: Boolean read FAutoFileServer write SetAutoFileServer;
  end;

implementation

procedure THTTPServer.AddMimeType(const Ext, MIMEType: string);
begin
  Instance.MIMETable.AddMimeType(Ext, MIMEType);
end;

constructor THTTPServer.Create;
begin
  Create(nil);
end;

constructor THTTPServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FAutoFileServer := False;
  FContentPath := 'www';
  FRoutes := TRoutes.Create;
  Instance := TidHTTPServer.Create(nil);
  Instance.OnCommandGet := DoCommand;
  Instance.MIMETable.BuildCache;
  Instance.MIMETable.AddMimeType('wasm', 'application/wasm');
  FillRoutes;
end;

destructor THTTPServer.Destroy;
begin
  FRoutes.Free;
  Instance.Free;
  inherited;
end;

procedure THTTPServer.FillRoutes;
var
  Context: TRttiContext;
begin
  for var Method in Context.GetType(ClassInfo).GetMethods do
    for var Attr in Method.GetAttributes do
      if Attr is RouteMethod then
        Route(RouteMethod(Attr).Method, RouteMethod(Attr).URI, Method);
end;

procedure THTTPServer.DoCommand(AContext: TIdContext; Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);
begin
  Writeln(Request.RemoteIP, ' ', Request.Command, ' ', Request.URI, ' ', Request.QueryParams, ' ', Request.Range);
  if FAutoFileServer and (Request.CommandType = hcGET) then
  begin
    var Path := Request.URI;
    if TFile.Exists(GetFilePath(Path)) then
    begin
      ResponseAsFile(GetFilePath(Path), Response);
      Exit;
    end;
  end;
  if not ProcRequest(Request, Response) then
    Response.ResponseNo := 404;
end;

function THTTPServer.GetFilePath(const FileName: string): string;
begin
  Result := TPath.Combine(FContentPath, FileName.TrimLeft(['/']));
end;

function THTTPServer.ProcRequest(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo): Boolean;
begin
  for var Route in FRoutes do
    if Route.CheckURI(Request) then
    begin
      if Assigned(Route.Proc) then
        Route.Proc(Request, Response);
      Exit(True);
    end;
  Result := False;
end;

procedure THTTPServer.ResponseAsFile(const FileName: string; Response: TIdHTTPResponseInfo);
begin
  Response.ContentType := Instance.MIMETable.GetFileMIMEType(FileName);
  Response.CharSet := 'charset=utf-8';
  Response.ContentStream := TFileStream.Create(FileName, fmShareDenyWrite);
end;

procedure THTTPServer.Route(Method: THTTPCommandTypes; const URI: string; Proc: TRttiMethod);
begin
  var LMethod: TMethod;
  LMethod.Code := Proc.CodeAddress;
  LMethod.Data := Self;
  FRoutes.Add(TRoute.Create(Method, URI, TOnRequestProc(LMethod)));
end;

procedure THTTPServer.Route(Method: THTTPCommandTypes; const URI: string; Proc: TOnRequest);
begin
  FRoutes.Add(TRoute.Create(Method, URI, Proc));
end;

procedure THTTPServer.Route(const URI: string; Proc: TOnRequest);
begin
  Route([], URI, Proc);
end;

procedure THTTPServer.Run(const Ports: TArray<Word>);
begin
  var command: string;
  Writeln('Starting...');
  repeat
    try
      TTask.Run(
        procedure
        begin
          for var Port in Ports do
            if Port <> 0 then
              Instance.Bindings.Add.Port := Port;
          Instance.Active := True;
        end);
      Writeln('Started');
      repeat
        Readln(command)
      until command = 'quit';
    except
      on E: Exception do
      begin
        Writeln(E.ClassName + ': ' + E.Message);
        Sleep(1000);
        Writeln('Restaring...');
      end;
    end;
  until command = 'quit';
end;

procedure THTTPServer.SetAutoFileServer(const Value: Boolean);
begin
  FAutoFileServer := Value;
end;

{ TRoute }

function TRoute.CheckURI(Request: TIdHTTPRequestInfo): Boolean;
begin
  Result := ((Method = []) or (Request.CommandType in Method)) and (Request.URI = URI);
end;

constructor TRoute.Create(const URI: string; Proc: TOnRequest);
begin
  Create([], URI, Proc);
end;

constructor TRoute.Create(Method: THTTPCommandTypes; const URI: string; Proc: TOnRequest);
begin
  inherited Create;
  Self.Method := Method;
  Self.URI := URI;
  Self.Proc := Proc;
end;

constructor TRoute.Create;
begin
  inherited;
  Method := [];
  URI := '';
  Proc := nil;
end;

{ RouteMethod }

constructor RouteMethod.Create(const URI: string; Method: THTTPCommandTypes);
begin
  inherited Create;
  Self.URI := URI;
  Self.Method := Method;
end;

end.

