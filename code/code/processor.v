`include "alu_const.v"

module processor #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18)
	(input wire clock,
	input logic reset,
	
	//Интерфейс для чтения программы
	output wire [(ADDR_SIZE-1):0] code_addr,
	input wire [(WORD_SIZE-1):0] code_word
/*	,
	//Интерфейс для чтения данных
	output wire data_write_enable,
	output wire [(ADDR_SIZE-1):0] data_addr,
	output wire [(WORD_SIZE-1):0] data_in,
	input wire [(WORD_SIZE-1):0] data_out
*/	
	);
	
	logic [3:0] reg_read_addr0;
	logic [(WORD_SIZE-1):0] reg_read_data0;
	logic [3:0] reg_read_addr1;
	logic [(WORD_SIZE-1):0] reg_read_data1;
	logic reg_write_enable;
	logic [3:0] reg_write_addr;
	logic [(WORD_SIZE-1):0] reg_write_data;
	
	//constant in opcode
	logic [(WORD_SIZE-1):0] imm;
	
	regfile #(.WORD_SIZE(WORD_SIZE))
		registers
		(.clock(clock),
		.reset(reset),
		.read_addr0(reg_read_addr0),
		.read_data0(reg_read_data0),
		.read_addr1(reg_read_addr1),
		.read_data1(reg_read_data1),
		.write_enable(reg_write_enable),
		.write_addr(reg_write_addr),
		.write_data(reg_write_data)
		);

	logic select_alu_reg0;
	logic select_alu_reg1;
	logic [(WORD_SIZE-1):0] alu_data0;
	logic [(WORD_SIZE-1):0] alu_data1;
	logic [3:0] alu_operation;
	
	always @(*)
	begin
		alu_data0= select_alu_reg0?reg_read_data0:imm;
		alu_data1 = select_alu_reg1?reg_read_data1:imm;
	end
	
	alu #(.WORD_SIZE(WORD_SIZE))
		alu0(
		.r0(alu_data0),
		.r1(alu_data1),
		.op(alu_operation),
		.res(reg_write_data)
		);
	
	// instruction pointer
	reg [(WORD_SIZE-1):0] ip;
	assign code_addr = ip;
	assign enable_add_ip = 1;
	
	
	wire [3:0] code_word_top;
	assign code_word_top = code_word[17:14];
	
	always @(*)
	begin
		reg_write_enable = 0;
		reg_write_addr = 0;
		reg_read_addr0 = 0;
		reg_read_addr1 = 0;
		//default imm8 data
		imm = {{10{code_word[7]}}, code_word[7:0]};
		
		alu_operation = `ALU_OP_REG0;
		select_alu_reg0 = 1;
		select_alu_reg1 = 1;
			
		if(code_word_top==1)
		begin
			//rx = imm11
			reg_write_enable = 1;
			reg_write_addr = code_word[13:11];
			imm = {{7{code_word[10]}}, code_word[10:0]};
			
			alu_operation = `ALU_OP_REG0;
			select_alu_reg0 = 0;
		end
		else
		if(code_word_top==4)
		begin
			//rx = ry + imm8
			reg_write_enable = 1;
			reg_write_addr = code_word[13:11];
			reg_read_addr0 = code_word[10:8];
			
			alu_operation = `ALU_OP_ADD;
			select_alu_reg0 = 1;
			select_alu_reg1 = 0;
		end
	end
	
	always @(posedge clock)
	if(reset)
	begin
		ip = 0;
	end
	else
	begin
		if(enable_add_ip)
			ip <= ip + 1;
	end

endmodule

module adder8 #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18, parameter integer MEM_SIZE = 1024)
	(
		output wire unsigned [(WORD_SIZE-1):0] resout,
		input wire unsigned [(WORD_SIZE-1):0] arg1,
		input wire signed [7:0] arg2
	);
	
	assign resout = arg1 + arg2;
endmodule