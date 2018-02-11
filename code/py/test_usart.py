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
COMMAND_SET_RESET = 5
COMMAND_READ_REGISTERS = 6


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


def sendLed(leds):
	command = COMMAND_SET_LED
	address = 0
	size = leds
	data = struct.pack("=BHH", command, address, size)
	ser.write(data)

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
	data = struct.pack("=BHH", command, address, size)
	ser.write(data)
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

def sendReadRegisters():
	address = 0
	size = 9
	return sendReadMemory(COMMAND_READ_REGISTERS, address, size)

def sendReset(resetOn):
	if resetOn:
		size = 1
	else:
		size = 0
	data = struct.pack("=BHH", COMMAND_SET_RESET, 0, size)
	ser.write(data)

def sendProgram(filename):
	prog = readProgram(filename)
	print(prog)
	if not prog:
		print("Cannot read program `"+filename+"`")
	sendWriteCodeMemory(0, prog)

if __name__ == "__main__":
	if not connect():
		print("Cannot connect to serial port")
		exit(1)

	sendReset(1)
	sendProgram("../intermediate/code.hex")
	print("code=", sendReadCodeMemory(0, 64))
	sendReset(0)
	time.sleep(0.2)
	print("data=", sendReadDataMemory(0, 20))
	print("reg=", sendReadRegisters())

	#sendLed(0x0F)
	#sendWriteDataMemory(0, [3, 7, 12, 28, 255, 12345, 65789, 102302])
	#sendWriteCodeMemory(0, [1024, 1000, 100, 50, 25])

	#print("data=", sendReadDataMemory(0, 20))
	#print("code=", sendReadCodeMemory(0, 20))
	#print("reg=", sendReadRegisters())
	
	pass
