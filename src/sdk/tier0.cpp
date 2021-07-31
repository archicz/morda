#include <sdk/tier0.h>

ModuleContext* tier0DLL = 0;
MsgFn Msg = 0;
Plat_FloatTimeFn Plat_FloatTime = 0;

bool LinkTier0()
{
	tier0DLL = CreateModuleContext("tier0.dll", false);
	if (!tier0DLL)
	{
		return false;
	}
	
	Msg = (MsgFn)GetModuleSymbol(tier0DLL, "Msg");
	Plat_FloatTime = (Plat_FloatTimeFn)GetModuleSymbol(tier0DLL, "Plat_FloatTime");

	return true;
}