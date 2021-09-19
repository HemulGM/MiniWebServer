program GetTester;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  System.SysUtils,
  System.Classes,
  System.Threading,
  System.Net.HttpClient;

begin
  try
    var Count := 0;
    var CountMax := 100000;
    var Tasks: TArray<ITask>;
    SetLength(Tasks, CountMax);
    repeat
      Tasks[Count] := TTask.Run(
        procedure
        begin
          try
            with THTTPClient.Create do
            try
              Writeln(Get('http://root.hemulgm.ru').StatusCode);
            finally
              Free;
            end;
          except
            on E: Exception do
              Writeln(E.ClassName, ': ', E.Message);
          end;
        end);
      Inc(Count);
    until Count > CountMax;
    TTask.WaitForAll(Tasks);
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
  Writeln('done');
  Readln;
end.

