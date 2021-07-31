#include <windows.h>

#include <sdk/tier0.h>
#include <sdk/luashared.h>
#include <sdk/engine.h>
#include <sdk/client.h>

DWORD WINAPI OnInject(LPVOID)
{
	if (!LinkTier0())
	{
		Msg("[morda] Failed to link with tier0.dll!\n");
		return 0;
	}

	if (!LinkLuaShared())
	{
		Msg("[morda] Failed to link with lua_shared.dll!\n");
		return 0;
	}

	if (!LinkEngine())
	{
		Msg("[morda] Failed to link with engine.dll!\n");
		return 0;
	}

	if (!LinkClient())
	{
		Msg("[morda] Failed to link with client.dll!\n");
		return 0;
	}

	Msg("[morda] Game linked & hooked!\n");

	return 1;
}

int WINAPI DllMain(HINSTANCE hinstDLL, DWORD fdwReason, LPVOID lpvReserved)
{
	switch (fdwReason)
	{
		case DLL_PROCESS_ATTACH:
			CreateThread(0, 0, OnInject, 0, 0, 0);
		break;
	}

	return 1;
}