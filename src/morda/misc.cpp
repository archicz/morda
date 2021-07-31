#include <sdk/luashared.h>
#include <sdk/client.h>
#include <sdk/engine.h>
#include <sdk/tier0.h>

LUA_FUNCTION(ReloadScriptLUA)
{
	LoadScript();
	return 1;
}

LUA_FUNCTION(ChangeNameLUA)
{
	const char* name = LUA->GetString(1);
	char pckBuf[64];

	StrojarBitbuffer pck(pckBuf, sizeof(pckBuf));
	pck.WriteUBitLong(net_SetConVar, NET_MESSAGE_BITS);
	pck.WriteByte(1);
	pck.WriteString("name");
	pck.WriteString(name);

	engine->GetNetChannel()->SendData(pck, true);
	return 1;
}

LUA_FUNCTION(FileFloodLUA)
{
	char pckBuf[512];

	StrojarBitbuffer pck(pckBuf, sizeof(pckBuf));
	pck.WriteUBitLong(net_File, NET_MESSAGE_BITS);
	pck.WriteUBitLong(512, 32);
	pck.WriteOneBit(1);
	pck.WriteUBitLong(1, 1);
	pck.WriteUBitLong(512, 32);

	engine->GetNetChannel()->SendData(pck, true);
	return 1;
}

LUA_FUNCTION(GetInSequenceLUA)
{
	LUA->PushNumber(engine->GetNetChannel()->inSequenceNr);
	return 1;
}

LUA_FUNCTION(SetInSequenceLUA)
{
	engine->GetNetChannel()->inSequenceNr = (int32)LUA->GetNumber();
	return 1;
}

LUA_FUNCTION(GetOutSequenceLUA)
{
	LUA->PushNumber(engine->GetNetChannel()->outSequenceNr);
	return 1;
}

LUA_FUNCTION(SetOutSequenceLUA)
{
	engine->GetNetChannel()->outSequenceNr = (int32)LUA->GetNumber();
	return 1;
}

void LoadMisc()
{
	ADD_LUA_FUNC(ReloadScript);
	ADD_LUA_FUNC(ChangeName);
	ADD_LUA_FUNC(FileFlood);

	ADD_LUA_FUNC(GetInSequence);
	ADD_LUA_FUNC(SetInSequence);

	ADD_LUA_FUNC(GetOutSequence);
	ADD_LUA_FUNC(SetOutSequence);
}