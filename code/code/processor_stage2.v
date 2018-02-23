//Чтение регистров и памяти.
module processor_stage2 #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18)
	(input wire clock,
	input wire reset,
	
	//Данные от предыдущей стадии
	input wire no_operation,
	input wire [(ADDR_SIZE-1):0] ip,
	input wire [(ADDR_SIZE-1):0] code_word,
	
	//Интерфейс для чтения из памяти и записи в память
	output logic [(ADDR_SIZE-1):0] memory_addr,
	output logic memory_write_enable,
	output logic [(WORD_SIZE-1):0] memory_in,

	//Интерфейс для чтения из регистров
	output logic [2:0] reg_read_addr0,
	input wire [(WORD_SIZE-1):0] reg_read_data0,
	output logic [2:0] reg_read_addr1,
	input wire [(WORD_SIZE-1):0] reg_read_data1,

	//Данные для следующей стадии
	output reg no_operation_out,
	output reg [(WORD_SIZE-1):0] alu_data0_out,
	output reg [(WORD_SIZE-1):0] alu_data1_out,
	output reg [(WORD_SIZE-1):0] code_word_out,
	output reg [(ADDR_SIZE-1):0] ip_out,
	output reg [(ADDR_SIZE-1):0] data1_plus_imm8_out
	);

	wire [3:0] code_word_top = code_word[17:14];
	wire [2:0] code_rx = code_word[13:11];
	wire [2:0] code_ry = code_word[10:8];
	logic signed [7:0] imm8;

	logic [(WORD_SIZE-1):0] data0;
	logic [(WORD_SIZE-1):0] data1;

	wire [(ADDR_SIZE-1):0] data1_plus_imm8 = data1 + imm8;

	logic [2:0] reg_read_addr1_wire;

	assign reg_read_addr0 = code_rx;

	always @(*)
	begin
		reg_read_addr1 = code_ry;
		data0 = reg_read_data0;
		data1 = reg_read_data1;
		memory_write_enable = 0;
		memory_in = reg_read_data0;
		imm8 = $signed(code_word[7:0]);
		memory_addr = data1_plus_imm8;
		if(!no_operation)
		case(code_word_top)
			OP_REG_ADD_IMM8 : begin //rx = ry + imm8
			end
			OP_REG_MOV_IMM11 : begin //rx = imm11
			end
			OP_REG_MOV_IMM11_TOP : begin //rx = imm11<<7
			end
			OP_LOAD_FROM_MEMORY : begin //rx = ry[imm8]
				
			end
			OP_WRITE_TO_MEMORY : begin //ry[imm8] = rx
				memory_write_enable = 1;
			end
			OP_IF : begin //if(rx op) goto ip+imm8
				data1 = ip;
			end
			OP_ALU : begin //rx = rx alu_op ry
			end
			OP_MUL_SHIFT : begin // rx = (rx*ry) >> imm
			end
			OP_CALL_IMM14 : begin // call imm14
				//sp[0] = ip+1;
				memory_write_enable = 1;
				reg_read_addr1 = 7; //sp
				memory_addr = reg_read_data1;
				data1 = ip;
				imm8 = 1;
				memory_in = data1_plus_imm8;
			end
			OP_RETURN : begin // ip = ry[imm8]
				
			end
			OP_WAIT : begin 
			end
		endcase
	end

	always @(posedge clock)
	begin
		no_operation_out <= reset?1:no_operation;
		alu_data0_out <= data0;
		alu_data1_out <= data1;
		ip_out <= ip;
		data1_plus_imm8_out <= data1_plus_imm8;
		code_word_out <= no_operation?0:code_word;
	end

endmodule

