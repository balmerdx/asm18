//Чтение инструкции из памяти для программы
module processor_stage1 #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18)
	(input wire clock,
	input wire reset,
	
	input wire no_operation,
	//Интерфейс для чтения программы
	output wire [(ADDR_SIZE-1):0] code_addr,
	//Условные и безусловные переходы
	input wire [(WORD_SIZE-1):0] ip_to_call,
	input wire call_performed,
	input wire [(WORD_SIZE-1):0] ip_to_return,
	input wire return_performed,
	//Данные для следующей стадии
	output reg no_operation_out,
	output reg [(ADDR_SIZE-1):0] ip_out,
	output reg [(ADDR_SIZE-1):0] ip_plus_one_out
	);

	reg [(WORD_SIZE-1):0] ip;
	wire [(WORD_SIZE-1):0] ip_plus_one;
	assign ip_plus_one = (call_performed?ip_to_call:(ip+ 1'd1));
	assign code_addr = ip;

	always @(posedge clock)
	if(reset)
	begin
		ip <= 0;
		ip_out <= 0;
		no_operation_out <= 0;
	end
	else
	begin
		no_operation_out <= no_operation || call_performed || return_performed;
		if(!no_operation)
		begin
			if(return_performed)
				ip <= ip_to_return;
			else
			if(call_performed)
				ip <= ip_to_call;
			else
				ip <= ip_plus_one;

			ip_out <= ip;
			ip_plus_one_out <= ip_plus_one;
		end
	end

endmodule 

