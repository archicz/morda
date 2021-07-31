#ifndef SDK_MATH_H
#define SDK_MATH_H
#pragma once

class Vector
{
public:
	float x, y, z;
};

class QAngle
{
public:
	float p, y, r;
};

template< class T >
inline T clamp(T const& val, T const& minVal, T const& maxVal)
{
	if (maxVal < minVal)
		return maxVal;
	else if (val < minVal)
		return minVal;
	else if (val > maxVal)
		return maxVal;
	else
		return val;
}

#endif