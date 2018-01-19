#include "stdafx.h"
#include "AsmParser.h"

int main(int argc, char* argv[])
{
	if (argc < 2)
	{
		std::cout << "AsmProcessor18 is asm18 compilator" << std::endl;
		std::cout << "AsmProcessor18.exe asm_file.asm18" << std::endl;
		return 1;
	}

	AsmParser parser;
	std::string input_filename = argv[1];
	if (!parser.load(input_filename))
		return 1;
	parser.parse();

	parser.code.fillTo(64);
	parser.code.writeToTextFile(input_filename+".hex");

	return 0;
}

