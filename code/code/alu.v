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

	
	always @(*)
	begin
		case(op)
		ALU_OP_REG0: res = r0;
		ALU_OP_REG1: res = r1;
		ALU_OP_ADD: res = r0+r1;
		default: res = 0;
		endcase
	end
endmodule