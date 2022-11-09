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

