#pragma once
#include "AsmMaker.h"

enum class TokenType
{
	Bad,
	Register,
	Operator,
	InstructionPointer,
	Number,
	Comment,
	Label,
	Id,
	Brackets, //[] ()
};

enum class OperatorType
{
	Bad,
	Copy, //=
	Plus, //+
	Minus, //-
	Equal, //==
};

struct Token
{
	TokenType type = TokenType::Bad;
	int line_offset = 0;
	std::string str;

	//For Register
	int register_index = 0;

	//For Number
	int number = 0;

	//For operator
	OperatorType op = OperatorType::Bad;

	bool isOperator(OperatorType o) const { return type == TokenType::Operator && op == o; }
};

/*
	�� ������ ������ ��������� ���� ����������.
	� ���������� ����� ���� �������� � ��������.
	��������:
	r3 = r2
	r1 += r7
	if(r0>0) goto Label
*/
class AsmParser
{
public:
	AsmParser();
	~AsmParser();

	bool load(std::string filename);

	void parse();

	AsmMaker code;
protected:
	void error(std::string message, int row);
	void errorRequiredOperand(const Token& token);

	bool nextLine();

	//Get token and move _current_line_offset
	Token parseToken();
	OperatorType parseOperator();

	std::string strOperator(OperatorType op);
	void printToken(Token& token);

	bool skipSpace();

	//������� ������
	inline char cur() { return _current_line_offset < _current_line.size() ? _current_line[_current_line_offset] : 0; }
	//��������� ������
	inline char cur1() { return (_current_line_offset+1) < _current_line.size() ? _current_line[_current_line_offset+1] : 0; }
	//������� � ���������� �������
	inline void next() { _current_line_offset++; }

	void lastTokenStr(Token& token);

	void processLine(std::vector<Token>& tokens);
protected:
	std::string _filename;
	std::string _filebody;
	std::size_t _filebody_offset;

	int _current_line_idx; //����� ������� ������. 1 - ����� ������� ������
	std::string _current_line;
	std::size_t _current_line_offset; //�������� � �������� _current_line
};