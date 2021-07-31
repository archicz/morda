#include <morda/opuscodec.h>
#include <string>

MordaOpusCodec::MordaOpusCodec() :
	encoder(0), decoder(0),
	overflowBytes(0, 0, false),
	sampleRate(0),
	curFrame(0), lastFrame(0)
{
}

bool MordaOpusCodec::Init(uint16 sRate)
{
	sampleRate = sRate;
	int32 err = 0;

	encoder = opus_encoder_create(sampleRate, MAX_CHANNELS, OPUS_APPLICATION_VOIP, &err);
	if (err < 0)
	{
		return false;
	}
	
	opus_encoder_ctl(encoder, OPUS_SET_SIGNAL_REQUEST, OPUS_SIGNAL_VOICE);
	opus_encoder_ctl(encoder, OPUS_SET_DTX_REQUEST, 1);

	decoder = opus_decoder_create(sampleRate, MAX_CHANNELS, &err);
	if (err < 0)
	{
		return false;
	}

	return true;
}

uint32 MordaOpusCodec::Encode(const char* pcm, uint32 numSamples, char* compressed, uint32 maxSize)
{
	if ((numSamples + overflowBytes.TellPut() / BYTES_PER_SAMPLE) < FRAME_SIZE)
	{
		overflowBytes.Put(pcm, numSamples * BYTES_PER_SAMPLE);
		return 0;
	}

	uint32 samples = numSamples;
	uint32 samplesRemaining = numSamples % FRAME_SIZE;
	char* data = (char*)pcm;

	if (overflowBytes.TellPut())
	{
		StrojarBuffer buf(0, 0, false);
		buf.Put(overflowBytes.Base(), overflowBytes.TellPut());
		buf.Put(pcm, numSamples * BYTES_PER_SAMPLE);
		overflowBytes.Clear();

		samples = (buf.TellPut() / BYTES_PER_SAMPLE);
		samplesRemaining = samples % FRAME_SIZE;

		data = (char*)buf.Base();
	}

	char* readCursor = data;
	char* writeCursor = compressed;
	char* writeMax = compressed + maxSize;

	uint32 numBlocks = samples - samplesRemaining;
	while (numBlocks > 0)
	{
		uint16* payloadSizeCursor = (uint16*)writeCursor;
		writeCursor += sizeof(uint16);

		*(uint16*)writeCursor = (curFrame++) % 1000;
		writeCursor += sizeof(uint16);

		uint32 maxBytes = writeMax - writeCursor;
		uint32 bytesWritten = opus_encode(encoder, (const opus_int16*)readCursor, FRAME_SIZE, (unsigned char*)writeCursor, maxBytes);

		numBlocks -= FRAME_SIZE;
		readCursor += FRAME_SIZE * 2;
		writeCursor += bytesWritten;

		*payloadSizeCursor = bytesWritten;
	}

	overflowBytes.Clear();

	if (samplesRemaining)
	{
		overflowBytes.Put(data + ((samples - samplesRemaining) * sizeof(uint16)), BYTES_PER_SAMPLE * samplesRemaining);
	}

	return writeCursor - compressed;
}

uint32 MordaOpusCodec::Decode(const char* compressed, uint32 size, char* pcm, uint32 maxSize)
{
	char* readCursor = (char*)compressed;
	char* readMax = readCursor + size;

	char* writeCursor = pcm;
	char* writeMax = pcm + maxSize;
	uint16 payloadSize = 0;
	uint32 bytes = 0;

	while (readCursor < readMax)
	{
		payloadSize = *(uint16*)readCursor;
		readCursor += sizeof(uint16);

		if (payloadSize == 0xFFFF)
		{
			lastFrame = 0;
			break;
		}

		uint16 decodedFrame = *(uint16*)readCursor;
		readCursor += sizeof(uint16);

		if (decodedFrame != lastFrame)
		{
			uint32 packetLoss = decodedFrame - lastFrame;
			for (uint32 i = 0; i < packetLoss; i++)
			{
				if (writeCursor + (FRAME_SIZE * BYTES_PER_SAMPLE) >= writeMax)
				{
					break;
				}

				bytes = opus_decode(decoder, 0, 0, (opus_int16*)writeCursor, FRAME_SIZE, 0);
				writeCursor += bytes * 2;
			}
		}

		lastFrame = decodedFrame + 1;

		if ((readCursor + payloadSize) > readMax)
		{
			break;
		}

		if (writeMax < writeCursor + (FRAME_SIZE * BYTES_PER_SAMPLE))
		{
			break;
		}

		memset(writeCursor, 0, FRAME_SIZE * BYTES_PER_SAMPLE);

		if (!payloadSize)
		{
			writeCursor += FRAME_SIZE * BYTES_PER_SAMPLE;
			continue;
		}

		bytes = opus_decode(decoder, (const unsigned char*)readCursor, payloadSize, (opus_int16*)writeCursor, FRAME_SIZE, 0);

		readCursor += payloadSize;
		writeCursor += bytes * 2;
	}

	return (writeCursor - pcm) / BYTES_PER_SAMPLE;
}