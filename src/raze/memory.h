#ifndef RAZE_MEMORY_H
#define RAZE_MEMORY_H
#pragma once

#include <Windows.h>
#include <common.h>

typedef void* (*CreateInterfaceFn)(const char*, int*);

struct ModuleContext
{
	HMODULE handle;
	void* addr;
	uint32 size;
	CreateInterfaceFn factory;
};

struct VTableContext
{
	uintp** vtable;
	uintp* vtableOrig;
	uintp* vtableCopy;
	uint32 methodCount;
};

int32* PatternToByteArray(const char* pattern, uint32* byteCount);
int32* StringToByteArray(const char* string, bool wildcard);

uint8* FindInMemory(void* addr, uint32 size, int32* bytes, uint32 byteCount);
uint8* FindInMemoryReverse(void* addr, uint32 size, int32* bytes, uint32 byteCount);

uint8* PatternScan(void* addr, uint32 size, const char* pattern);
uint8* PatternScanReverse(void* addr, uint32 size, const char* pattern);
uint8* StringScan(void* addr, uint32 size, const char* string, bool wilrdcard);

uint8* PointerXRef(void* addr, uint32 size, void* ptr);

uint8* FindFunctionStart(void* addr, uint32 size);
uint8* FindFunctionByString(void* addr, uint32 size, const char* string, uint32 findSize);

ModuleContext* CreateModuleContext(const char* fileName, bool hasFactory);
void* GetModuleSymbol(ModuleContext* ctx, const char* name);
void* GetModuleInterface(ModuleContext* ctx, const char* ver);

VTableContext* CreateVTableContext(void* vtb);
void RemoveVTableContext(VTableContext* ctx);

void SwapVTableOrig(VTableContext* ctx);
void SwapVTableCopy(VTableContext* ctx);

void HookVTableFunction(VTableContext* ctx, void* fn, uint32 index);
void* GetOriginalVTableFunction(VTableContext* ctx, uint32 index);

#endif