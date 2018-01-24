#pragma once
#include "AsmMaker.h"
#include <unordered_map>

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
	Less, //<
	Great,//>
	LessOrEqual,//<=
	GreatOrEqual,//>=
	PlusEqual,//+=
	MinusEqual,//-=
	AndEqual,//&=
	OrEqual,//|=
	XorEqual,//+=
	Not, //~
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
	bool isBracket(char c) const { return type == TokenType::Brackets && (str.size() == 1 && str[0]==c); }
};

/*
	На каждой строке находится одна инструкция.
	В инструкции может быть оператор и операнды.
	Например:
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
	void errorRequiredToken(const std::string& message, std::vector<Token>& tokens, size_t idx);
	void errorRequiredOperand(std::vector<Token>& tokens, size_t idx);
	void errorRequiredNumber(std::vector<Token>& tokens, size_t idx);
	void errorRequiredRegister(std::vector<Token>& tokens, size_t idx);
	void errorExtraLiteral(std::vector<Token>& tokens, size_t idx);

	bool nextLine();

	//Get token and move _current_line_offset
	Token parseToken();
	OperatorType parseOperator(bool parse=true);
	bool checkEndTag();

	std::string strOperator(OperatorType op);
	void printToken(Token& token);

	bool skipSpace();

	//Текущий символ
	inline char cur() { return _current_line_offset < _current_line.size() ? _current_line[_current_line_offset] : 0; }
	//Следующий символ
	inline char cur1() { return (_current_line_offset+1) < _current_line.size() ? _current_line[_current_line_offset+1] : 0; }
	//Переход к следующему символу
	inline void next() { _current_line_offset++; }

	void lastTokenStr(Token& token);

	void processLine(std::vector<Token>& tokens);

	void link();

	void removeSinglelineCommentToken(std::vector<Token>& tokens);
	void simplifyNegativeNumber(std::vector<Token>& tokens);

	bool parseIfGoto(std::vector<Token>& tokens);
	bool parseAluOperation(std::vector<Token>& tokens);
protected:
	std::string _filename;
	std::string _filebody;
	std::size_t _filebody_offset;

	int _current_line_idx; //Номер текущей строки. 1 - самая верхняя строка
	std::string _current_line;
	std::size_t _current_line_offset; //Смещение в пределах _current_line

	struct Label
	{
		std::string name;
		std::size_t text_line = 0;
	};

	std::unordered_map<std::string, Label> labels;
};