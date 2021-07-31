#ifndef SDK_USERCMD_H
#define SDK_USERCMD_H
#pragma once

#include <common.h>
#include <sdk/math.h>

class CUserCmd
{
public:
	int32 commandNumber;
	int32 tickCount;
	QAngle viewangles;
	float forwardmove;
	float sidemove;
	float upmove;
	int32 buttons;
};

#endif