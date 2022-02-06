unit HTTP.Server;

interface

uses
  System.Classes, System.SysUtils, System.Threading, IdContext,
  IdCustomHTTPServer, IdHTTPServer, IdSSLOpenSSL, System.IOUtils, HTTP.HTMLBuild,
  System.Generics.Collections;

type
  TOnRequest = reference to procedure(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);

  TRoute = class
    URI: string;
    Proc: TOnRequest;
    function CheckURI(Request: TIdHTTPRequestInfo): Boolean;
    constructor Create(const URI: string; Proc: TOnRequest);
  end;

  TRoutes = class(TObjectList<TRoute>)
  end;

  THTTPServer = class(TComponent)
  private
    FRoutes: TRoutes;
    FContentPath: string;
    Instance: TidHTTPServer;
    function GetFilePath(const FileName: string): string;
    procedure ResponseAsFile(const FileName: string; Response: TIdHTTPResponseInfo);
    procedure FOnCommandGet(AContext: TIdContext; Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);
    function ProcRequest(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo): Boolean;
  public
    procedure AddMimeType(const Ext, MIMEType: string);
    procedure Run(const Port: Word = 0); overload;
    procedure Run(const Ports: TArray<Word>); overload;
    constructor Create; reintroduce; overload;
    constructor Create(AOwner: TComponent); overload; override;
    destructor Destroy; override;
    property ContentPath: string read FContentPath write FContentPath;
    procedure Route(const URI: string; Proc: TOnRequest);
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
  FContentPath := 'www';
  FRoutes := TRoutes.Create;
  Instance := TidHTTPServer.Create(nil);
  Instance.OnCommandGet := FOnCommandGet;
  Instance.MIMETable.BuildCache;
  Instance.MIMETable.AddMimeType('wasm', 'application/wasm');
end;

destructor THTTPServer.Destroy;
begin
  FRoutes.Free;
  Instance.Free;
  inherited;
end;

procedure THTTPServer.FOnCommandGet(AContext: TIdContext; Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);
begin
  Writeln(Request.RemoteIP, ' ', Request.Command, ' ', Request.URI);
  Writeln(Request.QueryParams);
  Writeln(Request.Range);
  if (Request.CommandType = hcGET) then
  begin
    var Path := Request.URI;
    if Path = '/' then
      Path := 'index.html';
    if TFile.Exists(GetFilePath(Path)) then
    begin
      ResponseAsFile(GetFilePath(Path), Response);
      Exit;
    end;
  end;
  if ProcRequest(Request, Response) then
    Exit;
  if TFile.Exists(GetFilePath('404.html')) then
  begin
    ResponseAsFile(GetFilePath('404.html'), Response);
    Response.ResponseNo := 404;
  end
  else
    Response.ContentText := HTMLBuilder.Build.
      Title('Delphi forever').
      Body([
      'Command: ' + Request.Command,
      '<br />URI: ' + Request.URI,
      '<br />Host: ' + Request.Host,
      '<br />UserAgent: ' + Request.UserAgent,
      '<br />DateTime: ' + DateTimeToStr(Now)
      ]).HTML;
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

procedure THTTPServer.Route(const URI: string; Proc: TOnRequest);
begin
  FRoutes.Add(TRoute.Create(URI, Proc));
end;

procedure THTTPServer.Run(const Ports: TArray<Word>);
begin
  TTask.Run(
    procedure
    begin
      for var Port in Ports do
        if Port <> 0 then
          Instance.Bindings.Add.Port := Port;
      Instance.Active := True;
    end);
end;

procedure THTTPServer.Run(const Port: Word);
begin
  Run([Port]);
end;

{ TRoute }

function TRoute.CheckURI(Request: TIdHTTPRequestInfo): Boolean;
begin
  Result := Request.URI = URI;
end;

constructor TRoute.Create(const URI: string; Proc: TOnRequest);
begin
  inherited Create;
  Self.URI := URI;
  Self.Proc := Proc;
end;

end.

