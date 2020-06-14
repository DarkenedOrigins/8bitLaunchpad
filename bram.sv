/*
 *		This module instantiates the BRAM that we used to store the
 *		User's recorded data.
 */

module big_ram(
	input							Clk,
	input							WE,
	input  logic [17:0]		addr,		//Determines the Depth of memory
	output logic [9:0]		read_data,
	input  logic [9:0]		write_data //determines the width of the data
	
);
	// 262144 x 10 BRAM to store samples
	logic [9:0] RAM [262144];

	always_ff @ (posedge Clk)
	begin
		if(WE)
			RAM[addr] <= write_data;
		else
			read_data <= RAM[addr];
	end

endmodule
