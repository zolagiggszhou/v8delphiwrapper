#pragma once
#include "windows.h"

#define V8_ERROR 0
#define V8_RANGE_ERROR 1
#define V8_REFERENCE_ERROR 2
#define V8_SYNTAX_ERROR 3
#define V8_TYPE_ERROR 4

typedef void* V8Isolate;
typedef void* V8Context;
typedef void* V8String;
typedef void* V8Object;
typedef void* V8ObjectTemplate;
typedef void* V8FunctionCallbackInfo;

typedef void(*V8FunctionCallback)(V8FunctionCallbackInfo info);

BOOL __stdcall v8_init();
void __stdcall v8_cleanup();
V8Isolate __stdcall v8_new_isolate();
void __stdcall v8_destroy_isolate(V8Isolate);
void __stdcall v8_enter_isolate(V8Isolate);
void __stdcall v8_leave_isolate(V8Isolate);
void __stdcall v8_throw_exception(int type, const uint16_t* errmsg);
V8Context __stdcall v8_new_context(V8Isolate);
void __stdcall v8_enter_context(V8Context);
void __stdcall v8_leave_context(V8Context);
void __stdcall v8_destroy_context(V8Context);
V8Object __stdcall v8_global_object(V8Context);
void __stdcall v8_destroy_string(V8String);
V8String __stdcall v8_eval_asstr(V8Isolate, V8Context, const uint16_t*);
const uint16_t* __stdcall v8_strinfo(V8String, int*);

BOOL __stdcall v8_set_object(
	V8Isolate isolate,
	V8Context context,
	const uint16_t* propName,
	V8Object owner,
	V8Object propValue);

BOOL __stdcall v8_register_native_function(
	V8Isolate isolate,
	V8Context context,
	const char* funcname,
	V8FunctionCallback func,
	const void* data);

void* __stdcall v8_FunctionCallbackInfo_data(const V8FunctionCallbackInfo info);
V8Object __stdcall v8_FunctionCallbackInfo_this(const V8FunctionCallbackInfo info);
void* __stdcall v8_FunctionCallbackInfo_internal_field(const V8FunctionCallbackInfo info, int idx);
int32_t __stdcall v8_FunctionCallbackInfo_arg_count(const V8FunctionCallbackInfo info);
V8String __stdcall v8_FunctionCallbackInfo_arg_as_str(const V8FunctionCallbackInfo info, int idx);
BOOL __stdcall v8_FunctionCallbackInfo_arg_as_int32(const V8FunctionCallbackInfo info,
	int idx, int32_t* result);

BOOL __stdcall v8_FunctionCallbackInfo_arg_as_uint32(const V8FunctionCallbackInfo info,
	int idx, uint32_t* result);

BOOL __stdcall v8_FunctionCallbackInfo_arg_as_int64(const V8FunctionCallbackInfo info,
	int idx, int64_t* result);

BOOL __stdcall v8_FunctionCallbackInfo_arg_as_float(const V8FunctionCallbackInfo info,
	int idx, double* result);

V8Object __stdcall v8_FunctionCallbackInfo_arg_as_object(const V8FunctionCallbackInfo info, int idx);

void __stdcall v8_FunctionCallbackInfo_return_int32(const V8FunctionCallbackInfo info, int32_t result);
void __stdcall v8_FunctionCallbackInfo_return_uint32(const V8FunctionCallbackInfo info, uint32_t result);
void __stdcall v8_FunctionCallbackInfo_return_int64(const V8FunctionCallbackInfo info, int64_t* result);
void __stdcall v8_FunctionCallbackInfo_return_float(const V8FunctionCallbackInfo info, double result);
void __stdcall v8_FunctionCallbackInfo_return_string(const V8FunctionCallbackInfo info, const uint16_t* result);

V8ObjectTemplate __stdcall v8_new_object_template(V8Isolate, int InternalFieldCount);
void __stdcall v8_destroy_object_template(V8ObjectTemplate objTemplate);

BOOL __stdcall v8_object_template_add_method(V8Isolate, V8Context,
	V8ObjectTemplate objTemplate,
	const char* name, V8FunctionCallback func, const void* data);

V8Object __stdcall v8_new_object(V8Isolate isolate, V8Context context,
	V8ObjectTemplate objTemplate, void* FirstInternalField);

void __stdcall v8_destroy_object(V8Object obj);
int __stdcall v8_object_internal_field_count(V8Object obj);
void* __stdcall v8_object_get_internal_field(V8Object obj, int idx);
void __stdcall v8_object_set_internal_field(V8Object obj, int idx, void* value);
int32_t __stdcall v8_object_get_int32_field(V8Object _obj, const uint16_t* name, int32_t defValue);
uint32_t __stdcall v8_object_get_uint32_field(V8Object _obj, const uint16_t* name, uint32_t defValue);
BOOL __stdcall v8_object_get_float_field(V8Object _obj, const uint16_t* name, double* value);
BOOL __stdcall v8_object_get_int64_field(V8Object _obj, const uint16_t* name, int64_t* value);
V8String __stdcall v8_object_get_string_field(V8Object _obj, const uint16_t* name);
V8Object __stdcall v8_object_get_object_field(V8Object _obj, const uint16_t* name);




