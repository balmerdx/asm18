module processor #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18)
	(input wire clock,
	input logic reset,
	
	//Интерфейс для чтения программы
	output wire [(ADDR_SIZE-1):0] code_addr,
	input wire [(WORD_SIZE-1):0] code_word,
	//Интерфейс для чтения данных
	output wire memory_write_enable,
	output wire [(ADDR_SIZE-1):0] memory_addr,
	output wire [(WORD_SIZE-1):0] memory_in,
	input wire [(WORD_SIZE-1):0] memory_out
	);
	
	// instruction pointer
	reg [(WORD_SIZE-1):0] ip;
	// stack pointer
	reg [(WORD_SIZE-1):0] sp;
	// link register
	reg [(WORD_SIZE-1):0] lr;
	
	logic enable_add_ip;
	
	
	logic [3:0] reg_read_addr0;
	logic [(WORD_SIZE-1):0] reg_read_data0;
	logic [3:0] reg_read_addr1;
	logic [(WORD_SIZE-1):0] reg_read_data1;
	logic reg_write_enable;
	logic [3:0] reg_write_addr;
	logic [(WORD_SIZE-1):0] reg_write_data;
	logic [(WORD_SIZE-1):0] alu_write_data;
	
	//reg_data_from_memory==1 - перемещаем данные из memory в регистр
	logic reg_data_from_memory;
	
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
	
	logic [2:0] if_operation;
	logic if_ok;
	
	always @(*)
	begin
		alu_data0= select_alu_reg0?reg_read_data0:ip;
		alu_data1 = select_alu_reg1?reg_read_data1:imm;
	end
	
	alu #(.WORD_SIZE(WORD_SIZE))
		alu0(
		.r0(alu_data0),
		.r1(alu_data1),
		.op(alu_operation),
		.res(alu_write_data)
		);
		
	if_control #(.WORD_SIZE(WORD_SIZE))
		if_control0(
		.r0(reg_read_data0),
		.op(if_operation),
		.if_ok(if_ok)
		);
		
	assign memory_addr = alu_write_data;
	assign memory_in = reg_read_data1;
	
	assign reg_write_data = reg_data_from_memory? memory_out : alu_write_data;
	
	assign code_addr = ip;
	
	wire [3:0] code_word_top;
	assign code_word_top = code_word[17:14];

	assign memory_write_enable = code_word_top==4;
	
	always @(*)
	begin
		enable_add_ip = 1;
		reg_write_enable = 0;
		reg_write_addr = 0;
		reg_read_addr0 = 0;
		reg_read_addr1 = 0;
		reg_data_from_memory = 0;
		//default imm8 data
		imm = {{10{code_word[7]}}, code_word[7:0]};
		
		if_operation = code_word[10:8];
		
		alu_operation = alu0.ALU_OP_REG0;
		select_alu_reg0 = 1;
		select_alu_reg1 = 1;
		
		if(code_word_top==0)
		begin
			//rx = ry + imm8
			reg_write_enable = 1;
			reg_write_addr = code_word[13:11]; //rx
			reg_read_addr0 = code_word[10:8]; //ry
			
			alu_operation = alu0.ALU_OP_ADD;
			select_alu_reg1 = 0;
		end
		else
		if(code_word_top==1)
		begin
			//rx = imm11
			reg_write_enable = 1;
			reg_write_addr = code_word[13:11]; //rx
			imm = {{7{code_word[10]}}, code_word[10:0]};
			
			alu_operation = alu0.ALU_OP_REG1;
			select_alu_reg1 = 0;
		end
		else
		if(code_word_top==2)
		begin
			//rx = imm11<<7
			reg_write_enable = 1;
			reg_write_addr = code_word[13:11];
			imm = {code_word[10:0], {7{code_word[10]}}};
			
			alu_operation = alu0.ALU_OP_REG1;
			select_alu_reg1 = 0;
		end
		if(code_word_top==3)
		begin
			//rx = ry[imm8]
			reg_write_enable = 1;
			reg_data_from_memory = 1;
			reg_write_addr = code_word[13:11]; //rx
			reg_read_addr0 = code_word[10:8]; //ry
			
			alu_operation = alu0.ALU_OP_ADD;
			select_alu_reg1 = 0;
			
		end
		if(code_word_top==4)
		begin
			//ry[imm8] = rx
			reg_write_enable = 0;
			reg_read_addr1 = code_word[13:11]; //rx
			reg_read_addr0 = code_word[10:8]; //ry
			
			alu_operation = alu0.ALU_OP_ADD;
			select_alu_reg1 = 0;
		end
		if(code_word_top==5)
		begin
			//if(rx op) goto ip+addr
			alu_operation = alu0.ALU_OP_ADD;
			select_alu_reg0 = 0;
			select_alu_reg1 = 0;
			
			enable_add_ip = !if_ok;
		end
		if(code_word_top==6)
		begin
			//rx = rx alu_op ry
			alu_operation = code_word[3:0];
			reg_read_addr0 = code_word[13:11]; //rx
			reg_read_addr1 = code_word[10:8]; //ry
			reg_write_addr = reg_read_addr0;
			reg_write_enable = 1;
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
		else
			ip <= alu_write_data;
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