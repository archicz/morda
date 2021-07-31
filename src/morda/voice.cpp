#include <morda/voice.h>
#include <sdk/engine.h>
#include <sdk/tier0.h>
#include <sdk/crc32.h>
#include <sdk/luashared.h>
#include <sdk/math.h>

#include <SAM/reciter.h>
#include <SAM/sam.h>

#include <speex/speex_resampler.h>

static constexpr uint16 GMOD_VOICE_SAMPLERATE = 48000;

enum PayLoadType : uint8
{
	PLT_OPUS_PLC = 6,
	PLT_SamplingRate = 11
};

MordaAudioChannel::MordaAudioChannel() :
	buffer(0), bufferSamples(0), sampleRate(0), finalRate(0),
	curSample(0), lastTime(0.f),
	volume(1.f), pitch(1.f), finished(true),
	err(0), resampler(0)
{
	memset(samples, 0, sizeof(samples));
}

void MordaAudioChannel::ResetState()
{
	curSample = 0;
	lastTime = 0.f;
	finished = false;
}

void MordaAudioChannel::ResetResampler()
{
	finalRate = (uint32)(sampleRate * pitch);

	if (!resampler)
	{
		resampler = speex_resampler_init(MAX_CHANNELS, finalRate, GMOD_VOICE_SAMPLERATE, 3, &err);
		if (err != 0)
		{
			Msg("[morda] MordaAudioChannel::SetupResampler() -> speex_resampler_init() failed!\n");
			resampler = 0;
		}
	}
	else
	{
		speex_resampler_set_rate((SpeexResamplerState*)resampler, finalRate, GMOD_VOICE_SAMPLERATE);
	}
}

void MordaAudioChannel::SetVolume(float vol)
{
	volume = vol;
}

void MordaAudioChannel::SetPitch(float ptch)
{
	pitch = ptch;
	ResetResampler();
}

void MordaAudioChannel::Stop()
{
	finished = true;
}

void MordaAudioChannel::LoadFromFile(const char* fileName, uint32 inRate)
{
	int16* bufSamples = 0;
	uint32 numSamples = 0;
	FILE* fin = 0;

	fin = fopen(fileName, "rb");
	if (fin)
	{
		// Get the number of samples
		fseek(fin, 0, SEEK_END);
		numSamples = ftell(fin) / BYTES_PER_SAMPLE;
		fseek(fin, 0, SEEK_SET);

		// Read samples
		bufSamples = new int16[numSamples];
		fread(bufSamples, BYTES_PER_SAMPLE, numSamples, fin);
		fclose(fin);

		// Load as PCM buffer
		LoadFromPCM(bufSamples, numSamples, inRate);
	}
}

void MordaAudioChannel::LoadFromPCM(const int16* buf, uint32 samples, uint32 inRate)
{
	buffer = buf;
	bufferSamples = samples;
	sampleRate = inRate;

	ResetState();
	ResetResampler();
}

uint32 MordaAudioChannel::Play()
{
	if (!finished && resampler)
	{
		float curTime = Plat_FloatTime();
		uint32 shouldGet = (uint32)((curTime - lastTime) * finalRate);

		if (shouldGet > 0)
		{
			uint32 samplesMax = FRAME_SIZE * 2;
			uint32 remainingSamples = bufferSamples - curSample;
			uint32 getSamples = min(samplesMax, min(shouldGet, remainingSamples));

			if (getSamples > 0)
			{
				uint32 inLen = getSamples;
				uint32 outLen = samplesMax;
				speex_resampler_process_int((SpeexResamplerState*)resampler, 0, &buffer[curSample], &inLen, samples, &outLen);

				curSample += getSamples;
				lastTime = curTime;

				return outLen;
			}
			else
			{
				finished = true;
			}
		}
	}

	return 0;
}

MordaVoiceManager::MordaVoiceManager()
{
	codec = new MordaOpusCodec;
	codec->Init(GMOD_VOICE_SAMPLERATE);

	chan = new MordaAudioChannel;
}

uint32 MordaVoiceManager::EncodePayload(uint32 samples)
{
	char* cursor = encodedData;

	// SteamID
	*(uint32*)cursor = 0x00000011;
	cursor += 4;

	*(uint32*)cursor = 0x01100001;
	cursor += 4;

	// Sample rate
	*cursor = PLT_SamplingRate;
	++cursor;

	*(uint16*)cursor = codec->sampleRate;
	cursor += sizeof(uint16);

	// OPUS w/ packet loss concealment
	*cursor = PLT_OPUS_PLC;
	++cursor;

	uint16 bytesCompressed = codec->Encode((const char*)chan->samples, samples, cursor + sizeof(uint16), sizeof(encodedData) - ((sizeof(uint8) * 2 + sizeof(uint16) * 2) + sizeof(uint32)));

	// Write the payload size
	*(uint16*)cursor = bytesCompressed;
	cursor += sizeof(uint16);

	// Advance the write cursor by the bytes compressed
	cursor += bytesCompressed;

	// CRC32 checksum
	*(uint32*)cursor = CRC32_ProcessSingleBuffer(encodedData, cursor - encodedData);
	cursor += sizeof(uint32);

	return cursor - encodedData;
}

void MordaVoiceManager::SendPacket()
{
	uint32 numSamples = chan->Play();
	if (numSamples > 0)
	{
		uint32 encodedBits = Bytes2Bits(EncodePayload(numSamples));

		StrojarBitbuffer bf(packetData, sizeof(packetData));
		bf.WriteUBitLong(clc_VoiceData, NET_MESSAGE_BITS);
		bf.WriteWord(encodedBits);
		bf.WriteBits(encodedData, encodedBits);

		engine->GetNetChannel()->SendData(bf, true);
	}
}

LUA_FUNCTION(VoicePlayFileLUA)
{
	mordaVoice->chan->LoadFromFile(LUA->GetString(1), (uint32)LUA->GetNumber(2));
	return 1;
}

static char input[256];
static int16* samSamples = 0;

LUA_FUNCTION(VoicePlaySAMLUA)
{
	memset(input, 0, sizeof(input));
	strcpy(input, LUA->GetString(1));
	
	if (!TextToPhonemes((unsigned char*)input))
	{
		return 1;
	}

	SetInput(input);

	if (!SAMMain())
	{
		return 1;
	}

	if (samSamples)
	{
		delete[] samSamples;
	}

	uint32 numSamples = GetBufferLength() / 50;
	samSamples = new int16[numSamples];

	for (uint32 i = 0; i < numSamples; i++)
	{
		samSamples[i] = (int16)(GetBuffer()[i] - 0x80) << 8;
	}

	mordaVoice->chan->LoadFromPCM(samSamples, numSamples, 22050);
	return 1;
}

LUA_FUNCTION(VoiceGetFinishedLUA)
{
	LUA->PushBool(mordaVoice->chan->finished);
	return 1;
}

LUA_FUNCTION(VoiceSetFinishedLUA)
{
	mordaVoice->chan->finished = LUA->GetBool(1);
	return 1;
}

LUA_FUNCTION(VoiceTickLUA)
{
	mordaVoice->SendPacket();
	return 1;
}

void LoadVoice()
{
	ADD_LUA_FUNC(VoicePlayFile);
	ADD_LUA_FUNC(VoicePlaySAM);

	ADD_LUA_FUNC(VoiceGetFinished);
	ADD_LUA_FUNC(VoiceSetFinished);

	ADD_LUA_FUNC(VoiceTick);
}

MordaVoiceManager* mordaVoice = new MordaVoiceManager;