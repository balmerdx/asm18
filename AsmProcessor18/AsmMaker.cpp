#include "stdafx.h"
#include "AsmMaker.h"
#include <assert.h>
#include <fstream>
#include <iomanip>

//4 bit top command selector
const int BITS_TOP = 14;

//3 bit operand 0 or operation 0
const int BITS_OP0 = 11;

//3 bit operand 0 or operation 1
const int BITS_OP1 = 8;

const uint32_t OPCODE_WAIT = (0xA << BITS_TOP);

const int POW18 = 0x40000;

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
    return number >= -POW18 && number < POW18;
}

bool AsmMaker::isValidImm14unsigned(int number)
{
	return number >= 0 && number < 0x4000;
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
	return reg >= 0 && reg <= 7;
}

bool AsmMaker::isValidShift(int shift)
{
	return shift >= 0 && shift < 18;
}

void AsmMaker::fillTo(size_t size)
{
	assert(commands.size() <= size);
	commands.resize(size, OPCODE_WAIT);
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
		file << std::setfill('0') << std::setw(5) << std::hex << command << std::endl;
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

    if(number<0)
    {
        number = POW18 + number;
    }

    if (isValidImm11Top(number))
	{
		addMovImm11Top(reg, number);
		return;
	}

	int top = (number/128)*128;
    int bottom = number - top;
    addMovImm11Top(reg, top);
	addAddRegImm8(reg, reg, bottom);
}

void AsmMaker::addAddRegImm8(int rx, int ry, int imm8)
{
	assert(isValidReg(rx));
	assert(isValidReg(ry));
	assert(isValidImm8(imm8));

	uint32_t op = (0x0 << BITS_TOP) | (rx << BITS_OP0) | (ry << BITS_OP1) | ((uint32_t)imm8 & 0xFF);
	commands.push_back(op);
}

void AsmMaker::addLoadFromMemory(int rx, int ry, int imm8)
{
	assert(isValidReg(rx));
	assert(isValidReg(ry));
	assert(isValidImm8(imm8));

	uint32_t op = (0x3 << BITS_TOP) | (rx << BITS_OP0) | (ry << BITS_OP1) | ((uint32_t)imm8 & 0xFF);
	commands.push_back(op);
}

void AsmMaker::addStoreToMemory(int rx, int ry, int imm8)
{
	assert(isValidReg(rx));
	assert(isValidReg(ry));
	assert(isValidImm8(imm8));

	uint32_t op = (0x4 << BITS_TOP) | (rx << BITS_OP0) | (ry << BITS_OP1) | ((uint32_t)imm8 & 0xFF);
	commands.push_back(op);
}


void AsmMaker::addGotoIf(int rx, IfOperation if_op, const std::string& label, size_t text_line)
{
	assert(isValidReg(rx));
	uint32_t op = (0x5 << BITS_TOP) | (rx << BITS_OP0) | ((uint32_t)if_op << BITS_OP1);// | ((uint32_t)imm8 & 0xFF);
	JumpData jd;
	jd.command_pos = commands.size();
	jd.label = label;
	jd.text_line = text_line;
	jd.imm8_offset = true;
	short_jump_offset.push_back(jd);
	commands.push_back(op);
}

void AsmMaker::addAluOp(int rx, int ry, AluOperation alu_op)
{
	assert(isValidReg(rx));
	assert(isValidReg(ry));

	uint32_t op = (0x6 << BITS_TOP) | (rx << BITS_OP0) | (ry << BITS_OP1) | ((uint32_t)alu_op & 0xFF);
	commands.push_back(op);
}

void AsmMaker::addCall(const std::string& label, size_t text_line)
{
	uint32_t op = (0x8 << BITS_TOP);
	JumpData jd;
	jd.command_pos = commands.size();
	jd.label = label;
	jd.text_line = text_line;
	jd.imm8_offset = false;
	short_jump_offset.push_back(jd);
	commands.push_back(op);
}

void AsmMaker::addReturn()
{
	uint32_t op = (0x9 << BITS_TOP);
	commands.push_back(op);
}

void AsmMaker::addLabel(const std::string& label)
{
	assert(label_offsets.find(label) == label_offsets.end());
	label_offsets[label] = commands.size();
}

void AsmMaker::addMul(int rx, int ry, bool signedx, bool signedy, int shift_right)
{
	assert(isValidReg(rx));
	assert(isValidReg(ry));
	assert(isValidShift(shift_right));

	uint32_t signx = signedx ? 1 << 7 : 0;
	uint32_t signy = signedy ? 1 << 6 : 0;
	uint32_t op = (0x7 << BITS_TOP) | (rx << BITS_OP0) | (ry << BITS_OP1) | signx | signy | ((uint32_t)shift_right & 0x3F);
	commands.push_back(op);
}

void AsmMaker::addWait()
{
	commands.push_back(OPCODE_WAIT);
}

void AsmMaker::fixLabels(std::vector<JumpData>& big_offset_labels, std::vector<JumpData>& not_found_labels)
{
	for (JumpData& jd : short_jump_offset)
	{
		auto it = label_offsets.find(jd.label);
		if (it == label_offsets.end())
		{
			not_found_labels.push_back(jd);
			continue;
		}

		size_t label_offset = it->second;

		if (jd.imm8_offset)
		{
			int imm8 = (int)label_offset - (int)jd.command_pos;
			if (!isValidImm8(imm8))
			{
				big_offset_labels.push_back(jd);
				continue;
			}
			//Fix addGotoIf commands
			commands[jd.command_pos] |= ((uint32_t)imm8 & 0xFF);
		}
		else
		{
			//Fix goto imm14 commands
			if (!isValidImm14unsigned(label_offset))
			{
				big_offset_labels.push_back(jd);
				continue;
			}
			//Fix addGotoIf commands
			commands[jd.command_pos] |= ((uint32_t)label_offset & 0x3FFF);
		}

	}
}
