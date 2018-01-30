module mulxx #(parameter integer WORD_SIZE = 18)
	(
	input wire [WORD_SIZE-1:0] r0,
	input wire [WORD_SIZE-1:0] r1,
	input wire [4:0] shift, //0..17
	input wire signx,
	input wire signy,
	output reg [WORD_SIZE-1:0] res //result
	);
	
	logic [WORD_SIZE*2-1:0] mx;
	logic [WORD_SIZE*2-1:0] shift1;
	logic [WORD_SIZE*2-1:0] shift2;
	assign res = shift2[WORD_SIZE-1:0];
	
	always @(*)
	begin
		case({signx, signy})
		2'b00: mx = r0*r1;
		2'b01: mx = r0*$signed(r1);
		2'b10: mx = $signed(r0)*r1;
		2'b11: mx = $signed(r0)*$signed(r1);
		endcase
		
		case(shift[2:0])
		0: shift1 = mx;
		1: shift1 = mx>>1;
		2: shift1 = mx>>2;
		3: shift1 = mx>>3;
		4: shift1 = mx>>4;
		5: shift1 = mx>>5;
		6: shift1 = mx>>6;
		7: shift1 = mx>>7;
		endcase
		
		case(shift[4:3])
		0: shift2 = shift1;
		1: shift2 = shift1>>8;
		2: shift2 = shift1>>16;
		3: shift2 = shift1>>24;
		endcase
	end
	
endmodule