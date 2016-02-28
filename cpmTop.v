`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		Inspur Chaoyue
// Engineer: 
// 
// Create Date:    16:39:33 01/13/2016 
// Design Name: 
// Module Name:    cmpTop 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//					By Zhao-Tongliang
//////////////////////////////////////////////////////////////////////////////////
module cpmTop(
	input clk,
	input reset_n,
	
	input rx_feikong,
	input rx_wenmiao,
	input rx_fakong,
	input rx_adt,
	
	output tx_feikong,
	output tx_wenmiao,
	output tx_fakong,
	output tx_adt,
	
	inout  SJA1000_add_data,
	output can_ale,can_cs_n,can_rd_n,can_wr_n,can_rst,
	output convert_dir
    );

//SJA1000.v
	//inout类型不能放在内部模块，只能在顶层
	wire		rd_valid;
	reg[7:0]	can_in;
	wire		en_out;
	wire[7:0] 	can_out;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			can_in		<= 8'd0;
		else if(rd_valid)
			can_in		<= SJA1000_add_data;
	
	assign	SJA1000_add_data	= (en_out) ? can_out : 8'hZ;
	
SJA1000 SJA1000_inst (
    .clk(clk), 
    .reset_n(reset_n), 
    .can_rx_done(), 
    .can_rx_data(), 
    .can_tx_data(), 
    .convert_dir(convert_dir), 
    .can_in(can_in), 
    .can_out(can_out), 
    .en_out(en_out), 
    .rd_valid(rd_valid), 
    .can_ale(can_ale), 
    .can_wr_n(can_wr_n), 
    .can_rd_n(can_rd_n), 
    .can_cs_n(can_cs_n), 
    .can_rst(can_rst)
    );
	
	
//发控
wire[255:0]	fakong_tx_frame;
wire[71:0]	fakong_rx_frame;
wire		fakong_tx_start;
wire		fakong_tx_busy;
wire		fakong_rx_frame_done;
wire		fakong_check_sum_error;
wire		fakong_comNoResponse;
fakong fakong_inst (
    .clk(clk), 
    .reset_n(reset_n), 
    .rx(rx_fakong), 
    .tx_frame_start(fakong_tx_start), 
    .tx_frame(fakong_tx_frame), 
    .tx(tx_fakong), 
    .tx_busy(fakong_tx_busy), 
    .rx_frame_done(fakong_rx_frame_done), 
    .rx_frame(fakong_rx_frame), 
    .check_sum_error(fakong_check_sum_error), 
    .comNoResponse(fakong_comNoResponse)
    );
//飞控
wire[319:0]	feikong_rx_frame;
wire		feikong_rx_frame_done;
wire		feikong_check_sum_error;
wire		feikong_comNoResponse;
wire		feikong_tx_frame_start;
wire[79:0]	feikong_tx_frame;
wire		feikong_tx_busy;
wire		feikong_last2Error;

feikong feikong_inst (
    .clk(clk), 
    .reset_n(reset_n), 
    .rx(rx_feikong), 
    .tx_frame_start(feikong_tx_frame_start),/// 
    .tx_frame(feikong_tx_frame), ////////
    .tx(tx_feikong),/////
    .tx_busy(feikong_tx_busy), /////////
    .rx_frame_done(feikong_rx_frame_done), 
    .rx_frame(feikong_rx_frame), 
    .check_sum_error(feikong_check_sum_error), 
    .comNoResponse(feikong_comNoResponse),
	.last2Error(feikong_last2Error)
    );
//稳瞄	
wire[159:0]	wenmiao_tx_frame;
wire[455:0]	wenmiao_rx_frame;
wire		wenmiao_tx_start;
wire		wenmiao_tx_busy;
wire		wenmiao_rx_frame_done;
wire		wenmiao_check_sum_error;
wire		wenmiao_comNoResponse;
wenmiao wenmiao_inst(
    .clk			(clk), 
    .reset_n		(reset_n), 
    .rx				(rx_wenmiao), 
    .tx_frame_start	(wenmiao_tx_start), 
    .tx_frame		(wenmiao_tx_frame), 
    .tx				(tx_wenmiao), 
    .tx_busy		(wenmiao_tx_busy), 
    .rx_frame_done	(wenmiao_rx_frame_done), 
    .rx_frame		(wenmiao_rx_frame), 
    .check_sum_error(wenmiao_check_sum_error), 
    .comNoResponse	(wenmiao_comNoResponse)
    );
//ADT
wire[199:0]	adt_rx_frame;
wire		adt_rx_frame_done;
wire		adt_tx_busy;
wire		adt_wr_ram;
wire[15:0]	adt_addr_ram;
wire[7:0]	adt_data_ram;
wire		adt_tx_frame_start;
wire		adt_comNoResponse;
wire		adt_check_sum_error;

adt_term adt_inst (
    .clk(clk), 
    .reset_n(reset_n), 
    .rx(rx_adt), 
    .tx_frame_start(adt_tx_frame_start), 
    .data_ram(adt_data_ram), 
	.addr_ram(adt_addr_ram),
	.wr_ram(adt_wr_ram),
    .tx(tx_adt), 
    .tx_busy(adt_tx_busy), 
    .rx_frame_done(adt_rx_frame_done), 
    .rx_frame(adt_rx_frame),
	.comNoResponse(adt_comNoResponse),
	.check_sum_error(adt_check_sum_error)
    );
	
dataControl dataControl_inst (
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
	.feikong_tx_busy(feikong_tx_busy),
	.feikong_tx_frame_start(feikong_tx_frame_start),
    .feikong_rx_frame(feikong_rx_frame), 
    .feikong_rx_frame_done(feikong_rx_frame_done), 
    .feikong_check_sum_error(feikong_check_sum_error), 
    .feikong_comNoResponse(feikong_comNoResponse), 
	.feikong_last2Error(feikong_last2Error),
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
	.adt_wr_ram(adt_wr_ram),
	.adt_addr_ram(adt_addr_ram),
	.adt_data_ram(adt_data_ram),
	.adt_tx_frame_start(adt_tx_frame_start),
	.adt_check_sum_error(adt_check_sum_error),
	.adt_comNoResponse(adt_comNoResponse)
    );


endmodule
