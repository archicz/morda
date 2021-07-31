#include "engine.h"

ModuleContext* engineDLL = 0;
IVEngineClient* engine = 0;

bool LinkEngine()
{
	engineDLL = CreateModuleContext("engine.dll", true);
	if (!engineDLL)
	{
		return false;
	}

	engine = (IVEngineClient*)GetModuleInterface(engineDLL, ENGINE_VERSION);
	if (!engine)
	{
		return false;
	}
	
	return true;
}