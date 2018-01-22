#include "stdafx.h"
#include "AsmParser.h"

int main(int argc, char* argv[])
{
	if (argc < 2)
	{
		std::cout << "AsmProcessor18 is asm18 compilator" << std::endl;
		std::cout << "AsmProcessor18.exe asm_file.asm18 [options]" << std::endl;
		std::cout << "Options:" << std::endl;
		std::cout << "  -o out_filename" << std::endl;
		return 1;
	}

	AsmParser parser;
	std::string input_filename = argv[1];
	if (!parser.load(input_filename))
		return 1;

	std::string out_filename = input_filename + ".hex";
	for (int i = 2; i < argc; i++)
	{
		if (strcmp(argv[i], "-o") == 0 && i + 1 < argc)
		{
			out_filename = argv[i + 1];
			i++;
		}
	}

	parser.parse();

	parser.code.fillTo(64);
	parser.code.writeToTextFile(out_filename);

	return 0;
}

