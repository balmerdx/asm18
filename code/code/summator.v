
module full_summator(input a, input b, input cin,
	output sum, output cout);

	assign sum = a ^ b ^ cin;
	assign cout = (a&b)|(a&cin)|(b&cin);
endmodule

module full_summator4(input [3:0] a, input[3:0] b, input cin,
	output[3:0] sum, output cout);

	wire c1;
	wire c2;
	wire c3;
	full_summator s0(.a(a[0]), .b(b[0]), .cin(cin), .sum(sum[0]), .cout(c1));
	full_summator s1(.a(a[1]), .b(b[1]), .cin(c1), .sum(sum[1]), .cout(c2));
	full_summator s2(.a(a[2]), .b(b[2]), .cin(c2), .sum(sum[2]), .cout(c3));
	full_summator s3(.a(a[3]), .b(b[3]), .cin(c3), .sum(sum[3]), .cout(cout));
endmodule

module full_summator8(input [7:0] a, input[7:0] b, input cin,
	output[7:0] sum, output cout);

	wire c1;
	wire c2;
	full_summator4 s0(.a(a[3:0]), .b(b[3:0]), .cin(cin), .sum(sum[3:0]), .cout(c1));
	full_summator4 s1(.a(a[7:4]), .b(b[7:4]), .cin(c1), .sum(sum[7:4]), .cout(cout));
endmodule

module full_summator16(input [15:0] a, input[15:0] b, input cin,
	output[15:0] sum, output cout);

	wire c1;
	wire c2;
	full_summator8 s0(.a(a[7:0]), .b(b[7:0]), .cin(cin), .sum(sum[7:0]), .cout(c1));
	full_summator8 s1(.a(a[15:8]), .b(b[15:8]), .cin(c1), .sum(sum[15:8]), .cout(cout));
endmodule

//Умножение двух чисел res = a * b
//Умножение происходит за несколько тактов.
//Каждый такт происходит одно сложение чисел
// clock - тактовый генератор
// start - импульс для начала умножения чисел
// reset - сброс состояния системы
// ready - устанавливается в 1 после окончания умножения чисел

module multiplicator(input [7:0] a, input[7:0] b, output[15:0] res,
		input clock, input start, input reset, output ready);
	reg prev_start;
	reg [7:0] rega;
	reg [15:0] regb;
	reg [15:0] summator;
	wire [15:0] sumout;
	reg [3:0] counter;
	reg ready;
	reg cin;
	wire cout;
	
	assign res = summator;
	full_summator16 fsum(.a(regb&{15{rega[0]}}), .b(summator),
		.cin(cin), .sum(sumout), .cout(cout));
	//assign sumout = (regb&{15{rega[0]}})+summator;

	always @(posedge clock)
	begin
		if(reset==1)
		begin
			prev_start <= 0;
			summator <= 0;
			rega <= 0;
			regb <= 0;
			cin <= 0;
			ready <= 0;
		end
		
		if(start==1)
		begin
			if(prev_start==0)
			begin
				rega <= a;
				regb <= b;
				summator <= 0;
				prev_start <= start;
				ready <= 0;
				counter <= 0;
			end
		end
		
		if(prev_start==1)
		begin
			if(counter!=8)
			begin
				counter <= counter+1;
				regb <= {regb[14:0], 1'b0};
				rega <= {1'b0, rega[7:1]};
				summator <= sumout;
			end
			else
			begin
				ready <= 1;
				prev_start <= 0;
			end
		end
	end
endmodule
