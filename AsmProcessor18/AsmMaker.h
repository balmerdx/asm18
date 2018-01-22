#pragma once

class AsmMaker
{
public:
	AsmMaker();
	~AsmMaker();

	bool isValidImm18(int number);
	bool isValidImm11(int number);
	bool isValidImm11Top(int number);
	bool isValidImm8(int number);
	bool isValidReg(int reg);

	//reg = number
	//number - signed, 11 bit
	void addMovImm11(int reg, int number);

	//reg = number&~127;
	//number - signed, 11 bit shifted by 7 bit
	void addMovImm11Top(int reg, int number);

	//Use addMovImm11 and addMovImm11Top
	void addMovImm18(int reg, int number);

	//rx = ry + imm8
	void addAddRegImm8(int rx, int ry, int imm8);

	//ry[imm8] = rx
	void addStoreToMemory(int rx, int ry, int imm8);

	//rx = ry[imm8]
	void addLoadFromMemory(int rx, int ry, int imm8);

	void fillTo(size_t size);

	bool writeToTextFile(std::string filename);
protected:
	std::vector<uint32_t> commands;
};