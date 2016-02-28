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
	output reg		 can_rx_done,
	output reg[47:0] can_rx_data,
	//can_tx_start不由其他模块控制，接收完成就发。对SJA1000的读写操作得分开，不能同时
	input[39:0]		can_tx_data,
	output reg		can_tx_done,
	output			can_error,//是否要表明是哪个阶段的什么错误，便于调试
	
	//pin
	output		convert_dir,//电平转换板的方向，数据、地址
	//inout[7:0] can_add_data,
	input[7:0] 	can_in,
	output[7:0] can_out,
	output		en_out,
	output		rd_valid,
	
	output can_ale,
	output can_wr_n,can_rd_n,can_cs_n,
	output can_rst
    );
	
	
	//can_ctrl.v，总状态机，协调下面7个状态
	//每个状态模块有开始和结束接口
	`define		INIT	4'b0000
	`define		SR_RBS	4'b0001
	`define		RD_DATA	4'b0010
	`define		CMR_RRB	4'b0011
	`define		SR_TBS	4'b0100
	`define		WR_DATA	4'b0101
	`define		CMR_TR	4'b0110
	
	wire		ctrl_rd_start;
	wire		ctrl_wr_start;
	wire[7:0]	ctrl_address;
	wire[7:0]	ctrl_tx_data;
	
	wire[7:0]	ctrl_rx_data;
	wire		ctrl_rd_done;
	wire		ctrl_wr_done;
	
	reg[3:0]	can_state;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			;
		else
			case(can_state)
			`INIT:
				begin
				init_start	<= 1'b1;
				if(init_done)
					begin
					can_state	<= `SR_RBS;
					init_start	<= 1'b0;
					end
				end
			`SR_RBS:			//可以加个延时计数，没必要时刻扫描；
				begin
				SR_RBS_start	<= 1'b1;
				if(SR_RBS_done)
					begin
					SR_RBS_start<= 1'b0;
					can_state	<= `RD_DATA;
					end					
				end
			`RD_DATA:
				begin
				RD_DATA_start	<= 1'b1;
				if(RD_DATA_done)
					begin
					RD_DATA_start	<= 1'b0;
					can_state		<= `CMR_RRB;
					can_rx_data		<= can_rx_data_r;
					can_rx_done		<= 1'b1;
					end
				end
			`CMR_RRB:
				begin
				can_rx_done		<= 1'b0;
				CMR_RRB_start	<= 1'b1;
				if(CMR_RRB_done)
					begin
					CMR_RRB_start	<= 1'b0;
					can_state		<= `SR_TBS;
					end
				end
			`SR_TBS:
				begin
				SR_TBS_start	<= 1'b1;
				if(SR_TBS_done)
					begin
					SR_TBS_start	<= 1'b0;
					can_state		<= `WR_DATA;
					end
				end
			`WR_DATA:
				begin
				WR_DATA_start	<= 1'b1;
				if(WR_DATA_done)
					begin
					WR_DATA_start	<= 1'b0;
					can_state		<= `CMR_TR;
					can_tx_done		<= 1'b1;
					end
				end
			`CMR_TR:
				begin
				can_tx_done		<= 1'b0;
				CMR_TR_start	<= 1'b1;
				if(CMR_TR_done)
					begin
					CMR_TR_start	<= 1'b0;
					can_state		<= `SR_RBS;
					end
				end
			default:;
			endcase
	
	assign	ctrl_address	= (can_state==`INIT)?init_address:((can_state==`SR_RBS)?SR_RBS_address:
							((can_state==`RD_DATA)?rd_data_address:((can_state==`CMR_RRB)?CMR_RRB_address:
							((can_state==`SR_TBS)?SR_TBS_address:((can_state==`WR_DATA)?wr_data_address:
							((can_state==`CMR_TR)?CMR_TR_address:0))))));
	assign	ctrl_rd_start	= (can_state==`INIT)?init_rd_start:((can_state==`SR_RBS)?SR_RBS_rd_start:
							((can_state==`RD_DATA)?rd_data_rd_start:((can_state==`CMR_RRB)?0:
							((can_state==`SR_TBS)?SR_TBS_start:((can_state==`WR_DATA)?0:
							((can_state==`CMR_TR)?0:0))))));
	assign	ctrl_wr_start	= (can_state==`INIT)?init_wr_start:((can_state==`SR_RBS)?0/*SR_RBS_wr_start*/:
							((can_state==`RD_DATA)?0:((can_state==`CMR_RRB)?CMR_RRB_wr_start:
							((can_state==`SR_TBS)?0:((can_state==`WR_DATA)?wr_data_wr_start:
							((can_state==`CMR_TR)?CMR_TR_wr_start:0))))));
	assign	ctrl_tx_data	= (can_state==`INIT)?init_tx_data:((can_state==`SR_RBS)?0/*SR_RBS_tx_data*/:
							((can_state==`RD_DATA)?0:((can_state==`CMR_RRB)?CMR_RRB_tx_data:
							((can_state==`SR_TBS)?0:((can_state==`WR_DATA)?wr_data_tx_data:
							((can_state==`CMR_TR)?CMR_TR_tx_data:0))))));
	
	//can_rw.v，功能模块
	//rd_start,wr_start
	//rd_done,wr_done
can_rw can_rw_inst (
    .clk(clk), 
    .reset_n(reset_n), 
    .rd_start(ctrl_rd_start), 
    .wr_start(ctrl_wr_start), 
    .address(ctrl_address), 
    .tx_data(ctrl_tx_data), 
    .can_in(can_in), 
    .rx_data(ctrl_rx_data), 
    .en_out(en_out), 
    .can_out(can_out), 
    .rd_valid(rd_valid), 
    .convert_dir(convert_dir), 
    .can_ale(can_ale), 
    .can_wr_n(can_wr_n), 
    .can_rd_n(can_rd_n), 
    .can_cs_n(can_cs_n), 
    .rd_done(ctrl_rd_done), 
    .wr_done(ctrl_wr_done)
    );
	
	//can_init.v，初始化状态，1
	//子状态，复位、时钟、波特率、
	reg[3:0]	init_state;
	
	reg			init_start;
	reg 		init_done;
	
	reg[7:0]	init_address;
	reg[7:0]	init_tx_data;
	reg			init_rd_start;
	reg			init_wr_start;
	
	reg[7:0]	CR_temp;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			init_state		<= 0;
			init_done		<= 1'b0;
			init_address	<= 0;
			init_tx_data	<= 0;
			init_rd_start	<= 0;
			init_wr_start	<= 0;
			end
		else if(init_start)
			case(init_state)
			4'b0000:
				begin
				init_address	<= 8'h00;
				init_tx_data	<= 8'h09;
				init_wr_start	<= 1'b1;
				if(ctrl_wr_done)
					begin
					init_state	<= 4'b0001;
					init_wr_start	<= 1'b0;
					end
				end
			4'b0001:
				begin
				init_address	<= 8'h00;
				init_rd_start	<= 1'b1;
				if(ctrl_rd_done && (ctrl_rx_data[0] == 1'b1))
					begin
					init_state	<= 4'b0010;
					init_rd_start	<= 1'b0;
					end
				else if(ctrl_rd_done && (ctrl_rx_data[0] == 1'b0))
					begin
					init_state	<= 4'b0000;
					init_rd_start	<= 1'b0;
					end
				end
			4'b0010:
				begin
				init_address	<= 8'h1F;
				init_tx_data	<= 8'hC8;
				init_wr_start	<= 1'b1;
				if(ctrl_wr_done)
					begin
					init_state	<= 4'b0011;
					init_wr_start	<= 1'b0;
					end
				end
			4'b0011://是否检查刚才写的是否正确？检查
				begin
				init_address	<= 8'h1F;
				init_rd_start	<= 1'b1;
				if(ctrl_rd_done && (ctrl_rx_data == 8'hC8))
					begin
					init_state	<= 4'b0100;
					init_rd_start	<= 1'b0;
					init_address	<= 8'h14;
					end
				else if(ctrl_rd_done && (ctrl_rx_data != 8'hC8))
					begin
					init_state	<= 4'b0010;
					init_rd_start	<= 1'b0;
					end
				end
			4'b0100://AMR
				begin
				init_tx_data	<= 8'hFF;
				init_wr_start	<= 1'b1;
				if(ctrl_wr_done)
					begin
					init_address	<= init_address + 1'b1;
					init_wr_start	<= 1'b0;
					if(init_address	== 8'h17)
						init_state	<= 4'b0101;
					end				
				end
			4'b0101://Baudrate
				begin
				init_address	<= 8'h06;
				init_tx_data	<= 8'h01;
				init_wr_start	<= 1'b1;
				if(ctrl_wr_done)
					begin
					init_wr_start	<= 1'b0;
					init_state		<= 4'b0110;
					end
				end
			4'b0110:
				begin
				init_address	<= 8'h07;
				init_tx_data	<= 8'h1C;
				init_wr_start	<= 1'b1;
				if(ctrl_wr_done)
					begin
					init_wr_start	<= 1'b0;
					init_state		<= 4'b0111;
					end
				end
			4'b0111:
				begin
				init_address	<= 8'h08;
				init_tx_data	<= 8'h1A;
				init_wr_start	<= 1'b1;
				if(ctrl_wr_done)
					begin
					init_wr_start	<= 1'b0;
					init_state		<= 4'b1000;
					end
				end
			4'b1000:
				begin
				init_address	<= 8'h00;
				init_rd_start	<= 1'b1;
				if(ctrl_rd_done)
					begin
					init_rd_start	<= 1'b0;
					CR_temp			<= ctrl_rx_data;
					init_state		<= 4'b1001;
					end
				end
			4'b1001:
				begin
				init_address	<= 8'h00;
				init_tx_data	<= CR_temp & 8'hFE;
				init_wr_start	<= 1'b1;
				if(ctrl_wr_done)
					begin
					init_wr_start	<= 1'b0;
					init_state		<= 4'b1010;
					init_done		<= 1'b1;
					end
				end
			4'b1010:
				begin
				init_done	<= 1'b0;
				init_state		<= 4'b1011;
				end
			default:;
			endcase
				
	//can_SR_RBS.v，查询接收标志位，2
	reg			SR_RBS_done;
	reg			SR_RBS_start;
	reg[3:0]	SR_RBS_state;
	
	reg[7:0]	SR_RBS_address;
		//reg[7:0]	SR_RBS_tx_data;
	reg			SR_RBS_rd_start;
		//reg			SR_RBS_wr_start;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			SR_RBS_state 	<= 0;
			SR_RBS_address	<= 8'h0;
			SR_RBS_rd_start	<= 1'b0;
			SR_RBS_done		<= 1'b0;
			end
		else if(SR_RBS_start)
			case(SR_RBS_state)
			4'b0000:
				begin
				SR_RBS_address	<= 8'h02;
				SR_RBS_rd_start	<= 1'b1;
				if(ctrl_rd_done && ctrl_rx_data[0])
					begin
					SR_RBS_done	<= 1'b1;
					SR_RBS_rd_start	<= 1'b0;
					SR_RBS_state	<= 4'b0001;
					end
				end
			4'b0001:
				begin
				SR_RBS_done		<= 1'b0;
				SR_RBS_state	<= 4'b0000;
				end
			default:;
			endcase
			
	//can_rd_data.v，读接收数据，3
	reg			RD_DATA_done;
	reg			RD_DATA_start;
	reg[3:0]	RD_DATA_state;
	
	reg[7:0]	rd_data_address;
		//reg[7:0]	rd_data_tx_data;
	reg			rd_data_rd_start;
		//reg			rd_data_wr_start;
	reg[47:0]	can_rx_data_r;
	
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			RD_DATA_state	<= 0;
			rd_data_address	<= 0;
			rd_data_rd_start<= 0;
			end
		else if(RD_DATA_start)
			case(RD_DATA_state)
			4'b0000:
				begin
				rd_data_address		<= 8'h11;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done && ctrl_rx_data==8'h06)	//0x6020400
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b0001;
					end
				//如果不等于呢？
				end
			4'b0001:
				begin
				rd_data_address		<= 8'h12;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done && ctrl_rx_data==8'h02)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b0010;
					end
				end
			4'b0010:
				begin
				rd_data_address		<= 8'h13;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done && ctrl_rx_data==8'h04)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b0011;
					end
				end
			4'b0011:
				begin
				rd_data_address		<= 8'h14;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done && ctrl_rx_data==8'h00)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b0100;
					end
				end
			4'b0100:
				begin
				rd_data_address		<= 8'h15;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b0101;
					can_rx_data_r[7:0]	<= ctrl_rx_data; 
					end
				end
			4'b0101:
				begin
				rd_data_address		<= 8'h16;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b0110;
					can_rx_data_r[15:8]	<= ctrl_rx_data; 
					end
				end
			4'b0110:
				begin
				rd_data_address		<= 8'h17;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b0111;
					can_rx_data_r[23:16]	<= ctrl_rx_data; 
					end
				end
			4'b0111:
				begin
				rd_data_address		<= 8'h18;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b1000;
					can_rx_data_r[31:24]	<= ctrl_rx_data; 
					end
				end
			4'b1000:
				begin
				rd_data_address		<= 8'h19;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b1001;
					can_rx_data_r[39:32]	<= ctrl_rx_data; 
					end
				end
			4'b1001:
				begin
				rd_data_address		<= 8'h1A;
				rd_data_rd_start	<= 1'b1;
				if(ctrl_rd_done)
					begin
					rd_data_rd_start	<= 1'b0;
					RD_DATA_state		<= 4'b1010;
					can_rx_data_r[47:40]	<= ctrl_rx_data;
					RD_DATA_done		<= 1'b1;
					end
				end
			4'b1010:
				begin
				RD_DATA_done		<= 1'b0;
				RD_DATA_state		<= 4'b0;
				end
			default:;
		endcase
			
			
	//can_CMR_RRB.v，清接收缓存，4
	reg 		CMR_RRB_start;
	reg			CMR_RRB_done;
	reg[3:0]	CMR_RRB_state;
	
	reg[7:0]	CMR_RRB_address;
	reg			CMR_RRB_wr_start;
	reg[7:0]	CMR_RRB_tx_data;
	
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			CMR_RRB_address		<= 8'h0;
			CMR_RRB_wr_start	<= 1'b0;
			CMR_RRB_tx_data		<= 8'h0;
			CMR_RRB_done		<= 1'b0;
			CMR_RRB_state		<= 4'h0;
			end
		else if(CMR_RRB_start)
			case(CMR_RRB_state)
			4'b0000:
				begin
				CMR_RRB_address		<= 8'h01;
				CMR_RRB_wr_start	<= 1'b1;
				CMR_RRB_tx_data		<= 8'h04;
				if(ctrl_wr_done)
					begin
					CMR_RRB_wr_start	<= 1'b0;
					CMR_RRB_done		<= 1'b1;
					CMR_RRB_state		<= 4'b0001;
					end
				end
			4'b0001:
				begin
				CMR_RRB_done		<= 1'b0;
				CMR_RRB_state		<= 4'b0000;
				end
			default:;
			endcase
		
	//can_SR_TBS.v，查询发送标志位，5，清接收缓存就开始查询，发送
	reg			SR_TBS_start;
	reg			SR_TBS_done;
	reg[3:0]	SR_TBS_state;
	
	reg[7:0]	SR_TBS_address;
	reg			SR_TBS_rd_start;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			SR_TBS_address	<= 8'h0;
			SR_TBS_rd_start	<= 1'b0;
			SR_TBS_done		<= 1'b0;
			SR_TBS_state 	<= 0;
			end
		else if(SR_TBS_start)
			case(SR_TBS_state)
			4'b0000:
				begin
				SR_TBS_address	<= 8'h02;
				SR_TBS_rd_start	<= 1'b1;
				if(ctrl_rd_done && ctrl_rx_data[2])
					begin
					SR_TBS_done		<= 1'b1;
					SR_TBS_rd_start	<= 1'b0;
					SR_TBS_state	<= 4'b0001;
					end
				end
			4'b0001:
				begin
				SR_TBS_state	<= 4'b0000;
				SR_TBS_done		<= 1'b0;
				end
			default:;
			endcase
			
	//can_wr_data.v，写发送数据，6
	reg			WR_DATA_start;
	reg			WR_DATA_done;
	reg[3:0]	WR_DATA_state;
	
	reg[7:0]	wr_data_address;
	reg			wr_data_wr_start;
	reg[7:0]	wr_data_tx_data;
	
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			;
		else if(WR_DATA_start)
			case(WR_DATA_state)
			4'b0000:
				begin
				wr_data_address	<= 8'h10;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= 8'h85;
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b0001;
					end
				end
			4'b0001:
				begin
				wr_data_address	<= 8'h11;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= 8'h06;
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b0010;
					end
				end
			4'b0010:
				begin
				wr_data_address	<= 8'h12;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= 8'h04;
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b0011;
					end
				end
			4'b0011:
				begin
				wr_data_address	<= 8'h13;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= 8'h10;
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b0100;
					end
				end
			4'b0100:
				begin
				wr_data_address	<= 8'h14;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= 0;
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b0101;
					end
				end
			4'b0101:
				begin
				wr_data_address	<= 8'h15;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= can_tx_data[7:0];
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b0110;
					end
				end
			4'b0110:
				begin
				wr_data_address	<= 8'h16;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= can_tx_data[15:8];
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b0111;
					end
				end
			4'b0111:
				begin
				wr_data_address	<= 8'h17;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= can_tx_data[23:16];
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b1000;
					end
				end
			4'b1000:
				begin
				wr_data_address	<= 8'h18;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= can_tx_data[31:24];
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b1001;
					end
				end
			4'b1001:
				begin
				wr_data_address	<= 8'h19;
				wr_data_wr_start<= 1'b1;
				wr_data_tx_data	<= can_tx_data[39:32];
				if(ctrl_wr_done)
					begin
					wr_data_wr_start<= 1'b0;
					WR_DATA_state	<= 4'b1010;
					WR_DATA_done	<= 1'b1;
					end
				end
			4'b1010:
				begin
				WR_DATA_done		<= 1'b0;
				WR_DATA_state	<= 4'b0000;
				end			
			default:;
			endcase
	
	//can_CMR_TR.v，启动发送，7
	reg 		CMR_TR_start;
	reg			CMR_TR_done;
	reg[3:0]	CMR_TR_state;
	
	reg[7:0]	CMR_TR_address;
	reg			CMR_TR_wr_start;
	reg[7:0]	CMR_TR_tx_data;
	
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			CMR_TR_address		<= 8'h0;
			CMR_TR_wr_start	<= 1'b0;
			CMR_TR_tx_data		<= 8'h0;
			CMR_TR_done		<= 1'b0;
			CMR_TR_state		<= 4'h0;
			end
		else if(CMR_TR_start)
			case(CMR_TR_state)
			4'b0000:
				begin
				CMR_TR_address		<= 8'h01;
				CMR_TR_wr_start	<= 1'b1;
				CMR_TR_tx_data		<= 8'h04;
				if(ctrl_wr_done)
					begin
					CMR_TR_wr_start	<= 1'b0;
					CMR_TR_done		<= 1'b1;
					CMR_TR_state		<= 4'b0001;
					end
				end
			4'b0001:
				begin
				CMR_TR_done		<= 1'b0;
				CMR_TR_state		<= 4'b0000;
				end
			default:;
			endcase
		

endmodule
