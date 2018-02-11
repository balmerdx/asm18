//Send/receive uart 3 byte with speed 500 kbps

module uart_controller(
	input clk_50M,
	input uart_rx_pin,
	output reg uart_tx_pin,
	output reg [7:0] ledout_pins,
	//data memory
	output logic [15:0] data_address,
	input [17:0] data_read,
	output reg [17:0] data_write,
	output reg data_wren
	);

localparam UART_CLKS_PER_BIT = 100; //500 kbps

localparam COMMAND_SET_LED = 0;
localparam COMMAND_WRITE_DATA_MEMORY = 1;
localparam COMMAND_READ_DATA_MEMORY = 2;

logic [7:0] leds = 0;
assign ledout_pins = ~leds;

enum {
	RX_COMMAND, //next byte is command
	RX_ADDRESS, //next 2 byte is address
	RX_SIZE, //next 2 byte is size
	RX_PROCESSING_COMMAND//command processing, read or send many bytes
} rx_state = RX_COMMAND;

logic uart_rx_received;
wire [7:0] uart_rx_byte;

logic [23:0] rx_timeout;

logic uart_tx_send;
wire uart_tx_active;
wire uart_tx_done;
logic [7:0] usart_tx_data;

logic [7:0] command;

logic address_index;
logic size_index;
logic [15:0] address;
logic [15:0] size;

logic [1:0] rx_byte_index;
logic [17:0] data_rx = 0;

logic [1:0] tx_byte_index;

initial data_wren = 0;
assign data_address = address;
assign data_write = data_rx;

always @ ( posedge clk_50M )
begin
	data_wren <= 0;
	uart_tx_send <= 0;
	if(uart_rx_received)
	begin
		rx_timeout <= 24'd5000000;//100 ms timeout
		case(rx_state)
		RX_COMMAND: begin
				rx_state <= RX_ADDRESS;
				command <= uart_rx_byte;
				address_index <= 0;
				size_index <= 0;
				rx_byte_index <= 0;
				tx_byte_index <= 0;
			end
		RX_ADDRESS: begin
				if(address_index==0)
				begin
					address[7:0] <= uart_rx_byte;
					address_index <= 1;
				end
				else
				begin
					address[15:8] <= uart_rx_byte;
					rx_state <= RX_SIZE;
				end
			end
		RX_SIZE : begin
				if(size_index==0)
				begin
					size[7:0] <= uart_rx_byte;
					size_index <= 1;
				end
				else
				begin
					size[15:8] <= uart_rx_byte;
					rx_state <= RX_PROCESSING_COMMAND;
				end
			end
		RX_PROCESSING_COMMAND : begin
			case(command)
			COMMAND_WRITE_DATA_MEMORY : begin
				case(rx_byte_index)
				0 : begin
					rx_byte_index <= 1;
					data_rx[7:0] <= uart_rx_byte;
				end
				1 : begin
					rx_byte_index <= 2;
					data_rx[15:8] <= uart_rx_byte;
				end
				2 : begin
					rx_byte_index <= 0;
					data_rx[17:16] <= uart_rx_byte[1:0];
					size <= size-1'd1;
					data_wren <= 1;
				end
				endcase
			end
			endcase
		end
		endcase
	end
	else
	begin
		if(rx_timeout==0)
			rx_state <= RX_COMMAND;
		else
			rx_timeout <= rx_timeout-1'd1;
			
		if(rx_state==RX_PROCESSING_COMMAND)
		begin
			case(command)
			COMMAND_SET_LED:begin
					leds <= size[7:0];
					rx_state <= RX_COMMAND;
				end
			COMMAND_WRITE_DATA_MEMORY: begin
					if(data_wren)
					begin
						//increment address on next quant
						address <= address + 1'd1;
					end
						
					if(size==0)
					begin
						rx_state <= RX_COMMAND;
					end
				end
			COMMAND_READ_DATA_MEMORY : begin
					if(uart_tx_active==0 && uart_tx_send==0)
					begin
						if(size>0)
						begin
							case(tx_byte_index)
							0: begin
								usart_tx_data <= data_read[7:0];
								//usart_tx_data <= {address[5:0], tx_byte_index};
								tx_byte_index <= 1;
								uart_tx_send <= 1;
							end
							1: begin
								usart_tx_data <= data_read[15:8];
								//usart_tx_data <= {address[5:0], tx_byte_index};
								tx_byte_index <= 2;
								uart_tx_send <= 1;
							end
							2: begin
								usart_tx_data <= {6'b0,data_read[17:16]};
								//usart_tx_data <= {address[5:0], tx_byte_index};
								tx_byte_index <= 0;
								uart_tx_send <= 1;
								
								address <= address + 1'd1;
								size <= size-1'd1;
							end
							endcase
						end
						else
						begin
							//size==0
							rx_state <= RX_COMMAND;
						end
					end
				end
			endcase
		end
	end
end

 uart_rx 
  #(.CLKS_PER_BIT(UART_CLKS_PER_BIT))
	uart_rx0
  (
   .i_Clock(clk_50M),
   .i_Rx_Serial(uart_rx_pin),
   .o_Rx_DV(uart_rx_received),
   .o_Rx_Byte(uart_rx_byte)
   );

uart_tx 
  #(.CLKS_PER_BIT(UART_CLKS_PER_BIT))
   uart_tx0
  (
   .i_Clock(clk_50M),
   .i_Tx_DV(uart_tx_send),
   .i_Tx_Byte(usart_tx_data), 
   .o_Tx_Active(uart_tx_active),
   .o_Tx_Serial(uart_tx_pin),
   .o_Tx_Done(uart_tx_done)
   );

endmodule
