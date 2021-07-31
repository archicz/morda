#ifndef MORDA_VOICE_H
#define MORDA_VOICE_H
#pragma once

#include <morda/opuscodec.h>
#include <strojar/bitbuffer.h>
#include <strojar/vector.h>

class MordaAudioChannel
{
public:
	int16 samples[FRAME_SIZE * 2];
	const int16* buffer;
	uint32 bufferSamples;
	uint32 sampleRate;
	uint32 finalRate;

	uint32 curSample;
	float lastTime;

	float volume;
	float pitch;
	bool finished;

	int32 err;
	void* resampler;
public:
	MordaAudioChannel();
public:
	void ResetState();
	void ResetResampler();
public:
	void SetVolume(float vol);
	void SetPitch(float ptch);
	void Stop();
public:
	void LoadFromFile(const char* fileName, uint32 inRate);
	void LoadFromPCM(const int16* buf, uint32 samples, uint32 inRate);
public:
	uint32 Play();
};

class MordaVoiceManager
{
public:
	char encodedData[2048];
	char packetData[2048];
	
	MordaOpusCodec* codec;
	MordaAudioChannel* chan;
public:
	MordaVoiceManager();
public:
	uint32 EncodePayload(uint32 samples);
	void SendPacket();
};

extern MordaVoiceManager* mordaVoice;

#endif