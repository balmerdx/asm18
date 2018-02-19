
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
	input wire [(WORD_SIZE-1):0] memory_out,
	//Оснатовка и продолжение программы по команде wait
	//wait_for_continue==1 - программа остановленна, так как встретилась инструкция wait
	output wire wait_for_continue,
	//wait_continue_execution==0 - программа останавливается, если встречает wait операцию
	//wait_continue_execution==1 - программа дальше продлжается, если встречает wait операцию
	//Что-бы продолжить выполнение, надо на 1 такт выставить 1 здесь
	input wire wait_continue_execution 
`ifdef PROCESSOR_DEBUG_INTERFACE
	,
	//debug_get_param = 1 - processor stopped and get data from internal registers
	input wire debug_get_param,
	//debug_reg_addr = 0 r0
	//debug_reg_addr = 7 r7
	//debug_reg_addr = 8 ip
	input wire [3:0] debug_reg_addr,
	output wire [(WORD_SIZE-1):0] debug_data_out
`endif
	);
	
	localparam logic ALU_REG0_IS_REGISTER = 0;
	localparam logic ALU_REG0_IS_IMM = 1;
	
	localparam logic ALU_REG1_IS_REGISTER = 0;
	localparam logic ALU_REG1_IS_IP = 1;
	
	
	// instruction pointer
	reg [(WORD_SIZE-1):0] ip;
	
	//if conditional move ip = ip + imm8
	logic write_alu_to_ip;
	logic write_imm14_to_ip;
	
	logic wait_logic;
	assign wait_for_continue = wait_logic;
	
	logic [1:0] relaxation_quant;
	
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
	
	//reg_data_from_mullxx==1 - перемещаем данные умножителя в регистр
	logic reg_data_from_mullxx;
	
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

	//see ALU_REG0_IS_* constants
	logic [1:0] select_alu_reg0;
	
	//see ALU_REG1_IS_*
	logic select_alu_reg1;
	
	logic [(WORD_SIZE-1):0] alu_data0;
	logic [(WORD_SIZE-1):0] alu_data1;
	logic [3:0] alu_operation;
	
	logic [(WORD_SIZE-1):0] mulxx_write_data;
	logic [4:0] mulxx_shift;
	
	logic [2:0] if_operation;
	logic if_ok;
	logic [1:0] sp_operation;
	
	always @(*)
	begin
		alu_data0 = (select_alu_reg0==ALU_REG0_IS_REGISTER)?reg_read_data0:imm;
		alu_data1 = (select_alu_reg1==ALU_REG1_IS_REGISTER)?reg_read_data1:ip;
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

	mulxx #(.WORD_SIZE(WORD_SIZE))
		mulxx0(
		.r0(alu_data0),
		.r1(alu_data1),
		.shift(mulxx_shift),
		.res(mulxx_write_data) //result
		);
	
		
	logic mem_write;
	logic mem_write_ip_plus_one;
	assign memory_write_enable = mem_write;
	
	wire [(WORD_SIZE-1):0] ip_plus_one;
	assign ip_plus_one = ip + 1'd1;
	
	assign memory_addr = alu_write_data;
	assign memory_in = mem_write_ip_plus_one?ip_plus_one:reg_read_data0;
	
	assign reg_write_data = reg_data_from_memory? memory_out : (reg_data_from_mullxx?mulxx_write_data:alu_write_data);
	
	assign code_addr = ip;
	
	
	wire [3:0] code_word_top;
	assign code_word_top = code_word[17:14];
	wire [2:0] code_rx;
	assign code_rx = code_word[13:11];//r0..r7
	wire [2:0] code_ry;
	assign code_ry = code_word[10:8];
	
	//see if(code_word_top==7)
	assign mulxx_shift = code_word[4:0];

`ifdef PROCESSOR_DEBUG_INTERFACE
	assign debug_data_out = alu_data1;
`endif
	
	always @(*)
	begin
		write_alu_to_ip = 0;
		write_imm14_to_ip = 0;
		wait_logic = 0;
		reg_write_enable = 0;
		reg_write_addr = code_rx;
		reg_read_addr0 = code_rx;
		reg_read_addr1 = code_ry;
		reg_data_from_memory = 0;
		reg_data_from_mullxx = 0;
		mem_write = 0;
		mem_write_ip_plus_one = 0;
		//default imm8 data
		imm = {{10{code_word[7]}}, code_word[7:0]};
		
		if_operation = code_word[10:8];
		
		alu_operation = ALU_OP_REG0;
		select_alu_reg0 = ALU_REG0_IS_REGISTER;
		select_alu_reg1 = ALU_REG1_IS_REGISTER;
`ifdef PROCESSOR_DEBUG_INTERFACE
		if(debug_get_param)
		begin
			select_alu_reg1 = debug_reg_addr[3]?ALU_REG1_IS_IP:ALU_REG1_IS_REGISTER;
			reg_read_addr1 = debug_reg_addr[2:0];
		end
		else
`endif
		if(relaxation_quant==2'd2)
		begin
			//none on quant 0
		end
		else
		if(relaxation_quant==2'd1)
		begin
			//read memory on quant 1
			if(code_word_top==OP_LOAD_FROM_MEMORY ||
			   code_word_top==OP_RETURN)
			begin
				//read ry[imm8]
				alu_operation = ALU_OP_ADD;
				select_alu_reg0 = ALU_REG0_IS_IMM;
				select_alu_reg1 = ALU_REG1_IS_REGISTER;
			end
		end
		else
		if(code_word_top==OP_REG_ADD_IMM8)
		begin
			//rx = ry + imm8
			reg_write_enable = 1;
			alu_operation = ALU_OP_ADD;
			select_alu_reg0 = ALU_REG0_IS_IMM;
			select_alu_reg1 = ALU_REG1_IS_REGISTER;
		end
		else
		if(code_word_top==OP_REG_MOV_IMM11)
		begin
			//rx = imm11
			reg_write_enable = 1;
			imm = {{7{code_word[10]}}, code_word[10:0]};
			alu_operation = ALU_OP_REG0;
			select_alu_reg0 = ALU_REG0_IS_IMM;
		end
		else
		if(code_word_top==OP_REG_MOV_IMM11_TOP)
		begin
			//rx = imm11<<7
			reg_write_enable = 1;
			imm = {code_word[10:0], 7'd0};
			alu_operation = ALU_OP_REG0;
			select_alu_reg0 = ALU_REG0_IS_IMM;
		end
		else
		if(code_word_top==OP_LOAD_FROM_MEMORY)
		begin
			//rx = ry[imm8]
			reg_write_enable = 1;
			reg_data_from_memory = 1;
		end
		else
		if(code_word_top==OP_WRITE_TO_MEMORY)
		begin
			//ry[imm8] = rx
			mem_write = 1;
			alu_operation = ALU_OP_ADD;
			select_alu_reg0 = ALU_REG0_IS_IMM;
			select_alu_reg1 = ALU_REG1_IS_REGISTER;
		end
		else
		if(code_word_top==OP_IF)
		begin
			//if(rx op) goto ip+addr
			alu_operation = ALU_OP_ADD;
			select_alu_reg0 = ALU_REG0_IS_IMM;
			select_alu_reg1 = ALU_REG1_IS_IP;
			
			write_alu_to_ip = if_ok;
		end
		else
		if(code_word_top==OP_ALU)
		begin
			//rx = rx alu_op ry
			alu_operation = code_word[3:0];
			reg_write_enable = 1;
		end
		else
		if(code_word_top==OP_MUL_SHIFT)
		begin
			// rx = (rx*ry)>>shift
			reg_data_from_mullxx = 1;
			reg_write_enable = 1;
		end
		else
		if(code_word_top==OP_CALL_IMM14)
		begin
			//sp[0] = ip+1
			//ip = imm14
			write_imm14_to_ip = 1;
			
			mem_write = 1;
			mem_write_ip_plus_one = 1;
			imm = 0;
			
			alu_operation = ALU_OP_ADD;
			reg_read_addr1 = 7;//r7==sp
			select_alu_reg0 = ALU_REG0_IS_IMM;
			select_alu_reg1 = ALU_REG1_IS_REGISTER;
		end
		else
		if(code_word_top==OP_RETURN)
		begin
			//ip = ry[imm8]
			//return if (ry is sp) && imm8==0
			write_alu_to_ip = 1;
			reg_data_from_memory = 1;
		end
		else
		if(code_word_top==OP_WAIT)
		begin
			//wait command
			//Останавливаемся, если не выставлен флаг 
			//продолжения выполнения программы
			wait_logic = ~wait_continue_execution;
		end
		
	end
	
	always @(posedge clock)
	if(reset)
	begin
		ip <= 0;
		relaxation_quant <= 2'd2;
	end
	else
	begin
		//Совсем кривой вариант, замедляем процессор в 3 раза
		//Первый квант ожидаем, пока прочитается команда
		//Второй квант ожидаем, пока прочитаются данные из памяти данных
		relaxation_quant <= relaxation_quant-2'd1;
		
		if(wait_logic
`ifdef PROCESSOR_DEBUG_INTERFACE
			|| debug_get_param
`endif
			|| (relaxation_quant>0)
		)
		begin
			ip <= ip;
		end
		else
		begin
			relaxation_quant <= 2'd2;

			if(write_imm14_to_ip)
				ip <= {4'b0000, code_word[13:0]};
			else
			if(write_alu_to_ip)
				ip <= reg_write_data;
			else
				ip <= ip_plus_one;
		end
	end

endmodule
