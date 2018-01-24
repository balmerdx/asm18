module alu #(parameter integer WORD_SIZE = 18)
	(
	input wire [WORD_SIZE-1:0] r0,
	input wire [WORD_SIZE-1:0] r1,
	input wire [3:0] op, //operation
	output reg [WORD_SIZE-1:0] res //result
	);
	
	parameter integer ALU_OP_REG0 = 0;
	parameter integer ALU_OP_REG1 = 1;
	parameter integer ALU_OP_ADD = 2;
	parameter integer ALU_OP_SUB = 3;
	parameter integer ALU_OP_AND = 4;
	parameter integer ALU_OP_OR = 5;
	parameter integer ALU_OP_XOR = 6;
	parameter integer ALU_OP_NOT = 7;

	
	always @(*)
	begin
		case(op)
		ALU_OP_REG0: res = r0;
		ALU_OP_REG1: res = r1;
		ALU_OP_ADD: res = r0+r1;
		ALU_OP_SUB: res = r0-r1;
		ALU_OP_AND: res = r0 & r1;
		ALU_OP_OR: res = r0 | r1;
		ALU_OP_XOR: res = r0 ^ r1;
		ALU_OP_NOT: res = ~r1;
		default: res = 0;
		endcase
	end
endmodule