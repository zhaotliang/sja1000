`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:41:17 02/14/2016 
// Design Name: 
// Module Name:    SJA1000 
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
//
//////////////////////////////////////////////////////////////////////////////////
module SJA1000(
	input clk,
	input reset_n,
	output		 can_rx_done,
	output[47:0] can_rx_data,
	//can_tx_start不由其他模块控制，接收完成就发。对SJA1000的读写操作得分开，不能同时
	input[39:0]	 can_tx_data,
	
	//pin
	output	convert_dir,//电平转换板的方向，数据、地址
	inout[7:0] can_add_data,
	output can_ale,
	output can_wr_n,can_rd_n,can_cs_n,
	output can_rst
    );
	
	//can_rw.v，功能模块
	//rd_start,wr_start
	//rd_done,wr_done
	
	//can_ctrl.v，总状态机，协调下面7个状态
	//每个状态模块有开始和结束接口
	
	//can_init.v，初始化状态，1
	
	//can_SR_RBS.v，查询接收标志位，2
	
	//can_rd_data.v，读接收数据，3
	
	//can_CMR_RRB.v，清接收缓存，4

	//can_SR_TBS.v，查询发送标志位，5，清接收缓存就开始查询，发送
	
	//can_wr_data.v，写发送数据，6

	//can_CMR_TR.v，启动发送，7
	

endmodule
