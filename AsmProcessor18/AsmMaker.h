#pragma once
#include <unordered_map>

enum class IfOperation
{
	IF_ZERO = 0, //r0==0
	IF_LESS = 1, //r0<0
	IF_GREAT = 2,//r0>0
	IF_LESS_OR_EQUAL = 3,//r0<=0
	IF_GREAT_OR_EQUAL = 4,//r0>=0
	IF_ZERO_BIT_CLEAR = 5,//r0[0]==0
	IF_ZERO_BIT_SET = 6,//r0[0]==1
	IF_TRUE = 7, //Set true always
};

enum class AluOperation
{
	ALU_OP_BAD = -1,

	ALU_OP_ADD = 2,
	ALU_OP_SUB = 3,
	ALU_OP_AND = 4,
	ALU_OP_OR = 5,
	ALU_OP_XOR = 6,
	ALU_OP_NOT = 7,
};

struct JumpData
{
	size_t command_pos;
	std::string label;
	size_t text_line = 0;
	bool imm8_offset = true;
};

class AsmMaker
{
public:
	AsmMaker();
	~AsmMaker();

	bool isValidImm8(int number);
	bool isValidImm11(int number);
	bool isValidImm11Top(int number);
	bool isValidImm14unsigned(int number);
	bool isValidImm18(int number);
	bool isValidReg(int reg);
	bool isValidShift(int shift);

	int codeSize() { return (int)commands.size(); }

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

	//id(op(rx)) goto ip+imm8
	void addGotoIf(int rx, IfOperation if_op, const std::string& label, size_t text_line);
	void addLabel(const std::string& label);

	//call imm14
	void addCall(const std::string& label, size_t text_line);

	//return
	void addReturn();

	//rx op= ry
	//rx += ry
	//rx =~ ry
	void addAluOp(int rx, int ry, AluOperation alu_op);

	void addMul(int rx, int ry, bool signedx, bool signedy, int shift_right);
	
	//return labels with error (not found or very long call)
	void fixLabels(std::vector<JumpData>& big_offset_labels, std::vector<JumpData>& not_found_labels);

	void fillTo(size_t size);

	bool writeToTextFile(std::string filename);
protected:
	std::vector<uint32_t> commands;
	std::unordered_map<std::string, size_t> label_offsets;
	std::vector<JumpData> short_jump_offset;
};