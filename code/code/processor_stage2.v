//Чтение регистров и памяти.
//Определение, не нужно ли сделать reset конвееру.
//В случае инструкции wait делает ожидаение.
module processor_stage2 #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18)
	(input wire clock,
	input wire reset,
	
	//Данные от предыдущей стадии
	input wire no_operation,
	input wire [(ADDR_SIZE-1):0] ip,
	input wire [(ADDR_SIZE-1):0] ip_plus_one,
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
	output reg [(ADDR_SIZE-1):0] data1_plus_imm8_out,

	//Глобальный сигнал, останавливающий все стадии
	output wire waiting_global,
	//Интерфейс writeback регистра
	input wire writeback_reg_write_enable,
	input wire [2:0] writeback_reg_write_addr,
	input wire [(WORD_SIZE-1):0] writeback_reg_write_data,
	//Условные и безусловные переходы
	//Данные для предыдущей стадии
	output logic [(ADDR_SIZE-1):0] ip_to_call,
	output logic call_performed,
	output reg return_performed //На следующий квант надо вычитать данные для return
	);

	//Пришла команда wait и мы ожидаем много тактов.
	logic waiting;
	logic wait_command_received;
	assign waiting_global = waiting;

	wire [3:0] code_word_top = code_word[17:14];
	wire [2:0] code_rx = code_word[13:11];
	wire [2:0] code_ry = code_word[10:8];
	wire [7:0] imm8 = code_word[7:0];
	wire [2:0] if_operation = code_word[10:8];

	logic [(WORD_SIZE-1):0] data0;
	logic [(WORD_SIZE-1):0] data1;
	logic if_ok;

	wire [(ADDR_SIZE-1):0] data1_plus_imm8 = data1 + {{10{imm8[7]}}, imm8};//add signed imm8

	logic [2:0] reg_read_addr1_wire;

	assign reg_read_addr0 = code_rx;

	if_control #(.WORD_SIZE(WORD_SIZE))
		if_control0(
		.r0(data0),
		.op(if_operation),
		.if_ok(if_ok)
		);

	logic write_imm14_to_ip;
	logic return_found;


	always @(*)
	begin
		reg_read_addr1 = code_ry;
		
		if(code_word_top==OP_CALL_IMM14)
		begin
			reg_read_addr1 = 7; //sp
		end

		data0 = (writeback_reg_write_enable && reg_read_addr0==writeback_reg_write_addr)?writeback_reg_write_data:reg_read_data0;
		data1 = (writeback_reg_write_enable && reg_read_addr1==writeback_reg_write_addr)?writeback_reg_write_data:reg_read_data1;
		memory_write_enable = 0;
		memory_in = data0;
		wait_command_received = 0;
		call_performed = 0;
		write_imm14_to_ip = 0;
		memory_addr = data1_plus_imm8;
		return_found = 0;

		if(no_operation || waiting)
		begin
			
		end
		else
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
				if(if_ok)
				begin
					call_performed = 1;
					data1 = ip;
				end
			end
			OP_ALU : begin //rx = rx alu_op ry
			end
			OP_MUL_SHIFT : begin // rx = (rx*ry) >> imm
			end
			OP_CALL_IMM14 : begin // call imm14
				//sp[0] = ip+1;
				memory_write_enable = 1;
				memory_addr = data1;
				memory_in = ip_plus_one;
				write_imm14_to_ip = 1;
				call_performed = 1;
			end
			OP_RETURN : begin // ip = ry[imm8]
				return_found = 1;
			end
			OP_WAIT : begin 
				wait_command_received = 1;
			end
		endcase

		if(write_imm14_to_ip)
			ip_to_call = {4'b0000, code_word[13:0]};
		else
			ip_to_call = data1_plus_imm8;
	end

	always @(posedge clock)
	begin
		if(reset)
		begin
			no_operation_out <= 0;
			waiting <= 0;
			return_performed <= 0;
		end
		else
		begin
			no_operation_out <= no_operation || wait_command_received;
			alu_data0_out <= data0;
			alu_data1_out <= data1;
			data1_plus_imm8_out <= data1_plus_imm8;
			code_word_out <= code_word;
			return_performed <= return_found;

			if(wait_command_received)
				waiting <= 1;
		end		
	end

endmodule

