#include <sdk/luashared.h>
#include <sdk/tier0.h>

#include <string>

ModuleContext* luaSharedDLL = 0;
ILuaShared* luaShared = 0;
ILuaInterface* luaInterface = 0;

luaL_loadbufferFn luaL_loadbuffer = 0;
lua_setfenvFn lua_setfenv = 0;

static VTableContext* luaSharedVT = 0;
static VTableContext* luaInterfaceVT = 0;

static bool isLoaded = false;
extern void OnScriptLoad();
extern void OnScriptClose();

void LoadScript()
{
	Msg("[morda] Loading main script.\n");

	FILE* f = fopen("morda.lua", "rb");
	uint32 fs = 0;

	fseek(f, 0, SEEK_END);
	fs = ftell(f);
	rewind(f);

	char* script = new char[fs];
	fread(script, fs, 1, f);
	
	if (luaL_loadbuffer(luaInterface->GetLuaState(), script, fs, ""))
	{
		const char* err = luaInterface->GetString(-1);
		luaInterface->Pop();

		Msg("[morda] Lua Error: %s\n", err);

		return;
	}

	delete[] script;

	luaInterface->PushSpecial(SPECIAL_GLOB);
		luaInterface->CreateTable();
			OnScriptLoad();
		luaInterface->SetField(-2, "morda");
	luaInterface->Pop();
	
	if (luaInterface->PCall(0, 0, 0))
	{
		const char* err = luaInterface->GetString(-1);
		luaInterface->Pop();

		Msg("[morda] Lua Error: %s\n", err);
	}

	luaInterface->PushSpecial(SPECIAL_GLOB);
		luaInterface->GetField(-1, "morda");
		luaInterface->GetField(-1, "Init");
		luaInterface->Call(0, 0);
	luaInterface->Pop(2);
}

typedef bool(__thiscall* RunStringExFn)(ILuaInterface*, const char*, const char*, const char*, bool, bool, bool, bool);
static RunStringExFn origRunStringEx = 0;
static bool __fastcall HookRunStringEx(ILuaInterface* thisptr, int, const char* filename, const char* path, const char* buf, bool b1, bool b2, bool b3, bool b4)
{
	if (!isLoaded)
	{
		if (!strcmp(filename, "Startup"))
		{
			LoadScript();
			isLoaded = true;
		}
	}
	
	return origRunStringEx(thisptr, filename, path, buf, b1, b2, b3, b4);;
}

typedef ILuaInterface* (__thiscall* CreateLuaInterfaceFn)(ILuaShared*, uint8, bool);
static CreateLuaInterfaceFn origCreateLuaInterface = 0;
static ILuaInterface* __fastcall HookCreateLuaInterface(ILuaShared* thisptr, int, uint8 realm, bool x)
{
	ILuaInterface* lua = origCreateLuaInterface(thisptr, realm, x);

	if (realm == 0)
	{
		luaInterface = lua;
		isLoaded = false;

		luaInterfaceVT = CreateVTableContext(lua);
			HookVTableFunction(luaInterfaceVT, HookRunStringEx, LUAINTERFACE_RUNSTRINGEX_INDEX);
			origRunStringEx = (RunStringExFn)GetOriginalVTableFunction(luaInterfaceVT, LUAINTERFACE_RUNSTRINGEX_INDEX);
		SwapVTableCopy(luaInterfaceVT);
	}

	return lua;
}

typedef void (__thiscall* CloseLuaInterfaceFn)(ILuaShared*, ILuaInterface*);
static CloseLuaInterfaceFn origCloseLuaInterface = 0;
static void __fastcall HookCloseLuaInterface(ILuaShared* thisptr, int, ILuaInterface* lua)
{
	if (lua == luaInterface)
	{
		if (luaInterfaceVT)
		{
			SwapVTableOrig(luaInterfaceVT);
			RemoveVTableContext(luaInterfaceVT);
			OnScriptClose();
		}

		luaInterface = 0;
	}

	origCloseLuaInterface(thisptr, lua);
}

bool LinkLuaShared()
{
	luaSharedDLL = CreateModuleContext("lua_shared.dll", true);
	if (!luaSharedDLL)
	{
		return false;
	}

	luaL_loadbuffer = (luaL_loadbufferFn)GetModuleSymbol(luaSharedDLL, "luaL_loadbuffer");
	lua_setfenv = (lua_setfenvFn)GetModuleSymbol(luaSharedDLL, "lua_setfenv");

	luaShared = (ILuaShared*)GetModuleInterface(luaSharedDLL, LUASHARED_VERSION);
	if (!luaShared)
	{
		return false;
	}

	luaSharedVT = CreateVTableContext(luaShared);
		HookVTableFunction(luaSharedVT, HookCreateLuaInterface, LUASHARED_CREATELUAINTERFACE_INDEX);
		origCreateLuaInterface = (CreateLuaInterfaceFn)GetOriginalVTableFunction(luaSharedVT, LUASHARED_CREATELUAINTERFACE_INDEX);

		HookVTableFunction(luaSharedVT, HookCloseLuaInterface, LUASHARED_CLOSELUAINTERFACE_INDEX);
		origCloseLuaInterface = (CloseLuaInterfaceFn)GetOriginalVTableFunction(luaSharedVT, LUASHARED_CLOSELUAINTERFACE_INDEX);
	SwapVTableCopy(luaSharedVT);

	return true;
}