#!/usr/bin/env /usr/bin/python3.5
'''
Скрипт для:
 - компиляции verilog файлов
 - компиляции asm18 файлов
 - запуска тестовых заданий
 - проверки, что результат совпадает с ожидаемым
 
 формат python testbench/test.py commandline
'''
import subprocess
import sys
import os
import os.path
from os.path import abspath, normpath, join

COLOR_RED   = "\033[1;31m"  
COLOR_BLUE  = "\033[1;34m"
COLOR_CYAN  = "\033[1;36m"
COLOR_GREEN = "\033[0;32m"
COLOR_RESET = "\033[0;0m"
COLOR_BOLD    = "\033[;1m"
COLOR_REVERSE = "\033[;7m"

from tests_list import tests_list
import test_usart

intermediateDir = abspath("intermediate")
voutFile = join(intermediateDir, "wout.vvp")
vcdFile = join(intermediateDir, "wout.vcd")
codeHex = join(intermediateDir, "code.hex")
currentState = join(intermediateDir, "current.state")

runOnHardware = False
alltests = False

if sys.platform=="linux":
	assemblerExecutable = abspath("../AsmProcessor18/qt/AsmProcessor18-Debug/AsmProcessor18")
else:
	assemblerExecutable = abspath("../AsmProcessor18/VC2013/Debug/AsmProcessor18.exe")

sourceProcessor = [
	"ram.v",
	"regfile.v",
	"processor.v",
	"alu.v",
	"if_control.v",
	"mulxx.v"
	]

sourceTb = ["testbench/processor_tb.v"]

def runCommand(command):
	result = subprocess.run(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
	if not alltests or result.returncode!=0:
		print(result.stdout, result.stderr)
	if result.returncode!=0:
		exit(result.returncode)
		
def fileExist(filename):
	if not os.path.isfile(filename):
		print("File not found `"+filename+"`")
		exit(1)
	pass

def buildVerilog(generateVcd=False):
	command = ["iverilog", "-o", voutFile, "-g", "2012", "-g", "verilog-ams", "-I", "testbench", "-I", "code"]
	
	if generateVcd:
		command.append("-DOUT_VCD")

	for source in sourceProcessor:
		command.append(join("code", source))
	for source in sourceTb:
		command.append(source)

	command.append("-DPROCESSOR_DEBUG_INTERFACE")
		
	print("Build verilog files...")
	runCommand(command)
	pass

def assembleAsm18(asmName):
	if not alltests: print("Compile `"+asmName+"`")
	command = [assemblerExecutable, asmName, "-o", "intermediate/code.hex"]
	runCommand(command)
	pass

def runSimulation():
	if not alltests: print("Run simulation...")
	if not os.path.isfile(codeHex):
		print("File not found `"+codeHex+"`")
		exit(1)
	if os.path.isfile(vcdFile):
		os.remove(vcdFile)
	command = ["vvp", voutFile]
	runCommand(command)
	pass

def runProgram():
	global runOnHardware
	if runOnHardware:
		return test_usart.runProgram()
	else:
		return runSimulation()
	pass

def removeEndline(line):
	line = line.strip('\n')
	line = line.strip('\r')
	return line
	
def compareFiles(stateName, currentState):
	fs = open(stateName, "r")
	stateLines = fs.readlines()
	fs.close()
	
	fs = open(currentState, "r")
	currentLines = fs.readlines()
	fs.close()
	
	minlines = min(len(stateLines), len(currentLines))
	
	for i in range(minlines):
		sl = removeEndline(stateLines[i])
		cl = removeEndline(currentLines[i])
		if sl=='xxxxx':
			sl = '00000'
		if cl=='xxxxx':
			cl = '00000'

		if sl!=cl:
			print("Compare `"+stateName+"` and `"+currentState+"`")
			print("Lines "+COLOR_RED+ "not matched" + COLOR_RESET+ " line="+str(i+1))
			print(sl)
			print(cl)
			exit(1)
			
	if len(stateLines)!=len(currentLines):
		print("Compare `"+stateName+"` and `"+currentState+"`")
		print("File len not mathced")
		exit(1)
	
	pass

def test(asmName):
	if not alltests: print("Start test `"+asmName+"`")
	asmNameAbs = abspath(asmName)
	fileExist(asmNameAbs)
		
	stateName = os.path.splitext(asmNameAbs)[0]+".state"
	
	assembleAsm18(asmNameAbs)
	fileExist(codeHex)
	timeQuants = runProgram()
	fileExist(currentState)
	fileExist(stateName)
	compareFiles(stateName, currentState)
	
	print("Test `"+asmName+"`" + COLOR_GREEN + " -success" + COLOR_RESET, end="")
	if timeQuants:
		print(" time="+str(timeQuants))
	else:
		print()

	pass

def main():
	global runOnHardware
	global alltests

	if len(sys.argv)==1:
		print("Compile and run testbench, call from parent directory")
		print("Example: python testbench/test.py build");
		print("build - compile verilog processor")
		print("compile filename - compile asm18 file")
		print("run - run simulation")
		print("test filename - start testbench and check result")
		print("alltests - start all testbench in Icarus Verilog")
		print("Add at end flag -hard - run on Cyclone IV, else run on Icarus Verilog")
		return

	for i in range(2, len(sys.argv)):
		if sys.argv[i]=="-hard":
			print("Run tests in hardware")
			runOnHardware = True
		pass

	if runOnHardware:
		if not test_usart.connect():
			print("Cannot connect to serial port")
			exit(1)

	if "build"==sys.argv[1]:
		buildVerilog(generateVcd=True)
		return
	if "compile"==sys.argv[1]:
		assembleAsm18(sys.argv[2])
		return
	if "run"==sys.argv[1]:
		runProgram()
		return
	if "test"==sys.argv[1]:
		buildVerilog(generateVcd=False)
		test(sys.argv[2])
		return

	if "alltests"==sys.argv[1]:
		alltests = True
		buildVerilog(generateVcd=False)
		for cur_test in tests_list:
			test(cur_test)

		return

	pass
	
if __name__ == '__main__':
	main()
