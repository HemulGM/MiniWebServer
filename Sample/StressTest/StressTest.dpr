program StressTest;

uses
  System.SysUtils,
  HTTP.Server in '..\..\HTTP.Server.pas';

begin
  var Server := THTTPServer.Create;
  try
    Server.Route('/',
      procedure(var Response: string; var Code: Word)
      begin
        Response := 'Hello World Delphi!';
      end);

    Server.Route('/readfile',
      procedure(Request: TRequest; Response: TResponse)
      begin
        Response.AsFile('data.txt');
      end);

    Server.Route('/fibonacci',
      procedure(var Response: string; var Code: Word)
      begin
        Sleep(10000);
        var a, b, c: Cardinal;
        a := 0;
        b := 1;
        c := 0;
        for var i := 2 to 2000000 do
        begin
          c := a + b;
          a := b;
          b := c;
        end;
        Response := c.ToString;
      end);
    Server.Run([555]);
  finally
    Server.Free;
  end;
end.

