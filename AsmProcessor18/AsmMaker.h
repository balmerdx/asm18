#pragma once

class AsmMaker
{
public:
	AsmMaker();
	~AsmMaker();

	bool isValidImm11(int number);
	bool isValidImm8(int number);
	bool isValidReg(int reg);

	//reg = number
	//number - signed, 11 bit
	void addMovImm11(int reg, int number);

	//rx = ry[number]
	//number - signed, 8 bit
	void addMovIndirect(int rx, int ry, int imm8);

	//rx = ry + imm8
	void addAddRegImm8(int rx, int ry, int imm8);

	void fillTo(size_t size);

	bool writeToTextFile(std::string filename);
protected:
	std::vector<uint32_t> commands;
};