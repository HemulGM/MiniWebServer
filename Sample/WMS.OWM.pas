unit WMS.OWM;

interface

uses
  HTTP.Server;

procedure GetWeather(Request: TRequest; Response: TResponse);

implementation

procedure GetWeather(Request: TRequest; Response: TResponse);
begin
  Response.Json('{ "value": "+22" }');
end;

end.

