`timescale 1ns / 1ns

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   11:28:34 01/25/2016
// Design Name:   dataControl
// Module Name:   C:/Users/ztong/Desktop/WRJ/cpm_l/tb_dataControl.v
// Project Name:  cpm_l
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dataControl
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tb_dataControl;

	// Inputs
	reg clk;
	reg reset_n;
	reg [455:0] wenmiao_rx_frame;
	reg wenmiao_tx_busy;
	reg wenmiao_rx_frame_done;
	reg wenmiao_check_sum_error;
	reg wenmiao_comNoResponse;
	reg feikong_tx_busy;
	reg [319:0] feikong_rx_frame;
	reg feikong_rx_frame_done;
	reg feikong_check_sum_error;
	reg feikong_comNoResponse;
	reg [71:0] fakong_rx_frame;
	reg fakong_tx_busy;
	reg fakong_rx_frame_done;
	reg fakong_check_sum_error;
	reg fakong_comNoResponse;
	reg [199:0] adt_rx_frame;
	reg adt_rx_frame_done;
	reg adt_tx_busy;
	reg adt_check_sum_error;
	reg adt_comNoResponse;

	// Outputs
	wire [159:0] wenmiao_tx_frame;
	wire wenmiao_tx_start;
	wire [79:0] feikong_tx_frame;
	wire feikong_tx_frame_start;
	wire [255:0] fakong_tx_frame;
	wire fakong_tx_start;
	wire adt_wr_ram;
	wire [15:0] adt_addr_ram;
	wire [7:0] adt_data_ram;
	wire adt_tx_frame_start;

	// Instantiate the Unit Under Test (UUT)
	dataControl uut (
		.clk(clk), 
		.reset_n(reset_n), 
		.wenmiao_tx_frame(wenmiao_tx_frame), 
		.wenmiao_tx_start(wenmiao_tx_start), 
		.wenmiao_rx_frame(wenmiao_rx_frame), 
		.wenmiao_tx_busy(wenmiao_tx_busy), 
		.wenmiao_rx_frame_done(wenmiao_rx_frame_done), 
		.wenmiao_check_sum_error(wenmiao_check_sum_error), 
		.wenmiao_comNoResponse(wenmiao_comNoResponse), 
		.feikong_tx_frame(feikong_tx_frame), 
		.feikong_tx_frame_start(feikong_tx_frame_start), 
		.feikong_tx_busy(feikong_tx_busy), 
		.feikong_rx_frame(feikong_rx_frame), 
		.feikong_rx_frame_done(feikong_rx_frame_done), 
		.feikong_check_sum_error(feikong_check_sum_error), 
		.feikong_comNoResponse(feikong_comNoResponse), 
		.fakong_tx_frame(fakong_tx_frame), 
		.fakong_tx_start(fakong_tx_start), 
		.fakong_rx_frame(fakong_rx_frame), 
		.fakong_tx_busy(fakong_tx_busy), 
		.fakong_rx_frame_done(fakong_rx_frame_done), 
		.fakong_check_sum_error(fakong_check_sum_error), 
		.fakong_comNoResponse(fakong_comNoResponse), 
		.adt_rx_frame(adt_rx_frame), 
		.adt_rx_frame_done(adt_rx_frame_done), 
		.adt_tx_busy(adt_tx_busy), 
		.adt_check_sum_error(adt_check_sum_error), 
		.adt_comNoResponse(adt_comNoResponse), 
		.adt_wr_ram(adt_wr_ram), 
		.adt_addr_ram(adt_addr_ram), 
		.adt_data_ram(adt_data_ram), 
		.adt_tx_frame_start(adt_tx_frame_start)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset_n = 0;
		wenmiao_rx_frame = 0;
		wenmiao_tx_busy = 0;
		wenmiao_rx_frame_done = 0;
		wenmiao_check_sum_error = 0;
		wenmiao_comNoResponse = 0;
		feikong_tx_busy = 0;
		feikong_rx_frame = 0;
		feikong_rx_frame_done = 0;
		feikong_check_sum_error = 0;
		feikong_comNoResponse = 0;
		fakong_rx_frame = 0;
		fakong_tx_busy = 0;
		fakong_rx_frame_done = 0;
		fakong_check_sum_error = 0;
		fakong_comNoResponse = 0;
		adt_rx_frame = 0;
		adt_rx_frame_done = 0;
		adt_tx_busy = 0;
		adt_check_sum_error = 0;
		adt_comNoResponse = 0;

		// Wait 100 ns for global reset to finish
		#40
		reset_n = 1;
		#40
		reset_n	= 0;
		#20
		reset_n = 1;
		#20
		wenmiao_tx_busy = 1;
		fakong_tx_busy  = 1;
		#20
		wenmiao_tx_busy	= 0;
		fakong_tx_busy  = 0;
		
        
		// Add stimulus here
		//forever #10 clk = ~clk;
	end
	
	always #10 clk = ~clk;
      
endmodule

