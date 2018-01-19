/*
module multiplicator_tb;

	reg [7:0] a;
	reg [7:0] b;
	wire [15:0] res;
	reg clock ;
	reg reset;
	wire ready;
	reg start;

	initial
	begin
		clock = 0;
		forever  clock = #1 ~clock;
	end
	
	initial
	begin
		$dumpfile("wout.vcd");
		$dumpvars(0, m0);
		$monitor("A=%d, B=%d, res=%b", a, b, res);
		
		#1 start = 0;
		#1 reset = 1;
		#3 reset = 0;
		#1 a = 17; b = 19; start = 1;
		#2 if(ready!=0) $error("It's gone wrong");
		#1 start = 0;
		#30 if(res!=(17*19) || ready!=1) $error("It's gone wrong");
		
		#1 a = 3; b = 5; start = 1;
		#2 if(ready!=0) $error("It's gone wrong");
		#1 start = 0;
		#30 if(res!=(3*5) || ready!=1) $error("It's gone wrong");
		
		#1 a = 255; b = 255; start = 1;
		#2 if(ready!=0) $error("It's gone wrong");
		#1 start = 0;
		#30 if(res!=(255*255) || ready!=1) $error("It's gone wrong");
		
		#10 $finish;
	end

	multiplicator m0(a, b, res, clock, start, reset, ready);

endmodule
*/

module dump_ram #(parameter ADDR_SIZE = 18, parameter integer WORD_SIZE = 18, parameter integer MEM_SIZE = 1024)
 (clock, reset, addr);
	input wire clock;
	input wire reset;
	output reg [(ADDR_SIZE-1):0] addr;

	logic [(ADDR_SIZE-1):0] cur;
	initial cur = 0;
	
	always @(posedge clock)
	begin
		if(reset)
		begin
			cur <= 0;
		end

		if(cur<MEM_SIZE-1)
		begin
			cur <= cur + 1;
		end

		addr <= cur;
	end
endmodule

module fill_ram #(parameter ADDR_SIZE = 18, parameter integer WORD_SIZE = 18, parameter integer MEM_SIZE = 1024)
	(clock, addr, data, complete);
	input wire clock;
	output reg [(ADDR_SIZE-1):0] addr;
	output reg [(WORD_SIZE-1):0] data;
	output reg complete;
	
	logic [(ADDR_SIZE-1):0] cur;
	initial cur = 0;
	initial complete = 0;
	
	reg [(WORD_SIZE-1):0] mem_data[MEM_SIZE];
	initial $readmemh("vmem.txt", mem_data);

	always @(posedge clock)
	begin
		if(cur<=MEM_SIZE)
		begin
			cur <= cur + 1;
			complete <= 0;
			if(cur<MEM_SIZE)
			begin
				addr <= cur;
				data <= mem_data[addr];
			end
		end
		else
		begin
			complete <= 1;
		end

	end
	
endmodule
	

module multiplicator_tb;
	parameter MEM_SIZE = 64;
	parameter WORD_SIZE = 18;

	reg clock;
	reg reset;
	reg ram_write_enable;
	reg [(WORD_SIZE-1):0] in_data;
	wire [(WORD_SIZE-1):0] out_data;
	wire complete_fill_ram;
	

	logic [3:0] read_addr0;
	logic [(WORD_SIZE-1):0] read_data0;
	logic [3:0] read_addr1;
	logic [(WORD_SIZE-1):0] read_data1;
	logic reg_write_enable;
	logic [3:0] write_addr;
	logic [(WORD_SIZE-1):0] write_data;
	
	logic [(WORD_SIZE-1):0] program_memory_addr;
	wire [(WORD_SIZE-1):0] processor_program_memory_addr;
	reg [(WORD_SIZE-1):0] filler_program_memory_addr;
	reg program_memory_bind_to_processor;
	assign program_memory_addr = program_memory_bind_to_processor?processor_program_memory_addr:filler_program_memory_addr;
	
	logic processor_reset;
	
	integer i;

	initial
	begin
		clock = 0;
		forever  clock = #1 ~clock;
	end
	
	initial
	begin
		$dumpfile("wout.vcd");
		$dumpvars(0, program_memory_addr);
		$dumpvars(0, out_data);
		$dumpvars(0, program_memory);
		$dumpvars(0, program_memory.mem[0]);
		$dumpvars(0, processor18);
		$dumpvars(0, processor18.registers.regs[0]);
		$dumpvars(0, processor18.registers.regs[1]);
		ram_write_enable = 1;
		
		program_memory_bind_to_processor = 0;
		
		reg_write_enable = 0;
		read_addr0 = 0;
		read_addr1 = 0;
		write_addr = 0;
		write_data = 0;
		processor_reset = 1;
		
		#2 reset = 1;
		#2 reset = 0;
		
		wait(complete_fill_ram)
		$monitor("in_data=%x, out_data=%x addr=%x", in_data, out_data, program_memory_addr);
		$monitor("mem[0]=%x", program_memory.mem[0]);
		
		#2 $display("Memory filled end addr=%x",program_memory_addr);
		ram_write_enable = 0;
		
		#2 $display("read_data0=%x, read_data1=%x", read_data0, read_data1);
		program_memory_bind_to_processor = 1;
		#2 processor_reset = 0;
/*
		#2 write_addr = 3; write_data = 'h12; read_addr1 = 3;
		#2 reg_write_enable = 1;
		#2 reg_write_enable = 0;
		#2 $display("read_data0=%x, read_data1=%x", read_data0, read_data1);
		#2 write_addr = 0; write_data = 'h77;
		#2 reg_write_enable = 1;
		#2 reg_write_enable = 0;
		#2 $display("read_data0=%x, read_data1=%x", read_data0, read_data1);
*/
		#10 $finish;
	end

	ram #(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE)) 
		program_memory(.clock(clock), .we(ram_write_enable),
		   .addr(program_memory_addr), .din(in_data), .dout(out_data));
		   
	//dump_ram  #(.ADDR_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE))	dump_ram0(.clock(clock), .reset(reset), .addr(addr));
	
	fill_ram #(.ADDR_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE)) 
		fill_ram0(.clock(clock), .addr(filler_program_memory_addr), .data(in_data), .complete(complete_fill_ram));
/*
	regfile #(.WORD_SIZE(WORD_SIZE))
	regfile0
	(.clock(clock),
	.reset(reset),
	.read_addr0(read_addr0),
	.read_data0(read_data0),
	.read_addr1(read_addr1),
	.read_data1(read_data1),
	.write_enable(reg_write_enable),
	.write_addr(write_addr),
	.write_data(write_data)
	);
*/	
	processor #(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE))
	processor18
	(.clock(clock),
	.reset(processor_reset),
	
	//Интерфейс для чтения программы
	.code_addr(processor_program_memory_addr),
	.code_word(out_data)
	);

endmodule
