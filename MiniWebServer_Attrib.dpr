program MiniWebServer_Attrib;

uses
  System.SysUtils,
  System.Json,
  HTTP.Server in 'HTTP.Server.pas',
  WMS.OWM in 'Sample\WMS.OWM.pas';

type
  TServer = class(THTTPServer)
    procedure Test(Request: TRequest; Response: TResponse);
    procedure Check(Request: TRequest; Response: TResponse);
  end;

{ TServer }

[RouteMethod('/check', [GET])]
procedure TServer.Check;
begin
  //send json
  Response.Json('{ "value": "test_text" }', 401);
  //send file
  Response.AsFile('C:\file.ext');
end;

[RouteMethod('/test', [GET, HEAD])]
procedure TServer.Test;
begin
  var Json := TJSONObject.Create;

  Json.AddPair('id', TJSONNumber.Create(Request.Params.Values['id'].ToInteger));
  Json.AddPair('text', 'Text');
  Json.AddPair('array', TJSONArray.Create('text1', 'text2'));
  Response.Json(Json);
end;

begin
  var Server := TServer.Create;
  try
    Server.AutoFileServer := True;
    Server.Route('/run',
      procedure(Request: TRequest; Response: TResponse)
      begin
        Response.Json('{ "text": "done" }', 200);
      end);
    Server.Route('/weather', GetWeather);
    Server.Run([777]);
  finally
    Server.Free;
  end;
end.

