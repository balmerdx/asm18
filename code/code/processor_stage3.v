//Последняя стадия делает собcтвенно всю работу
//ALU
//write to memory
//write to register
//IF
module processor_stage3 #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18)
	(input wire clock,
	input wire reset,
	//Данные с предыдущей стадии
	input wire no_operation,
	input wire [(WORD_SIZE-1):0] alu_data0,
	input wire [(WORD_SIZE-1):0] alu_data1,
	input wire [(WORD_SIZE-1):0] data1_plus_imm8,
	input wire [(WORD_SIZE-1):0] code_word,
	input wire [(ADDR_SIZE-1):0] ip,
	input wire [(ADDR_SIZE-1):0] ip_plus_one,
	//Интерфейс для записи регистра
	output logic reg_write_enable,
	output wire [2:0] reg_write_addr,
	output logic [(WORD_SIZE-1):0] reg_write_data,
	//
	input logic [(WORD_SIZE-1):0] memory_out
	);

	localparam logic ALU_REG0_IS_REGISTER = 0;
	localparam logic ALU_REG0_IS_IMM = 1;

	wire [3:0] code_word_top = code_word[17:14];
	wire [2:0] code_rx = code_word[13:11];
	wire [4:0] mulxx_shift = code_word[4:0];
	assign reg_write_addr =  code_rx;

	logic [(WORD_SIZE-1):0] alu_result;
	logic [(WORD_SIZE-1):0] mulxx_result;

	logic [3:0] alu_operation;
	alu #(.WORD_SIZE(WORD_SIZE))
		alu0(
		.r0(alu_data0),
		.r1(alu_data1),
		.op(alu_operation),
		.res(alu_result)
		);
	
	mulxx #(.WORD_SIZE(WORD_SIZE))
		mulxx0(
		.r0(alu_data0),
		.r1(alu_data1),
		.shift(mulxx_shift),
		.res(mulxx_result) //result
		);

	always @(*)
	begin
		alu_operation = ALU_OP_ADD;
		reg_write_data = data1_plus_imm8;
		reg_write_enable = 0;
		if(!no_operation)
		case(code_word_top)
			OP_REG_ADD_IMM8 : begin //rx = ry + imm8
				reg_write_enable = 1;
			end
			OP_REG_MOV_IMM11 : begin //rx = imm11
				reg_write_enable = 1;
				reg_write_data = {{7{code_word[10]}}, code_word[10:0]};
			end
			OP_REG_MOV_IMM11_TOP : begin //rx = imm11<<7
				reg_write_enable = 1;
				reg_write_data = {code_word[10:0], 7'd0};
			end
			OP_LOAD_FROM_MEMORY : begin //rx = ry[imm8]
				reg_write_enable = 1;
				reg_write_data = memory_out;
			end
			OP_WRITE_TO_MEMORY : begin //ry[imm8] = rx
			end
			OP_IF : begin //if(rx op) goto ip+imm8
			end
			OP_ALU : begin //rx = rx alu_op ry
				reg_write_enable = 1;
				alu_operation = code_word[3:0];
				reg_write_data = alu_result;
			end
			OP_MUL_SHIFT : begin // rx = (rx*ry) >> imm
				reg_write_data = mulxx_result;
			end
			OP_CALL_IMM14 : begin // call imm14
			end
			OP_RETURN : begin // ip = ry[imm8]
				
			end
			OP_WAIT : begin
			end
		endcase
	end

	always @(posedge clock)
	begin
	end

endmodule

