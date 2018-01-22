#include "stdafx.h"
#include "AsmMaker.h"
#include <assert.h>
#include <fstream>

//4 bit top command selector
const int BITS_TOP = 14;

//3 bit operand 0 or operation 0
const int BITS_OP0 = 11;

//3 bit operand 0 or operation 1
const int BITS_OP1 = 8;

AsmMaker::AsmMaker()
{
}

AsmMaker::~AsmMaker()
{
}

bool AsmMaker::isValidImm11(int number)
{
	return number >= -1024 && number < 1024;
}

bool AsmMaker::isValidImm11Top(int number)
{
	int bit7 = 128;
	if (number%bit7)
		return false;
	return number >= -1024*128 && number < 1024*128;
}

bool AsmMaker::isValidImm18(int number)
{
	return number >= -1024 * 128 && number < 1024 * 128;
}

bool AsmMaker::isValidImm8(int number)
{
	return number >= -128 && number < 128;
}

bool AsmMaker::isValidReg(int reg)
{
	return reg >= 0 && reg < 7;
}

bool AsmMaker::writeToTextFile(std::string filename)
{
	std::ofstream file;
	file.open(filename.c_str(), std::ofstream::out | std::ofstream::trunc);
	if (!file.is_open())
	{
		std::cerr << "Cannot open file '" << filename << "'" << std::endl;
		return false;
	}

	for (uint32_t command : commands)
	{
		file << std::hex << command << std::endl;
	}

	return true;
}

void AsmMaker::addMovImm11(int reg, int number)
{
	assert(isValidReg(reg));
	assert(isValidImm11(number));
	
	uint32_t op = (0x1 << BITS_TOP) | (reg << BITS_OP0) | ((uint32_t)number & 0x7FF);
	commands.push_back(op);
}

void AsmMaker::addMovImm11Top(int reg, int number)
{
	assert(isValidReg(reg));
	assert(isValidImm11Top(number));

	number /= 128;

	uint32_t op = (0x2 << BITS_TOP) | (reg << BITS_OP0) | ((uint32_t)number & 0x7FF);
	commands.push_back(op);
}

void AsmMaker::addMovImm18(int reg, int number)
{
	assert(isValidReg(reg));
	assert(isValidImm18(number));

	if (isValidImm11(number))
	{
		addMovImm11(reg, number);
		return;
	}

	if (isValidImm11Top(number))
	{
		addMovImm11Top(reg, number);
		return;
	}

	int top = (number/128)*128;
	addMovImm11Top(reg, top);
	int bottom = number - top;
	addAddRegImm8(reg, reg, bottom);
}

void AsmMaker::addMovIndirect(int rx, int ry, int imm8)
{
	assert(isValidReg(rx));
	assert(isValidReg(ry));
	assert(isValidImm8(imm8));

	uint32_t op = (0x2 << BITS_TOP) | (rx << BITS_OP0) | (ry << BITS_OP1) | ((uint32_t)imm8 & 0xFF);
	commands.push_back(op);
}

void AsmMaker::addAddRegImm8(int rx, int ry, int imm8)
{
	assert(isValidReg(rx));
	assert(isValidReg(ry));
	assert(isValidImm8(imm8));

	uint32_t op = (0x0 << BITS_TOP) | (rx << BITS_OP0) | (ry << BITS_OP1) | ((uint32_t)imm8 & 0xFF);
	commands.push_back(op);
}

void AsmMaker::fillTo(size_t size)
{
	assert(commands.size() <= size);
	commands.resize(size);
}