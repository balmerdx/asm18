
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
		$dumpvars(0, data_memory.mem[0]);
		$dumpvars(0, data_memory.mem[1]);
		
		processor_reset = 1;
		#2 processor_reset = 0;
		
		//wait(complete_fill_ram)
		//$monitor("in_data=%x, out_data=%x addr=%x", in_data, out_data, program_memory_addr);
		$monitor("mem[0]=%x", program_memory.mem[0]);
		
		#10 $finish;
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
		.data_write_enable(data_we),
		.data_addr(data_addr),
		.data_in(data_din),
		.data_out(data_dout)
	);

endmodule
