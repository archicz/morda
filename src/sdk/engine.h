#ifndef SDK_ENGINE_H
#define SDK_ENGINE_H
#pragma once

#include <raze/memory.h>
#include <sdk/netchan.h>
#include <sdk/math.h>

#define ENGINE_VERSION "VEngineClient013"
#define ENGINE_GETLOCALPLAYER_INDEX 12
#define ENGINE_ISINGAME_INDEX 26
#define ENGINE_ISCONNECTED_INDEX 27
#define ENGINE_GETNETCHANNELINFO_INDEX 72
#define ENGINE_ISPAUSED_INDEX 84

class IVEngineClient
{
public:
	int GetLocalPlayer()
	{
		return CallVFunction<int(__thiscall*)(void*)>(this, ENGINE_GETLOCALPLAYER_INDEX)(this);
	}

	bool IsInGame()
	{
		return CallVFunction<bool (__thiscall*)(void*)>(this, ENGINE_ISINGAME_INDEX)(this);
	}

	bool IsConnected()
	{
		return CallVFunction<bool (__thiscall*)(void*)>(this, ENGINE_ISCONNECTED_INDEX)(this);
	}
	
	INetChannel* GetNetChannel()
	{
		return CallVFunction<INetChannel* (__thiscall*)(void*)>(this, ENGINE_GETNETCHANNELINFO_INDEX)(this);
	}
};

extern ModuleContext* engineDLL;
extern IVEngineClient* engine;

bool LinkEngine();

#endif