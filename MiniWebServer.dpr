program MiniWebServer;

uses
  System.Classes, System.SysUtils, System.Threading, IdContext, IdCustomHTTPServer, IdHTTPServer, IdSSLOpenSSL, System.IOUtils;

type
  Server = class
    class var Instance: TidHTTPServer;
    class procedure FOnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  end;

class procedure Server.FOnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
  Writeln(ARequestInfo.RemoteIP, ' ', ARequestInfo.Command, ' ', ARequestInfo.URI);
  if TFile.Exists('www' + ARequestInfo.URI) then
  begin
    AResponseInfo.ContentType := Server.Instance.MIMETable.GetFileMIMEType('www' + ARequestInfo.URI);
    AResponseInfo.CharSet := 'charset=utf-8';
    AResponseInfo.ContentStream := TFileStream.Create('www' + ARequestInfo.URI, fmShareDenyWrite);
  end
  else
    AResponseInfo.ContentText :=
      '<html><head><title>Delphi forever</title></head>' +
      '<body>Command: ' + ARequestInfo.Command +
      '<br />URI: ' + ARequestInfo.URI +
      '<br />Host: ' + ARequestInfo.Host +
      '<br />UserAgent: ' + ARequestInfo.UserAgent +
      '<br />DateTime: ' + DateTimeToStr(Now) +
      '</body></html>';
end;

begin
  var command: string;
  Writeln('Starting...');
  repeat
    try
      Server.Instance := TidHTTPServer.Create(nil);
      try
        Server.Instance.OnCommandGet := Server.FOnCommandGet;
        TTask.Run(procedure begin Server.Instance.Active := True; end);
        Writeln('Started');
        repeat Readln(command) until command = 'quit';
      finally
        Server.Instance.Free;
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
