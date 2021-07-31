extern void LoadMisc();
extern void LoadVoice();
extern void LoadClient();

void OnScriptLoad()
{
	LoadMisc();
	LoadVoice();
	LoadClient();
}

void OnScriptClose()
{

}