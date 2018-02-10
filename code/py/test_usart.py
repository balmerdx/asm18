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

	print(data)

	ser.write(data)

def sendReadDataMemory(address, size):
	command = COMMAND_READ_DATA_MEMORY
	data = struct.pack("=BHH", command, address, size)
	ser.write(data)
	received_size = 0
	while(received_size<size*3):
		data = ser.read()

		for b in data:
			i = int(b)
			print(hex(i), i%4, i//4, end="")
		print("")
		time.sleep(0.1)

if __name__ == "__main__":
	if not connect():
		print("Cannot connect to serial port")
		exit(1)


	#sendLed(0xF0)
	#memoryContent = [3, 7, 12, 28]
	#sendWriteDataMemory(0, memoryContent)

	sendReadDataMemory(7,4)

	'''
	data = bytearray()
	data.append(0)
	ser.write(data)
	time.sleep(0.2)
	'''

	'''	
	for i in range(256):
		data = bytearray()
		data.append(i)
		ser.write(data)
		time.sleep(1)
	'''
	
	
	'''
	for i in range(255):
		data = bytearray()
		data.append(i)
		print(data, end="")
		ser.write(data)
		time.sleep(0.1)
		data = ser.read()
		print(data)
	'''
	
	'''
	is_empty = False
	while True:
		line = ser.readline()
		if len(line)==0:
			is_empty = True
			print(".", end='')
			sys.stdout.flush()
			continue

		if is_empty:
			print("")
		is_empty = False
		value = line.decode('latin1')[:-1]
		print(datetime.datetime.now(), " : ", value)
	'''
	pass
