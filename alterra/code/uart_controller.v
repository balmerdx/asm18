//Send/receive uart 3 byte with speed 500 kbps

module uart_controller
	#(parameter integer WORD_SIZE = 18)
	(
	input clock,
	input uart_rx_pin,
	output reg uart_tx_pin,
	output reg [7:0] ledout_pins,
	//data memory
	output logic [15:0] data_address,
	input [(WORD_SIZE-1):0] data_read,
	output reg [(WORD_SIZE-1):0] data_write,
	output reg data_wren,
	//code memory
	output logic [15:0] code_address,
	input [(WORD_SIZE-1):0] code_read,
	output reg [(WORD_SIZE-1):0] code_write,
	output reg code_wren,
	//processor communication
	output processor_reset,
	input wait_for_continue,
	output reg wait_continue_execution,
	output reg debug_get_param,
	output reg [3:0] debug_reg_addr,
	input [(WORD_SIZE-1):0] debug_data_out
	);

//localparam UART_CLKS_PER_BIT = 100; //500 kbps for 50 MHz clock
localparam UART_CLKS_PER_BIT = 50; //500 kbps for 25 MHz clock

localparam COMMAND_SET_LED = 0;
localparam COMMAND_WRITE_DATA_MEMORY = 1;
localparam COMMAND_READ_DATA_MEMORY = 2;
localparam COMMAND_WRITE_CODE_MEMORY = 3;
localparam COMMAND_READ_CODE_MEMORY = 4;
localparam COMMAND_CLEAR_DATA_MEMORY = 5;
localparam COMMAND_CLEAR_CODE_MEMORY = 6;
localparam COMMAND_SET_RESET = 7;
localparam COMMAND_READ_REGISTERS = 8;
localparam COMMAND_STEP = 9; //Запускает процессор на несколько шагов size, потом останавливает его
localparam COMMAND_TIMER = 10;

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

logic [3:0] command;

logic address_index;
logic size_index;
logic [15:0] address;
logic [15:0] size;

logic [1:0] rx_byte_index;
logic [17:0] data_rx = 0;

logic [1:0] tx_byte_index;

//Время, за которая программа дошла от
//processor_reset ==0 до wait_for_continue==0

logic [31:0] execution_timer;
logic [31:0] execution_timer_to_send;
logic execution_timer_sended;
logic execution_timer_started;

initial data_wren = 0;
assign data_address = address;
assign data_write = data_rx;

initial code_wren = 0;
assign code_address = address;
assign code_write = data_rx;

initial processor_reset = 1;
initial wait_continue_execution = 0;
initial debug_get_param = 0;
logic old_debug_get_param = 0;

assign debug_reg_addr = address[3:0];

wire [17:0] data_code_read;
assign data_code_read = (command==COMMAND_READ_REGISTERS)?debug_data_out:
			((command==COMMAND_READ_DATA_MEMORY)?data_read:code_read);

always @ ( posedge clock )
begin
	data_wren <= 0;
	code_wren <= 0;
	uart_tx_send <= 0;
	
	if(wait_for_continue==1)
		execution_timer_started <= 0;
	if(execution_timer_started)
		execution_timer <= execution_timer+1;
	
	if(uart_rx_received)
	begin
		rx_timeout <= 24'd5000000;//100 ms timeout
		case(rx_state)
		RX_COMMAND: begin
				rx_state <= RX_ADDRESS;
				command <= uart_rx_byte[3:0];
				address_index <= 0;
				size_index <= 0;
				rx_byte_index <= 0;
				tx_byte_index <= 0;
				execution_timer_to_send <= execution_timer;
				execution_timer_sended <= 0;
				
				if(uart_rx_byte==COMMAND_READ_REGISTERS)
				begin
					old_debug_get_param <= debug_get_param;
					debug_get_param <= 1;
				end
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
			COMMAND_WRITE_DATA_MEMORY, COMMAND_WRITE_CODE_MEMORY: begin
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
					
					if(command==COMMAND_WRITE_DATA_MEMORY)
						data_wren <= 1;
					else
						code_wren <= 1;
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
			COMMAND_WRITE_DATA_MEMORY, COMMAND_WRITE_CODE_MEMORY: begin
					if(data_wren || code_wren)
					begin
						//increment address on next quant
						address <= address + 1'd1;
					end
						
					if(size==0)
					begin
						rx_state <= RX_COMMAND;
					end
				end
			COMMAND_READ_DATA_MEMORY,
			COMMAND_READ_CODE_MEMORY,
			COMMAND_READ_REGISTERS: begin
					if(uart_tx_active==0 && uart_tx_send==0)
					begin
						if(size>0)
						begin
							case(tx_byte_index)
							0: begin
								usart_tx_data <= data_code_read[7:0];
								tx_byte_index <= 1;
								uart_tx_send <= 1;
							end
							1: begin
								usart_tx_data <= data_code_read[15:8];
								tx_byte_index <= 2;
								uart_tx_send <= 1;
							end
							2: begin
								usart_tx_data <= {6'b0, data_code_read[17:16]};
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
							if(command==COMMAND_READ_REGISTERS)
							begin
								debug_get_param <= old_debug_get_param;
							end
						end
					end
				end
			COMMAND_SET_RESET : begin
				processor_reset <= address[0];
				debug_get_param <= address[1];
				rx_state <= RX_COMMAND;
				execution_timer_started <= ~address[0];
				if(address[0])
					execution_timer <= 0;
				end
				
			COMMAND_STEP : begin
					if(size>0)
					begin
						debug_get_param <= 0;
						size <= size-1'd1;
					end
					else
					begin
						debug_get_param <= 1;
						rx_state <= RX_COMMAND;
					end
				end
			COMMAND_CLEAR_DATA_MEMORY,
			COMMAND_CLEAR_CODE_MEMORY : begin
					if(data_wren || code_wren)
					begin
						//increment address on next quant
						address <= address + 1'd1;
					end
					else
					begin
						data_rx <= 0;
						size <= size-1'd1;
						
						if(command==COMMAND_CLEAR_DATA_MEMORY)
							data_wren <= 1;
						else
							code_wren <= 1;
					end
					
						
					if(size==0)
					begin
						rx_state <= RX_COMMAND;
					end
				end
			COMMAND_TIMER : begin
					if(uart_tx_active==0 && uart_tx_send==0)
					begin
						if(execution_timer_sended==0)
						begin
							case(tx_byte_index)
							0: begin
								usart_tx_data <= execution_timer_to_send[7:0];
								tx_byte_index <= 1;
								uart_tx_send <= 1;
							end
							1: begin
								usart_tx_data <= execution_timer_to_send[15:8];
								tx_byte_index <= 2;
								uart_tx_send <= 1;
							end
							2: begin
								usart_tx_data <= execution_timer_to_send[23:16];
								tx_byte_index <= 3;
								uart_tx_send <= 1;
							end
							3: begin
								usart_tx_data <= execution_timer_to_send[31:24];
								tx_byte_index <= 0;
								uart_tx_send <= 1;
								execution_timer_sended <= 1;
							end
							endcase
						end
						else
						begin
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
   .i_Clock(clock),
   .i_Rx_Serial(uart_rx_pin),
   .o_Rx_DV(uart_rx_received),
   .o_Rx_Byte(uart_rx_byte)
   );

uart_tx 
  #(.CLKS_PER_BIT(UART_CLKS_PER_BIT))
   uart_tx0
  (
   .i_Clock(clock),
   .i_Tx_DV(uart_tx_send),
   .i_Tx_Byte(usart_tx_data), 
   .o_Tx_Active(uart_tx_active),
   .o_Tx_Serial(uart_tx_pin),
   .o_Tx_Done(uart_tx_done)
   );

endmodule
