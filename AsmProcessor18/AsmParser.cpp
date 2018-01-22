#include "stdafx.h"
#include "AsmParser.h"
#include <fstream>

static bool isSpace(char c)
{
	return c == 9 || c == 32;
}

static bool isSpaceOrNull(char c)
{
	return c == 9 || c == 32 || c==0;
}

static bool isAlpha(char c)
{
	return (c>='a' && c<='z') || (c>='A' && c<='Z');
}

static bool isNumber(char c)
{
	return c >='0' && c<='9';
}

static bool isBinNumber(char c)
{
	return c >= '0' && c <= '7';
}

static bool isOctNumber(char c)
{
	return c >= '0' && c <= '7';
}

static bool isHexNumber(char c)
{
	return (c>='0' && c<='9') ||
		   (c>='a' && c<='f') ||
		   (c>='A' && c<='F');
}

static bool isBrackets(char c)
{
	return c=='(' || c==')' ||
		   c=='[' || c==']';
}

static bool isAlphaNumber(char c)
{
	return isAlpha(c) || isNumber(c);
}

AsmParser::AsmParser()
{
}

AsmParser::~AsmParser()
{
}

bool AsmParser::load(std::string filename)
{
	_filename = filename;
	std::ifstream file;
	file.open(filename.c_str(), std::ios::binary);
	if (!file)
	{
		std::cerr << "Cannot open file '" << filename << "'"<< std::endl;
		return false;
	}

	// get length of file:
	file.seekg(0, std::ios::end);
	std::size_t length = (std::size_t)file.tellg();
	file.seekg(0, std::ios::beg);

	_filebody.resize(length);

	file.read((char*)_filebody.data(), length);
	return true;
}

void AsmParser::parse()
{
	_current_line_idx = 0;
	_filebody_offset = 0;
	while (nextLine())
	{
		//std::cout << _current_line_idx << " - " << _current_line << std::endl;

		std::vector<Token> tokens;
		while (cur())
		{
			Token token = parseToken();
			if (token.str.empty())
				break;
			if (token.type == TokenType::Bad)
				error("Bad token", token.line_offset);
			//printToken(token);
			tokens.push_back(token);
		}

		processLine(tokens);
	}
}

bool AsmParser::nextLine()
{
	_current_line_offset = 0;
	_current_line.clear();
	if (_filebody_offset >= _filebody.size())
		return false;

	std::size_t cur_offset = _filebody_offset;
	while (cur_offset < _filebody.size())
	{
		if (_filebody[cur_offset] == 13)
		{
			break;
		}

		cur_offset++;
	}

	_current_line.assign(_filebody.data() + _filebody_offset, cur_offset - _filebody_offset);

	bool line_is = !_current_line.empty();
	if (cur_offset < _filebody.size())
	{
		line_is = true;
		cur_offset++;
		if (cur_offset < _filebody.size() && _filebody[cur_offset] == 10)
			cur_offset++;
	}

	_filebody_offset = cur_offset;

	if (line_is)
	{
		_current_line_idx++;
		return true;
	}

	return false;
}

bool AsmParser::skipSpace()
{
	bool skipped = false;
	while (char c = cur())
	{
		if (isSpace(c)) //tab or space
			next();
		else
			break;
	}

	return skipped;
}

void AsmParser::lastTokenStr(Token& token)
{
	token.str.assign(_current_line.data() + token.line_offset, _current_line_offset - token.line_offset);
}

Token AsmParser::parseToken()
{
	Token token;
	skipSpace();

	token.line_offset = _current_line_offset;

	token.op = parseOperator();
	if (token.op != OperatorType::Bad)
	{
		token.type = TokenType::Operator;
		lastTokenStr(token);
		return token;
	}

	if (isBrackets(cur()))
	{
		next();
		lastTokenStr(token);
		token.type = TokenType::Brackets;
		return token;
	}

	if (cur() == '/' && cur1() == '/')
	{
		token.type = TokenType::Comment;
		next();
		next();
		token.str.assign(_current_line.data() + _current_line_offset, _current_line.size() - _current_line_offset);
		_current_line_offset = _current_line.size();
		return token;
	}

	if (isAlpha(cur()))
	{
		next();
		for (; isAlphaNumber(cur()); next())
		{
		}

		if (cur() == ':')
		{
			next();
			lastTokenStr(token);
			token.type = TokenType::Label;
			return token;
		}

		//alphanumetic token
		lastTokenStr(token);

		if (token.str.size() == 2 && token.str[0]=='r' &&
			token.str[1]>='0' && token.str[1]<='7'
			)
		{
			token.type = TokenType::Register;
			token.register_index = token.str[1]-'0';
			return token;
		}

		token.type = TokenType::Id;
		return token;
	}

	if (isNumber(cur()))
	{
		char first = cur();

		//digit
		next();

		bool is_hex = first == '0' && cur()=='x';
		bool is_bin = first == '0' && cur() == 'b';
		bool is_oct = first == '0' && isNumber(cur());

		if (is_hex)
		{
			//hexadecimal digit
			next();
			for (; isHexNumber(cur()); next());
			if (checkEndTag())
			{
				//number
				lastTokenStr(token);
				token.number = strtol(token.str.c_str()+2, 0, 16);
				token.type = TokenType::Number;
				return token;
			}
		}

		if (is_oct)
		{
			//octal digit
			next();
			for (; isOctNumber(cur()); next());
			if (checkEndTag())
			{
				//number
				lastTokenStr(token);
				token.number = strtol(token.str.c_str() + 1, 0, 8);
				token.type = TokenType::Number;
				return token;
			}
		}

		if (is_bin)
		{
			//octal digit
			next();
			for (; isBinNumber(cur()); next());
			if (checkEndTag())
			{
				//number
				lastTokenStr(token);
				token.number = strtol(token.str.c_str() + 2, 0, 2);
				token.type = TokenType::Number;
				return token;
			}
		}

		//decimal digit
		for (; isNumber(cur()); next());
		if (checkEndTag())
		{
			//number
			lastTokenStr(token);
			token.number = atoi(token.str.c_str());
			token.type = TokenType::Number;
			return token;
		}

		//Bad token
		_current_line_offset = token.line_offset;
	}

	//Bad token = all characters to end string
	token.str.assign(_current_line.data() + _current_line_offset, _current_line.size() - _current_line_offset);
	_current_line_offset = _current_line.size();
	return token;
}

bool AsmParser::checkEndTag()
{
	char c = cur();
	if (isSpaceOrNull(c))
		return true;
	if (parseOperator(false) != OperatorType::Bad)
		return true;

	if (isBrackets(c))
		return true;

	return false;
}

OperatorType AsmParser::parseOperator(bool parse)
{
	char c = cur();
	if (c == '=')
	{
		c = cur1();
		if (c == '=')
		{
			if (parse)
			{
				next();
				next();
			}
			return OperatorType::Equal;
		}

		if (parse) next();
		return OperatorType::Copy;
	}

	if (c == '+')
	{
		if (parse) next();
		return OperatorType::Plus;
	}

	if (c == '-')
	{
		if (parse) next();
		return OperatorType::Minus;
	}

	return OperatorType::Bad;
}

std::string AsmParser::strOperator(OperatorType op)
{
	struct D
	{
		OperatorType op;
		std::string str;
	};

	std::vector<D> data
	{
		{ OperatorType::Bad , "Bad"},
		{ OperatorType::Copy, "Copy" },
		{ OperatorType::Plus, "Plus" },
		{ OperatorType::Minus, "Minus" },
		{ OperatorType::Equal, "Equal" },
	};

	for (const D& d : data)
		if (d.op == op)
			return d.str;

	return data[0].str;
}

void AsmParser::printToken(Token& token)
{
	if (token.type == TokenType::Bad)
	{
		std::cout << "Bad token '" << token.str << "'" << std::endl;
	} else
	if (token.type == TokenType::Register)
	{
		std::cout << "Register '" << token.str << "'  n=" << token.register_index << std::endl;
	} else
	if (token.type == TokenType::Operator)
	{
		std::cout << "Operator '" << token.str << "'  op=" << strOperator(token.op) << std::endl;
	} else
	if (token.type == TokenType::InstructionPointer)
	{
		std::cout << "InstructionPointer '" << token.str << "'" << std::endl;
	} else
	if (token.type == TokenType::Number)
	{
		std::cout << "Number '" << token.str << "'  N=" << token.number << std::endl;
	} else
	if (token.type == TokenType::Comment)
	{
		std::cout << "Comment '" << token.str << "'" << std::endl;
	} else
	if (token.type == TokenType::Label)
	{
		std::cout << "Label '" << token.str << "'" << std::endl;
	} else
	if (token.type == TokenType::Id)
	{
		std::cout << "Id '" << token.str << "'" << std::endl;
	} else
	if (token.type == TokenType::Brackets)
	{
		std::cout << "Brackets '" << token.str << "'" << std::endl;
	} else
	{
		std::cout << "Undefined token '" << token.str << "'" << " type=" << (int)token.type << std::endl;
	}
}

void AsmParser::error(std::string message, int row)
{
	std::cout << "Error at line=" << _current_line_idx << " row=" << row << std::endl;
	std::cout << _current_line << std::endl;
	std::cout << message << std::endl;
	exit(1);
}

void AsmParser::errorRequiredToken(const std::string& message, std::vector<Token>& tokens, size_t idx)
{
	int row = 0;
	if (idx < tokens.size())
		row = tokens[idx].line_offset;
	else
	if (tokens.size()>0)
		row = tokens.back().line_offset;
	error(message, row);
}

void AsmParser::errorRequiredOperand(std::vector<Token>& tokens, size_t idx)
{
	errorRequiredToken("Required operand", tokens, idx);
}

void AsmParser::errorRequiredNumber(std::vector<Token>& tokens, size_t idx)
{
	errorRequiredToken("Required number", tokens, idx);
}

void AsmParser::errorRequiredRegister(std::vector<Token>& tokens, size_t idx)
{
	errorRequiredToken("Required register", tokens, idx);
}

void AsmParser::errorExtraLiteral(std::vector<Token>& tokens, size_t idx)
{
	errorRequiredToken("Extra literal", tokens, idx);
}

void AsmParser::processLine(std::vector<Token>& tokens)
{
	//remove comments token
	for (auto it = tokens.begin(); it != tokens.end(); )
	{
		if (it->type == TokenType::Comment)
			it = tokens.erase(it);
		else
			++it;
	}

	if (tokens.size() == 0)
		return;

	//Sequence operator minus number convert to negative number
	for (size_t i = 0; i + 2 < tokens.size(); )
	{
		const Token& t0 = tokens[i];
		const Token& t1 = tokens[i+1];
		Token& t2 = tokens[i+2];

		if ((t0.type == TokenType::Operator || t0.type == TokenType::Brackets) &&
			t1.type == TokenType::Operator && t1.op == OperatorType::Minus &&
			t2.type == TokenType::Number
			)
		{
			t2.str = t1.str + t2.str;
			t2.number = -t2.number;
			tokens.erase(tokens.begin() + i + 1);
		}
		else
		{
			i++;
		}
	}

	int k = 0;
	// rX = ...
	if (tokens.size() >= 2 &&
		tokens[0].type == TokenType::Register &&
		tokens[1].isOperator(OperatorType::Copy)
		)
	{
		int rX = tokens[0].register_index;

		size_t cur_token = 2;
		if (cur_token >= tokens.size())
			errorRequiredOperand(tokens, cur_token);

		if (tokens[cur_token].type == TokenType::Number)
		{
			// rX = imm18
			int imm18 = tokens[cur_token].number;
			cur_token++;

			if (!code.isValidImm18(imm18))
				error("Immediate out of range [-131072, 131071]", tokens[2].line_offset);
			if(tokens.size() > 3)
				error("Bad syntax for rX = imm11", tokens[3].line_offset);

			code.addMovImm18(rX, imm18);
			return;
		}

		if (tokens[cur_token].type == TokenType::Register)
		{
			int rY = tokens[cur_token].register_index;
			cur_token++;

			if (cur_token < tokens.size() &&
				(tokens[cur_token].isOperator(OperatorType::Plus) ||
				tokens[cur_token].isOperator(OperatorType::Minus)
				))
			{
				// rX = rY +- imm8
				bool is_minus = tokens[cur_token].isOperator(OperatorType::Minus);
				cur_token++;

				if (cur_token >= tokens.size() || tokens[cur_token].type != TokenType::Number)
					errorRequiredNumber(tokens, cur_token);

				// rX = rY + imm8
				// rX = rY - imm8
				int imm8 = tokens[cur_token].number;
				if (is_minus)
					imm8 = -imm8;
				cur_token++;

				if (!code.isValidImm8(imm8))
					error("Immediate out of range [-128, 127]", tokens[2].line_offset);


				code.addAddRegImm8(rX, rY, imm8);

				if (cur_token < tokens.size())
					errorExtraLiteral(tokens, cur_token);
				return;
			}

			if (cur_token < tokens.size() && tokens[cur_token].isBracket('['))
			{
				//rX = rY[imm8]
				cur_token++;
				if (cur_token >= tokens.size() || tokens[cur_token].type != TokenType::Number)
					errorRequiredNumber(tokens, cur_token);
				int imm8 = tokens[cur_token].number;
				cur_token++;

				if (cur_token >= tokens.size() || !tokens[cur_token].isBracket(']'))
					errorRequiredToken("Required ]", tokens, cur_token);
				cur_token++;

				code.addLoadFromMemory(rX, rY, imm8);

				if (cur_token<tokens.size())
					errorExtraLiteral(tokens, cur_token);
				return;
			}
		}
	}

	// ry[imm8] = rx
	if (tokens.size() >= 2 &&
		tokens[0].type == TokenType::Register &&
		tokens[1].isBracket('[')
		)
	{
		int ry = tokens[0].register_index;

		size_t cur_token = 2;
		if (cur_token >= tokens.size() || tokens[cur_token].type != TokenType::Number)
			errorRequiredNumber(tokens, cur_token);
		int imm8 = tokens[cur_token].number;
		if (!code.isValidImm8(imm8))
			error("Immediate out of range [-128, 127]", tokens[cur_token].line_offset);
		cur_token++;

		if (cur_token >= tokens.size() || !tokens[cur_token].isBracket(']'))
			errorRequiredToken("Required ]", tokens, cur_token);
		cur_token++;

		if (cur_token >= tokens.size() || !tokens[cur_token].isOperator(OperatorType::Copy))
			errorRequiredToken("Required =", tokens, cur_token);
		cur_token++;

		if (cur_token >= tokens.size() || tokens[cur_token].type != TokenType::Register)
			errorRequiredRegister(tokens, cur_token);
		int rx = tokens[cur_token].register_index;
		cur_token++;

		code.addStoreToMemory(rx, ry, imm8);

		if (cur_token<tokens.size())
			errorExtraLiteral(tokens, cur_token);
		return;
	}



	error("Bad token sequence", 0);
	return;
}
