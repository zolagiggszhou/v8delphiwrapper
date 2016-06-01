(*
 *                       Delphi wrapper for V8 JavaScript Engine
 *
 * Usage allowed under the restrictions of the Lesser GNU General Public License
 * or alternatively the restrictions of the Mozilla Public License 1.1
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License for
 * the specific language governing rights and limitations under the License.
 *
 * Author    	: Ryan Zhou <zhouzuoji@outlook.com>
 * Web site 	: https://github.com/zolagiggszhou
 * Repository 	: https://github.com/zolagiggszhou/v8delphiwrapper
 *
 * Embarcadero Technologies, Inc is not permitted to use or redistribute
 * this source code without explicit permission.
 *
 *)

unit Unit1;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, v8, ExtCtrls, StdCtrls, Buttons, HttpApp;

type
  TForm1 = class(TForm)
    Memo1: TMemo;
    Panel1: TPanel;
    SpeedButton1: TSpeedButton;
    Memo2: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure SpeedButton1Click(Sender: TObject);
  private
    FEngine: Tv8Engine;
    FObjectTemplate: Tv8ObjectTemplate;
    FObjectTemplate2: Tv8ObjectTemplate;
    Fv8Object: Iv8Object;
    FJsAccessableObject: Iv8Object;
    Fv8GlobalObject: Iv8Object;
  public
    { Public declarations }
  end;

  {$TYPEINFO ON}
  {$METHODINFO ON}
  {$RTTI EXPLICIT METHODS([vcPublic, vcProtected, vcPublished]) PROPERTIES([vcPublic, vcProtected, vcPublished]) FIELDS([vcPublic, vcProtected, vcPublished])}

  ///
  ///
  ///
  TJsAccessableClass = class
  public
    function add(a,b: Double): Double;
    function httpEncode(const s: string): string;
  end;

var
  Form1: TForm1;

implementation

procedure raiseException(_info: V8FunctionCallbackInfo); cdecl;
begin
  v8_throw_exception(V8_ERROR, 'exception raised by delphi');
end;

procedure alert2(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  dlgparam: Iv8Object;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  dlgparam := info.args[0].AsObject;
  Application.MessageBox(PChar(dlgparam.GetStr('text')), PChar(dlgparam.GetStr('caption')), MB_ICONWARNING or MB_OK);
end;

procedure alert(_info: V8FunctionCallbackInfo); cdecl;
var
  msg, caption: string;
  argcnt: Integer;
  info: Tv8FunctionCallbackInfo;
  form: TForm1;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  argcnt := info.ArgCount;
  form := TForm1(info.GetInternalField);
  if argcnt > 0 then
    msg := info.args[0].AsString
  else
    msg := 'undefined';

  if argcnt > 1 then
    caption := info.args[1].AsString
  else if Assigned(form) then
    caption := form.Caption
  else
    caption := 'Zolagiggs Zhou';

  Application.MessageBox(PChar(msg), PChar(caption), MB_ICONWARNING or MB_OK);
end;

procedure console_log(_info: V8FunctionCallbackInfo); cdecl;
var
  msg: string;
  argcnt: Integer;
  info: Tv8FunctionCallbackInfo;
  form: TForm1;
  this: Iv8Object;
begin
  info := Tv8FunctionCallbackInfo.Create(_info);
  this := info.this;
  argcnt := info.ArgCount;
  form := TForm1(this.GetInternalField(0));
  if argcnt > 0 then
    msg := info.args[0].AsString
  else
    msg := 'undefined';

  OutputDebugString(PChar(form.Caption + ': ' + msg));
end;

{$R *.dfm}

procedure TForm1.FormCreate(Sender: TObject);
begin
  v8.v8_init; // initialize v8 library
  FEngine := Tv8Engine.Create; // create engine
  FEngine.enter;
  Fv8GlobalObject := FEngine.GlobalObject;

  // manually make an object template which has only a method named 'log'
  FObjectTemplate := Tv8ObjectTemplate.Create(1);
  FObjectTemplate.AddMethod('log', console_log, nil);

  // create an instance of FObjectTemplate, and bind Form1 as its first internal field
  Fv8Object := FObjectTemplate.CreateInstance(Self);

  // set the 'console' property of js engine global object to Fv8Object
  Fv8GlobalObject.SetObject('console', Fv8Object);

  // register 3 functions
  FEngine.RegisterNativeFunction('alert', alert, nil);
  FEngine.RegisterNativeFunction('alert2', alert2, nil);
  FEngine.RegisterNativeFunction('raiseException', raiseException, nil);


  // create an object template of TJsAccessableClass
  FObjectTemplate2 := FEngine.RegisterRttiClass(TJsAccessableClass);
  FJsAccessableObject := FObjectTemplate2.CreateInstance(TJsAccessableClass.Create);
  Fv8GlobalObject.SetObject('hostexe', FJsAccessableObject);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FObjectTemplate.Free;
  Fv8Object := nil;
  Fv8GlobalObject := nil;
  TObject(FJsAccessableObject.GetInternalField(0)).Free;
  FJsAccessableObject := nil;
  FObjectTemplate2.Free;
  FEngine.leave;
  FEngine.Free;
  v8.v8_cleanup;
end;

procedure TForm1.SpeedButton1Click(Sender: TObject);
begin
  Memo2.Text := FEngine.eval(Memo1.Text);
end;

{ TJsAccessableClass }

function TJsAccessableClass.httpEncode(const s: string): string;
begin
  Result := string(HttpApp.HTTPEncode(AnsiString(s)));
end;

function TJsAccessableClass.add;
begin
  Result := a + b;
end;

end.
