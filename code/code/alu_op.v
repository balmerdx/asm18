typedef enum logic [3:0] {
	ALU_OP_REG0 = 4'h0,
	ALU_OP_REG1 = 4'h1,
	ALU_OP_ADD = 4'h2,
	ALU_OP_SUB = 4'h3,
	ALU_OP_AND = 4'h4,
	ALU_OP_OR = 4'h5,
	ALU_OP_XOR = 4'h6,
	ALU_OP_NOT = 4'h7
} ALU_OP;

