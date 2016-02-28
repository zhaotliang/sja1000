`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:53:26 01/13/2016 
// Design Name: 
// Module Name:    fakong 
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
module fakong(
	input 			clk,
	input 			reset_n,
	input			rx,
	
	input			tx_frame_start,		//开始发送帧
	input[255:0]	tx_frame,
	output 			tx,
	output reg			tx_busy,			//当前帧尚未发送完成
	
	output reg			rx_frame_done,		//接收到一个正确的数据帧
	output reg[71:0]	rx_frame,			//
	output reg			check_sum_error,	//脉冲信号
	output			comNoResponse		//脉冲
    );
//Para
	parameter		SEND_BYTE_NUM		=   8'd32;	//发送32个字节
	parameter		RECEIVE_BYTE_NUM	=   8'd9;	//接收9个字节
	parameter		R_SOF_L			=	8'h8E;
	parameter 		R_SOF_H			= 	8'hAA;
	parameter		T1S 			=	32'd50_000_000;
	parameter		T100NS			=	5;

	
//////////////////////////////////////////////////////////////////////////////////发送数据
always @ (posedge clk or negedge reset_n)
	if(!reset_n)
		tx_busy	<= 1'b0; 
	else if(tx_frame_start)//???????????需要脉冲信号，或者这里检测上升沿
		tx_busy	<= 1'b1;
	else if(tx_byte_cnt == SEND_BYTE_NUM) 
		tx_busy	<= 1'b0; 
//发送计数
reg[7:0]	tx_byte_cnt;
always @ (posedge clk or negedge reset_n)
	if(!reset_n)
		tx_byte_cnt	<= 0;
	else if(tx_byte_done)
		tx_byte_cnt <= tx_byte_cnt + 1'b1;
	else if(tx_byte_cnt == SEND_BYTE_NUM)
		tx_byte_cnt <= 0;
//发送字节赋值
always @ (posedge clk or negedge reset_n)
	if(!reset_n)
		tx_byte_data	<= 0;
	else 
		case(tx_byte_cnt)
			8'd0	:	tx_byte_data	<= tx_frame[7:0];
			8'd1	:	tx_byte_data	<= tx_frame[15:8];
			8'd2	:	tx_byte_data	<= tx_frame[23:16];
			8'd3	:	tx_byte_data	<= tx_frame[31:24];
			8'd4	:	tx_byte_data	<= tx_frame[39:32];
			8'd5	:	tx_byte_data	<= tx_frame[47:40];
			8'd6	:	tx_byte_data	<= tx_frame[55:48];
			8'd7	:	tx_byte_data	<= tx_frame[63:56];
			8'd8	:	tx_byte_data	<= tx_frame[71:64];
			8'd9	:	tx_byte_data	<= tx_frame[79:72];
			8'd10	:	tx_byte_data	<= tx_frame[87:80];
			8'd11	:	tx_byte_data	<= tx_frame[95:88];
			8'd12	:	tx_byte_data	<= tx_frame[103:96];
			8'd13	:	tx_byte_data	<= tx_frame[111:104];
			8'd14	:	tx_byte_data	<= tx_frame[119:112];
			8'd15	:	tx_byte_data	<= tx_frame[127:120];
			8'd16	:	tx_byte_data	<= tx_frame[135:128];
			8'd17	:	tx_byte_data	<= tx_frame[143:136];
			8'd18	:	tx_byte_data	<= tx_frame[151:144];
			8'd19	:	tx_byte_data	<= tx_frame[159:152];
			8'd20	:	tx_byte_data	<= tx_frame[167:160];
			8'd21	:	tx_byte_data	<= tx_frame[175:168];
			8'd22	:	tx_byte_data	<= tx_frame[183:176];
			8'd23	:	tx_byte_data	<= tx_frame[191:184];
			8'd24	:	tx_byte_data	<= tx_frame[199:192];
			8'd25	:	tx_byte_data	<= tx_frame[207:200];
			8'd26	:	tx_byte_data	<= tx_frame[215:208];
			8'd27	:	tx_byte_data	<= tx_frame[223:216];
			8'd28	:	tx_byte_data	<= tx_frame[231:224];
			8'd29	:	tx_byte_data	<= tx_frame[239:232];
			8'd30	:	tx_byte_data	<= tx_frame[247:240];
			8'd31	:	tx_byte_data	<= tx_frame[255:248];
			
			default:;
		endcase;

//字节间隔
reg[7:0]		intervalCnt;
always @ (posedge clk or negedge reset_n)
	if(!reset_n)
		intervalCnt	<= 0;
	else if(tx_byte_done)
		intervalCnt	<= 0;
	else if(!tx_byte_start)
		intervalCnt	<= intervalCnt + 1'b1;
	else
		intervalCnt	<= 0;

always @ (posedge clk or negedge reset_n)
	if(!reset_n)
		tx_byte_start 	<= 1'b0;
	else if(tx_byte_done)
		tx_byte_start 	<= 1'b0;
	else if((intervalCnt > T100NS) && tx_busy)
		tx_byte_start	<= 1'b1;
	
//////////////////////////////////////////////////////////////////////////////////接收数据
	//帧头0x9F，0xE4，帧尾是前面56个字节的校验和
	
	//一直校验帧头，不正确的包就不会进入接收，正确则正常接收
	reg[7:0]		rx_data1,rx_data0;
	wire			sof_ok;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			rx_data0 	<= 0;
			rx_data1 	<= 0;
			end
		else if(rx_valid)
			begin
			rx_data0 	<= rx_byte_data;
			rx_data1 	<= rx_data0;
			end
		else
			rx_data1 	<= 0;//使sof_ok只有一个周期
	assign 	sof_ok 		= (rx_data0==R_SOF_H) && (rx_data1==R_SOF_L);
	
	//接收完第9个字节，此字节为校验和，和本模块计算的rx_check_sum比较
	//reg		rx_frame_done;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			rx_frame_done <= 1'b0;		
		else if((rx_byte_cnt==RECEIVE_BYTE_NUM) && (rx_check_sum==rx_byte_data))
			rx_frame_done <= 1'b1;
		else
			rx_frame_done <= 1'b0;
			
	//接收状态机	
	reg[3:0]		rx_state;				
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			rx_state 	<= 4'b0000;
		else if(sof_ok && (rx_byte_cnt<3))//(rx_byte_cnt<3)防止万一接收过程中有两个字节和帧头两个字节一样
			rx_state 	<= 4'b0001;
		else if(rx_byte_cnt == (RECEIVE_BYTE_NUM-1'b1))
			rx_state 	<= 4'b0010;
		else if(rx_frame_done)
			rx_state 	<= 0;
		else if(check_sum_error || comNoResponse)
			rx_state 	<= 0;
	
	
	reg[7:0] 		rx_byte_cnt;
	reg[7:0]		rx_check_sum;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			rx_byte_cnt		<= 0;
			rx_check_sum	<= 0;
			rx_frame		<= 0;
			end
		else
			case(rx_state)
			4'b0000:
				begin
				rx_byte_cnt 	<= 8'd2;
				rx_check_sum 	<= R_SOF_H + R_SOF_L;
				rx_frame[7:0]	<= R_SOF_L;
				rx_frame[15:8]	<= R_SOF_H;
				end
			4'b0001:
				if(rx_valid)
					begin
					rx_byte_cnt 	<= rx_byte_cnt + 1'b1;
					rx_check_sum 	<= rx_check_sum + rx_byte_data;
					case(rx_byte_cnt)
					8'd2	:	rx_frame[23:16] <= rx_byte_data;
					8'd3	:	rx_frame[31:24] <= rx_byte_data;
					8'd4	:	rx_frame[39:32] <= rx_byte_data;
					8'd5	:	rx_frame[47:40] <= rx_byte_data;
					8'd6	:	rx_frame[55:48] <= rx_byte_data;
					8'd7	:	rx_frame[63:56] <= rx_byte_data;
			
					endcase;

					end
			4'b0010:
				if(rx_valid)
					begin
					rx_byte_cnt 		<= rx_byte_cnt + 1'b1;
					rx_frame[71:64] 	<= rx_byte_data;
					end
			default:;
			endcase;
	
	
	//接收异常处理
	//原则		:1、自行恢复到正常接收等待状态；2、指示给谁？
	//
	//异常情况	：
	//
	//			1、	数据帧头校验通过，没接收到足够的字节
	//			计时，1s以内有接收完成则重新计数，不影响接收状态；如果1s没有接收完成则通信中断，告知地面通信状态（如何放到adt通信包？）且恢复到正常接收状态
	//			2、	接收到足够的字节数，数据和校验错误
	//			通信错误，告知地面且恢复到正常接收状态

	//wire			comNoResponse;
	reg[31:0]		T1sCnt;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			T1sCnt	<= 0;
		else if(rx_frame_done || comNoResponse || rx_valid)
			T1sCnt 	<= 0;
		else
			T1sCnt	<= T1sCnt + 1'b1;
	assign	comNoResponse	= (T1sCnt > T1S);
	
	//reg				check_sum_error;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			check_sum_error 	<= 1'b0;
		else if((rx_byte_cnt==RECEIVE_BYTE_NUM) && (rx_check_sum!=rx_byte_data))
			check_sum_error 	<= 1'b1;
		else
			check_sum_error 	<= 1'b0;

//////////////////////////////////////////////////////////////////////////////////单字节收发	
	wire			rx_bps_start;
	wire			rx_clk_bps;
	wire[7:0]		rx_byte_data;
	wire 			rx_valid;
speed_select		fakong_rx_speed	(.clk			(clk),
										 .rst_n			(reset_n),
										 .bps_start		(rx_bps_start),
										 .clk_bps		(rx_clk_bps));	
my_uart_rx			fakong_rx			(.clk   		(clk),
										 .rst_n			(reset_n),
										 .rs232_rx		(rx),
										 .rx_data		(rx_byte_data),
										 .rx_int		(),
										 .clk_bps		(rx_clk_bps),
										 .bps_start		(rx_bps_start),
										 .rx_data_valid	(rx_valid));
	wire			tx_bps_start;
	wire			tx_clk_bps;
	reg[7:0]		tx_byte_data;
	wire			tx_byte_done;	//脉冲信号
	reg				tx_byte_start;
speed_select		fakong_tx_speed	(.clk			(clk),
										 .rst_n			(reset_n),
										 .bps_start		(tx_bps_start),
										 .clk_bps		(tx_clk_bps));
my_uart_tx			fakong_tx			(.clk			(clk),
										 .rst_n   		(reset_n),
										 .tx_data		(tx_byte_data),
										 .tx_int		(tx_byte_start),
										 .rs232_tx		(tx),
										 .clk_bps		(tx_clk_bps),
										 .bps_start		(tx_bps_start),
										 .tx_done		(tx_byte_done));	

endmodule
