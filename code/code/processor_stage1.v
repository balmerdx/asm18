//Чтение инструкции из памяти для программы
module processor_stage1 #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18)
	(input wire clock,
	input wire reset,
	
	input wire no_operation,
	//Интерфейс для чтения программы
	output wire [(ADDR_SIZE-1):0] code_addr,
	input wire [(WORD_SIZE-1):0] code_word,
	//Условные и безусловные переходы
	input wire [(WORD_SIZE-1):0] ip_to_call,
	input wire call_performed,
	//Данные для следующей стадии
	output reg no_operation_out,
	output reg [(ADDR_SIZE-1):0] ip_out,
	output reg [(WORD_SIZE-1):0] code_word_out
	);

	reg [(WORD_SIZE-1):0] ip;
	wire [(WORD_SIZE-1):0] ip_plus_one;
	assign ip_plus_one = ip + 1'd1;

	always @(posedge clock)
	if(reset)
	begin
		ip <= 0;
		ip_out <= 0;
		code_word_out <= 0;
		no_operation_out <= 0;
	end
	else
	begin
		no_operation_out <= no_operation;
		if(call_performed)
			ip <= ip_to_call;
		else
			ip <= ip_plus_one;
		code_word_out <= code_word;
	end

endmodule 

