program Project2;

uses
  System.Classes, System.SysUtils, System.Threading, IdContext, IdCustomHTTPServer, IdHTTPServer;

type
  Server = class
    class var Instance: TidHTTPServer;
    class procedure FOnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
  end;

class procedure Server.FOnCommandGet(AContext: TIdContext; ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
begin
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
  Server.Instance := TidHTTPServer.Create(nil);
  Server.Instance.OnCommandGet := Server.FOnCommandGet;
  TTask.Run(
    procedure
    begin
      Server.Instance.Active := True;
    end);
  var command: string;
  repeat Readln(command) until command <> 'quit';
  Server.Instance.Free;
end.

