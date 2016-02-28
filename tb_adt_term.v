`timescale 1ns / 1ns

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   13:50:09 01/25/2016
// Design Name:   adt_term
// Module Name:   C:/Users/ztong/Desktop/WRJ/cpm_l/tb_adt_term.v
// Project Name:  cpm_l
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: adt_term
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_adt_term;

	// Inputs
	reg clk;
	reg reset_n;
	reg rx;
	reg tx_frame_start;
	reg [7:0] data_ram;
	reg [15:0] addr_ram;
	reg wr_ram;

	// Outputs
	wire tx;
	wire tx_busy;
	wire rx_frame_done;
	wire [199:0] rx_frame;
	wire comNoResponse;
	wire check_sum_error;

	// Instantiate the Unit Under Test (UUT)
	adt_term uut (
		.clk(clk), 
		.reset_n(reset_n), 
		.rx(rx), 
		.tx_frame_start(tx_frame_start), 
		.data_ram(data_ram), 
		.addr_ram(addr_ram), 
		.wr_ram(wr_ram), 
		.tx(tx), 
		.tx_busy(tx_busy), 
		.rx_frame_done(rx_frame_done), 
		.rx_frame(rx_frame), 
		.comNoResponse(comNoResponse), 
		.check_sum_error(check_sum_error)
	);
	reg		wr_ram_r;
	initial begin
		// Initialize Inputs
		clk = 0;
		reset_n = 0;
		rx = 0;
		tx_frame_start = 0;
		data_ram = 0;
		addr_ram = 0;
		wr_ram_r = 0;

		// Wait 100 ns for global reset to finish
		#20	
		reset_n		= 1;
        #40
		reset_n		= 0;
		#20 
		reset_n		= 1;
		#90
		wr_ram_r		= 1;
		
		// Add stimulus here
	end
    //reg		clk_25M		= 0;
	
	always #10 clk 		= ~clk;
	//always #20 clk_25M	= ~clk_25M;
	reg[3:0]		clkCnt;
	wire			clk_25M;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			clkCnt 	<= 0;
		else
			clkCnt	<= clkCnt + 1'b1;
	assign	clk_25M	= clkCnt[1];//clk_12P5M
	
	
	always	@	(posedge	clk)
		if(addr_ram == 99)
			wr_ram_r <= 0;
		else if(addr_ram == 100)
			tx_frame_start	<= 1'b1;
		else
			tx_frame_start	<= 1'b0;
			
	
	always	@	(posedge	clk_25M)
			wr_ram	<= wr_ram_r;
	
	always	@	(posedge	clk_25M)
		if(wr_ram)
			addr_ram	<= addr_ram + 1'b1;
		else
			addr_ram	<= 0;
			
			
	always	@	(posedge	clk	or	negedge	reset_n)
		case(addr_ram)
		0:	data_ram 	<= 8'h11;
		1:	data_ram	<= 8'h22;
		2:	data_ram	<= 8'h33;
		3:	data_ram	<= 8'h44;
		4:	data_ram	<= 8'h55;
		5:	data_ram	<= 8'h66;
		6:	data_ram	<= 8'h77;
		7:	data_ram	<= 8'h88;
		8:	data_ram	<= 8'h99;
		9:	data_ram	<= 8'hAA;
		10,11,12,13,14,15,16,17,18,19,20,
		21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
		41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56:
			data_ram	<= 8'h55;
		57:	data_ram	<= 8'h57;
		58:	data_ram	<= 8'h58;
		59:	data_ram	<= 8'h59;
		60:	data_ram	<= 8'h60;
		61:	data_ram	<= 8'h61;
		62:	data_ram	<= 8'h62;
		63:	data_ram	<= 8'h63;
		64:	data_ram	<= 8'h64;
		65:	data_ram	<= 8'h65;
		66:	data_ram	<= 8'h66;
		67,68,69,70,71,72,73,74,75,76,77,78,79,
		80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95,96:
			data_ram	<= 8'h55;
		97: data_ram	<= 8'h97;
		98: data_ram	<= 8'h98;
		99: data_ram	<= 8'h99;
		default:data_ram <= 0;
		endcase;
	
endmodule

