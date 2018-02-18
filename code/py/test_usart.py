#!/usr/bin/env /usr/bin/python3.5

import time
import serial
import datetime
import sys
import struct

#dmesg | grep tty  <--- ubuntu com port list
# ls /dev/cu.* <--- find device MacOs

# Все коменды начинаются с 5 байт
# байт 0 - command
# байт 1,2 - address
# байт 3,4 - size
COMMAND_SET_LED = 0
COMMAND_WRITE_DATA_MEMORY = 1
COMMAND_READ_DATA_MEMORY = 2
COMMAND_WRITE_CODE_MEMORY = 3
COMMAND_READ_CODE_MEMORY = 4
COMMAND_CLEAR_DATA_MEMORY = 5;
COMMAND_CLEAR_CODE_MEMORY = 6;
COMMAND_SET_RESET = 7
COMMAND_READ_REGISTERS = 8
COMMAND_STEP = 9
COMMAND_TIMER = 10


ser = None

def connect():
	global ser
	ser = serial.Serial(
		#port='/dev/cu.usbserial',
		port='/dev/ttyUSB0',
		baudrate=500000,
		parity=serial.PARITY_NONE,
		stopbits=serial.STOPBITS_ONE,
		bytesize=serial.EIGHTBITS,
		timeout = 0.1
	)

	return ser.isOpen()

def close():
	ser.close()


def readProgram(filename):
	fs = open(filename, "r")
	if not fs:
		return None
	lines = fs.readlines()
	fs.close()

	arr = []
	for line in lines:
		arr.append(int(line, 16))

	return arr

def sendCommand(command, address, size):
	data = struct.pack("=BHH", command, address, size)
	ser.write(data)

def sendLed(leds):
	command = COMMAND_SET_LED
	address = 0
	size = leds
	sendCommand(command, address, size)

def sendWriteMemory(command, address, memoryContent):
	size = len(memoryContent)
	data = bytearray(struct.pack("=BHH", command, address, size))
	for d in memoryContent:
		db = struct.pack("=I", d)
		data.append(db[0])
		data.append(db[1])
		data.append(db[2])

	ser.write(data)

def sendReadMemory(command, address, size):
	sendCommand(command, address, size)

	data = ser.read(size*3)
	assert(len(data)==size*3)
	out = []
	for i in range(size):
		n = data[i*3]+data[i*3+1]*0x100+data[i*3+2]*0x10000;
		out.append(n)
	return out

def sendWriteDataMemory(address, memoryContent):
	sendWriteMemory(COMMAND_WRITE_DATA_MEMORY, address, memoryContent)

def sendReadDataMemory(address, size):
	return sendReadMemory(COMMAND_READ_DATA_MEMORY, address, size)

def sendWriteCodeMemory(address, memoryContent):
	sendWriteMemory(COMMAND_WRITE_CODE_MEMORY, address, memoryContent)

def sendReadCodeMemory(address, size):
	return sendReadMemory(COMMAND_READ_CODE_MEMORY, address, size)

def sendClearDataMemory(address, size):
	sendCommand(COMMAND_CLEAR_DATA_MEMORY, address, size)
	time.sleep(1e-3)

def sendClearCodeMemory(address, size):
	sendCommand(COMMAND_CLEAR_CODE_MEMORY, address, size)
	time.sleep(1e-3)

def sendReadRegisters():
	address = 0
	size = 9
	return sendReadMemory(COMMAND_READ_REGISTERS, address, size)

def sendReset(resetOn, debugGetParamOn):
	addr = 0
	size = 0
	if resetOn:
		addr += 1
	if debugGetParamOn:
		addr += 2
	sendCommand(COMMAND_SET_RESET, addr, size)

def sendStep(count):
	#запускаем процессор на несколько шагов
	sendCommand(COMMAND_STEP, 0, count)
	

def sendProgram(filename):
	prog = readProgram(filename)
	#print(prog)
	if not prog:
		print("Cannot read program `"+filename+"`")
	sendWriteCodeMemory(0, prog)

def sendGetTimer():
	sendCommand(COMMAND_TIMER, 0, 0)
	data = ser.read(4)
	assert(len(data)==4)
	return struct.unpack("=I", data)[0]

def printReg(reg):
	print("reg=", reg[0:8])
	print("ip=", reg[8])

def saveState(filename):
	mem = sendReadDataMemory(0, 64)
	reg = sendReadRegisters()
	f = open(filename, "wt")
	print("registers", file=f);
	for i in range(8):
		print("r{0} = {1:05x}".format(i, reg[i]), file=f);
	print("ip = {:05x}".format(reg[8]), file=f);
	print("memory", file=f);
	for m in mem:
		print("{:05x}".format(m), file=f);
	f.close()

def runProgram():
	time.sleep(1e-3)
	sendReset(resetOn=1, debugGetParamOn=0)
	sendClearDataMemory(0, 511)
	sendClearCodeMemory(0, 511)
	sendProgram("intermediate/code.hex")
	sendReset(resetOn=0, debugGetParamOn=0)
	time.sleep(0.01)

	timeQuants = sendGetTimer()
	saveState("intermediate/current.state")
	return timeQuants

if __name__ == "__main__":
	if not connect():
		print("Cannot connect to serial port")
		exit(1)

	sendReset(resetOn=1, debugGetParamOn=0)
	sendClearDataMemory(0, 511)
	sendClearCodeMemory(0, 511)
	sendProgram("../intermediate/code.hex")
	#sendReset(resetOn=0, debugGetParamOn=1)
	#sendStep(2)
	sendReset(resetOn=0, debugGetParamOn=0)
	time.sleep(0.01)

	saveState("state.txt")
	#print("code=", sendReadCodeMemory(0, 20))


	'''
	sendReset(1, 0)
	sendWriteDataMemory(0, [101,102,103,104,105,106,107,108,109,110,111,112,113,114,115])
	sendWriteCodeMemory(0, [1,2,3,4,5,6,7,8,9,10,11,12,13,14,15])
	saveState("state.txt")
	print("data=", sendReadDataMemory(0, 20))
	print("code=", sendReadCodeMemory(0, 20))
	sendClearDataMemory(0, 511)
	sendClearCodeMemory(0, 511)
	print("data=", sendReadDataMemory(0, 20))
	print("code=", sendReadCodeMemory(0, 20))
	'''
	pass
