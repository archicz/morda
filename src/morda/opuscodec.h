#ifndef MORDA_OPUSCODEC_H
#define MORDA_OPUSCODEC_H
#pragma once

#include <opus.h>
#include <strojar/buffer.h>

constexpr uint32 BYTES_PER_SAMPLE = 2;
constexpr uint32 MAX_CHANNELS = 1;
constexpr uint32 FRAME_SIZE = 480;
constexpr uint32 MAX_FRAME_SIZE = 3 * FRAME_SIZE;

class MordaOpusCodec
{
public:
	OpusEncoder* encoder;
	OpusDecoder* decoder;

	StrojarBuffer overflowBytes;

	uint16 sampleRate;
	uint32 curFrame;
	uint32 lastFrame;
public:
	MordaOpusCodec();
public:
	bool Init(uint16 sRate);
public:
	uint32 Encode(const char* pcm, uint32 numSamples, char* compressed, uint32 maxSize);
	uint32 Decode(const char* compressed, uint32 size, char* pcm, uint32 maxSize);
};

#endif