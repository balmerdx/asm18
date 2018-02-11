module if_control #(parameter integer WORD_SIZE = 18)
	(
	input wire [WORD_SIZE-1:0] r0,
	input wire [2:0] op,
	output reg if_ok
	);

	localparam integer IF_ZERO = 0; //r0==0
	localparam integer IF_LESS = 1; //r0<0
	localparam integer IF_GREAT = 2;//r0>0
	localparam integer IF_LESS_OR_EQUAL = 3;//r0<=0
	localparam integer IF_GREAT_OR_EQUAL = 4;//r0>=0
	localparam integer IF_ZERO_BIT_CLEAR = 5;//r0[0]==0
	localparam integer IF_ZERO_BIT_SET = 6;//r0[0]==1
	localparam integer IF_TRUE = 7; //Set true always
	
	wire is_zero = (r0==0);
	wire is_less = r0[WORD_SIZE-1];
	wire is_zero_bit = r0[0];
	
	always @(*)
	begin
		case(op)
		IF_ZERO: if_ok = is_zero;
		IF_LESS: if_ok = is_less;
		IF_GREAT: if_ok = !is_zero && !is_less;
		IF_LESS_OR_EQUAL: if_ok = is_zero | is_less;
		IF_GREAT_OR_EQUAL: if_ok = !is_less;
		IF_ZERO_BIT_CLEAR: if_ok = !is_zero_bit;
		IF_ZERO_BIT_SET: if_ok = is_zero_bit;
		IF_TRUE: if_ok = 1;
		default: if_ok = 1;
		endcase
	end
endmodule

