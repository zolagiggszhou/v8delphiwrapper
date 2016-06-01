#include "stdafx.h"
#include "v8dll.h"

using namespace v8;

#define LocalStringFromUtf8(isolate, s) (String::NewFromUtf8(isolate, s, NewStringType::kNormal).ToLocalChecked())
#define LocalString(isolate, s) (String::NewFromTwoByte(isolate, (const uint16_t*)s, NewStringType::kNormal).ToLocalChecked())

Platform* v8Platform;

class SimpleArrayBufferAllocator : public ArrayBuffer::Allocator {
public:
	virtual void* Allocate(size_t length) {
		void* data = AllocateUninitialized(length);
		return data == nullptr ? data : memset(data, 0, length);
	}
	virtual void* AllocateUninitialized(size_t length) { return malloc(length); }
	virtual void Free(void* data, size_t) { free(data); }
};

SimpleArrayBufferAllocator array_buffer_allocator;

BOOL __stdcall v8_init() {
	if (!V8::InitializeICU())
		return FALSE;

	OutputDebugStringA("InitializeICU ok");

	v8Platform = platform::CreateDefaultPlatform();

	if (!v8Platform)
		return FALSE;

	OutputDebugStringA("CreateDefaultPlatform ok");

	V8::InitializePlatform(v8Platform);

	OutputDebugStringA("InitializePlatform ok");

	if (!V8::Initialize())
	{
		OutputDebugStringA("Initialize fail");
		delete v8Platform;
		v8Platform = nullptr;
		return FALSE;
	}

	return TRUE;
}

void __stdcall v8_cleanup() {
	V8::Dispose();
	V8::ShutdownPlatform();
	delete v8Platform;
	v8Platform = nullptr;
}

V8Isolate __stdcall v8_new_isolate() {
	Isolate::CreateParams create_params;
	create_params.array_buffer_allocator = &array_buffer_allocator;
	return (V8Isolate)Isolate::New(create_params);
}

void __stdcall v8_destroy_isolate(V8Isolate isolate) {
	((Isolate*)isolate)->Dispose();
}

void __stdcall v8_enter_isolate(V8Isolate isolate) {
	((Isolate*)isolate)->Enter();
}

void __stdcall v8_leave_isolate(V8Isolate isolate) {
	((Isolate*)isolate)->Exit();
}

void __stdcall v8_throw_exception(int type, const uint16_t* errmsg)
{
	Isolate* isolate = Isolate::GetCurrent();
	HandleScope scope(isolate);
	switch (type) {
	case V8_RANGE_ERROR:
		isolate->ThrowException(Exception::RangeError(LocalString(isolate, errmsg)));
		break;

	case V8_REFERENCE_ERROR:
		isolate->ThrowException(Exception::ReferenceError(LocalString(isolate, errmsg)));
		break;

	case V8_SYNTAX_ERROR:
		isolate->ThrowException(Exception::SyntaxError(LocalString(isolate, errmsg)));
		break;

	case V8_TYPE_ERROR:
		isolate->ThrowException(Exception::TypeError(LocalString(isolate, errmsg)));
		break;

	default:
		isolate->ThrowException(Exception::Error(LocalString(isolate, errmsg)));
		break;
	}
}

V8Context __stdcall v8_new_context(V8Isolate _isolate) {
	Isolate* isolate = (Isolate*)_isolate;
	HandleScope handle_scope(isolate);
	Local<Context> context = Context::New(isolate);
	return new Global<Context>(isolate, context);
}

void __stdcall v8_enter_context(V8Context _context) {
	auto context = (Global<Context>*)_context;
	auto isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	Local<Context> lcontext = Local<Context>::New(isolate, *context);
	lcontext->Enter();
}

void __stdcall v8_leave_context(V8Context _context) {
	auto context = (Global<Context>*)_context;
	auto isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	Local<Context> lcontext = Local<Context>::New(isolate, *context);
	lcontext->Exit();
}


void __stdcall v8_destroy_context(V8Context context) {
	delete (Global<Context>*)context;
}

V8Object __stdcall v8_global_object(V8Context _context) {
	auto context = (Global<Context>*)_context;
	auto isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	Local<Context> lcontext = Local<Context>::New(isolate, *context);
	return (V8Object)new Global<Object>(isolate, lcontext->Global());
}

const uint16_t* __stdcall v8_strinfo(V8String _str, int* len)
{
	auto str = (String::Value*)_str;
	if (len)
		*len = str->length();
	return **str;
}

String::Value* __stdcall v8_val_to_string(const Local<Value>* value)
{
	return new String::Value(*value);
}

void __stdcall v8_destroy_string(V8String p)
{
	delete (String::Value*)p;
}

const char* ToCString(const String::Utf8Value& value) {
	return *value ? *value : "<string conversion failed>";
}

void ReportException(Isolate* isolate, TryCatch* try_catch) {
	HandleScope handle_scope(isolate);
	String::Utf8Value exception(try_catch->Exception());

	const char* exception_string = ToCString(exception);
	Local<Message> message = try_catch->Message();
	if (message.IsEmpty()) {
		// V8 didn't provide any extra information about this error; just
		// print the exception.
		OutputDebugStringA(exception_string);
	}
	else {
		// Print (filename):(line number): (message).
		String::Utf8Value filename(message->GetScriptOrigin().ResourceName());
		Local<Context> context(isolate->GetCurrentContext());
		const char* filename_string = ToCString(filename);
		int linenum = message->GetLineNumber(context).FromJust();

		char buf[4096];
		sprintf_s(buf, "%s:%i: %s\n", filename_string, linenum, exception_string);
		OutputDebugStringA(buf);
		// Print line of source code.
		String::Utf8Value sourceline(
			message->GetSourceLine(context).ToLocalChecked());
		const char* sourceline_string = ToCString(sourceline);
		OutputDebugStringA(sourceline_string);
		// Print wavy underline (GetUnderline is deprecated).
		int start = message->GetStartColumn(context).FromJust();
		for (int i = 0; i < start; i++) {
			OutputDebugStringA(" ");
		}
		int end = message->GetEndColumn(context).FromJust();
		for (int i = start; i < end; i++) {
			OutputDebugStringA("^");
		}
		OutputDebugStringA("\n");
		Local<Value> stack_trace_string;
		if (try_catch->StackTrace(context).ToLocal(&stack_trace_string) &&
			stack_trace_string->IsString() &&
			Local<String>::Cast(stack_trace_string)->Length() > 0) {
			String::Utf8Value stack_trace(stack_trace_string);
			const char* stack_trace_string = ToCString(stack_trace);
			OutputDebugStringA(stack_trace_string);
		}
	}
}

V8String __stdcall v8_eval_asstr(V8Isolate _isolate, V8Context _context, const uint16_t* code)
{
	auto isolate = (Isolate*)_isolate;
	auto context = (Global<Context>*)_context;
	if (!isolate)
		isolate = Isolate::GetCurrent();

	if (!isolate)
		return nullptr;

	HandleScope handle_scope(isolate);

	Local<Context> lcontext;

	if (context)
		lcontext = Local<Context>::New(isolate, *context);
	else
		lcontext = isolate->GetCurrentContext();

	Context::Scope context_scope(lcontext);
	TryCatch tryCatch(isolate);
	Local<String> source = LocalString(isolate, code);

	MaybeLocal<Script> script = Script::Compile(lcontext, source);

	if (script.IsEmpty())
	{
		OutputDebugStringA("Compile error");
		ReportException(isolate, &tryCatch);
		return (V8String)new String::Value(tryCatch.Exception());
	}

	MaybeLocal<Value> result = script.ToLocalChecked()->Run(lcontext);

	if (result.IsEmpty())
	{
		OutputDebugStringA("Run error");
		ReportException(isolate, &tryCatch);
		return (V8String)new String::Value(tryCatch.Exception());
	}

	auto lresult = result.ToLocalChecked();
	return (V8String)v8_val_to_string(&lresult);
}

BOOL __stdcall v8_set_object(
	V8Isolate _isolate,
	V8Context _context,
	const uint16_t* propName,
	V8Object _owner,
	V8Object _propValue) {

	auto isolate = (Isolate*)_isolate;
	auto context = (Global<Context>*)_context;
	auto owner = (Global<Object>*)_owner;
	auto propValue = (Global<Object>*)_propValue;

	if (!isolate)
		isolate = Isolate::GetCurrent();

	if (!isolate)
		return FALSE;

	HandleScope handle_scope(isolate);
	Local<Context> lcontext;

	if (context)
		lcontext = Local<Context>::New(isolate, *context);
	else
		lcontext = isolate->GetCurrentContext();

	Context::Scope context_scope(lcontext);
	Local<Object> obj;
	if (owner)
		obj = Local<Object>::New(isolate, *owner);
	else
		obj = lcontext->Global();

	auto result = obj->Set(lcontext, LocalString(isolate, propName), Local<Object>::New(isolate, *propValue));

	return result.FromMaybe(false);
}

BOOL __stdcall v8_register_native_function(
	V8Isolate _isolate,
	V8Context _context,
	const char* funcname,
	V8FunctionCallback func,
	const void* data) {
	auto isolate = (Isolate*)_isolate;
	auto context = (Global<Context>*)_context;
	if (!isolate)
		isolate = Isolate::GetCurrent();

	if (!isolate)
		return FALSE;

	HandleScope handle_scope(isolate);
	Local<Context> lcontext;

	if (context)
		lcontext = Local<Context>::New(isolate, *context);
	else
		lcontext = isolate->GetCurrentContext();
	Context::Scope context_scope(lcontext);
	Local<Object> global = lcontext->Global();
	auto result = global->Set(lcontext, LocalStringFromUtf8(isolate, funcname),
		Function::New(lcontext, (FunctionCallback)func, External::New(isolate, (void*)data)).ToLocalChecked());

	return result.FromMaybe(false);
}

void* __stdcall v8_FunctionCallbackInfo_data(const V8FunctionCallbackInfo _info) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	auto data = info->Data();
	if (data->IsExternal())
	{
		auto tmp = Local<External>::Cast(data);
		return tmp->Value();
	}
	else
		return nullptr;
}

V8Object __stdcall v8_FunctionCallbackInfo_this(const V8FunctionCallbackInfo _info) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	auto isolate = info->GetIsolate();
	HandleScope handleScope(isolate);
	return new Global<Object>(isolate, info->This());
}

void* __stdcall v8_FunctionCallbackInfo_internal_field(const V8FunctionCallbackInfo _info, int idx) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	HandleScope handleScope(info->GetIsolate());
	Local<Object> holder = info->Holder();
	if (holder->InternalFieldCount() > idx) {
		Local<External> field = Local<External>::Cast(holder->GetInternalField(idx));
		if (field.IsEmpty())
			return nullptr;
		else
			return field->Value();
	}
	else
		return nullptr;
}

int32_t __stdcall v8_FunctionCallbackInfo_arg_count(const V8FunctionCallbackInfo _info)
{
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	return info->Length();
}

V8String __stdcall v8_FunctionCallbackInfo_arg_as_str(const V8FunctionCallbackInfo _info, int idx) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	auto arg = (*info)[idx];
	return (V8String)v8_val_to_string(&arg);
}

BOOL __stdcall v8_FunctionCallbackInfo_arg_as_int32(
	const V8FunctionCallbackInfo _info,
	int idx, int32_t* result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	auto isolate = info->GetIsolate();
	HandleScope handleScope(isolate);
	auto arg = (*info)[idx];
	auto value = arg->Int32Value(isolate->GetCurrentContext());

	if (value.IsJust())
	{
		if (result)
			*result = value.FromJust();
		return TRUE;
	}
	else
	{
		return false;
	}
}

BOOL __stdcall v8_FunctionCallbackInfo_arg_as_uint32(
	const V8FunctionCallbackInfo _info,
	int idx, uint32_t* result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	auto isolate = info->GetIsolate();
	HandleScope handleScope(isolate);
	auto arg = (*info)[idx];
	auto value = arg->Uint32Value(isolate->GetCurrentContext());
	if (value.IsJust())
	{
		if (result)
			*result = value.FromJust();
		return TRUE;
	}
	else
	{
		return false;
	}
}

BOOL __stdcall v8_FunctionCallbackInfo_arg_as_int64(
	const V8FunctionCallbackInfo _info,
	int idx, int64_t* result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	auto isolate = info->GetIsolate();
	HandleScope handleScope(isolate);
	auto arg = (*info)[idx];
	auto value = arg->IntegerValue(isolate->GetCurrentContext());

	if (value.IsJust())
	{
		if (result)
			*result = value.FromJust();
		return TRUE;
	}
	else
	{
		return false;
	}
}

BOOL __stdcall v8_FunctionCallbackInfo_arg_as_float(
	const V8FunctionCallbackInfo _info,
	int idx, double* result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	auto isolate = info->GetIsolate();
	HandleScope handleScope(isolate);
	auto arg = (*info)[idx];
	auto value = arg->NumberValue(isolate->GetCurrentContext());

	if (value.IsJust())
	{
		if (result)
			*result = value.FromJust();
		return TRUE;
	}
	else
	{
		return false;
	}
}

V8Object __stdcall v8_FunctionCallbackInfo_arg_as_object(const V8FunctionCallbackInfo _info, int idx)
{
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	auto isolate = info->GetIsolate();
	HandleScope handleScope(isolate);
	auto context = isolate->GetCurrentContext();
	auto arg = (*info)[idx];
	auto tmp = arg->ToObject(context);
	if (tmp.IsEmpty())
		return nullptr;
	else
		return (V8Object)new Global<Object>(isolate, tmp.ToLocalChecked());
}

void __stdcall v8_FunctionCallbackInfo_return_int32(const V8FunctionCallbackInfo _info, int32_t result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	info->GetReturnValue().Set(result);
}

void __stdcall v8_FunctionCallbackInfo_return_uint32(const V8FunctionCallbackInfo _info, uint32_t result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	info->GetReturnValue().Set(result);
}

void __stdcall v8_FunctionCallbackInfo_return_int64(const V8FunctionCallbackInfo _info, int64_t* result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	info->GetReturnValue().Set(Number::New(info->GetIsolate(), (double)*result));
}

void __stdcall v8_FunctionCallbackInfo_return_float(const V8FunctionCallbackInfo _info, double result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	info->GetReturnValue().Set(result);
}

void __stdcall v8_FunctionCallbackInfo_return_string(const V8FunctionCallbackInfo _info, const uint16_t* result) {
	auto info = (const FunctionCallbackInfo<v8::Value>*)_info;
	info->GetReturnValue().Set(LocalString(info->GetIsolate(), result));
}

V8ObjectTemplate __stdcall v8_new_object_template(V8Isolate _isolate, int InternalFieldCount) {
	auto isolate = (Isolate*)_isolate;
	if (!isolate)
		isolate = Isolate::GetCurrent();

	if (!isolate)
		return nullptr;

	HandleScope handle_scope(isolate);
	Local<ObjectTemplate> objTemplate = ObjectTemplate::New(isolate);
	objTemplate->SetInternalFieldCount(InternalFieldCount);
	return (V8ObjectTemplate)new Global<ObjectTemplate>(isolate, objTemplate);
}

void __stdcall v8_destroy_object_template(V8ObjectTemplate objTemplate) {
	delete (Global<ObjectTemplate>*)objTemplate;
}

BOOL __stdcall v8_object_template_add_method(V8Isolate _isolate, V8Context _context, V8ObjectTemplate _objTemplate,
	const char* name, V8FunctionCallback func, const void* data) {
	auto isolate = (Isolate*)_isolate;
	auto context = (Global<Context>*)_context;
	auto objTemplate = (Global<ObjectTemplate>*)_objTemplate;
	if (!isolate)
		isolate = Isolate::GetCurrent();

	if (!isolate)
		return FALSE;

	HandleScope handle_scope(isolate);
	Local<ObjectTemplate> tmpl = Local<ObjectTemplate>::New(isolate, *objTemplate);

	Local<Context> lcontext;

	if (context)
		lcontext = Local<Context>::New(isolate, *context);
	else
		lcontext = isolate->GetCurrentContext();

	Context::Scope context_scope(lcontext);
	auto funcObj = Function::New(lcontext, (FunctionCallback)func, External::New(isolate, (void*)data));

	if (funcObj.IsEmpty())
		return FALSE;
	else {
		tmpl->Set(isolate, name, funcObj.ToLocalChecked());
		return TRUE;
	}
}

V8Object __stdcall v8_new_object(V8Isolate _isolate, V8Context _context,
	V8ObjectTemplate _objTemplate, void* FirstInternalField) {
	auto isolate = (Isolate*)_isolate;
	auto context = (Global<Context>*)_context;
	auto objTemplate = (Global<ObjectTemplate>*)_objTemplate;
	if (!isolate)
		isolate = Isolate::GetCurrent();

	if (!isolate)
		return nullptr;

	HandleScope handle_scope(isolate);
	Local<Context> lcontext;

	if (context)
		lcontext = Local<Context>::New(isolate, *context);
	else
		lcontext = isolate->GetCurrentContext();
	Context::Scope context_scope(lcontext);
	Local<ObjectTemplate> tmpl = Local<ObjectTemplate>::New(isolate, *objTemplate);
	auto obj = tmpl->NewInstance(lcontext);

	if (obj.IsEmpty())
		return nullptr;
	else {
		auto result = obj.ToLocalChecked();

		if (result->InternalFieldCount() > 0)
			result->SetInternalField(0, External::New(isolate, FirstInternalField));

		return new Global<Object>(isolate, result);
	}
}

void __stdcall v8_destroy_object(V8Object obj) {
	delete (Global<Object>*)obj;
}

int __stdcall v8_object_internal_field_count(V8Object _obj) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	Local<Object> lobj = Local<Object>::New(isolate, *obj);
	return lobj->InternalFieldCount();
}

void* __stdcall v8_object_get_internal_field(V8Object _obj, int idx) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	Local<Object> lobj = Local<Object>::New(isolate, *obj);

	if (lobj->InternalFieldCount() > idx) {
		Local<External> field = Local<External>::Cast(lobj->GetInternalField(idx));
		if (field.IsEmpty())
			return nullptr;
		else
			return field->Value();
	}
	else
		return nullptr;
}

void __stdcall v8_object_set_internal_field(V8Object _obj, int idx, void* value) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	Local<Object> lobj = Local<Object>::New(isolate, *obj);

	if (lobj->InternalFieldCount() > idx)
		lobj->SetInternalField(idx, External::New(isolate, value));
}

int32_t __stdcall v8_object_get_int32_field(V8Object _obj, const uint16_t* name, int32_t defValue) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	auto context = isolate->GetCurrentContext();
	Local<Object> lobj = Local<Object>::New(isolate, *obj);
	auto result = lobj->Get(isolate->GetCurrentContext(), LocalString(isolate, name));
	if (result.IsEmpty())
		return defValue;
	else {
		auto tmp = result.ToLocalChecked()->Int32Value(context);
		if (tmp.IsJust())
			return tmp.FromJust();
		else
			return defValue;
	}
}

uint32_t __stdcall v8_object_get_uint32_field(V8Object _obj, const uint16_t* name, uint32_t defValue) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	auto context = isolate->GetCurrentContext();
	Local<Object> lobj = Local<Object>::New(isolate, *obj);
	auto result = lobj->Get(isolate->GetCurrentContext(), LocalString(isolate, name));
	if (result.IsEmpty())
		return defValue;
	else {
		auto tmp = result.ToLocalChecked()->Uint32Value(context);
		if (tmp.IsJust())
			return tmp.FromJust();
		else
			return defValue;
	}
}

BOOL __stdcall v8_object_get_float_field(V8Object _obj, const uint16_t* name, double* value) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	auto context = isolate->GetCurrentContext();
	Local<Object> lobj = Local<Object>::New(isolate, *obj);
	auto result = lobj->Get(context, LocalString(isolate, name));
	if (result.IsEmpty())
		return false;
	else {
		auto tmp = result.ToLocalChecked()->NumberValue(context);
		if (tmp.IsJust())
		{
			*value = tmp.FromJust();
			return true;
		}
		else
			return false;
	}
}

BOOL __stdcall v8_object_get_int64_field(V8Object _obj, const uint16_t* name, int64_t* value) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	auto context = isolate->GetCurrentContext();
	Local<Object> lobj = Local<Object>::New(isolate, *obj);
	auto result = lobj->Get(context, LocalString(isolate, name));
	if (result.IsEmpty())
		return false;
	else {
		auto tmp = result.ToLocalChecked()->IntegerValue(context);
		if (tmp.IsJust())
		{
			*value = tmp.FromJust();
			return true;
		}
		else
			return false;
	}
}

V8String __stdcall v8_object_get_string_field(V8Object _obj, const uint16_t* name) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	auto context = isolate->GetCurrentContext();
	Local<Object> lobj = Local<Object>::New(isolate, *obj);
	auto result = lobj->Get(context, LocalString(isolate, name));
	if (result.IsEmpty())
		return nullptr;
	else {
		auto tmp = result.ToLocalChecked();
		return v8_val_to_string(&tmp);
	}
}

V8Object __stdcall v8_object_get_object_field(V8Object _obj, const uint16_t* name) {
	auto obj = (Global<Object>*)_obj;
	Isolate *isolate = Isolate::GetCurrent();
	HandleScope handleScope(isolate);
	auto context = isolate->GetCurrentContext();
	Local<Object> lobj = Local<Object>::New(isolate, *obj);
	auto result = lobj->Get(context, LocalString(isolate, name));
	if (result.IsEmpty())
		return nullptr;
	else {
		auto tmp = result.ToLocalChecked()->ToObject(context);
		if (tmp.IsEmpty())
			return nullptr;
		else
			return (V8Object)new Global<Object>(isolate, tmp.ToLocalChecked());
	}
}
