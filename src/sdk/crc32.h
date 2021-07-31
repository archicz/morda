#ifndef SDK_CRC32_H
#define SDK_CRC32_H
#pragma once

#include <common.h>

void CRC32_Init(uint32* pulCRC);
void CRC32_ProcessBuffer(uint32* pulCRC, const void* p, uint32 len);
void CRC32_Final(uint32* pulCRC);

inline uint32 CRC32_ProcessSingleBuffer(const void* p, uint32 len)
{
	uint32 crc;

	CRC32_Init(&crc);
	CRC32_ProcessBuffer(&crc, p, len);
	CRC32_Final(&crc);

	return crc;
}

#endif