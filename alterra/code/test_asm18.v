module test_asm18(
	input clk_50M,
	output reg [7:0] ledout,
	input uart_rx_pin,
	output reg uart_tx_pin,
	input key_86,
	input key_87
);

logic [17:0] data_address_a = 0;
logic [17:0] data_address_b = 0;
logic [17:0] data_write_a = 0;
logic [17:0] data_write_b;
wire [17:0] data_read_a;
wire [17:0] data_read_b;
logic data_wren_a = 0;
logic data_wren_b;

uart_controller uart_controller0(
	.clk_50M(clk_50M),
	.uart_rx_pin(uart_rx_pin),
	.uart_tx_pin(uart_tx_pin),
	.ledout_pins(ledout),
	.data_address(data_address_b),
	.data_read(data_read_b),
	.data_write(data_write_b),
	.data_wren(data_wren_b)
);

mem1k  mem1k_data(
	.address_a(data_address_a),
	.address_b(data_address_b),
	.clock(clk_50M),
	.data_a(data_write_a),
	.data_b(data_write_b),
	.wren_a(data_wren_a),
	.wren_b(data_wren_b),
	.q_a(data_read_a),
	.q_b(data_read_b)
);


endmodule
