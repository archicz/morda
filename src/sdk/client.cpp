#include <sdk/client.h>
#include <sdk/luashared.h>
#include <sdk/usercmd.h>
#include <sdk/engine.h>

ModuleContext* clientDLL = 0;
IBaseClientDLL* client = 0;
IClientMode* clientMode = 0;

static VTableContext* clientVT = 0;
static VTableContext* clientModeVT = 0;

static CUserCmd* curCmd = 0;

typedef void(__thiscall* FrameStageNotifyFn)(IBaseClientDLL*, ClientFrameStage_t);
static FrameStageNotifyFn origFrameStageNotify = 0;
void __fastcall HookFrameStageNotify(IBaseClientDLL* thisptr, int, ClientFrameStage_t stage)
{
	return origFrameStageNotify(thisptr, stage);
}

typedef bool(__thiscall* CreateMoveFn)(IClientMode*, float, CUserCmd*);
static CreateMoveFn origCreateMove = 0;
bool __fastcall HookCreateMove(IClientMode* thisptr, int, float inputSampleTime, CUserCmd* cmd)
{
	uintp addr;

	__asm
	{
		mov addr, ebp
	}

	bool& bSendPacket = *(***(bool****)(addr)-0x1);
	bool ret = false;
	
	if (luaInterface)
	{
		curCmd = cmd;
		
		if (cmd->commandNumber != 0)
		{
			luaInterface->PushSpecial(SPECIAL_GLOB);
				luaInterface->GetField(-1, "morda");
				luaInterface->GetField(-1, "sendPacket");
				bSendPacket = luaInterface->GetBool(-1);
			luaInterface->Pop(3);
		}
	}
	else
	{
		bSendPacket = true;
	}
	
	return origCreateMove(thisptr, inputSampleTime, cmd);
}

bool LinkClient()
{
	clientDLL = CreateModuleContext("client.dll", true);
	if (!clientDLL)
	{
		return false;
	}

	client = (IBaseClientDLL*)GetModuleInterface(clientDLL, CLIENT_VERSION);
	if (!client)
	{
		return false;
	}

	clientMode = **(IClientMode***)((*(uintp**)client)[10] + 0x5);
	if (!clientMode)
	{
		return false;
	}

	clientVT = CreateVTableContext(client);
		HookVTableFunction(clientVT, HookFrameStageNotify, CLIENT_FRAMESTAGENOTIFY_INDEX);
		origFrameStageNotify = (FrameStageNotifyFn)GetOriginalVTableFunction(clientVT, CLIENT_FRAMESTAGENOTIFY_INDEX);
	SwapVTableCopy(clientVT);

	clientModeVT = CreateVTableContext(clientMode);
		HookVTableFunction(clientModeVT, HookCreateMove, CLIENTMODE_INDEX_CREATEMOVE);
		origCreateMove = (CreateMoveFn)GetOriginalVTableFunction(clientModeVT, CLIENTMODE_INDEX_CREATEMOVE);
	SwapVTableCopy(clientModeVT);

	return true;
}

LUA_FUNCTION(UpdatePredictionLUA)
{
	return 1;
}

LUA_FUNCTION(StartPredictionLUA)
{
	return 1;
}

LUA_FUNCTION(EndPredictionLUA)
{
	return 1;
}

void LoadClient()
{
	ADD_LUA_FUNC(UpdatePrediction);
	ADD_LUA_FUNC(StartPrediction);
	ADD_LUA_FUNC(EndPrediction);
}