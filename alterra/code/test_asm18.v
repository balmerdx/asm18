module test_asm18(
	input clk_50M,
	output reg [7:0] ledout,
	input uart_rx,
	output reg uart_tx,
	input key_86,
	input key_87
);

logic [29:0] count;

	always @ ( posedge clk_50M )
	begin
		count <= count+1'd1;
		ledout <= ~count[29:22];
	end


endmodule
