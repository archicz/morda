#ifndef SDK_LUASHARED_H
#define SDK_LUASHARED_H
#pragma once

#include <raze/memory.h>
#include <GarrysMod/Lua/Interface.h>
using namespace GarrysMod::Lua;

#define LUASHARED_CREATELUAINTERFACE_INDEX 4
#define LUASHARED_CLOSELUAINTERFACE_INDEX 5
#define LUASHARED_VERSION "LUASHARED003"

#define LUAINTERFACE_RUNSTRINGEX_INDEX 111

class ILuaInterface : public ILuaBase
{
public:
	lua_State* GetLuaState()
	{
		return *reinterpret_cast<lua_State**>(this + 1);
	}
};

class ILuaShared;

extern ModuleContext* luaSharedDLL;
extern ILuaShared* luaShared;
extern ILuaInterface* luaInterface;

typedef int (*luaL_loadbufferFn)(lua_State* L, const char* buff, size_t sz, const char* name);
extern luaL_loadbufferFn luaL_loadbuffer;

typedef int (*lua_setfenvFn)(lua_State* L, int index);
extern lua_setfenvFn lua_setfenv;

bool LinkLuaShared();
void LoadScript();

#define ADD_LUA_FUNC(name) \
luaInterface->PushCFunction(name##LUA); \
luaInterface->SetField(-2, #name); \

#endif