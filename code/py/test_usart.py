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

def sendLed(leds):
	command = COMMAND_SET_LED
	address = 0
	size = leds
	data = struct.pack("=BHH", command, address, size)
	ser.write(data)

def sendWriteDataMemory(address, memoryContent):
	command = COMMAND_WRITE_DATA_MEMORY
	size = len(memoryContent)
	data = bytearray(struct.pack("=BHH", command, address, size))
	for d in memoryContent:
		db = struct.pack("=I", d)
		data.append(db[0])
		data.append(db[1])
		data.append(db[2])

	ser.write(data)

def sendReadDataMemory(address, size):
	command = COMMAND_READ_DATA_MEMORY
	data = struct.pack("=BHH", command, address, size)
	ser.write(data)
	data = ser.read(size*3)
	assert(len(data)==size*3)
	out = []
	for i in range(size):
		n = data[i*3]+data[i*3+1]*0x100+data[i*3+2]*0x10000;
		out.append(n)
	return out

if __name__ == "__main__":
	if not connect():
		print("Cannot connect to serial port")
		exit(1)


	#sendLed(0x0F)
	memoryContent = [3, 7, 12, 28, 255, 12345, 65789, 102302]
	#sendWriteDataMemory(0, memoryContent)

	print(sendReadDataMemory(0, 20))
	
	pass
