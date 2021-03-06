
{Summary 将字符串序列Token化的通用 Tokenizer 类。

Description

   @author  Riceball LEE(riceballl@hotmail.com)
   @version $Revision$

分析
   Token 类型分为两类， 

SimpleToken, 
ComplexToken。 
SimpleToken: 是由固定的字符串序列组成, eg, ';' 。 

ComplexToken: 由起始 Token，结束Token 以及夹在其间的字符串组成，如，注释和字符串。 

ComplexToken 的处理方式有： tfEscapeDuplicateToken, tfOneLine, tfEscapeChar。

tfOneLine: 表示只处理1行
tfEscapeDuplicateToken: 是否处理转义TokenEnd符号，当双写TokenEnd符号时候表示，一个TokenEnd符号，如： ''''，表示一个单引号。 
tfEscapeChar: 是否启用 EscapeChar 转义字符串序列的下一个字符. 转义字符在属性 EscapeChar 中设置. DeQuotedString只处理转义自身和转义TokenEnd符号，如果有其它字符转义你需要重载 DoEscapedChar或联系OnEscapedChar事件。
加入新的TokenId

简单类型的TokenId:

ttArgSpliter := 32;

SimpleTokens.AddStandardToken(ttSpliter, ';');
SimpleTokens.Add(ttArgSpliter, ',');


复杂类型的 TokenId：
Tokens.AddStandardToken(ttComment, '//', '', [tfOneLine]);
Tokens.Add(aTokenId, aTokenBegin, aTokenEnd, aTokenFlags); 

通过LoadFromXX加载待处理的字符流，调用 ReadToken 方法对字符流进行 Token化。



* 属性和事件 *

IgnoreCase: 是否忽略大小写
BlankChars: 哪些字符是需要忽略的空白字符
EscapeChar: 在 ComplexToken 中的转义字符定义，如果为空，则无转义 
property Errors: PMeTokenErrors read GetErrors;  收集在Tokenize过程中发生的错误，如果无错误，Errors.Count =0.
property CurrentToken: TMeToken read FCurrentToken; 
property SimpleTokens: PMeSimpleTokenTypes read FSimpleTokens;
property Tokens: PMeComplexTokenTypes read FTokens;
property OnEscapedChar: TMeEscapedCharEvent read FOnEscapedChar write FOnEscapedChar;
property OnComment: TMeOnCommentEvent read FOnComment write FOnComment; 


* 方法 *

function HasTokens: Boolean;
function ReadToken: PMeToken;  从字符流中读入一个Token,如果返回nil表示再无Token可读。
function NextToken: PMeToken;  返回当前字符流中的下一个Token。
procedure LoadFromStream(const Stream: PMeStream); 加载待处理的字符流。
procedure LoadFromFile(const FileName: string); 从文件加载待处理的字符流。
procedure LoadFromString(const aValue: string);
procedure Clear;
function DeQuotedString(const aToken: PMeToken): string;  如果aToken是ComplexToken那么将该Token 作 DeQuotedString 处理.

  License:
    * The contents of this file are released under a dual \license, and
    * you may choose to use it under either the Mozilla Public License
    * 1.1 (MPL 1.1, available from http://www.mozilla.org/MPL/MPL-1.1.html)
    * or the GNU Lesser General Public License 2.1 (LGPL 2.1, available from
    * http://www.opensource.org/licenses/lgpl-license.php).
    * Software distributed under the License is distributed on an "AS
    * IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
    * implied. See the License for the specific language governing
    * rights and limitations under the \license.
    * The Original Code is $RCSfile: uMeTokenizer.pas,v $.
    * The Initial Developers of the Original Code are Riceball LEE.
    * Portions created by Riceball LEE is Copyright (C) 2007-2008
    * All rights reserved.
    * Contributor(s):
}
unit uMeTokenizer;

interface

{$I MeSetting.inc}

uses
  {$IFDEF MSWINDOWS}
  Windows,
  {$ENDIF MSWINDOWS}
  SysUtils
  , FastcodeCompareTextExUnit
  , uMeObject
  , uMeStream
  ;

(* in System.pas
  TTextLineBreakStyle = (tlbsLF, tlbsCRLF);

var   { Text output line break handling.  Default value for all text files }
  DefaultTextLineBreakStyle: TTextLineBreakStyle = {$IFDEF LINUX} tlbsLF {$ENDIF}
                                                 {$IFDEF MSWINDOWS} tlbsCRLF {$ENDIF};
const
  sLineBreak = {$IFDEF LINUX} #10 {$ENDIF} {$IFDEF MSWINDOWS} #13#10 {$ENDIF};
*)

ResourceString
  //1: %i: Line; 2: %i: Col; 3. %i: the ErrorCode; 4. %s: the ErrorToken; 
  rsMeTokenErrorMissedToken = '(%d:%d) Fatal: %d the %s is expected. ';
  rsMeTokenErrorUnknown =  '(%d:%d) Fatal: Unknown Token Error %d the error token is "%s" . ';

type
  TMeCharset = set of char;
const
  cCR = #$0D;
  cLF = #$0A;

  cMaxTokenLength  = 32;
  cMeControlCharset: TMeCharset = [#0..#31];

  cMeTokenErrorMissedToken  = 1;
  cMeTokenErrorUnknownToken = 2;

  cMeCustomTokenType = 32;

{
  ttToken      = 0;
  ttSpliter    = 1;
  ttBlockBegin = 2;
  ttBlockEnd   = 3;
  ttString     = 4;
  ttComment    = 5;
}

type
  PMeTokenString = ^ TMeTokenString;
  TMeTokenString = String[cMaxTokenLength];
  {
  @param ttToken  the general token. this general token not the include the control-chars or blankChars.
  @param ttSimpleToken the general Simple Token.
  @param ttComplexToken the general Complex Token.
  }
  TMeTokenType = (ttUnknown, ttSimpleToken, ttComplexToken);
  TMeCustomTokenType = (ttToken, ttSpliter, ttBlockBegin, ttBlockEnd, ttString, ttComment);

  {
    @param tfEscapeDuplicateToken  转义在CompexToken 序列中 双写"TokenEnd"表示一个TokenEnd，不会结束序列。
    @param tfEscapeChar            是否启用 EscapeChar. 转义字符串序列的下一个字符. 转义字符在属性 EscapeChar 中设置. 
                                   DeQuotedString只处理转义自身和转义TokenEnd符号，如果有其它字符转义你需要重载 DoEscapedChar 方法或联系OnEscapedChar事件。
    @param tfOneLine               在CompexToken 序列中遇到 CRLF则停止，只处理一行。
  }
  TMeTokenFlag = (tfEscapeDuplicateToken, tfOneLine, tfEscapeChar);
  TMeTokenFlags = set of TMeTokenFlag;

  PMeComplexTokenTypes = ^ TMeComplexTokenTypes;
  PMeTokenizer = ^ TMeTokenizer;
  PMeToken = ^ TMeToken;

  PMeSimpleTokenType = ^ TMeSimpleTokenType;
  TMeSimpleTokenType = Object
    TokenType: TMeTokenType;
    //note: the 0-31 is preserved for system
    TokenId: Integer;
    //the Token should not be empty.
    Token: TMeTokenString;
  end;

  //for String or Comment like.
  PMeComplexTokenType = ^ TMeComplexTokenType;
  TMeComplexTokenType = Object(TMeSimpleTokenType)
    //treate the duplicate tokenEnd as single symbol in it(the duplicate tokenEnd is not the Token to end.).
    //only used in ttString
    Flags: TMeTokenFlags;
    //TokenBegin: TMeTokenString; it is TMeSimpleTokenType.Token
    //if TokenEnd is '' and tfOneLine in Flags then it is one line !
    TokenEnd: TMeTokenString;
  end;

  PMeSimpleTokenTypes = ^ TMeSimpleTokenTypes;
  TMeSimpleTokenTypes = Object(TMeList)
  protected
    function GetItem(const Index: Integer): PMeSimpleTokenType;
  public
    destructor Destroy; virtual;{override}
    procedure Clear;
    procedure Add(const aTokenId: Integer; const aTokenName: string);{$IFDEF SUPPORTS_OVERLOAD}overload;{$ENDIF}
    {$IFDEF SUPPORTS_OVERLOAD}
    procedure Add(const aTokenId: TMeCustomTokenType; const aTokenName: string);overload;
    {$ENDIF}
    procedure AddStandardToken(const aTokenId: TMeCustomTokenType; const aTokenName: string);
    function IsSimpleToken(const aToken: PChar): Boolean;
  public
    property Items[const Index: Integer]: PMeSimpleTokenType read GetItem; default;
  end;

  TMeComplexTokenTypes = Object(TMeList)
  protected
    function GetItem(const Index: Integer): PMeComplexTokenType;
  public
    destructor Destroy; virtual;{override}
    procedure Clear;
    procedure Add(const aTokenId: Integer; const aTokenBegin, aTokenEnd: string; const aFlags: TMeTokenFlags = []);{$IFDEF SUPPORTS_OVERLOAD}overload;{$ENDIF}
    {$IFDEF SUPPORTS_OVERLOAD}
    procedure Add(const aTokenId: TMeCustomTokenType; const aTokenBegin, aTokenEnd: string; const aFlags: TMeTokenFlags = []);overload;
    {$ENDIF}
    procedure AddStandardToken(const aTokenId: TMeCustomTokenType; const aTokenBegin, aTokenEnd: string; const aFlags: TMeTokenFlags = []);
    function IndexOfId(const aId: Integer; const aBeginIndex: Integer = 0): Integer;
    //search the index of TokenBegin 
    function IndexOf(const aName: string; const aBeginIndex: Integer = 0; const aIgnoreCase: Boolean = false): Integer;
    //search the index of TokenEnd
    function IndexOfEnd(const aName: string; const aBeginIndex: Integer = 0; const aIgnoreCase: Boolean = false): Integer;
  public
    property Items[const Index: Integer]: PMeComplexTokenType read GetItem; default;
  end;

  TMeToken = Object //Note: DO NOT USE VIRTUAL OBJECT! Treat as Record.
  protected
    function GetToken: string;
  public
    procedure Reset;
    function IsEmpty: Boolean;
    procedure Assign(const aValue: PMeToken);
  public
    Pos: PChar; //pos = nil means empty token.
    TokenId: Integer; //if TokenId = ttToken then TokeType means nil.
    TokenType: PMeSimpleTokenType;
    Size: Integer;
    Line, Col: Integer;
    LineEnd, ColEnd: Integer; //this token end line No and end column No.
    
    property Token: String read GetToken;
  end;

  PMeTokens = ^TMeTokens;
  TMeTokens = Object(TMeList)
  protected
    function GetItem(const Index: Integer): PMeToken;
  public
    destructor Destroy; virtual;{override}
    procedure Clear;
  public
    property Items[const Index: Integer]: PMeToken read GetItem; default;
  end;

  PMeTokenErrorInfo = ^ TMeTokenErrorInfo;
  TMeTokenErrorInfo = Object(TMeToken)
  public
    function ErrorInfo: string;
  public
    ErrorCode: Integer;
    ErrorFmt: ShortString;
  end;

  PMeTokenErrors = ^ TMeTokenErrors;
  TMeTokenErrorEvent = procedure(const Sender: PMeTokenErrors; const aError: PMeTokenErrorInfo) of object;
  TMeTokenErrors = Object(TMeList)
  protected
    FOnError: TMeTokenErrorEvent;
    function GetItem(const Index: Integer): PMeTokenErrorInfo;
  public
    destructor Destroy; virtual;{override}
    procedure Add(const aToken: PMeToken; const aErrorCode: Integer; const aErrorFmt: ShortString='');
    procedure Clear;
  public
    property Items[const Index: Integer]: PMeTokenErrorInfo read GetItem; default;
    property OnError: TMeTokenErrorEvent read FOnError write FOnError;
  end;

  {the Me Tokenizer}
  {
   Init the system supported internal Tokens:
     SimpleTokens.Add(ttSpliter, ';');
     SimpleTokens.Add(ttSpliter, ',');
     Tokens.Add(aTokenId, aTokenBegin, aTokenEnd);
   Note: the token never be CRLF!! 只有在 BlankChars 中才可以包含CRLF，在定义的Token字符串中绝对不能有 CRLF.

   First LoadFromXXX, 
   then 
     call ReadToken to read next token. return nil means no more token to get.
     call NextToken to pre-read the next token. return nil means no more token to get.
   search order:
     SimpleTokenType, ComplexTokenType.
     
  }
  TMeEscapedCharEvent = procedure(const Sender: PMeTokenizer; var EscapedStr: TMeTokenString) of object;
  TMeOnCommentEvent = procedure(const Sender: PMeTokenizer; const Comment: string) of object;
  TMeTokenizer = Object(TMeDynamicObject)
  protected
    FIgnoreCase: Boolean;
    FBlankChars: TMeCharset;
    FEscapeChar: TMeTokenString;

    FSimpleTokens: PMeSimpleTokenTypes;
    FTokens: PMeComplexTokenTypes;

    //the Source text to tokenize
    FSource: PChar;
    FSourceEnd: PChar;
    FSourceSize: Integer;
    FCurrentToken: TMeToken;
    FNextToken: TMeToken;
    FErrors: PMeTokenErrors;
    FOnEscapedChar: TMeEscapedCharEvent;
    FOnComment: TMeOnCommentEvent;
  protected
    procedure Init;virtual; {override}
    procedure Reset;
    procedure SkipBlankChars(var aToken: TMeToken);
    function IsBlankChar(const aToken: TMeToken): Boolean;

    function GetErrors: PMeTokenErrors;
    procedure ConsumeToken(var aToken: TMeToken);
    function CompareTokenText(const S1, S2: PChar; const Len: Integer): Boolean;
    procedure DoEscapedChar(var EscapedStr: TMeTokenString);virtual;
    procedure DoComment(const Comment: string);virtual;

  public
    destructor Destroy; virtual;{override}

    function HasTokens: Boolean;
    function ReadToken: PMeToken;
    function NextToken: PMeToken;

    procedure LoadFromStream(const Stream: PMeStream);
    procedure LoadFromFile(const FileName: string);
    procedure LoadFromString(const aValue: string);
    procedure Clear;
    function DeQuotedString(const aToken: PMeToken): string;
  public
    property CurrentToken: TMeToken read FCurrentToken;
    {collect the Token Errors}
    property Errors: PMeTokenErrors read GetErrors;

    property IgnoreCase: Boolean read FIgnoreCase write FIgnoreCase;
    property BlankChars: TMeCharset read FBlankChars write FBlankChars;
    //this is EscapeChar for string. if empty means not used. process in the compiler. here only process to escape to the tokenEnd.
    property EscapeChar: TMeTokenString read FEscapeChar write FEscapeChar;

    //collect the simple token types
    property SimpleTokens: PMeSimpleTokenTypes read FSimpleTokens;
    //collect the string, comment token types like.
    property Tokens: PMeComplexTokenTypes read FTokens;
    property OnEscapedChar: TMeEscapedCharEvent read FOnEscapedChar write FOnEscapedChar;
    property OnComment: TMeOnCommentEvent read FOnComment write FOnComment;
  end;

implementation

const
  cMeSystemSimpleTokenTypes = [ttSpliter, ttBlockBegin, ttBlockEnd];
  cMeSystemComplexTokenTypes = [ttString, ttComment];

{ TMeToken }
procedure TMeToken.Assign(const aValue: PMeToken);
begin
  if Assigned(aValue) then
  begin
    Pos := aValue.Pos;
    TokenId := aValue.TokenId;
    TokenType:= aValue.TokenType;
    Size := aValue.Size;
    Line := aValue.Line;
    Col  := aValue.Col;
    LineEnd := aValue.LineEnd;
    ColEnd := aValue.ColEnd;
  end;
end;

function TMeToken.GetToken: string;
begin
  Result := '';
  if Assigned(Pos) and (Size > 0) then
  begin
    SetLength(Result, Size);
    Move(Pos^, Result[1], Size);
  end;
end;

function TMeToken.IsEmpty: Boolean;
begin
  Result := Pos = nil;
end;

procedure TMeToken.Reset;
begin
    Pos     := nil;
    Size    := 0;
    Line    := 1;
    Col     := 1;
    LineEnd := 1;
    ColEnd  := 1;
    TokenId := 0;
    TokenType := nil;
end;

{ TMeTokens }
destructor TMeTokens.Destroy;
begin
  FreePointers;
  inherited;
end;

procedure TMeTokens.Clear;
begin
  FreePointers;
  inherited;
end;

function TMeTokens.GetItem(const Index: Integer): PMeToken;
begin
  Result := Inherited Get(Index);
end;

{ TMeSimpleTokenTypes }
destructor TMeSimpleTokenTypes.Destroy;
begin
  FreePointers;
  inherited;
end;

procedure TMeSimpleTokenTypes.Clear;
begin
  FreePointers;
  inherited;
end;

procedure TMeSimpleTokenTypes.Add(const aTokenId: Integer; const aTokenName: string);
var
  vTokenItem: PMeSimpleTokenType;
begin
  New(vTokenItem);
  with vTokenItem^ do
  begin
    TokenType := ttSimpleToken;
    TokenId := aTokenId;
    Token := aTokenName;
  end;
  inherited Add(vTokenItem);
end;

{$IFDEF SUPPORTS_OVERLOAD}
procedure TMeSimpleTokenTypes.Add(const aTokenId: TMeCustomTokenType; const aTokenName: string);
begin
  Add(Ord(aTokenId), aTokenName);
end;

{$ENDIF}
procedure TMeSimpleTokenTypes.AddStandardToken(const aTokenId: TMeCustomTokenType; const aTokenName: string);
begin
  Add(Ord(aTokenId), aTokenName);
end;

function TMeSimpleTokenTypes.GetItem(const Index: Integer): PMeSimpleTokenType;
begin
  Result := Inherited Get(Index);
end;

function IsSameTokenStr(aToken: PChar; const s: string): Boolean;
var
  i: Integer;
begin
  Result := False;
  for i := 1 to Length(s) do
  begin
    if (aToken = #0) then exit;
    Result := aToken^ = s[i];
     //writeln('  ', aToken,':',s[i],':',Result);
    if not Result then exit;
    Inc(aToken);
  end;
end;

function TMeSimpleTokenTypes.IsSimpleToken(const aToken: PChar): Boolean;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
  begin
    with Items[i]^ do 
    //if TokenId = Ord(aTokenId) then
    begin
      Result := IsSameTokenStr(aToken, Token);
      //writeln(aToken,':',Token,':',Result);
      if Result then exit;
    end;
  end;
  Result := False;
end;

{ TMeComplexTokenTypes }
destructor TMeComplexTokenTypes.Destroy;
begin
  FreePointers;
  inherited;
end;

procedure TMeComplexTokenTypes.Clear;
begin
  FreePointers;
  inherited;
end;

procedure TMeComplexTokenTypes.Add(const aTokenId: Integer; const aTokenBegin, aTokenEnd: string; const aFlags: TMeTokenFlags);
var
  vTokenItem: PMeComplexTokenType;
begin
  New(vTokenItem);
  with vTokenItem^ do
  begin
    TokenType  := ttComplexToken;
    TokenId    := aTokenId;
    Flags      := aFlags;
    Token      := aTokenBegin;
    TokenEnd   := aTokenEnd;
  end;
  inherited Add(vTokenItem);
end;

{$IFDEF SUPPORTS_OVERLOAD}
procedure TMeComplexTokenTypes.Add(const aTokenId: TMeCustomTokenType; const aTokenBegin, aTokenEnd: string; const aFlags: TMeTokenFlags);
begin
  Add(Ord(aTokenId), aTokenBegin, aTokenEnd, aFlags);
end;

{$ENDIF}
procedure TMeComplexTokenTypes.AddStandardToken(const aTokenId: TMeCustomTokenType; const aTokenBegin, aTokenEnd: string; const aFlags: TMeTokenFlags);
begin
  Add(Ord(aTokenId), aTokenBegin, aTokenEnd, aFlags);
end;

function TMeComplexTokenTypes.GetItem(const Index: Integer): PMeComplexTokenType;
begin
  Result := Inherited Get(Index);
end;

function TMeComplexTokenTypes.IndexOfId(const aId: Integer; const aBeginIndex: Integer = 0): Integer;
begin
  for Result := aBeginIndex to Count - 1 do
  begin
    if aId = Items[Result].TokenId then exit;
  end;
  Result := -1;
end;

function TMeComplexTokenTypes.IndexOf(const aName: string; const aBeginIndex: Integer; const aIgnoreCase: Boolean): Integer;
begin
  for Result := aBeginIndex to Count - 1 do
  begin
    if aIgnoreCase then
    begin
      if AnsiSameText(aName, Items[Result].Token) then exit;
    end
    else
      if aName = Items[Result].Token then exit;
  end;
  Result := -1;
end;

function TMeComplexTokenTypes.IndexOfEnd(const aName: string; const aBeginIndex: Integer; const aIgnoreCase: Boolean): Integer;
begin
  for Result := aBeginIndex to Count - 1 do
  begin
    if aIgnoreCase then
    begin
      if AnsiSameText(aName, Items[Result].TokenEnd) then exit;
    end
    else
      if aName = Items[Result].TokenEnd then exit;
  end;
  Result := -1;
end;

{ TMeTokenErrorInfo }
function TMeTokenErrorInfo.ErrorInfo: string;
begin
  //1: %i: Line; 2: %i: Col; 3. %i: the ErrorCode; 4. %s: the ErrorToken;
  case ErrorCode of
    cMeTokenErrorMissedToken: 
    begin
      Result := Format(rsMeTokenErrorMissedToken, [Line, Col, ErrorCode, ErrorFmt]);
    end;
    cMeTokenErrorUnknownToken:
      Result := Format(rsMeTokenErrorUnknown, [Line, Col, ErrorCode, Token]);
    else if ErrorFmt <> '' then
      Result := Format(ErrorFmt, [Line, Col, ErrorCode, Token]);
  end;  //case
end;

{ TMeTokenErrors }
destructor TMeTokenErrors.Destroy;
begin
  FreePointers;
  inherited;
end;

procedure TMeTokenErrors.Clear;
begin
  FreePointers;
  inherited;
end;

procedure TMeTokenErrors.Add(const aToken: PMeToken; const aErrorCode: Integer; const aErrorFmt: ShortString);
var
  vItem: PMeTokenErrorInfo;
begin
  New(vItem);
  inherited Add(vItem);
  vItem.Assign(aToken);
  vItem.ErrorCode := aErrorCode;
  vItem.ErrorFmt := aErrorFmt;
  if Assigned(FOnError) then FOnError(@Self, vItem);
end;

function TMeTokenErrors.GetItem(const Index: Integer): PMeTokenErrorInfo;
begin
  Result := Inherited Get(Index);
end;

{ TMeTokenizer }
destructor TMeTokenizer.Destroy;
begin
  MeFreeAndNil(FSimpleTokens);
  MeFreeAndNil(FTokens);
  MeFreeAndNil(FErrors);
  if Assigned(FSource) then FreeMem(FSource);
  inherited;
end;

procedure TMeTokenizer.Init;
begin
  inherited;
  New(FSimpleTokens, Create);
  New(FTokens, Create);
end;

type
  TMeMemoryStreamAccess = Object(TMeMemoryStream)
  end;

function TMeTokenizer.CompareTokenText(const S1, S2: PChar; const Len: Integer): Boolean;
begin
  if IgnoreCase then
  begin
    Result := FastcodeCompareTextEx(S1, S2, Len) = 0;
        {
        GetMem(vPChar, Length(Token) + 1);
        GetMem(vPChar1, Length(Token) + 1);
        try
          Move(Token[1], vPChar^, Length(Token));
          Move(aToken.Pos^, vPChar1^, Length(Token));
          vPChar[Length(Token)] := #0;
          vPChar1[Length(Token)] := #0;
          vFound := AnsiStrComp(vPChar, vPChar1) = 0;
        finally
          FreeMem(vPChar);
          FreeMem(vPChar1);
        end;
        //}
  end
  else
    Result := CompareMem(S1, S2, Len);
end;

procedure TMeTokenizer.DoComment(const Comment: string);
begin
  if Assigned(FOnComment) then
    FOnComment(@Self, Comment);
end;

procedure TMeTokenizer.DoEscapedChar(var EscapedStr: TMeTokenString);
begin
  if Assigned(FOnEscapedChar) then
    FOnEscapedChar(@Self, EscapedStr);
end;

function TMeTokenizer.IsBlankChar(const aToken: TMeToken): Boolean;
begin
  with aToken do
    Result := {$IFDEF MBCS_SUPPORT} (StrByteType(Pos, 0) = mbSingleByte) and {$ENDIF}
      (Pos^ in BlankChars);
end;

procedure TMeTokenizer.SkipBlankChars(var aToken: TMeToken);
begin
  //try SkipChars
  with aToken do
    While (Integer(Pos) < Integer(FSourceEnd))
      {$IFDEF MBCS_SUPPORT} and (StrByteType(Pos, 0) = mbSingleByte) {$ENDIF}
      and ((Pos^ in BlankChars) or (Pos^ in cMeControlCharset)) do
    begin
      if (Pos^ = cLF) then
      begin
        Inc(Line);
        Col := 1;
      end
      else
      begin
        Inc(Col);
      end;
      LineEnd := Line;
      ColEnd := Col;
      Inc(Pos);
      //writeln('pos.char=', ord(pos^));
    end;
end;

procedure TMeTokenizer.Clear;
begin
  if Assigned(FSource) then FreeMem(FSource);
  FSource    := nil;
  FSourceEnd := nil;
  Reset;
end;

procedure TMeTokenizer.ConsumeToken(var aToken: TMeToken);
var
  i: Integer;
  vSize: Integer;
  vFound: Boolean;
  vPChar: PChar;
  {$IFDEF MBCS_SUPPORT} 
  j: Integer;
  {$ENDIF}
  label NextTk;
begin
  if Assigned(FSource) then
  begin
    with aToken do
    begin
      if not Assigned(Pos) then
      begin
        Pos := FSource;
      end
      else begin
NextTk:
        Inc(Pos, Size);
        if Integer(Pos) >= Integer(FSourceEnd) then 
        begin
          aToken.Pos := nil;
          exit;
        end;
        Col := ColEnd;
        Line := LineEnd;
      end;
    end; //with

    SkipBlankChars(aToken);
    vFound := False;

    //Ok, Now aToken.Pos is the non-blank PChar
    //check SimpleTokens
    for i := 0 to FSimpleTokens.Count - 1 do
    with FSimpleTokens.Items[i]^ do
      if Integer(FSourceEnd) - Integer(aToken.Pos) >= Length(Token) then
      begin
        if CompareTokenText(aToken.Pos, @Token[1], Length(Token)) then
        begin
          aToken.Size := Length(Token);
          aToken.TokenType := FSimpleTokens.Items[i];
          aToken.TokenId := TokenId;
          aToken.ColEnd  := aToken.Col + Length(Token);
          exit;
        end;
      end;

    //check the Complex Tokens now:
    for i := 0 to FTokens.Count - 1 do
      with FTokens.Items[i]^ do
      if Integer(FSourceEnd) - Integer(aToken.Pos) >= (Length(Token) + Length(TokenEnd)) then
      begin
        if CompareTokenText(aToken.Pos, @Token[1], Length(Token)) then
        begin //got the TokenBegin, now try to find the TokenEnd
          vPChar := aToken.Pos;
          Inc(vPChar, Length(Token));
          Inc(aToken.Size, Length(Token));
          Inc(aToken.ColEnd, Length(Token));

          //search the TokenEnd
          Repeat
            if (vPChar^ = cCR) or (vPChar^ = cLF) then
            begin
              if (tfOneLine in Flags) then
              begin
                vFound := TokenEnd = '';
                if not vFound then
                begin
                  aToken.Size := Integer(vPChar)- Integer(aToken.Pos);
                  aToken.TokenId := TokenId;
                  aToken.TokenType := FTokens.Items[i];
                  FErrors.Add(@aToken, cMeTokenErrorMissedToken, TokenEnd);
                  exit;
                end;
              end;
              if not vFound then
              begin
                Inc(vPChar);
                if (vPChar^ = cLF) then 
                  Inc(vPChar);
                Inc(aToken.LineEnd);
                aToken.ColEnd := 1;
              end;
              continue;
            end;
            if (tfEscapeChar in Flags) and (EscapeChar <> '') and CompareMem(vPChar, @EscapeChar[1], Length(EscapeChar)) then
            begin
              //only Escape the EscapeChar and TokenEnd.
              Inc(vPChar, Length(EscapeChar));
              Inc(aToken.ColEnd, Length(EscapeChar));
              if (Integer(vPChar) + Length(EscapeChar) < FSourceSize + Integer(FSource)) and CompareMem(vPChar, @EscapeChar[1], Length(EscapeChar)) then
              begin
                Inc(vPChar, Length(EscapeChar));
                Inc(aToken.ColEnd, Length(EscapeChar));
                continue;
              end
              else if (TokenEnd <> '') and (Integer(vPChar) + Length(TokenEnd) < FSourceSize + Integer(FSource)) and CompareMem(vPChar, @TokenEnd[1], Length(TokenEnd)) then begin
                Inc(vPChar, Length(TokenEnd));
                Inc(aToken.ColEnd, Length(TokenEnd));
                continue;
              end;
            end;
            vFound := (TokenEnd <> '') and CompareTokenText(vPChar, @TokenEnd[1], Length(TokenEnd));
            if vFound then
            begin
              if (tfEscapeDuplicateToken in Flags) and (Integer(FSourceEnd) - Integer(@vPChar[Length(TokenEnd)]) >= Length(TokenEnd)) then
              begin
                if CompareTokenText(@vPChar[Length(TokenEnd)], @TokenEnd[1], Length(TokenEnd)) then
                begin
                  vFound := False;
                  Inc(vPChar, Length(TokenEnd));
                  Inc(aToken.ColEnd, Length(TokenEnd));
                end;
              end;
            end;
            if not vFound then
            begin
              //forward a char
              {$IFDEF MBCS_SUPPORT} 
              if StrByteType(vPChar, 0) = mbLeadByte then
              begin
                j := 0;
                while (Integer(vPChar) + j < Integer(FSourceEnd)) and (StrByteType(vPChar, j) <> mbTrailByte) do
                begin
                  Inc(j);
                end;
                Inc(vPChar, j);
                Inc(aToken.ColEnd, j);
              end;
              {$ENDIF}
              Inc(vPChar);
              Inc(aToken.ColEnd);
            end;
          Until vFound or (Integer(vPChar) >= FSourceSize + Integer(FSource));

          if vFound then
          begin
            aToken.Size := Integer(vPChar)- Integer(aToken.Pos) + Length(TokenEnd);
            aToken.TokenId := TokenId;
            aToken.TokenType := FTokens.Items[i];
            if Length(TokenEnd) > 1 then
              Inc(aToken.ColEnd, Length(TokenEnd)-1);
            if (TokenId = Ord(ttComment)) and ((@aToken = @FCurrentToken) or (@aToken = @FNextToken)) then
            begin
              DoComment(DeQuotedString(@aToken));
              Goto NextTk;
            end
            else
              exit;
          end;
        end;
      end; //FTokens

    //now treat this as the general token
    vPChar := aToken.Pos;
    Repeat
      {$IFDEF MBCS_SUPPORT} 
      if StrByteType(vPChar, 0) = mbLeadByte then
      begin
        j := 0;
        while (Integer(vPChar)+j < Integer(FSourceEnd)) and (StrByteType(vPChar, j) = mbSingleByte) do
        begin
          Inc(j);
        end;
        Inc(vPChar, j);
        Inc(aToken.ColEnd, j);
      end;
      {$ENDIF}
      Inc(vPChar);
      Inc(aToken.ColEnd);

      if SimpleTokens.IsSimpleToken(vPChar) or (vPChar^ in cMeControlCharset) or (vPChar^ in FBlankChars) then
      begin
        vFound := True;
      end;
    Until vFound or (Integer(vPChar) >= FSourceSize + Integer(FSource));

    aToken.Size := Integer(vPChar)- Integer(aToken.Pos);
    aToken.TokenId := Ord(ttToken);
    aToken.TokenType := nil;

  end
  else
    aToken.Pos := nil;
end;

function TMeTokenizer.DeQuotedString(const aToken: PMeToken): string;
var
  vPChar: PChar;
  {$IFDEF MBCS_SUPPORT} 
  i: Integer;
  {$ENDIF}
  vEscapedChar: TMeTokenString;
begin
  Result := '';
  if Assigned(aToken.Pos) and Assigned(aToken.TokenType) and (aToken.TokenType.TokenType = ttComplexToken) then
  begin
    vPChar := aToken.Pos;
        with PMeComplexTokenType(aToken.TokenType)^ do
        begin
          Inc(vPChar, Length(Token));
          while (Integer(vPChar) < aToken.Size + Integer(aToken.Pos)) do
          begin
            if (vPChar^ = cCR) or (vPChar^ = cLF) then
            begin
                Result := Result + vPChar^;
                Inc(vPChar);
                if (vPChar^ = cLF) then 
                begin
                  Result := Result + vPChar^;
                  Inc(vPChar);
                end;
              continue;
            end;
            if (tfEscapeChar in Flags) and (EscapeChar <> '') and CompareMem(vPChar, @EscapeChar[1], Length(EscapeChar)) then
            begin
              //only Escape the EscapeChar and TokenEnd.
              Inc(vPChar, Length(EscapeChar));
              if (Integer(vPChar)  + Length(EscapeChar) < aToken.Size + Integer(aToken.Pos)) and CompareMem(vPChar, @EscapeChar[1], Length(EscapeChar)) then
              begin
                Result := Result + EscapeChar;
                Inc(vPChar, Length(EscapeChar));
              end
              else if (TokenEnd <> '') and (Integer(vPChar) + Length(TokenEnd) < aToken.Size + Integer(aToken.Pos)) and CompareMem(vPChar, @TokenEnd[1], Length(TokenEnd)) then begin
                Result := Result + TokenEnd;
                Inc(vPChar, Length(TokenEnd));
              end
              else begin
                vEscapedChar := '';
                {$IFDEF MBCS_SUPPORT}
                if StrByteType(vPChar, 0) = mbLeadByte then
                begin
                  i := 0;
                  while (Integer(vPChar)+i < aToken.Size + Integer(aToken.Pos)) and (StrByteType(vPChar, i) <> mbTrailByte) do
                  begin
                    vEscapedChar := vEscapedChar + vPChar[i];
                    Inc(i);
                  end;
                  Inc(vPChar, i);
                end;
                {$ENDIF}
                vEscapedChar := vEscapedChar + vPChar^;
                Inc(vPChar);
                DoEscapedChar(vEscapedChar);
                Result := Result + vEscapedChar;
              end;
              continue;
            end;
            if (TokenEnd <> '') and CompareTokenText(vPChar, @TokenEnd[1], Length(TokenEnd)) then
            begin
              Inc(vPChar, Length(TokenEnd));
              if (tfEscapeDuplicateToken in Flags) and (Integer(vPChar) + Length(TokenEnd) < aToken.Size + Integer(aToken.Pos)) and CompareTokenText(vPChar, @TokenEnd[1], Length(TokenEnd)) then
              begin
                Result := Result + TokenEnd;
                Inc(vPChar, Length(TokenEnd));
              end;
            end
            else
            begin
              //forward a char
              {$IFDEF MBCS_SUPPORT} 
              if StrByteType(vPChar, 0) = mbLeadByte then
              begin
                i := 0;
                while (Integer(vPChar)+i < aToken.Size + Integer(aToken.Pos)) and (StrByteType(vPChar, i) <> mbTrailByte) do
                begin
                  Result := Result + vPChar[i];
                  Inc(i);
                end;
                Inc(vPChar, i);
              end;
              {$ENDIF}
              Result := Result + vPChar^;
              Inc(vPChar);
            end;
          end; //while
        end;
  end
end;

function TMeTokenizer.GetErrors: PMeTokenErrors;
begin
  if not Assigned(FErrors) then New(FErrors, Create);
  Result := FErrors;
end;

function TMeTokenizer.HasTokens: Boolean;
begin
  Result := Assigned(FCurrentToken.Pos);
  if not Result then 
    Result := Assigned(ReadToken());
end;

procedure TMeTokenizer.LoadFromStream(const Stream: PMeStream);
var
  vStream: PMeMemoryStream;
begin
  New(vStream, Create);
  try
    vStream.LoadFromStream(Stream);
    FSourceSize := TMeMemoryStreamAccess(vStream^).FSize;
    if FSourceSize <> 0 then
    begin
      ReallocMem(FSource, FSourceSize+1);
      Move(vStream.Memory^, FSource^, FSourceSize);
      FSource[FSourceSize] := #0;
      FSourceEnd := @FSource[FSourceSize];
    end
    else
    begin
      FreeMem(FSource);
      FSource := nil;
      FSourceEnd := nil;
    end;
  finally
    vStream.Free;
  end;
  Reset;
end;

procedure TMeTokenizer.LoadFromFile(const FileName: string);
var
  vStream: PMeFileStream;
begin
  New(vStream, Create);
  try
    vStream.Open(FileName, fmOpenRead or fmShareDenyNone);
    FSourceSize := vStream.GetSize;
    if FSourceSize <> 0 then
    begin
      ReallocMem(FSource, FSourceSize+1);
      vStream.ReadBuffer(FSource^, FSourceSize);
      FSource[FSourceSize] := #0;
      FSourceEnd := @FSource[FSourceSize];
    end
    else
    begin
      FreeMem(FSource);
      FSource := nil;
      FSourceEnd := nil;
    end;
  finally
    vStream.Free;
  end;
  Reset;
end;

procedure TMeTokenizer.LoadFromString(const aValue: string);
begin
  FSourceSize := Length(aValue);
  if FSourceSize <> 0 then
  begin
    ReallocMem(FSource, FSourceSize+1);
    Move(aValue[1], FSource^, FSourceSize);
    FSource[FSourceSize] := #0;
    FSourceEnd := @FSource[FSourceSize];
  end
  else
  begin
    FreeMem(FSource);
    FSource := nil;
    FSourceEnd := nil;
  end;
  Reset;
end;

function TMeTokenizer.NextToken: PMeToken;
//var
  //vToken: TMeToken;
begin
  if not Assigned(FNextToken.Pos) then
  begin
    FNextToken := FCurrentToken;
    ConsumeToken(FNextToken);
    //FNextToken := vToken;
  end;
  if Assigned(FNextToken.Pos) then
    Result := @FNextToken
  else
    Result := nil;
end;

function TMeTokenizer.ReadToken: PMeToken;
begin
  if Assigned(FNextToken.Pos) then
  begin
    FCurrentToken := FNextToken;
    FNextToken.Reset;
    Assert(FNextToken.Pos=nil);
  end
  else
    ConsumeToken(FCurrentToken);
  if Assigned(FCurrentToken.Pos) then
    Result := @FCurrentToken
  else
    Result := nil;
end;
procedure TMeTokenizer.Reset;
begin
  FCurrentToken.Reset;
  FNextToken.Reset;
end;

initialization
  SetMeVirtualMethod(TypeOf(TMeTokenizer), ovtVmtParent, TypeOf(TMeDynamicObject));
  {$IFDEF MeRTTI_SUPPORT}
  SetMeVirtualMethod(TypeOf(TMeTokenizer), ovtVmtClassName, nil);
  {$ENDIF}
end.
