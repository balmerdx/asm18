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

intermediateDir = abspath("intermediate")
voutFile = join(intermediateDir, "wout.vvp")
vcdFile = join(intermediateDir, "wout.vcd")
codeHex = join(intermediateDir, "code.hex")
currentState = join(intermediateDir, "current.state")

if sys.platform=="linux":
	assemblerExecutable = abspath("../AsmProcessor18/qt/AsmProcessor18-Debug/AsmProcessor18")
else:
	assemblerExecutable = abspath("../AsmProcessor18/VC2013/Debug/AsmProcessor18.exe")
assemblerSamples = abspath("../AsmSamples")
print(assemblerSamples)

sourceProcessor = [
	"summator.v",
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
		
	print("Build verilog files...")
	runCommand(command)
	pass

def assembleAsm18(asmName):
	print("Compile `"+asmName+"`")
	command = [assemblerExecutable, asmName, "-o", "intermediate/code.hex"]
	runCommand(command)
	pass

def runSimulation():
	print("Run simulation...")
	if not os.path.isfile(codeHex):
		print("File not found `"+codeHex+"`")
		exit(1)
	if os.path.isfile(vcdFile):
		os.remove(vcdFile)
	command = ["vvp", voutFile]
	runCommand(command)
	pass
	
def compareFiles(stateName, currentState):
	fs = open(stateName, "r")
	stateLines = fs.readlines()
	fs.close()
	
	fs = open(currentState, "r")
	currentLines = fs.readlines()
	fs.close()
	
	minlines = min(len(stateLines), len(currentLines))
	
	for i in range(minlines):
		if stateLines[i]!=currentLines[i]:
			print("Compare `"+stateName+"` and `"+currentState+"`")
			print("Lines not matched line="+str(i+1))
			exit(1)
			
	if len(stateLines)!=len(currentLines):
		print("Compare `"+stateName+"` and `"+currentState+"`")
		print("File len not mathced")
		exit(1)
	
	pass

def test(asmName):
	print("Start test `"+asmName+"`")
	asmNameAbs = abspath(asmName)
	fileExist(asmNameAbs)
		
	stateName = os.path.splitext(asmNameAbs)[0]+".state"
	fileExist(stateName)
	
	assembleAsm18(asmNameAbs)
	fileExist(codeHex)
	runSimulation()
	fileExist(currentState)
	
	compareFiles(stateName, currentState)
	
	print("Test success `"+asmName+"`")
	pass

def main():
	if len(sys.argv)==1:
		print("Compile and run testbench, call from parent directory")
		print("Example: python testbench/test.py build");
		print("build - compile verilog processor")
		print("compile filename - compile asm18 file")
		print("run - run simulation")
		print("test filename - start testbench and check result")
		return
		
	if "build"==sys.argv[1]:
		buildVerilog(generateVcd=True)
		return
	if "compile"==sys.argv[1]:
		assembleAsm18(sys.argv[2])
		return
	if "run"==sys.argv[1]:
		runSimulation()
		return
	if "test"==sys.argv[1]:
		buildVerilog(generateVcd=False)
		test(sys.argv[2])
		return
	pass
	
if __name__ == '__main__':
	main()
