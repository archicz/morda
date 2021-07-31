#ifndef SDK_MD5_H
#define SDK_MD5_H
#pragma once

#define MD5_DIGEST_LENGTH 16  
#define MD5_BIT_LENGTH ( MD5_DIGEST_LENGTH * sizeof(unsigned char) )

struct MD5Context_t
{
	unsigned int	buf[4];
	unsigned int	bits[2];
	unsigned char	in[64];
};

void MD5Init(MD5Context_t* context);
void MD5Update(MD5Context_t* context, unsigned char const* buf, unsigned int len);
void MD5Final(unsigned char digest[MD5_DIGEST_LENGTH], MD5Context_t* context);

unsigned int MD5_PseudoRandom(unsigned int nSeed);

#endif