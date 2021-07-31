#ifndef SDK_CLIENT_H
#define SDK_CLIENT_H
#pragma once

#include <raze/memory.h>
#include <sdk/math.h>

#define CLIENT_VERSION "VClient017"
#define CLIENT_FRAMESTAGENOTIFY_INDEX 35
#define CLIENTMODE_INDEX_CREATEMOVE 21

enum ClientFrameStage_t
{
	FRAME_UNDEFINED = -1,
	FRAME_START,
	FRAME_NET_UPDATE_START,
	FRAME_NET_UPDATE_POSTDATAUPDATE_START,
	FRAME_NET_UPDATE_POSTDATAUPDATE_END,
	FRAME_NET_UPDATE_END,
	FRAME_RENDER_START,
	FRAME_RENDER_END
};

class IBaseClientDLL;
class IClientMode;
class CClientState;

extern ModuleContext* clientDLL;
extern IBaseClientDLL* client;
extern IClientMode* clientMode;

bool LinkClient();

#endif