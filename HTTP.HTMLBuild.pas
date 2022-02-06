unit HTTP.HTMLBuild;

interface

uses
  System.Classes, System.SysUtils;

type
  TDocSection = class(TStringList)
    procedure AddTagSection(const Tag: string; Lines: TArray<string>);
  end;

  IHTMLBuilder = interface
    function Title(const Value: string): IHTMLBuilder;
    function HTML: string;
    function Head(const Tag: string; Lines: TArray<string>): IHTMLBuilder; overload;
    function Body(const Tag: string; Lines: TArray<string>): IHTMLBuilder; overload;
    function Doc(const Tag: string; Lines: TArray<string>): IHTMLBuilder; overload;
    function Head(Lines: TArray<string>): IHTMLBuilder; overload;
    function Body(Lines: TArray<string>): IHTMLBuilder; overload;
    function Doc(Lines: TArray<string>): IHTMLBuilder; overload;
    function Head(const Value: string): IHTMLBuilder; overload;
    function Body(const Value: string): IHTMLBuilder; overload;
    function Doc(const Value: string): IHTMLBuilder; overload;
  end;

  HTMLBuilder = class(TInterfacedObject, IHTMLBuilder)
  private
    FHead: TDocSection;
    FBody: TDocSection;
    FLines: TDocSection;
  public
    class function Build: IHTMLBuilder;
    function HTML: string;
    function Body(const Tag: string; Lines: TArray<string>): IHTMLBuilder; overload;
    function Body(const Value: string): IHTMLBuilder; overload;
    function Body(Lines: TArray<string>): IHTMLBuilder; overload;
    function Doc(const Tag: string; Lines: TArray<string>): IHTMLBuilder; overload;
    function Doc(Lines: TArray<string>): IHTMLBuilder; overload;
    function Doc(const Value: string): IHTMLBuilder; overload;
    function Head(const Tag: string; Lines: TArray<string>): IHTMLBuilder; overload;
    function Head(Lines: TArray<string>): IHTMLBuilder; overload;
    function Head(const Value: string): IHTMLBuilder; overload;
    function Title(const Value: string): IHTMLBuilder;
    constructor Create;
    destructor Destroy; override;
  end;

function OpenTag(const Tag: string): string;

function CloseTag(const Tag: string): string;

implementation

function OpenTag(const Tag: string): string;
begin
  Result := Format('<%s>', [Tag]);
end;

function CloseTag(const Tag: string): string;
begin
  Result := Format('</%s>', [Tag]);
end;

{ HTMLBuilder }

class function HTMLBuilder.Build: IHTMLBuilder;
begin
  Result := HTMLBuilder.Create;
end;

constructor HTMLBuilder.Create;
begin
  inherited;
  FHead := TDocSection.Create;
  FBody := TDocSection.Create;
  FLines := TDocSection.Create;
end;

destructor HTMLBuilder.Destroy;
begin
  FHead.Free;
  FBody.Free;
  FLines.Free;
  inherited;
end;

function HTMLBuilder.Body(const Value: string): IHTMLBuilder;
begin
  FBody.Add(Value);
  Result := Self;
end;

function HTMLBuilder.Doc(const Value: string): IHTMLBuilder;
begin
  FLines.Add(Value);
  Result := Self;
end;

function HTMLBuilder.Head(const Value: string): IHTMLBuilder;
begin
  FHead.Add(Value);
  Result := Self;
end;

function HTMLBuilder.Body(Lines: TArray<string>): IHTMLBuilder;
begin
  FBody.AddStrings(Lines);
  Result := Self;
end;

function HTMLBuilder.Doc(Lines: TArray<string>): IHTMLBuilder;
begin
  FLines.AddStrings(Lines);
  Result := Self;
end;

function HTMLBuilder.Head(Lines: TArray<string>): IHTMLBuilder;
begin
  FHead.AddStrings(Lines);
  Result := Self;
end;

function HTMLBuilder.Doc(const Tag: string; Lines: TArray<string>): IHTMLBuilder;
begin
  FLines.AddTagSection(Tag, Lines);
  Result := Self;
end;

function HTMLBuilder.Head(const Tag: string; Lines: TArray<string>): IHTMLBuilder;
begin
  FHead.AddTagSection(Tag, Lines);
  Result := Self;
end;

function HTMLBuilder.Body(const Tag: string; Lines: TArray<string>): IHTMLBuilder;
begin
  FBody.AddTagSection(Tag, Lines);
  Result := Self;
end;

function HTMLBuilder.HTML: string;
begin
  FLines.Insert(0, '<html>');
  if FHead.Count > 0 then
    FLines.AddTagSection('head', FHead.ToStringArray);
  if FBody.Count > 0 then
    FLines.AddTagSection('body', FBody.ToStringArray);
  FLines.Add('</html>');
  Result := FLines.Text;
end;

function HTMLBuilder.Title(const Value: string): IHTMLBuilder;
begin
  Result := Head('title', [Value]);
end;

{ TDocSection }

procedure TDocSection.AddTagSection(const Tag: string; Lines: TArray<string>);
begin
  Add(OpenTag(Tag));
  AddStrings(Lines);
  Add(CloseTag(Tag));
end;

end.

