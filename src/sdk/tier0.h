#ifndef SDK_TIER0_H
#define SDK_TIER0_H
#pragma once

#include <raze/memory.h>

extern ModuleContext* tier0DLL;

typedef void(*MsgFn)(const char* format, ...);
extern MsgFn Msg;

typedef float(*Plat_FloatTimeFn)();
extern Plat_FloatTimeFn Plat_FloatTime;

bool LinkTier0();

#endif