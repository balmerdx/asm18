module ram #(parameter integer ADDR_SIZE = 18, parameter integer WORD_SIZE = 18, parameter integer MEM_SIZE = 1024)
	(input wire clock,
	input wire we,
	input wire [(ADDR_SIZE-1):0] addr,
	input wire [(WORD_SIZE-1):0] din,
	//output wire [(WORD_SIZE-1):0] dout //async ram
	output logic [(WORD_SIZE-1):0] dout //sync ram
	);

	reg [(WORD_SIZE-1):0] mem [(MEM_SIZE-1):0];
	always @(posedge clock)
	begin
		if (we)
			mem [addr] <= din;
		dout <= mem[addr]; //sync ram
	end

	//assign dout = mem[addr]; //async ram
endmodule
