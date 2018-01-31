/*
module code_ram #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18, parameter integer MEM_SIZE = 1024)
	(input wire [(ADDR_SIZE-1):0] addr,
	output wire [(WORD_SIZE-1):0] dout);

	reg [(WORD_SIZE-1):0] mem [(MEM_SIZE-1):0];
	
	initial $readmemh("vmem.txt", mem);
	
	assign dout = mem[addr];
endmodule

module processor_tb;
	parameter MEM_SIZE = 64;
	parameter WORD_SIZE = 18;

	reg clock;

	logic [(WORD_SIZE-1):0] program_memory_addr;
	wire [(WORD_SIZE-1):0] program_memory_out_data;
	
	logic processor_reset;
	
	integer i;
	
	wire data_we;
	wire [(WORD_SIZE-1):0] data_addr;
	wire [(WORD_SIZE-1):0] data_din;
	wire [(WORD_SIZE-1):0] data_dout;

	initial
	begin
		clock = 0;
		forever  clock = #1 ~clock;
	end
	
	initial
	begin
		$dumpfile("wout.vcd");
		$dumpvars(0, program_memory_addr);
		$dumpvars(0, program_memory_out_data);
		$dumpvars(0, processor18);
		$dumpvars(0, processor18.registers.regs[0]);
		$dumpvars(0, processor18.registers.regs[1]);
		$dumpvars(0, processor18.registers.regs[2]);
		$dumpvars(0, processor18.registers.regs[3]);
		$dumpvars(0, processor18.registers.regs[7]);
		$dumpvars(0, data_memory.mem[0]);
		$dumpvars(0, data_memory.mem[1]);
		$dumpvars(0, data_memory.mem[2]);
		$dumpvars(0, data_memory.mem[3]);
		$dumpvars(0, data_memory.mem[4]);
		$dumpvars(0, data_memory.mem[5]);
		$dumpvars(0, data_memory.mem[6]);
		$dumpvars(0, data_memory.mem[7]);
		
		processor_reset = 1;
		#2 processor_reset = 0;
		
		//wait(complete_fill_ram)
		//$monitor("in_data=%x, out_data=%x addr=%x", in_data, out_data, program_memory_addr);
		$monitor("mem[0]=%x", program_memory.mem[0]);
		
		#70 $finish;
	end
	
	ram #(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE)) 
		data_memory(
		.clock(clock),
		.we(data_we),
		.addr(data_addr),
		.din(data_din),
		.dout(data_dout));
	
	code_ram #(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE))
		program_memory(
		.addr(program_memory_addr),
		.dout(program_memory_out_data));
		
	processor #(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE))
		processor18(
		.clock(clock),
		.reset(processor_reset),
	
		//Интерфейс для чтения программы
		.code_addr(program_memory_addr),
		.code_word(program_memory_out_data),
		//Интерфейс для чтения данных
		.memory_write_enable(data_we),
		.memory_addr(data_addr),
		.memory_in(data_din),
		.memory_out(data_dout)
	);

endmodule//processor_tb
*/
/*
module if_tb;
	parameter WORD_SIZE = 18;
	
	logic signed [WORD_SIZE-1:0] r0;
	logic [2:0] op;
	logic if_ok;
	initial
	begin
		#2 r0 = 1; op = if_control0.IF_ZERO;
		#2 $display("r0=%d (r0==0)=%d", r0, if_ok);
		#2 r0 = 0; op = if_control0.IF_ZERO;
		#2 $display("r0=%d (r0==0)=%d", r0, if_ok);
		#2 r0 = -1; op = if_control0.IF_ZERO;
		#2 $display("r0=%d (r0==0)=%d", r0, if_ok);
		
		#2 r0 = 1; op = if_control0.IF_LESS;
		#2 $display("r0=%d (r0<0)=%d", r0, if_ok);
		#2 r0 = 0; op = if_control0.IF_LESS;
		#2 $display("r0=%d (r0<0)=%d", r0, if_ok);
		#2 r0 = -1; op = if_control0.IF_LESS;
		#2 $display("r0=%d (r0<0)=%d", r0, if_ok);
		
		#2 r0 = 1; op = if_control0.IF_GREAT;
		#2 $display("r0=%d (r0>0)=%d", r0, if_ok);
		#2 r0 = 0; op = if_control0.IF_GREAT;
		#2 $display("r0=%d (r0>0)=%d", r0, if_ok);
		#2 r0 = -1; op = if_control0.IF_GREAT;
		#2 $display("r0=%d (r0>0)=%d", r0, if_ok);
		#2 r0 = 131071; op = if_control0.IF_GREAT;
		#2 $display("r0=%d (r0>0)=%d", r0, if_ok);
		#2 r0 = -131072; op = if_control0.IF_GREAT;
		#2 $display("r0=%d (r0>0)=%d", r0, if_ok);

		#2 r0 = 1; op = if_control0.IF_LESS_OR_EQUAL;
		#2 $display("r0=%d (r0<=0)=%d", r0, if_ok);
		#2 r0 = 0; op = if_control0.IF_LESS_OR_EQUAL;
		#2 $display("r0=%d (r0<=0)=%d", r0, if_ok);
		#2 r0 = -1; op = if_control0.IF_LESS_OR_EQUAL;
		#2 $display("r0=%d (r0<=0)=%d", r0, if_ok);
		#2 r0 = +222; op = if_control0.IF_LESS_OR_EQUAL;
		#2 $display("r0=%d (r0<=0)=%d", r0, if_ok);
		#2 r0 = -222; op = if_control0.IF_LESS_OR_EQUAL;
		#2 $display("r0=%d (r0<=0)=%d", r0, if_ok);

		#2 r0 = 1; op = if_control0.IF_GREAT_OR_EQUAL;
		#2 $display("r0=%d (r0>=0)=%d", r0, if_ok);
		#2 r0 = 0; op = if_control0.IF_GREAT_OR_EQUAL;
		#2 $display("r0=%d (r0>=0)=%d", r0, if_ok);
		#2 r0 = -1; op = if_control0.IF_GREAT_OR_EQUAL;
		#2 $display("r0=%d (r0>=0)=%d", r0, if_ok);
		#2 r0 = +222; op = if_control0.IF_GREAT_OR_EQUAL;
		#2 $display("r0=%d (r0>=0)=%d", r0, if_ok);
		#2 r0 = -222; op = if_control0.IF_GREAT_OR_EQUAL;
		#2 $display("r0=%d (r0>=0)=%d", r0, if_ok);

		#2 r0 = 1; op = if_control0.IF_ZERO_BIT_CLEAR;
		#2 $display("r0=%d !(r0&1)=%d", r0, if_ok);
		#2 r0 = 0; op = if_control0.IF_ZERO_BIT_CLEAR;
		#2 $display("r0=%d !(r0&1)=%d", r0, if_ok);
		#2 r0 = -1; op = if_control0.IF_ZERO_BIT_CLEAR;
		#2 $display("r0=%d !(r0&1)=%d", r0, if_ok);
		#2 r0 = 2; op = if_control0.IF_ZERO_BIT_CLEAR;
		#2 $display("r0=%d !(r0&1)=%d", r0, if_ok);

		#2 r0 = 1; op = if_control0.IF_ZERO_BIT_SET;
		#2 $display("r0=%d (r0&1)=%d", r0, if_ok);
		#2 r0 = 0; op = if_control0.IF_ZERO_BIT_SET;
		#2 $display("r0=%d (r0&1)=%d", r0, if_ok);
		#2 r0 = -1; op = if_control0.IF_ZERO_BIT_SET;
		#2 $display("r0=%d (r0&1)=%d", r0, if_ok);
		#2 r0 = 2; op = if_control0.IF_ZERO_BIT_SET;
		#2 $display("r0=%d (r0&1)=%d", r0, if_ok);
		
		#2 r0 = 2; op = if_control0.IF_TRUE;
		#2 $display("r0=%d (true)=%d", r0, if_ok);
	end
	

	if_control #(.WORD_SIZE(WORD_SIZE))
		if_control0
	(
	.r0(r0),
	.op(op),
	.if_ok(if_ok)
	);
endmodule//if_tb
*/
/*
module alu_tb;
	parameter WORD_SIZE = 18;
	parameter WORD_MIN = -131072;
	parameter WORD_MAX = 131071;
	logic signed [WORD_SIZE-1:0] r0;
	logic signed [WORD_SIZE-1:0] r1;
	logic signed [WORD_SIZE-1:0] res;
	logic [3:0] op;
	initial
	begin
		$monitor("r0=%d, r1=%d, op=%d, res=%d", r0, r1, op, res);
		#2 r0 = 1; r1 = 2; op = alu0.ALU_OP_ADD;
		#2 if(res!=3) $error("Fail");
		#2 r0 = WORD_MAX; r1 = 1; op = alu0.ALU_OP_ADD;
		#2 if(res!=WORD_MIN) $error("Fail");
		
		#2 r0 = 3; r1 = 1; op = alu0.ALU_OP_SUB;
		#2 if(res!=2) $error("Fail");
		#2 r0 = 1; r1 = 3; op = alu0.ALU_OP_SUB;
		#2 if(res!=-2) $error("Fail");
		
		#2 r0 = 18'b101111011000110010; r1 = 18'b100101111010100111; op = alu0.ALU_OP_AND;
		#2 if(res!=$signed(18'b100101011000100010)) $error("Fail");
		#2 r0 = 18'b001111011000110010; r1 = 18'b100101111010100111; op = alu0.ALU_OP_AND;
		#2 if(res!=$signed(18'b000101011000100010)) $error("Fail");
		
		#2 r0 = 18'b101111011000110010; r1 = 18'b100101111010100111; op = alu0.ALU_OP_OR;
		#2 if(res!=$signed(18'b101111111010110111)) $error("Fail");
		
		#2 r0 = 18'b101111011000110010; r1 = 18'b100101111010100111; op = alu0.ALU_OP_XOR;
		#2 if(res!=$signed(18'b001010100010010101)) $error("Fail");
		
		#2 r0 = 18'b101111011000110010; r1 = 18'b100101111010100111; op = alu0.ALU_OP_NOT;
		#2 if(res!=$signed(18'b011010000101011000)) $error("Fail");
		
		#2 $finish;
	end
	
	alu #(.WORD_SIZE(WORD_SIZE))
		alu0(
		.r0(r0),
		.r1(r1),
		.op(op),
		.res(res)
		);

endmodule//alu_tb
*/

module mullxx_tb;
	parameter WORD_SIZE = 18;
	logic [WORD_SIZE-1:0] r0;
	logic [WORD_SIZE-1:0] r1;
	logic [WORD_SIZE-1:0] res;
	logic [4:0] shift;
	logic signx;
	logic signy;
	
	logic signed [WORD_SIZE-1:0] r0s;
	logic signed [WORD_SIZE-1:0] r1s;
	logic signed [WORD_SIZE-1:0] ress;
	
	assign r0s = $signed(r0);
	assign r1s = $signed(r1);
	assign ress = $signed(res);
	
	initial
	begin
	$monitor("r0=%d, r1=%d, res=%d sx=%d sy=%d shift=%d, r0s=%d, r1s=%d, ress=%d", r0, r1, res, signx, signy, shift, r0s, r1s, ress);
	r0 = 0; r1 = 0; shift = 0; signx = 0; signy = 0;
	
	#2 r0 = 2; r1 = 2; shift = 0; signx = 0; signy = 0;
	#2 if(res!=4) $error("Fail");
	
	#2 r0 = 2; r1 = 3; shift = 0; signx = 0; signy = 0;
	#2 if(res!=6) $error("Fail");
	
	#2 r0 = -2; r1 = 3; shift = 0; signx = 1; signy = 0;
	#2 if($signed(res)!=-6) $error("Fail");
	
	#2 r0 = 2; r1 = -1; shift = 0; signx = 1; signy = 1;
	#2 if($signed(res)!=-2) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 1; shift = 0; signx = 0; signy = 0;
	#2 if(res!='h3ffff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 1; shift = 1; signx = 0; signy = 0;
	#2 if(res!='h1ffff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 1; shift = 2; signx = 0; signy = 0;
	#2 if(res!='hffff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 1; shift = 3; signx = 0; signy = 0;
	#2 if(res!='h7fff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 1; shift = 4; signx = 0; signy = 0;
	#2 if(res!='h3fff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 1; shift = 5; signx = 0; signy = 0;
	#2 if(res!='h1fff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 1; shift = 6; signx = 0; signy = 0;
	#2 if(res!='hfff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 1; shift = 7; signx = 0; signy = 0;
	#2 if(res!='h7ff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 37; shift = 7; signx = 0; signy = 0;
	#2 if(res!='h127ff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 37; shift = 8; signx = 0; signy = 0;
	#2 if(res!='h93ff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 37; shift = 9; signx = 0; signy = 0;
	#2 if(res!='h49ff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 37; shift = 10; signx = 0; signy = 0;
	#2 if(res!='h24ff) $error("Fail");
	
	#2 r0 = 4727; r1 = 56782; shift = 10; signx = 0; signy = 0;
	#2 if(res!='h3ffe5) $error("Fail");
	
	#2 r0 = 4727; r1 = 56782; shift = 11; signx = 0; signy = 0;
	#2 if(res!='h1fff2) $error("Fail");
	
	#2 r0 = 4727; r1 = 56782; shift = 12; signx = 0; signy = 0;
	#2 if(res!='hfff9) $error("Fail");
	
	#2 r0 = 4727; r1 = 56782; shift = 13; signx = 0; signy = 0;
	#2 if(res!='h7ffc) $error("Fail");
	
	#2 r0 = 4727; r1 = 56782; shift = 14; signx = 0; signy = 0;
	#2 if(res!='h3ffe) $error("Fail");
	
	#2 r0 = 4727; r1 = 56782; shift = 15; signx = 0; signy = 0;
	#2 if(res!='h1fff) $error("Fail");
	
	#2 r0 = 4727; r1 = 56782; shift = 16; signx = 0; signy = 0;
	#2 if(res!='hfff) $error("Fail");
	
	#2 r0 = 47273; r1 = 56782; shift = 16; signx = 0; signy = 0;
	#2 if(res!='h9ffe) $error("Fail");
	
	#2 r0 = 47273; r1 = 56782; shift = 17; signx = 0; signy = 0;
	#2 if(res!='h4fff) $error("Fail");
	
	#2 r0 = 47273; r1 = 56782; shift = 18; signx = 0; signy = 0;
	#2 if(res!='h27ff) $error("Fail");
	
	#2 r0 = 'h3ffff; r1 = 'h3ffff; shift = 18; signx = 0; signy = 0;
	#2 if(res!='h3fffe) $error("Fail");
	
	#2 r0 = -1; r1 = 1; shift = 0; signx = 1; signy = 1;
	#2 if($signed(res)!=-1) $error("Fail");
	
	#2 r0 = -1; r1 = -1; shift = 0; signx = 1; signy = 1;
	#2 if($signed(res)!=1) $error("Fail");
	
	end

	mulxx #(.WORD_SIZE(WORD_SIZE))
		mulxx0(
		.r0(r0),
		.r1(r1),
		.shift(shift), //0..17
		.signx(signx),
		.signy(signy),
		.res(res) //result
		);

endmodule//mullxx_tb