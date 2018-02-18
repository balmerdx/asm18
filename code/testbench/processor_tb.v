module code_ram #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18, parameter integer MEM_SIZE = 1024)
	(
	input wire clock,
	input wire [(ADDR_SIZE-1):0] addr,
	//output wire [(WORD_SIZE-1):0] dout //async ram
	output logic [(WORD_SIZE-1):0] dout //sync ram
	);

	reg [(WORD_SIZE-1):0] mem [(MEM_SIZE-1):0];
	
	initial $readmemh("intermediate/code.hex", mem);

	always @(posedge clock)
	begin
		dout <= mem[addr]; //sync ram
	end

	//assign dout = mem[addr]; //async ram
endmodule

module processor_tb;
	parameter MEM_SIZE = 64;
	parameter WORD_SIZE = 18;

	reg clock;

	logic [(WORD_SIZE-1):0] program_memory_addr;
	wire [(WORD_SIZE-1):0] program_memory_out_data;
	
	logic processor_reset;
	logic wait_continue_execution;
	logic wait_for_continue;
	
	wire data_we;
	wire [(WORD_SIZE-1):0] data_addr;
	wire [(WORD_SIZE-1):0] data_din;
	wire [(WORD_SIZE-1):0] data_dout;

`ifdef PROCESSOR_DEBUG_INTERFACE
	logic debug_get_param = 0;
	logic [3:0] debug_reg_addr;
	logic [(WORD_SIZE-1):0] debug_data_out;
`endif

	task print_state;
		integer i;
		integer f;
		f = $fopen("intermediate/current.state", "w");
		$fwrite(f,"registers\n");
		for (i = 0; i < 8; i = i +1)
			$fwrite(f,"r%0d = %h\n", i, processor18.registers.regs[i]);
		$fwrite(f,"ip = %h\n", processor18.ip);
		$fwrite(f,"memory\n");
		for (i = 0; i < MEM_SIZE; i = i +1)
			$fwrite(f,"%h\n", data_memory.mem[i]);
		$fclose(f);
	endtask

`ifdef PROCESSOR_DEBUG_INTERFACE
	task print_debug_interface;
		integer i;
		integer f;
		f = $fopen("intermediate/debug.state", "w");
		debug_get_param = 1;
		for (i = 0; i < 8; i = i +1)
		begin
			debug_reg_addr = i;
			#2;
			$fwrite(f,"r%0d = %h\n", i, debug_data_out);
		end

		debug_reg_addr = 8;
		#2;
		$fwrite(f,"ip = %h\n", debug_data_out);
		$fclose(f);
		debug_get_param = 0;
	endtask

	task check_debug_interface;
		integer i;
		debug_get_param = 1;
		for (i = 0; i < 8; i = i +1)
		begin
			debug_reg_addr = i;
			#2;
			if(debug_data_out != processor18.registers.regs[i])
			begin
				$display("r[%0d] not equal. Real=%h debug=%h",
						i, processor18.registers.regs[i], debug_data_out);
				$finish(1);
			end
		end

		debug_reg_addr = 8;
		#2;
		if(debug_data_out != processor18.ip)
		begin
			$display("ip not equal. ip=%h ipd=%h", processor18.ip, debug_data_out);
			$finish(1);
		end
		debug_get_param = 0;
		
		$display("Check debug interface completed.");
	endtask
`endif

	initial
	begin
		clock = 0;
		forever  clock = #1 ~clock;
	end
	
	initial
	begin
`ifdef OUT_VCD
		$dumpfile("intermediate/wout.vcd");
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
`endif
		
		wait_continue_execution = 0;
		processor_reset = 1;
		#2 processor_reset = 0;
		
		//$monitor("in_data=%x, out_data=%x addr=%x", in_data, out_data, program_memory_addr);
		//$monitor("mem[0]=%x", program_memory.mem[0]);
		
		wait(wait_for_continue);
		
		//#2 wait_continue_execution = 1;
		//#2 wait_continue_execution = 0;
		print_state();

`ifdef PROCESSOR_DEBUG_INTERFACE
		//print_debug_interface();
		check_debug_interface();
`endif
		
		#2 $finish;
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
		.clock(clock),
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
		.memory_out(data_dout),
		//Интерфейс для ожидания внешних данных
		.wait_for_continue(wait_for_continue),
		.wait_continue_execution(wait_continue_execution)
`ifdef PROCESSOR_DEBUG_INTERFACE
		,
		.debug_get_param(debug_get_param),
		.debug_reg_addr(debug_reg_addr),
		.debug_data_out(debug_data_out)
`endif
	);

endmodule//processor_tb
