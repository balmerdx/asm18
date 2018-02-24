//Процессор с конвеером.
//Конвеер пускай будет на 3 стадии.
// Первая стадия - загрузка кода программы.
// Вторая сталия - чтение регистров и памяти.
// Третья стадия - alu операции и запись в память.

module processor_staged #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18)
	(input wire clock,
	input wire reset,
	
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
	
	wire waiting_global;

	logic no_operation_stage1;
	logic no_operation_stage2;
	logic no_operation_stage3;

	assign wait_for_continue = waiting_global;
	assign no_operation_stage1 = waiting_global;

	logic [(WORD_SIZE-1):0] ip_to_call;
	logic call_performed;
	logic [(WORD_SIZE-1):0] ip_stage2;
	logic [(WORD_SIZE-1):0] ip_plus_one_stage2;

	logic [(WORD_SIZE-1):0] alu_data0_stage3;
	logic [(WORD_SIZE-1):0] alu_data1_stage3;
	logic [(WORD_SIZE-1):0] code_word_stage3;
	logic [(ADDR_SIZE-1):0] ip_stage3;
	logic [(ADDR_SIZE-1):0] ip_plus_one_stage3;
	logic [(ADDR_SIZE-1):0] data1_plus_imm8_stage3;
	
	logic [2:0] reg_read_addr0;
	logic [(WORD_SIZE-1):0] reg_read_data0;
	logic [2:0] reg_read_addr1;
	logic [(WORD_SIZE-1):0] reg_read_data1;
	logic reg_write_enable;
	logic [2:0] reg_write_addr;
	logic [(WORD_SIZE-1):0] reg_write_data;

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

	processor_stage1 #(.ADDR_SIZE(ADDR_SIZE), .WORD_SIZE(WORD_SIZE))
		processor_stage1_m(
		.clock(clock),
		.reset(reset),
	
		.no_operation(no_operation_stage1),
		//Интерфейс для чтения программы
		.code_addr(code_addr),
		//Условные и безусловные переходы
		.ip_to_call(ip_to_call),
		.call_performed(call_performed),
		//Данные для следующей стадии
		.no_operation_out(no_operation_stage2),
		.ip_out(ip_stage2),
		.ip_plus_one_out(ip_plus_one_stage2)
		);

	processor_stage2 #(.ADDR_SIZE(ADDR_SIZE), .WORD_SIZE(WORD_SIZE))
		processor_stage2_m(
		.clock(clock),
		.reset(reset),
	
		//Данные от предыдущей стадии
		.no_operation(no_operation_stage2),
		.ip(ip_stage2),
		.ip_plus_one(ip_plus_one_stage2),
		.code_word(code_word),
	
		//Интерфейс для чтения из памяти и записи в память
		.memory_addr(memory_addr),
		.memory_write_enable(memory_write_enable),
		.memory_in(memory_in),

		//Интерфейс для чтения из регистров
		.reg_read_addr0(reg_read_addr0),
		.reg_read_data0(reg_read_data0),
		.reg_read_addr1(reg_read_addr1),
		.reg_read_data1(reg_read_data1),

		//Данные для следующей стадии
		.no_operation_out(no_operation_stage3),
		.alu_data0_out(alu_data0_stage3),
		.alu_data1_out(alu_data1_stage3),
		.code_word_out(code_word_stage3),
		.ip_out(ip_stage3),
		.ip_plus_one_out(ip_plus_one_stage3),
		.data1_plus_imm8_out(data1_plus_imm8_stage3),

		//Глобальный сигнал, останавливающий все стадии
		.waiting_global(waiting_global),
		//Интерфейс writeback регистра
		.writeback_reg_write_enable(reg_write_enable),
		.writeback_reg_write_addr(reg_write_addr),
		.writeback_reg_write_data(reg_write_data)
		);

	processor_stage3 #(.ADDR_SIZE(ADDR_SIZE), .WORD_SIZE(WORD_SIZE))
		processor_stage3_m(
		.clock(clock),
		.reset(reset),
		//Данные с предыдущей стадии
		.no_operation(no_operation_stage3),
		.alu_data0(alu_data0_stage3),
		.alu_data1(alu_data1_stage3),
		.data1_plus_imm8(data1_plus_imm8_stage3),
		.code_word(code_word_stage3),
		.ip(ip_stage3),
		.ip_plus_one(ip_plus_one_stage3),

		//Интерфейс для записи регистра
		.reg_write_enable(reg_write_enable),
		.reg_write_addr(reg_write_addr),
		.reg_write_data(reg_write_data),
		//
		.memory_out(memory_out),
		//Условные и безусловные переходы
		.ip_to_call(ip_to_call),
		.call_performed(call_performed)
	);


/*	
`ifdef PROCESSOR_DEBUG_INTERFACE
	assign debug_data_out = debug_reg_addr[3]?ip_stage3:reg_read_data1;
`endif

	always @(*)
	begin
`ifdef PROCESSOR_DEBUG_INTERFACE
		if(debug_get_param)
		begin
			select_alu_reg1 = debug_reg_addr[3]?ALU_REG1_IS_IP:ALU_REG1_IS_REGISTER;
			reg_read_addr1 = debug_reg_addr[2:0];
		end
`endif
	end

	always @(posedge clock)
	if(reset)
	begin
	end
	else
	begin

		if(wait_logic
`ifdef PROCESSOR_DEBUG_INTERFACE
			|| debug_get_param
`endif
		)
		begin
		end
		else
		begin
		end
	end
*/	
endmodule

