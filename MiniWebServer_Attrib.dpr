program MiniWebServer_Attrib;

uses
  System.Classes,
  System.SysUtils,
  IdCustomHTTPServer,
  HTTP.Server in 'HTTP.Server.pas';

type
  TServer = class(THTTPServer)
  public
    [RouteMethod('/test', [hcGET, hcHEAD])]
    procedure Test(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);
    [RouteMethod('/check', [hcGET])]
    procedure Check(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);
  end;

{ TServer }

procedure TServer.Check(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);
begin
  Response.ContentText := '{ "value": "test_text" }';
  Response.ContentType := 'application/json';
  Response.ResponseNo := 401;
end;

procedure TServer.Test(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo);
begin
  if Request.CommandType = hcHEAD then
  begin
    Response.ContentLength := 100;
    Exit;
  end;
  Writeln(Request.QueryParams);
  Writeln(Request.Range);
  Response.ContentText := '{ "value": 13 }';
  Response.ContentType := 'application/json';
  Response.ResponseNo := 200;
end;

begin
  var Server := TServer.Create;
  try
    Server.Route('/run',
      procedure(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo)
      begin
        Response.ContentText := '{ "text": "done" }';
        Response.ContentType := 'application/json';
        Response.ResponseNo := 200;
      end);

    Server.Run([80, 8080, 9090]);
  finally
    Server.Free;
  end;
end.

