unit HTTP.Server;

interface

uses
  System.Classes, System.SysUtils, System.Threading, IdContext, System.Rtti,
  IdCustomHTTPServer, IdHTTPServer, System.IOUtils, System.Generics.Collections,
  System.JSON;

type
  TRequest = TIdHTTPRequestInfo;

  TRequestHelper = class helper for TRequest
  public
    function IsHead: Boolean;
    function IsGet: Boolean;
    function IsPost: Boolean;
    function IsDelete: Boolean;
    function IsPut: Boolean;
    function IsTrace: Boolean;
    function IsOption: Boolean;
  end;

  TResponse = TIdHTTPResponseInfo;

  TResponseHelper = class helper for TResponse
  public
    procedure Json(const Text: string; Code: Integer = 200); overload;
    procedure Json(const JSONValue: TJSONValue; Code: Integer = 200); overload;
    procedure Json(const Obj: TObject; Code: Integer = 200); overload;
    procedure AsFile(const FileName: string; Code: Integer = 200);
  end;

  TOnRequest = reference to procedure(Request: TRequest; Response: TResponse);

  TOnResponsePlainText = reference to procedure(var Response: string; var Code: Word);

  TOnRequestProc = procedure(Request: TRequest; Response: TResponse) of object;

  THTTPCommand = (HEAD, GET, POST, DELETE, PUT, TRACE, OPTION);

  THTTPCommands = set of THTTPCommand;

  THTTPCommandTypes = set of THTTPCommandType;

  THTTPCommandsHelper = record helper for THTTPCommands
    function ToHTTPCommandTypes: THTTPCommandTypes;
  end;

  TRoute = class
    URI: string;
    Method: THTTPCommandTypes;
    function CheckURI(Request: TRequest): Boolean;
    constructor Create; overload;
    constructor Create(const URI: string); overload;
    constructor Create(Method: THTTPCommandTypes; const URI: string); overload;
    procedure Execute(Request: TRequest; Response: TResponse); virtual; abstract;
  public
  end;

  TRouteFull = class(TRoute)
  protected
    Proc: TOnRequest;
  public
    constructor Create(const URI: string; Proc: TOnRequest); overload;
    constructor Create(Method: THTTPCommandTypes; const URI: string; Proc: TOnRequest); overload;
    procedure Execute(Request: TRequest; Response: TResponse); override;
  end;

  TRoutePlaiText = class(TRoute)
  protected
    Proc: TOnResponsePlainText;
  public
    constructor Create(const URI: string; Proc: TOnResponsePlainText); overload;
    constructor Create(Method: THTTPCommandTypes; const URI: string; Proc: TOnResponsePlainText); overload;
    procedure Execute(Request: TRequest; Response: TResponse); override;
  end;

  RouteMethod = class(TCustomAttribute)
  private
    URI: string;
    Method: THTTPCommands;
  public
    constructor Create(const URI: string; Method: THTTPCommands = []);
  end;

  TRoutes = class(TObjectList<TRoute>)
  end;

  TOnServerWork = reference to procedure(var Stop: Boolean);

  TOnServerErrorBind = reference to procedure;

  THTTPServer = class(TComponent)
  private
    FRoutes: TRoutes;
    FContentPath: string;
    Instance: TidHTTPServer;
    FAutoFileServer: Boolean;
    function ProcRequest(Request: TRequest; Response: TResponse): Boolean;
    procedure FillRoutes;
    procedure SetAutoFileServer(const Value: Boolean);
  protected
    procedure DoCommand(AContext: TIdContext; Request: TRequest; Response: TResponse);
    function GetFilePath(const FileName: string): string;
  public
    constructor Create; reintroduce; overload;
    constructor Create(AOwner: TComponent); overload; override;
    destructor Destroy; override;
    procedure AddMimeType(const Ext, MIMEType: string);
    procedure Run(const Ports: TArray<Word> = []); overload;
    procedure RunSync(const Port: Word);
    procedure Route(const URI: string; Proc: TOnRequest); overload;
    procedure Route(Method: THTTPCommands; const URI: string; Proc: TOnRequest); overload;
    procedure Route(Method: THTTPCommands; const URI: string; Proc: TOnResponsePlainText); overload;
    procedure Route(const URI: string; Proc: TOnResponsePlainText); overload;
    procedure Route(Method: THTTPCommands; const URI: string; Proc: TRttiMethod); overload;
    property ContentPath: string read FContentPath write FContentPath;
    property AutoFileServer: Boolean read FAutoFileServer write SetAutoFileServer;
  end;

implementation

uses
  REST.Json;

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
  Instance.OnCommandOther := DoCommand;
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

procedure THTTPServer.DoCommand(AContext: TIdContext; Request: TRequest; Response: TResponse);
begin
  //Writeln(Request.RemoteIP, ' ', Request.Command, ' ', Request.URI, ' ', Request.QueryParams, ' ', Request.Range);
  if FAutoFileServer and (Request.CommandType in [hcGET, hcHEAD]) then
  begin
    var Path := Request.URI;
    if TFile.Exists(GetFilePath(Path)) then
    begin
      Response.AsFile(GetFilePath(Path));
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

function THTTPServer.ProcRequest(Request: TRequest; Response: TResponse): Boolean;
begin
  for var Route in FRoutes do
    if Route.CheckURI(Request) then
    begin
      Route.Execute(Request, Response);
      Exit(True);
    end;
  Result := False;
end;

procedure THTTPServer.Route(Method: THTTPCommands; const URI: string; Proc: TRttiMethod);
begin
  var LMethod: TMethod;
  LMethod.Code := Proc.CodeAddress;
  LMethod.Data := Self;
  FRoutes.Add(TRouteFull.Create(Method.ToHTTPCommandTypes, URI, TOnRequestProc(LMethod)));
end;

procedure THTTPServer.Route(const URI: string; Proc: TOnResponsePlainText);
begin
  FRoutes.Add(TRoutePlaiText.Create([], URI, Proc));
end;

procedure THTTPServer.Route(Method: THTTPCommands; const URI: string; Proc: TOnResponsePlainText);
begin
  FRoutes.Add(TRoutePlaiText.Create(Method.ToHTTPCommandTypes, URI, Proc));
end;

procedure THTTPServer.Route(Method: THTTPCommands; const URI: string; Proc: TOnRequest);
begin
  FRoutes.Add(TRouteFull.Create(Method.ToHTTPCommandTypes, URI, Proc));
end;

procedure THTTPServer.Route(const URI: string; Proc: TOnRequest);
begin
  Route([], URI, Proc);
end;

procedure THTTPServer.RunSync(const Port: Word);
begin
  Instance.Bindings.Add.Port := Port;
  Instance.Active := True;
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

{ RouteMethod }

constructor RouteMethod.Create(const URI: string; Method: THTTPCommands);
begin
  inherited Create;
  Self.URI := URI;
  Self.Method := Method;
end;

{ TResponseHelper }

procedure TResponseHelper.Json(const Text: string; Code: Integer);
begin
  ContentText := Text;
  ContentType := 'application/json';
  ResponseNo := Code;
end;

procedure TResponseHelper.Json(const JSONValue: TJSONValue; Code: Integer);
begin
  try
    Json(JSONValue.ToJSON, Code);
  finally
    JSONValue.Free;
  end;
end;

procedure TResponseHelper.AsFile(const FileName: string; Code: Integer);
begin
  ContentType := HTTPServer.MIMETable.GetFileMIMEType(FileName);
  //ContentLength := TFile.GetSize(FileName);
  ContentStream := TFileStream.Create(FileName, fmShareDenyWrite);
  ResponseNo := Code;
end;

procedure TResponseHelper.Json(const Obj: TObject; Code: Integer);
begin
  Json(TJson.ObjectToJsonString(Obj), Code);
end;

{ TRequestHelper }

function TRequestHelper.IsDelete: Boolean;
begin
  Result := CommandType = hcDELETE;
end;

function TRequestHelper.IsGet: Boolean;
begin
  Result := CommandType = hcGET;
end;

function TRequestHelper.IsHead: Boolean;
begin
  Result := CommandType = hcHEAD;
end;

function TRequestHelper.IsOption: Boolean;
begin
  Result := CommandType = hcOPTION;
end;

function TRequestHelper.IsPost: Boolean;
begin
  Result := CommandType = hcPOST;
end;

function TRequestHelper.IsPut: Boolean;
begin
  Result := CommandType = hcPUT;
end;

function TRequestHelper.IsTrace: Boolean;
begin
  Result := CommandType = hcTRACE;
end;

{ THTTPCommandsHelper }

function THTTPCommandsHelper.ToHTTPCommandTypes: THTTPCommandTypes;
begin
  if GET in Self then
    Include(Result, hcGET);
  if HEAD in Self then
    Include(Result, hcHEAD);
  if POST in Self then
    Include(Result, hcPOST);
  if DELETE in Self then
    Include(Result, hcDELETE);
  if PUT in Self then
    Include(Result, hcPUT);
  if TRACE in Self then
    Include(Result, hcTRACE);
  if OPTION in Self then
    Include(Result, hcOPTION);
end;

{ TRoute }

function TRoute.CheckURI(Request: TRequest): Boolean;
begin
  Result := ((Method = []) or (Request.CommandType in Method)) and (Request.URI = URI);
end;

constructor TRoute.Create(const URI: string);
begin
  Create([], URI);
end;

constructor TRoute.Create(Method: THTTPCommandTypes; const URI: string);
begin
  inherited Create;
  Self.Method := Method;
  Self.URI := URI;
end;

constructor TRoute.Create;
begin
  inherited;
  Method := [];
  URI := '';
end;

{ TRouteFull }

constructor TRouteFull.Create(const URI: string; Proc: TOnRequest);
begin
  inherited Create(URI);
  Self.Proc := Proc;
end;

constructor TRouteFull.Create(Method: THTTPCommandTypes; const URI: string; Proc: TOnRequest);
begin
  inherited Create(Method, URI);
  Self.Proc := Proc;
end;

procedure TRouteFull.Execute(Request: TRequest; Response: TResponse);
begin
  Proc(Request, Response);
end;

{ TRoutePlaiText }

constructor TRoutePlaiText.Create(const URI: string; Proc: TOnResponsePlainText);
begin
  inherited Create(URI);
  Self.Proc := Proc;
end;

constructor TRoutePlaiText.Create(Method: THTTPCommandTypes; const URI: string; Proc: TOnResponsePlainText);
begin
  inherited Create(Method, URI);
  Self.Proc := Proc;
end;

procedure TRoutePlaiText.Execute(Request: TRequest; Response: TResponse);
var
  ResponseText: string;
  ResponseCode: Word;
begin
  ResponseCode := 200;
  Proc(ResponseText, ResponseCode);
  Response.ContentText := ResponseText;
  Response.ResponseNo := ResponseCode;
end;

end.

