typedef enum logic [3:0] {
	OP_REG_ADD_IMM8 = 4'h0, //rx = ry + imm8
	OP_REG_MOV_IMM11 = 4'h1, //rx = imm11
	OP_REG_MOV_IMM11_TOP = 4'h2, //rx = imm11<<7
	OP_LOAD_FROM_MEMORY = 4'h3, //rx = ry[imm8]
	OP_WRITE_TO_MEMORY = 4'h4, //ry[imm8] = rx
	OP_IF = 4'h5, //if(rx op) goto ip+addr
	OP_ALU = 4'h6, //rx = rx alu_op ry
	OP_MUL_SHIFT = 4'h7, // rx = (rx*ry) >> imm
	OP_CALL_IMM14 = 4'h8, // call imm14
	OP_RETURN = 4'h9, // ip = ry[imm8]
	OP_WAIT = 4'hA
} OPCODES;

