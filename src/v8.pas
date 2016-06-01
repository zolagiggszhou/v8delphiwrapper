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

unit v8;

interface

uses
  SysUtils, Classes, TypInfo, Rtti;

const
  V8_ERROR = 0;
  V8_RANGE_ERROR = 1;
  V8_REFERENCE_ERROR = 2;
  V8_SYNTAX_ERROR = 3;
  V8_TYPE_ERROR = 4;

type
  PUInt32 = ^UInt32;
  V8FunctionCallbackInfo = type Pointer;
  V8Isolate = type Pointer;
  V8Context = type Pointer;
  V8String = type Pointer;
  V8Object = type Pointer;
  V8ObjectTemplate = type Pointer;
  V8FunctionCallback = procedure(info: V8FunctionCallbackInfo); cdecl;

  Iv8Object = interface;
  Tv8Object = class;
  Tv8ObjectTemplate = class;

  Tv8Base = class
  protected
    FInternalDataPointer: Pointer;
  public
    function GetInternalDataPointer: Pointer;
  end;

  ///
  ///  V8 engine (executing context)
  ///
  Tv8Engine = class
  private
    FIsolate: V8Isolate;
    FContext: V8Context;
  public
    constructor Create;
    destructor Destroy; override;

    ///
    ///   Tv8Engine.enter should be called before use in a thread
    ///
    procedure enter;

    ///
    ///   Tv8Engine.leave should be called after use in a thread
    ///
    procedure leave;

    ///
    ///   get the global object
    ///
    function GlobalObject: Iv8Object;

    ///
    ///   execute code and cast the return value as string
    ///
    function eval(const code: string): string;

    ///
    ///   register a delphi function for use in javascript code
    ///
    function RegisterNativeFunction(const name: RawByteString; func: V8FunctionCallback; data: Pointer): Boolean;

    ///
    ///    register a delphi class as an V8 object template
    ///
    function RegisterRttiClass(_ClassType: TClass): Tv8ObjectTemplate;
  end;

  ///
  ///  V8 Javascipt function argument
  ///
  Tv8FunctionArg = record
  private
    FInternalDataPointer: V8FunctionCallbackInfo;
    FIndex: Integer;
  public
    constructor Create(_internal: V8FunctionCallbackInfo; _index: Integer);
    function AsString: string;
    function AsInteger: Integer;
    function AsUInt32: UInt32;
    function AsInt64: Int64;
    function AsFloat: Double;
    function AsObject: Iv8Object;
  end;   

  ///
  ///   V8 Javascript function calling context (arguments, this object, etc.)
  ///
  Tv8FunctionCallbackInfo = record
  private
    FInternalDataPointer: V8FunctionCallbackInfo;
    function GetArgs(index: Integer): Tv8FunctionArg;
  public
    constructor Create(_InternalData: V8FunctionCallbackInfo);
    function ArgCount: Integer;
    function GetInternalField(idx: Integer = 0): Pointer;
    function this: Iv8Object;
    property args[index: Integer]: Tv8FunctionArg read GetArgs;
  end;

  ///
  ///   V8 Javascript Object
  ///   you can bind several pointers to an object, called "internal fields"
  ///
  Iv8Object = interface
    function GetInternalObject: V8Object;

    function GetInternalFieldCount: Integer;
    procedure SetInternalField(idx: Integer; value: Pointer);
    function GetInternalField(idx: Integer): Pointer;

    ///
    ///   set an object property
    ///
    procedure SetObject(const name: UnicodeString; value: Iv8Object);

    ///
    ///   get an string property
    ///
    function GetStr(const name: UnicodeString): UnicodeString;

    ///
    ///   get an integer property
    ///
    function GetInt32(const name: UnicodeString): Int32;

    ///
    ///   get an unsigned integer property
    ///
    function GetUInt32(const name: UnicodeString): UInt32;

    ///
    ///   get an 64bit integer property
    ///
    function GetInt64(const name: UnicodeString): Int64;

    ///
    ///   get an float property
    ///
    function GetFloat(const name: UnicodeString): Double;

    ///
    ///   get an object property
    ///
    function GetObject(const name: UnicodeString): Iv8Object;
  end;

  Tv8Object = class(TInterfacedObject, Iv8Object)
  private
    FInternalObject: V8Object;
  public
    constructor Create(_obj: V8Object);
    destructor Destroy; override;
    function GetInternalObject: V8Object;
    function GetInternalFieldCount: Integer;
    procedure SetInternalField(idx: Integer; value: Pointer);
    function GetInternalField(idx: Integer): Pointer;
    procedure SetObject(const name: UnicodeString; value: Iv8Object);
    function GetStr(const name: UnicodeString): UnicodeString;
    function GetInt32(const name: UnicodeString): Int32;
    function GetUInt32(const name: UnicodeString): UInt32;
    function GetInt64(const name: UnicodeString): Int64;
    function GetFloat(const name: UnicodeString): Double;
    function GetObject(const name: UnicodeString): Iv8Object;
  end;

  ///
  ///   V8 Javascript Object Template
  ///
  Tv8ObjectTemplate = class(Tv8Base)
  public
    constructor Create(InternalFieldCount: Integer);
    destructor Destroy; override;

    ///
    ///  add a method to object template
    ///
    function AddMethod(const name: RawByteString; func: V8FunctionCallback; data: Pointer): Boolean;

    ///
    ///  create an object with object template
    ///
    function CreateInstance(FirstInternalField: Pointer): Iv8Object;
  end;

///
///   initialize v8 library, should be called before use of any other api
///
function v8_init: LongBool; stdcall;

///
///   cleanup v8 library
///
procedure v8_cleanup; stdcall;

function v8_new_isolate: V8Isolate; stdcall;
procedure v8_destroy_isolate(isolate: V8Isolate); stdcall;
procedure v8_enter_isolate(isolate: V8Isolate); stdcall;
procedure v8_leave_isolate(isolate: V8Isolate); stdcall;
procedure v8_throw_exception(_type: Integer; errmsg: PWideChar); stdcall;
function v8_new_context(isolate: V8Isolate): V8Context; stdcall;
procedure v8_enter_context(context: V8Context); stdcall;
procedure v8_leave_context(context: V8Context); stdcall;
procedure v8_destroy_context(context: V8Context); stdcall;
function v8_global_object(context: V8Context): V8Object; stdcall;
procedure v8_destroy_string(str: V8String); stdcall;
function v8_eval_asstr(isolate: V8Isolate; context: V8Context; code: PWideChar): V8String; stdcall;
function v8_strinfo(str: V8String; len: PInteger): PWideChar; stdcall;

function v8_set_object(isolate: V8Isolate; context: V8Context; propName: PWideChar;
  owner, propValue: V8Object): LongBool; stdcall;

function v8_register_native_function(isolate: V8Isolate; context: V8Context;
  funcname: PAnsiChar; func: V8FunctionCallback;
  data: Pointer): LongBool; stdcall;

function v8_FunctionCallbackInfo_data(info: V8FunctionCallbackInfo): Pointer; stdcall;
function v8_FunctionCallbackInfo_this(info: V8FunctionCallbackInfo): V8Object; stdcall;
function v8_FunctionCallbackInfo_internal_field(info: V8FunctionCallbackInfo;
  idx: Integer): Pointer; stdcall;

function v8_FunctionCallbackInfo_arg_count(info: V8FunctionCallbackInfo): Integer; stdcall;

function v8_FunctionCallbackInfo_arg_as_str(info: V8FunctionCallbackInfo;
  idx: Integer): V8String; stdcall;

function v8_FunctionCallbackInfo_arg_as_int32(info: V8FunctionCallbackInfo;
  idx: Integer; value: PInteger): LongBool; stdcall;

function v8_FunctionCallbackInfo_arg_as_uint32(info: V8FunctionCallbackInfo;
  idx: Integer; value: PUInt32): LongBool; stdcall;

function v8_FunctionCallbackInfo_arg_as_int64(info: V8FunctionCallbackInfo;
  idx: Integer; value: PInt64): LongBool; stdcall;

function v8_FunctionCallbackInfo_arg_as_float(info: V8FunctionCallbackInfo;
  idx: Integer; value: PDouble): LongBool; stdcall;

function v8_FunctionCallbackInfo_arg_as_object(info: V8FunctionCallbackInfo;idx: Integer): V8Object; stdcall;

procedure v8_FunctionCallbackInfo_return_int32(info: V8FunctionCallbackInfo; value: Integer); stdcall;
procedure v8_FunctionCallbackInfo_return_uint32(info: V8FunctionCallbackInfo; value: UInt32); stdcall;
procedure v8_FunctionCallbackInfo_return_float(info: V8FunctionCallbackInfo; value: Double); stdcall;
procedure v8_FunctionCallbackInfo_return_string(info: V8FunctionCallbackInfo; value: PWideChar); stdcall;

function v8_new_object_template(isolate: V8Isolate; InternalFieldCount: Integer): V8ObjectTemplate; stdcall;
procedure v8_destroy_object_template(objTemplate: V8ObjectTemplate); stdcall;

function v8_object_template_add_method(isolate: V8Isolate; context: V8Context;
  objTemplate: V8ObjectTemplate; name: PAnsiChar; func: V8FunctionCallback;
  data: Pointer): LongBool; stdcall;

function v8_new_object(isolate: V8Isolate; context: V8Context; objTemplate: V8ObjectTemplate;
  FirstInternalField: Pointer): V8Object; stdcall;

procedure v8_destroy_object(obj: V8Object); stdcall;

function v8_object_internal_field_count(obj: V8Object): Integer; stdcall;
function v8_object_get_internal_field(obj: V8Object; idx: Integer): Pointer; stdcall;
procedure v8_object_set_internal_field(obj: V8Object; idx: Integer; value: Pointer); stdcall;

function v8_object_get_int32_field(_obj: V8Object; name: PWideChar; defValue: Int32): Int32; stdcall;
function v8_object_get_uint32_field(_obj: V8Object; name: PWideChar; defValue: UInt32): UInt32; stdcall;
function v8_object_get_float_field(_obj: V8Object; name: PWideChar; value: PDouble): LongBool; stdcall;
function v8_object_get_int64_field(_obj: V8Object; name: PWideChar; value: PInt64): LongBool; stdcall;
function v8_object_get_string_field(_obj: V8Object; name: PWideChar): V8String; stdcall;
function v8_object_get_object_field(_obj: V8Object; name: PWideChar): V8Object; stdcall;

implementation

function v8_init: LongBool; external 'v8dll.dll';
procedure v8_cleanup; external 'v8dll.dll';

function v8_new_isolate: V8Isolate; stdcall; external 'v8dll.dll';
procedure v8_destroy_isolate(isolate: V8Isolate); stdcall; external 'v8dll.dll';
procedure v8_enter_isolate(isolate: V8Isolate); stdcall; external 'v8dll.dll';
procedure v8_leave_isolate(isolate: V8Isolate); stdcall; external 'v8dll.dll';
procedure v8_throw_exception; external 'v8dll.dll';
function v8_new_context(isolate: V8Isolate): V8Context; stdcall; external 'v8dll.dll';
procedure v8_enter_context(context: V8Context); stdcall; external 'v8dll.dll';
procedure v8_leave_context(context: V8Context); stdcall; external 'v8dll.dll';
procedure v8_destroy_context(context: V8Context); stdcall; external 'v8dll.dll';
function v8_global_object; external 'v8dll.dll';
procedure v8_destroy_string(str: V8String); stdcall; external 'v8dll.dll';
function v8_eval_asstr; external 'v8dll.dll';
function v8_strinfo(str: V8String; len: PInteger): PWideChar; stdcall; external 'v8dll.dll';
function v8_set_object(isolate: V8Isolate; context: V8Context; propName: PWideChar;
  owner, propValue: V8Object): LongBool; stdcall; external 'v8dll.dll';

function v8_register_native_function(isolate: V8Isolate; context: V8Context;
  funcname: PAnsiChar; func: V8FunctionCallback;
  data: Pointer): LongBool; stdcall; external 'v8dll.dll';

function v8_FunctionCallbackInfo_data(info: V8FunctionCallbackInfo): Pointer; stdcall; external 'v8dll.dll';
function v8_FunctionCallbackInfo_this; external 'v8dll.dll';
function v8_FunctionCallbackInfo_internal_field(info: V8FunctionCallbackInfo;
  idx: Integer): Pointer; stdcall; external 'v8dll.dll';

function v8_FunctionCallbackInfo_arg_count(info: V8FunctionCallbackInfo): Integer; stdcall; external 'v8dll.dll';

function v8_FunctionCallbackInfo_arg_as_str(info: V8FunctionCallbackInfo;
  idx: Integer): V8String; stdcall; external 'v8dll.dll';

function v8_FunctionCallbackInfo_arg_as_int32(info: V8FunctionCallbackInfo;
  idx: Integer; value: PInteger): LongBool; stdcall; external 'v8dll.dll';

function v8_FunctionCallbackInfo_arg_as_uint32(info: V8FunctionCallbackInfo;
  idx: Integer; value: PUInt32): LongBool; stdcall; external 'v8dll.dll';

function v8_FunctionCallbackInfo_arg_as_int64(info: V8FunctionCallbackInfo;
  idx: Integer; value: PInt64): LongBool; stdcall; external 'v8dll.dll';

function v8_FunctionCallbackInfo_arg_as_float(info: V8FunctionCallbackInfo;
  idx: Integer; value: PDouble): LongBool; stdcall; external 'v8dll.dll';

function v8_FunctionCallbackInfo_arg_as_object; external 'v8dll.dll';

procedure v8_FunctionCallbackInfo_return_int32; external 'v8dll.dll';
procedure v8_FunctionCallbackInfo_return_uint32; external 'v8dll.dll';
procedure v8_FunctionCallbackInfo_return_float; external 'v8dll.dll';
procedure v8_FunctionCallbackInfo_return_string; external 'v8dll.dll';

function v8_new_object_template(isolate: V8Isolate; InternalFieldCount: Integer): V8ObjectTemplate; stdcall; external 'v8dll.dll';
procedure v8_destroy_object_template(objTemplate: V8ObjectTemplate); stdcall; external 'v8dll.dll';

function v8_object_template_add_method(isolate: V8Isolate; context: V8Context;
  objTemplate: V8ObjectTemplate; name: PAnsiChar; func: V8FunctionCallback;
  data: Pointer): LongBool; stdcall; external 'v8dll.dll';

function v8_new_object(isolate: V8Isolate; context: V8Context; objTemplate: V8ObjectTemplate;
  FirstInternalField: Pointer): V8Object; stdcall; external 'v8dll.dll';

procedure v8_destroy_object(obj: V8Object); stdcall; external 'v8dll.dll';

function v8_object_internal_field_count; external 'v8dll.dll';
function v8_object_get_internal_field; external 'v8dll.dll';
procedure v8_object_set_internal_field; external 'v8dll.dll';

function v8_object_get_int32_field; external 'v8dll.dll';
function v8_object_get_uint32_field; external 'v8dll.dll';
function v8_object_get_float_field; external 'v8dll.dll';
function v8_object_get_int64_field; external 'v8dll.dll';
function v8_object_get_string_field; external 'v8dll.dll';
function v8_object_get_object_field;
begin
  Result := nil;
end;

function ConvertInternalString(v8InternalStr: V8String): string;
var
  s: PWideChar;
  len: Integer;
begin
  s := v8_strinfo(v8InternalStr, @len);
  SetLength(Result, len);
  Move(s^, Pointer(Result)^, len * 2);
end;

{ Tv8Base }

function Tv8Base.GetInternalDataPointer: Pointer;
begin
  Result := FInternalDataPointer;
end;

{ Tv8FunctionCallbackInfo }

function Tv8FunctionCallbackInfo.ArgCount: Integer;
begin
  Result := v8_FunctionCallbackInfo_arg_count(FInternalDataPointer);
end;

constructor Tv8FunctionCallbackInfo.Create(_InternalData: V8FunctionCallbackInfo);
begin
  FInternalDataPointer := _InternalData;
end;

function Tv8FunctionCallbackInfo.GetArgs(index: Integer): Tv8FunctionArg;
begin
  Result.FInternalDataPointer := FInternalDataPointer;
  Result.FIndex := index;
end;

function Tv8FunctionCallbackInfo.GetInternalField;
var
  jsobj: Iv8Object;
begin
  jsobj := this;
  Result := jsobj.GetInternalField(idx);
end;

function Tv8FunctionCallbackInfo.this: Iv8Object;
var
  tmp: V8Object;
begin
  tmp := v8_FunctionCallbackInfo_this(FInternalDataPointer);

  if Assigned(tmp) then
    Result := Tv8Object.Create(tmp)
  else
    Result := nil;
end;

{ Tv8FunctionArg }

function Tv8FunctionArg.AsFloat: Double;
begin
  if not v8_FunctionCallbackInfo_arg_as_float(FInternalDataPointer, FIndex, @Result) then
    Result := 0;
end;

function Tv8FunctionArg.AsInt64: Int64;
begin
  if not v8_FunctionCallbackInfo_arg_as_int64(FInternalDataPointer, FIndex, @Result) then
    Result := 0;
end;

function Tv8FunctionArg.AsInteger: Integer;
begin
  if not v8_FunctionCallbackInfo_arg_as_int32(FInternalDataPointer, FIndex, @Result) then
    Result := 0;
end;

function Tv8FunctionArg.AsObject: Iv8Object;
var
  obj: V8Object;
begin
  obj := v8_FunctionCallbackInfo_arg_as_object(FInternalDataPointer, FIndex);

  if Assigned(obj) then
    Result := Tv8Object.Create(obj)
  else
    Result := nil;
end;

function Tv8FunctionArg.AsString: string;
var
  v8str: Pointer;
begin
  v8str := v8_FunctionCallbackInfo_arg_as_str(FInternalDataPointer, FIndex);
  Result := ConvertInternalString(v8str);
  v8_destroy_string(v8str);
end;

function Tv8FunctionArg.AsUInt32: UInt32;
begin
  if not v8_FunctionCallbackInfo_arg_as_uint32(FInternalDataPointer, FIndex, @Result) then
    Result := 0;
end;

constructor Tv8FunctionArg.Create(_internal: V8FunctionCallbackInfo; _index: Integer);
begin
  FInternalDataPointer := _internal;
  FIndex := _index;
end;

{ Tv8ObjectTemplate }

function Tv8ObjectTemplate.AddMethod(const name: RawByteString; func: V8FunctionCallback; data: Pointer): Boolean;
begin
  Result := v8_object_template_add_method(nil, nil, FInternalDataPointer, PAnsiChar(name), func, data);
end;

constructor Tv8ObjectTemplate.Create(InternalFieldCount: Integer);
begin
  inherited Create;
  FInternalDataPointer := v8_new_object_template(nil, InternalFieldCount);
end;

function Tv8ObjectTemplate.CreateInstance(FirstInternalField: Pointer): Iv8Object;
var
  obj: V8Object;
begin
  obj := v8_new_object(nil, nil, FInternalDataPointer, FirstInternalField);

  if Assigned(obj) then
    Result := Tv8Object.Create(obj)
  else
    Result := nil;
end;

destructor Tv8ObjectTemplate.Destroy;
begin
  v8_destroy_object_template(FInternalDataPointer);
  inherited;
end;

{ Tv8Object }

constructor Tv8Object.Create(_obj: V8Object);
begin
  inherited Create;
  FInternalObject := _obj;
end;

destructor Tv8Object.Destroy;
begin
  v8_destroy_object(FInternalObject);
  inherited;
end;

function Tv8Object.GetFloat(const name: UnicodeString): Double;
begin
  v8_object_get_float_field(FInternalObject, PWideChar(name), @Result);
end;

function Tv8Object.GetInt32(const name: UnicodeString): Int32;
begin
  Result := v8_object_get_int32_field(FInternalObject, PWideChar(name), 0);
end;

function Tv8Object.GetInt64(const name: UnicodeString): Int64;
begin
  v8_object_get_int64_field(FInternalObject, PWideChar(name), @Result);
end;

function Tv8Object.GetInternalField(idx: Integer): Pointer;
begin
  Result := v8_object_get_internal_field(FInternalObject, idx);
end;

function Tv8Object.GetInternalFieldCount: Integer;
begin
  Result := v8_object_internal_field_count(FInternalObject);
end;

function Tv8Object.GetInternalObject: V8Object;
begin
  Result := FInternalObject;
end;

function Tv8Object.GetObject(const name: UnicodeString): Iv8Object;
var
  v8boj: V8Object;
begin
  v8boj := v8_object_get_object_field(FInternalObject, PWideChar(name));

  if Assigned(v8boj) then
    Result := Tv8Object.Create(v8boj)
  else
    Result := nil;
end;

function Tv8Object.GetStr(const name: UnicodeString): UnicodeString;
var
  v8s: V8String;
begin
  v8s := v8_object_get_string_field(FInternalObject, PWideChar(name));

  if Assigned(v8s) then
  begin
    Result := ConvertInternalString(v8s);
    v8_destroy_string(v8s);
  end
  else
    Result := '';
end;

function Tv8Object.GetUInt32(const name: UnicodeString): UInt32;
begin
  Result := v8_object_get_uint32_field(FInternalObject, PWideChar(name), 0);
end;

procedure Tv8Object.SetInternalField(idx: Integer; value: Pointer);
begin
  v8_object_set_internal_field(FInternalObject, idx, value);
end;

procedure Tv8Object.SetObject(const name: UnicodeString; value: Iv8Object);
begin
  v8_set_object(nil, nil, PWideChar(name), FInternalObject, value.GetInternalObject);
end;

{ Tv8Engine }

constructor Tv8Engine.Create;
begin
  FIsolate := v8_new_isolate;
  v8_enter_isolate(FIsolate);
  FContext := v8_new_context(FIsolate);
  v8_leave_isolate(FIsolate);
end;

destructor Tv8Engine.Destroy;
begin
  v8_destroy_context(FContext);
  v8_destroy_isolate(FIsolate);
  inherited;
end;

procedure Tv8Engine.enter;
begin
  v8_enter_isolate(FIsolate);
  v8_enter_context(FContext);
end;

function Tv8Engine.eval(const code: string): string;
var
  v8result: V8String;
begin
  v8result := v8_eval_asstr(FIsolate, FContext, PWideChar(code));
  if Assigned(v8result) then
  begin
    Result := ConvertInternalString(v8result);
    v8_destroy_string(v8result);
  end
  else
    Result := '';
end;

function Tv8Engine.GlobalObject: Iv8Object;
var
  obj: V8Object;
begin
  obj := v8_global_object(FContext);
  Result := Tv8Object.Create(obj);
end;

procedure Tv8Engine.leave;
begin
  v8_leave_context(FContext);
  v8_leave_isolate(FIsolate);
end;

function Tv8Engine.RegisterNativeFunction(const name: RawByteString; func: V8FunctionCallback; data: Pointer): Boolean;
begin
  Result := v8_register_native_function(FIsolate, FContext, PAnsiChar(name), func, data);
end;


procedure CallDelphiMethod(_info: V8FunctionCallbackInfo); cdecl;
var
  info: Tv8FunctionCallbackInfo;
  methods: TArray<TRttiMethod>;
  method: TRttiMethod;
  dobj: TObject;
  parameters: TArray<TRttiParameter>;
  parameter: TRttiParameter;
  ParamType: TRttiType;
  i, nParams: Integer;
  values: TArray<TValue>;
  ReturnValue: TValue;
  str: string;
  rttictx: TRttiContext;
  rttiType: TRttiType;
  CodeAddress: Pointer;

  procedure getMethodByCodeAddress;
  var
    tmp: TRttiMethod;
  begin
    methods := rttiType.GetDeclaredMethods;
    for tmp in methods do
      if tmp.CodeAddress = CodeAddress then
      begin
        method := tmp;
        Break;
      end;
  end;
begin
  method := nil;
  info := Tv8FunctionCallbackInfo.Create(_info);
  dobj := TObject(info.GetInternalField);
  rttictx := TRttiContext.Create;
  rttiType := rttictx.GetType(dobj.ClassType);
  CodeAddress := v8_FunctionCallbackInfo_data(_info);
  getMethodByCodeAddress;

  if not Assigned(method) then
  begin
    v8_throw_exception(V8_REFERENCE_ERROR, 'method not found!');
    Exit;
  end;

  parameters := method.GetParameters;
  nParams := Length(parameters);

  if nParams > info.ArgCount then
  begin
    v8_throw_exception(V8_TYPE_ERROR, 'no enough parameters!');
    Exit;
  end;

  SetLength(values, nParams);

  for i := 0 to nParams - 1 do
  begin
    parameter := parameters[i];
    ParamType := parameter.ParamType;
    case ParamType.TypeKind of
      tkInteger: values[i] := TValue.From(info.args[i].AsInteger);
      tkFloat: values[i] := TValue.From(info.args[i].AsFloat);
      tkString, tkLString, tkWString, tkUString, tkVariant: values[i] := TValue.From(info.args[i].AsString);
      tkInt64: values[i] := TValue.From(info.args[i].AsInt64);
      else begin
        v8_throw_exception(V8_TYPE_ERROR, 'parameter type dismatch!');
        Exit;
      end;
    end;
  end;

  ReturnValue := method.Invoke(dobj, values);

  if Assigned(method.ReturnType) then
  begin
    case method.ReturnType.TypeKind of
      tkInteger: v8_FunctionCallbackInfo_return_int32(_info, ReturnValue.AsInteger);
      tkFloat: v8_FunctionCallbackInfo_return_float(_info, ReturnValue.AsExtended);

      tkString, tkLString, tkWString, tkUString, tkVariant:
        begin
          str := ReturnValue.AsString;
          v8_FunctionCallbackInfo_return_string(_info, PWideChar(str));
        end;

      tkInt64: v8_FunctionCallbackInfo_return_float(_info, ReturnValue.AsExtended);
    end;
  end;
end;

function Tv8Engine.RegisterRttiClass(_ClassType: TClass): Tv8ObjectTemplate;
var
  rttictx: TRttiContext;
  rttiType: TRttiType;
  methods: TArray<TRttiMethod>;
  method: TRttiMethod;
begin
  rttictx := TRttiContext.Create;
  rttiType := rttictx.GetType(_ClassType);
  Result := Tv8ObjectTemplate.Create(1);
  methods := rttiType.GetDeclaredMethods;

  for method in methods do
    if method.MethodKind in [mkProcedure, mkFunction, mkOperatorOverload] then
      Result.AddMethod(RawByteString(method.Name), CallDelphiMethod, method.CodeAddress);
end;

end.
