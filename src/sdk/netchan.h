#ifndef SDK_NETCHAN_H
#define SDK_NETCHAN_H
#pragma once

#include <common.h>
#include <strojar/bitbuffer.h>

#define NETCHAN_SENDDATA_INDEX 41
#define NETCHAN_SENDDATAGRAM_INDEX 46

#define NET_MESSAGE_BITS 6
#define	net_NOP 0
#define net_Disconnect 1
#define net_File 2
#define net_Tick 3
#define net_StringCmd 4	
#define net_SetConVar 5
#define	net_SignonState 6

#define clc_ClientInfo 8
#define	clc_Move 9
#define clc_VoiceData 10
#define clc_BaselineAck 11
#define clc_ListenEvents 12
#define clc_RespondCvarValue 13
#define clc_FileCRCCheck 14
#define clc_SaveReplay 15
#define clc_CmdKeyValues 16
#define clc_FileMD5Check 17

class INetChannelInfo
{
public:
	enum
	{
		GENERIC = 0,
		LOCALPLAYER,
		OTHERPLAYERS,
		ENTITIES,
		SOUNDS,
		EVENTS,
		USERMESSAGES,
		ENTMESSAGES,
		VOICE,
		STRINGTABLE,
		MOVE,
		STRINGCMD,
		SIGNON,
		TOTAL,
	};
public:
	virtual const char* GetName() = 0;
	virtual const char* GetAddress() = 0;
	virtual float GetTime() = 0;
	virtual float GetTimeConnected() = 0;
	virtual int GetBufferSize() = 0;
	virtual int	GetDataRate() = 0;
public:
	virtual bool IsLoopback() = 0;
	virtual bool IsTimingOut() = 0;
	virtual bool IsPlayback() = 0;
public:
	virtual float GetLatency(int flow) = 0;
	virtual float GetAvgLatency(int flow) = 0;
	virtual float GetAvgLoss(int flow) = 0;
	virtual float GetAvgChoke(int flow) = 0;
	virtual float GetAvgData(int flow) = 0;
	virtual float GetAvgPackets(int flow) = 0;
	virtual int GetTotalData(int flow) = 0;
	virtual int	GetSequenceNr(int flow) = 0;
	virtual bool IsValidPacket(int flow, int frame_number) = 0;
	virtual float GetPacketTime(int flow, int frame_number) = 0;
	virtual int	GetPacketBytes(int flow, int frame_number, int group) = 0;
	virtual bool GetStreamProgress(int flow, int* received, int* total) = 0;
	virtual float GetTimeSinceLastReceived() = 0;
	virtual	float GetCommandInterpolationAmount(int flow, int frame_number) = 0;
	virtual void GetPacketResponseLatency(int flow, int frame_number, int* pnLatencyMsecs, int* pnChoke) = 0;
	virtual void GetRemoteFramerate(float* pflFrameTime, float* pflFrameTimeStdDeviation) = 0;
	virtual float GetTimeoutSeconds() = 0;
};

class INetChannel : public INetChannelInfo
{
public:
	bool SendData(StrojarBitbuffer& msg, bool reliable)
	{
		return CallVFunction<bool (__thiscall*)(void*, StrojarBitbuffer&, bool)>(this, NETCHAN_SENDDATA_INDEX)(this, msg, reliable);
	}

	int	SendDatagram(StrojarBitbuffer* data)
	{
		return CallVFunction<int (__thiscall*)(void*, StrojarBitbuffer*)>(this, NETCHAN_SENDDATAGRAM_INDEX)(this, data);
	}
public:
	int32 connectionState;
	int32 outSequenceNr;
	int32 inSequenceNr;
	int32 outSequenceNrAck;
	int32 outReliableState;
	int32 inReliableState;
	int32 chokedPackets;
	int32 packetDrop;
};

#endif