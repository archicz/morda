#include "bitbuffer.h"

#include <string.h>

uint32 g_LittleBits[32];
uint32 g_BitWriteMasks[32][33];
uint32 g_ExtraMasks[33];

class StrojarBitMask
{
public:
	StrojarBitMask()
	{
		for (uint32 startbit = 0; startbit < 32; startbit++)
		{
			for (uint32 nBitsLeft = 0; nBitsLeft < 33; nBitsLeft++)
			{
				uint32 endbit = startbit + nBitsLeft;
				g_BitWriteMasks[startbit][nBitsLeft] = GetBitForBitnum(startbit) - 1;

				if (endbit < 32)
				{
					g_BitWriteMasks[startbit][nBitsLeft] |= ~(GetBitForBitnum(endbit) - 1);
				}
			}
		}

		for (uint32 maskBit = 0; maskBit < 32; maskBit++)
		{
			g_ExtraMasks[maskBit] = GetBitForBitnum(maskBit) - 1;
		}

		g_ExtraMasks[32] = ~0ul;

		for (uint32 littleBit = 0; littleBit < 32; littleBit++)
		{
			(&g_LittleBits[littleBit])[0] = 1u << littleBit;
		}
	}
};

static StrojarBitMask bitmasks;

StrojarBitbuffer::StrojarBitbuffer()
{
	m_pData = 0;
	m_nDataBytes = 0;
	m_nDataBits = 0;
	m_nCurBit = 0;
}

StrojarBitbuffer::StrojarBitbuffer(void* pData, uint32 nBytes, int32 nMaxBits)
{
	nBytes &= ~3;

	m_pData = (unsigned long*)pData;
	m_nDataBytes = nBytes;

	if (nMaxBits == -1)
	{
		m_nDataBits = nBytes << 3;
	}
	else
	{
		m_nDataBits = nMaxBits;
	}

	m_nCurBit = 0;
}

uint32 StrojarBitbuffer::GetNumBitsLeft()
{
	return m_nDataBits - m_nCurBit;
}

uint32 StrojarBitbuffer::GetNumBytesLeft()
{
	return GetNumBitsLeft() >> 3;
}

uint32 StrojarBitbuffer::GetNumBitsProcessed()
{
	return m_nCurBit;
}

uint32 StrojarBitbuffer::GetNumBytesProcessed()
{
	return Bits2Bytes(m_nCurBit);
}

void StrojarBitbuffer::Reset()
{
	m_nCurBit = 0;
}

void StrojarBitbuffer::Seek(uint32 bitpos)
{
	m_nCurBit = bitpos;
}

void StrojarBitbuffer::SeekRelative(uint32 bitpos)
{
	Seek(m_nCurBit + bitpos);
}

char* StrojarBitbuffer::Cursor()
{
	return (char*)m_pData + GetNumBytesProcessed();
}

char* StrojarBitbuffer::CursorMax()
{
	return (char*)m_pData + m_nDataBytes;
}

void StrojarBitbuffer::WriteOneBit(uint8 bit)
{
	if (bit)
	{
		m_pData[m_nCurBit >> 5] |= g_LittleBits[m_nCurBit & 31];
	}
	else
	{
		m_pData[m_nCurBit >> 5] &= ~g_LittleBits[m_nCurBit & 31];
	}

	++m_nCurBit;
}

void StrojarBitbuffer::WriteUBitLong(uint32 data, uint32 numbits)
{
	if (GetNumBitsLeft() < numbits)
	{
		return;
	}

	int32 iCurBitMasked = m_nCurBit & 31;
	int32 iDWord = m_nCurBit >> 5;
	m_nCurBit += numbits;

	// Mask in a dword.
	uintp* __restrict pOut = &m_pData[iDWord];

	// Rotate data into dword alignment
	data = (data << iCurBitMasked) | (data >> (32 - iCurBitMasked));

	// Calculate bitmasks for first and second word
	uint32 temp = 1 << (numbits - 1);
	uint32 mask1 = (temp * 2 - 1) << iCurBitMasked;
	uint32 mask2 = (temp - 1) >> (31 - iCurBitMasked);

	// Only look beyond current word if necessary (avoid access violation)
	int32 i = mask2 & 1;
	uintp dword1 = pOut[0];
	uintp dword2 = pOut[i];

	// Drop bits into place
	dword1 ^= (mask1 & (data ^ dword1));
	dword2 ^= (mask2 & (data ^ dword2));

	// Note reversed order of writes so that dword1 wins if mask2 == 0 && i == 0
	pOut[i] = dword2;
	pOut[0] = dword1;
}

void StrojarBitbuffer::WriteSBitLong(int32 data, uint32 numbits)
{
	// Force the sign-extension bit to be correct even in the case of overflow.
	int32 nValue = data;
	int32 nPreserveBits = (0x7FFFFFFF >> (32 - numbits));
	int32 nSignExtension = (nValue >> 31) & ~nPreserveBits;
	nValue &= nPreserveBits;
	nValue |= nSignExtension;
	
	WriteUBitLong(nValue, numbits);
}

void StrojarBitbuffer::WriteVarInt32(uint32 data)
{
	// Check if align and we have room, slow path if not
	if ((m_nCurBit & 7) == 0 && (m_nCurBit + 5 * 8) <= m_nDataBits)
	{
		uint8 *target = ((uint8*)m_pData) + (m_nCurBit >> 3);

		target[0] = static_cast<uint8>(data | 0x80);
		if (data >= (1 << 7))
		{
			target[1] = static_cast<uint8>((data >> 7) | 0x80);
			if (data >= (1 << 14))
			{
				target[2] = static_cast<uint8>((data >> 14) | 0x80);
				if (data >= (1 << 21))
				{
					target[3] = static_cast<uint8>((data >> 21) | 0x80);
					if (data >= (1 << 28))
					{
						target[4] = static_cast<uint8>(data >> 28);
						m_nCurBit += 5 * 8;
						return;
					}
					else
					{
						target[3] &= 0x7F;
						m_nCurBit += 4 * 8;
						return;
					}
				}
				else
				{
					target[2] &= 0x7F;
					m_nCurBit += 3 * 8;
					return;
				}
			}
			else
			{
				target[1] &= 0x7F;
				m_nCurBit += 2 * 8;
				return;
			}
		}
		else
		{
			target[0] &= 0x7F;
			m_nCurBit += 1 * 8;
			return;
		}
	}
	else // Slow path
	{
		while (data > 0x7F)
		{
			WriteUBitLong((data & 0x7F) | 0x80, 8);
			data >>= 7;
		}
		WriteUBitLong(data & 0x7F, 8);
	}
}

void StrojarBitbuffer::WriteFloat(float data)
{
	WriteBits(&data, sizeof(data) << 3);
}

bool StrojarBitbuffer::WriteBits(void* pIn, uint32 nBits)
{
	uint8* pOut = (uint8*)pIn;
	uint32 nBitsLeft = nBits;

	// Align output to dword boundary
	while (((uintp)pOut & 3) != 0 && nBitsLeft >= 8)
	{

		WriteUBitLong(*pOut, 8);
		++pOut;
		nBitsLeft -= 8;
	}

	if ((nBitsLeft >= 32) && (m_nCurBit & 7) == 0)
	{
		// current bit is byte aligned, do block copy
		int32 numbytes = nBitsLeft >> 3;
		int32 numbits = numbytes << 3;

		memcpy((char*)m_pData + (m_nCurBit >> 3), pOut, numbytes);
		pOut += numbytes;
		nBitsLeft -= numbits;
		m_nCurBit += numbits;
	}

	// X360TBD: Can't write dwords in WriteBits because they'll get swapped
	if (nBitsLeft >= 32)
	{
		uintp iBitsRight = (m_nCurBit & 31);
		uintp iBitsLeft = 32 - iBitsRight;
		uintp bitMaskLeft = g_BitWriteMasks[iBitsRight][32];
		uintp bitMaskRight = g_BitWriteMasks[0][iBitsRight];

		uintp* pData = &m_pData[m_nCurBit >> 5];

		// Read dwords.
		while (nBitsLeft >= 32)
		{
			uintp curData = *(uintp*)pOut;
			pOut += sizeof(unsigned long);

			*pData &= bitMaskLeft;
			*pData |= curData << iBitsRight;

			pData++;

			if (iBitsLeft < 32)
			{
				curData >>= iBitsLeft;
				*pData &= bitMaskRight;
				*pData |= curData;
			}

			nBitsLeft -= 32;
			m_nCurBit += 32;
		}
	}


	// write remaining bytes
	while (nBitsLeft >= 8)
	{
		WriteUBitLong(*pOut, 8);
		++pOut;
		nBitsLeft -= 8;
	}

	// write remaining bits
	if (nBitsLeft)
	{
		WriteUBitLong(*pOut, nBitsLeft);
	}

	return true;
}

bool StrojarBitbuffer::WriteBytes(void* pIn, uint32 nBytes)
{
	return WriteBits(pIn, nBytes << 3);
}

void StrojarBitbuffer::WriteChar(char val)
{
	WriteSBitLong(val, 8);
}

void StrojarBitbuffer::WriteByte(uint8 val)
{
	WriteUBitLong(val, 8);
}

void StrojarBitbuffer::WriteShort(int16 val)
{
	WriteSBitLong(val, 16);
}

void StrojarBitbuffer::WriteWord(uint16 val)
{
	WriteUBitLong(val, 16);
}

void StrojarBitbuffer::WriteLong(int32 val)
{
	WriteSBitLong(val, 32);
}

void StrojarBitbuffer::WriteUnsignedLong(uint32 val)
{
	WriteUBitLong(val, 32);
}

bool StrojarBitbuffer::WriteString(const char* pStr)
{
	if (pStr)
	{
		do
		{
			WriteChar(*pStr);
			++pStr;
		} while (*(pStr - 1) != 0);
	}
	else
	{
		WriteChar(0);
	}

	return true;
}



uint8 StrojarBitbuffer::ReadOneBit()
{
	unsigned int value = ((uintp* __restrict)m_pData)[m_nCurBit >> 5] >> (m_nCurBit & 31);

	++m_nCurBit;
	return value & 1;
}

uint32 StrojarBitbuffer::ReadUBitLong(uint32 numbits) __restrict
{
	if (GetNumBitsLeft() < numbits)
	{
		return 0;
	}

	uint32 iStartBit = m_nCurBit & 31u;
	int32 iLastBit = m_nCurBit + numbits - 1;
	uint32 iWordOffset1 = m_nCurBit >> 5;
	uint32 iWordOffset2 = iLastBit >> 5;
	m_nCurBit += numbits;

	uint32 bitmask = (2 << (numbits - 1)) - 1;

	uint32 dw1 = m_pData[iWordOffset1] >> iStartBit;
	uint32 dw2 = m_pData[iWordOffset2] << (32 - iStartBit);

	return (dw1 | dw2) & bitmask;
}

int32 StrojarBitbuffer::ReadSBitLong(uint32 numbits)
{
	uint32 r = ReadUBitLong(numbits);
	uint32 s = 1 << (numbits - 1);

	if (r >= s)
	{
		r = r - s - s;
	}

	return r;
}

uint32 StrojarBitbuffer::ReadVarInt32()
{
	uint32 result = 0;
	int count = 0;
	uint32 b;

	do
	{
		if (count == 5)
		{
			return result;
		}
		b = ReadUBitLong(8);
		result |= (b & 0x7F) << (7 * count);
		++count;
	} while (b & 0x80);

	return result;
}

float StrojarBitbuffer::ReadFloat()
{
	float ret;
	ReadBits(&ret, 32);
	
	return ret;
}

void StrojarBitbuffer::ReadBits(void* pOutData, uint32 nBits)
{
	uint8* pOut = (uint8*)pOutData;
	uint32 nBitsLeft = nBits;
	
	// align output to dword boundary
	while (((uint32)pOut & 3) != 0 && nBitsLeft >= 8)
	{
		*pOut = (uint8)ReadUBitLong(8);
		++pOut;
		nBitsLeft -= 8;
	}

	while (nBitsLeft >= 32)
	{
		*((uintp*)pOut) = ReadUBitLong(32);
		pOut += sizeof(uintp);
		nBitsLeft -= 32;
	}

	// read remaining bytes
	while (nBitsLeft >= 8)
	{
		*pOut = ReadUBitLong(8);
		++pOut;
		nBitsLeft -= 8;
	}

	// read remaining bits
	if (nBitsLeft)
	{
		*pOut = ReadUBitLong(nBitsLeft);
	}
}

void StrojarBitbuffer::ReadBytes(void* pOut, uint32 nBytes)
{
	ReadBits(pOut, nBytes << 3);
}

char StrojarBitbuffer::ReadChar()
{
	return ReadSBitLong(8);
}

uint8 StrojarBitbuffer::ReadByte()
{
	return ReadUBitLong(8);
}

int16 StrojarBitbuffer::ReadShort()
{
	return ReadSBitLong(16);
}

uint16 StrojarBitbuffer::ReadWord()
{
	return ReadUBitLong(16);
}

int32 StrojarBitbuffer::ReadLong()
{
	return ReadSBitLong(32);
}

uint32 StrojarBitbuffer::ReadUnsignedLong()
{
	return ReadUBitLong(32);
}

bool StrojarBitbuffer::ReadString(char* pStr, uint32 bufLen)
{
	bool bTooSmall = false;
	uint32 nChar = 0;

	while (1)
	{
		char val = ReadChar();
		if (val == 0)
			break;

		if (nChar < (bufLen - 1))
		{
			pStr[nChar] = val;
			++nChar;
		}
		else
		{
			bTooSmall = true;
		}
	}

	pStr[nChar] = 0;
	return !bTooSmall;
}
