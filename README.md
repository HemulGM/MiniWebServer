# MiniWebServer
 
```pascal
program MiniWebServer;

uses
  HTTP.Server in 'HTTP.Server.pas',
  WMS.OWM in 'Sample\WMS.OWM.pas';

begin
  var Server := THTTPServer.Create;
  try
    Server.Route('/weather', GetWeather);
    Server.Run([80, 8080, 9090]);
  finally
    Server.Free;
  end;
end.
```

```pascal
program MiniWebServer_Attrib;

uses
  HTTP.Server in 'HTTP.Server.pas',
  WMS.OWM in 'Sample\WMS.OWM.pas';

type
  TServer = class(THTTPServer)
    //auto class routes
    [RouteMethod('/test', [GET, HEAD])]
    procedure Test(Request: TRequest; Response: TResponse);
    [RouteMethod('/check', [GET])]
    procedure Check(Request: TRequest; Response: TResponse);
  end;

{ TServer }

procedure TServer.Check;
begin
  //send json text
  Response.Json('{ "value": "test_text" }', 401);
  //send file
  Response.AsFile('C:\file.ext');
  //send json object
  var JObject := TJsonObject.Create;
  Response.Json(JObject, 200); // auto clear
end;

procedure TServer.Test;
begin
  //send object
  var Obj := TObject.Create;
  Response.Json(Obj);
  Obj.Free;
end;

begin
  var Server := TServer.Create;
  try
    //GET files
    Server.AutoFileServer := True;
    //inline route
    Server.Route('/run',
      procedure(Request: TRequest; Response: TResponse)
      begin
        Response.Json('{ "text": "done" }', 200);
      end);
    //add route
    Server.Route('/weather', GetWeather);
    Server.Run([80, 8080, 9090]);
  finally
    Server.Free;
  end;
end.
```
