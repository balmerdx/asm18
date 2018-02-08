module test_asm18(
	input clk_50M,
	output reg [7:0] ledout,
	input uart_rx,
	output reg uart_tx,
	input key_86,
	input key_87
);

localparam UART_CLKS_PER_BIT = 100; //500 kbps
logic uart_byte_received;
logic uart_byte_send;
wire [7:0] uart_rx_byte;
wire uart_tx_active;
wire uart_tx_done;
logic [7:0] usart_out_data;

//logic [29:0] count;
	//assign ledout = ~uart_rx_byte;

	always @ ( posedge clk_50M )
	begin
		//count <= count+1'd1;
		//ledout <= ~count[29:22];
		if(uart_byte_received)
		begin
			ledout <= ~uart_rx_byte;
			usart_out_data <= uart_rx_byte+8'h10;
			uart_byte_send <= 1;
		end
		
		if(uart_byte_send)
		begin
			uart_byte_send <= 0;
		end
	end

 uart_rx 
  #(.CLKS_PER_BIT(UART_CLKS_PER_BIT))
	uart_rx0
  (
   .i_Clock(clk_50M),
   .i_Rx_Serial(uart_rx),
   .o_Rx_DV(uart_byte_received),
   .o_Rx_Byte(uart_rx_byte)
   );

uart_tx 
  #(.CLKS_PER_BIT(UART_CLKS_PER_BIT))
   uart_tx0
  (
   .i_Clock(clk_50M),
   .i_Tx_DV(uart_byte_send),
   .i_Tx_Byte(usart_out_data), 
   .o_Tx_Active(uart_tx_active),
   .o_Tx_Serial(uart_tx),
   .o_Tx_Done(uart_tx_done)
   );

endmodule
