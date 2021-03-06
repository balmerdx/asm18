//`define USE_25MHZ
`define USE_100MHZ

module test_asm18(
	input clk_50M,
	output reg [7:0] ledout,
	input uart_rx_pin,
	output reg uart_tx_pin,
	input key_86,
	input key_87
);

localparam WORD_SIZE = 18;


wire clock_proc;

logic [17:0] data_address_a = 0;
logic [17:0] data_address_b = 0;
logic [17:0] data_write_a = 0;
logic [17:0] data_write_b;
wire [17:0] data_read_a;
wire [17:0] data_read_b;
logic data_wren_a = 0;
logic data_wren_b;

wire [17:0] code_address_a;
wire [17:0] code_address_b;
wire [17:0] code_write_a = 0;
wire [17:0] code_write_b;
wire [17:0] code_read_a;
wire [17:0] code_read_b;
logic code_wren_a = 0;
logic code_wren_b;

logic processor_reset = 1;
logic wait_for_continue;
logic wait_continue_execution = 0;

logic debug_get_param = 0;
logic [3:0] debug_reg_addr = 0;
logic [(WORD_SIZE-1):0] debug_data_out;

`ifdef USE_100MHZ
	localparam UART_CLKS_PER_BIT = 200; //500 kbps for 100 MHz clock
	fast_pll pll25mhz(clk_50M, clock_proc);
`else
	`ifdef USE_25MHZ
		localparam UART_CLKS_PER_BIT = 50; //500 kbps for 25 MHz clock
		slow_pll pll25mhz(clk_50M, clock_proc);
	`else
		localparam UART_CLKS_PER_BIT = 100; //500 kbps for 50 MHz clock
		assign clock_proc = clk_50M;
	`endif
`endif


uart_controller #(.UART_CLKS_PER_BIT(UART_CLKS_PER_BIT))
	uart_controller0(
	.clock(clock_proc),
	.uart_rx_pin(uart_rx_pin),
	.uart_tx_pin(uart_tx_pin),
	.ledout_pins(ledout),
	.data_address(data_address_b),
	.data_read(data_read_b),
	.data_write(data_write_b),
	.data_wren(data_wren_b),
	.code_address(code_address_b),
	.code_read(code_read_b),
	.code_write(code_write_b),
	.code_wren(code_wren_b),
	.processor_reset(processor_reset),
	.wait_for_continue(wait_for_continue),
	.wait_continue_execution(wait_continue_execution),
	.debug_get_param(debug_get_param),
	.debug_reg_addr(debug_reg_addr),
	.debug_data_out(debug_data_out)
);

mem_async  mem1k_data(
	.address_a(data_address_a),
	.address_b(data_address_b),
	.clock(clock_proc),
	.data_a(data_write_a),
	.data_b(data_write_b),
	.wren_a(data_wren_a),
	.wren_b(data_wren_b),
	.q_a(data_read_a),
	.q_b(data_read_b)
);

mem_async  mem1k_code(
	.address_a(code_address_a),
	.address_b(code_address_b),
	.clock(clock_proc),
	.data_a(code_write_a),
	.data_b(code_write_b),
	.wren_a(code_wren_a),
	.wren_b(code_wren_b),
	.q_a(code_read_a),
	.q_b(code_read_b)
);

//processor
processor_staged
	#(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE))
		processor18(
		.clock(clock_proc),
		.reset(processor_reset),
	
		//Интерфейс для чтения программы
		.code_addr(code_address_a),
		.code_word(code_read_a),
		//Интерфейс для чтения данных
		.memory_write_enable(data_wren_a),
		.memory_addr(data_address_a),
		.memory_in(data_write_a),
		.memory_out(data_read_a),
		//Интерфейс для ожидания внешних данных
		.wait_for_continue(wait_for_continue),
		.wait_continue_execution(wait_continue_execution),
		
		//Debug
		.debug_get_param(debug_get_param),
		.debug_reg_addr(debug_reg_addr),
		.debug_data_out(debug_data_out)
	);


endmodule
