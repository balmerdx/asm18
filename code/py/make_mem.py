f = open("vmem.txt", "wt")

for addr in range(128):
	print("{:X}".format(addr+0x200), file=f)
