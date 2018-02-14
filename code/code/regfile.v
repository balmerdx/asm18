module regfile #(parameter integer WORD_SIZE = 18, parameter integer REG_COUNT = 8)
	(input wire clock,
	input wire reset,
	input wire [3:0] read_addr0,
	output wire [(WORD_SIZE-1):0] read_data0,
	input wire [3:0] read_addr1,
	output wire [(WORD_SIZE-1):0] read_data1,
	input wire write_enable,
	input wire [3:0] write_addr,
	input wire [(WORD_SIZE-1):0] write_data
	);
	//Два входных порта и один выходной
	//Регистров всего 8
	//rx0-rx6 - регистры общего назначения
	//rx7 - stack pointer (sp)
	
	reg [(WORD_SIZE-1):0] regs[(REG_COUNT-1):0];
	integer i;
	always @(posedge clock)
	begin
		if(reset)
		begin
			for (i=0; i < REG_COUNT; i=i+1)
				regs[i] <= 0;
		end
		else
		begin
			if(write_enable)
				regs[write_addr] <= write_data;
		end
	end
	
	assign read_data0 = regs[read_addr0];
	assign read_data1 = regs[read_addr1];
	
endmodule