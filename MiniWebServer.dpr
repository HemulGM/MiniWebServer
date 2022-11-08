program MiniWebServer;

uses
  System.Classes,
  System.SysUtils,
  IdCustomHTTPServer,
  HTTP.Server in 'HTTP.Server.pas',
  HTTP.HTMLBuild in 'HTTP.HTMLBuild.pas';

begin
  var Server := THTTPServer.Create;
  var command: string;
  Writeln('Starting...');
  repeat
    try
      try
        Server.Route([hcGET, hcHEAD], '/test',
          procedure(Request: TIdHTTPRequestInfo; Response: TIdHTTPResponseInfo)
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
          end);
        Server.Run([80, 8080, 9090]);
        Writeln('Started');
        repeat
          Readln(command)
        until command = 'quit';
      finally
        Server.Free;
      end;
    except
      on E: Exception do
        Writeln(E.ClassName + ': ' + E.Message);
    end;
    Sleep(1000);
    if command <> 'quit' then
      Writeln('Restaring...');
  until command = 'quit';
end.

