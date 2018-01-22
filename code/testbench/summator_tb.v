
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

/*
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
*/
module code_ram #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18, parameter integer MEM_SIZE = 1024)
	(input wire [(ADDR_SIZE-1):0] addr,
	output wire [(WORD_SIZE-1):0] dout);

	reg [(WORD_SIZE-1):0] mem [(MEM_SIZE-1):0];
	
	initial $readmemh("vmem.txt", mem);
	
	assign dout = mem[addr];
endmodule


module multiplicator_tb;
	parameter MEM_SIZE = 64;
	parameter WORD_SIZE = 18;

	reg clock;

	logic [(WORD_SIZE-1):0] program_memory_addr;
	wire [(WORD_SIZE-1):0] program_memory_out_data;
	
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
		$dumpvars(0, program_memory_out_data);
		$dumpvars(0, processor18);
		$dumpvars(0, processor18.registers.regs[0]);
		$dumpvars(0, processor18.registers.regs[1]);
		
		processor_reset = 1;
		#2 processor_reset = 0;
		
		//wait(complete_fill_ram)
		//$monitor("in_data=%x, out_data=%x addr=%x", in_data, out_data, program_memory_addr);
		$monitor("mem[0]=%x", program_memory.mem[0]);
		
		#10 $finish;
	end

	//ram #(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE)) 
	//	program_memory(.clock(clock), .we(ram_write_enable),
	//	   .addr(program_memory_addr), .din(in_data), .dout(out_data));
		   
	//dump_ram  #(.ADDR_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE))	dump_ram0(.clock(clock), .reset(reset), .addr(addr));
	
	//fill_ram #(.ADDR_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE)) 
	//	fill_ram0(.clock(clock), .addr(filler_program_memory_addr), .data(in_data), .complete(complete_fill_ram));
	
	code_ram #(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE), .MEM_SIZE(MEM_SIZE))
		program_memory(
		.addr(program_memory_addr),
		.dout(program_memory_out_data));
		
	processor #(.ADDR_SIZE(WORD_SIZE), .WORD_SIZE(WORD_SIZE))
	processor18
	(.clock(clock),
	.reset(processor_reset),
	
	//Интерфейс для чтения программы
	.code_addr(program_memory_addr),
	.code_word(program_memory_out_data)
	);

endmodule
