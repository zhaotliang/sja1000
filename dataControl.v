`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		Inspur Chaoyue
// Engineer: 
// 
// Create Date:    16:45:28 01/13/2016 
// Design Name: 
// Module Name:    dataControl 
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
//
//////////////////////////////////////////////////////////////////////////////////

//稳瞄相关
`define	WM_TX_SOF_L	8'h64
`define	WM_TX_SOF_H	8'h00

`define	WM_TX_STATUS	23
`define	WM_TX_SW1		31
`define	WM_TX_SW2		39
`define	WM_TX_SW3		47
`define	WM_TX_SW4		55
`define	WM_TX_HPARA_L8	63
`define	WM_TX_HPARA_H4	71
`define	WM_TX_VPARA_L4	67
`define	WM_TX_VPARA_H8	79
`define	WM_TX_RDER_L	87
`define	WM_TX_RDER_H	95
`define	WM_TX_LSER		103
`define	WM_TX_TV_L		111
`define	WM_TX_TV_H		119
`define	WM_TX_CHECK_SUM	159

//发控相关
`define	FAK_TX_SOF_L		8'hAA
`define	FAK_TX_SOF_H		8'h8E
`define	FAK_TX_HANG_L		23
`define	FAK_TX_HANG_H		31
`define	FAK_TX_FU_L			39
`define	FAK_TX_FU_H			47
`define	FAK_TX_GUN_L		55
`define	FAK_TX_GUN_H		63
`define	FAK_TX_DVEL_L		71
`define	FAK_TX_DVEL_H		79
`define	FAK_TX_DHANG_L		87
`define	FAK_TX_DHANG_H		95
`define	FAK_TX_HEIGHT_L		103
`define	FAK_TX_HEIGHT_H		111
`define	FAK_TX_WM_PHANG_L	119
`define	FAK_TX_WM_PHANG_H	127
`define	FAK_TX_WM_FU_L		135
`define	FAK_TX_WM_FU_H		143
`define	FAK_TX_WM_DIS_L		151
`define	FAK_TX_WM_DIS_H		159
`define	FAK_TX_WIND_L		167
`define	FAK_TX_WIND_H		175
`define	FAK_TX_MISSILE_CON_L	183
`define	FAK_TX_MISSILE_CON_H	191

`define	FAK_TX_CHECK_SUM		255



	//在发送数据组包过程中，用各模块上一次接收正确的数据
	
	//可以在80ms计数的一半时组包(模块灵活性更好)，也可以按照tx_busy指示组包（模块间耦合性变强，不利于模块移植）
	//发控、稳瞄、飞控用的tx_busy信号，有耦合
	//adt都是由本模块控制

module dataControl(
	input			clk,
	input			reset_n,
	
	//wenmiao
	output reg[159:0]	wenmiao_tx_frame,
	output			wenmiao_tx_start,
	input[455:0]	wenmiao_rx_frame,
	input			wenmiao_tx_busy,
	input			wenmiao_rx_frame_done,
	input			wenmiao_check_sum_error,///////////
	input			wenmiao_comNoResponse,/////////////
	
	//feikong
	output reg[79:0] feikong_tx_frame,
	output			feikong_tx_frame_start,
	input			feikong_tx_busy,
	input[319:0]	feikong_rx_frame,
	input			feikong_rx_frame_done,
	input			feikong_check_sum_error,///////////
	input			feikong_comNoResponse,/////////////
	input			feikong_last2Error,////////////////
	
	//fakong
	output reg[255:0]	fakong_tx_frame,
	output			fakong_tx_start,
	input[71:0]		fakong_rx_frame,
	input			fakong_tx_busy,
	input			fakong_rx_frame_done,
	input			fakong_check_sum_error,///////////
	input			fakong_comNoResponse,/////////////

	//adt
	input[199:0]	adt_rx_frame,
	input			adt_rx_frame_done,
	input			adt_tx_busy,//////////////////////
	input			adt_check_sum_error,//////////////
	input			adt_comNoResponse,////////////////
	output reg			adt_wr_ram,
	output reg[15:0]	adt_addr_ram,
	output reg[7:0]		adt_data_ram,
	output reg			adt_tx_frame_start
    );
	//Para
	parameter		T_INTERVAL =	3_999_999;//40_000_000;//80ms：3999999，1s：50_000_000
	parameter		T_FRAME_LEN_ADT	=	16'd66;
	
//////////////////////////////////////////////////////////////////////////////////定时
	reg[31:0]		timerCnt;
	wire			timerEnd;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			timerCnt	<= 	0;
		else	if(timerCnt	==	T_INTERVAL)
			timerCnt 	<= 	0;
		else
			timerCnt 	<=	timerCnt	+	1'b1;
	assign	wenmiao_tx_start	=	(timerCnt == (T_INTERVAL-1'b1));
	assign	fakong_tx_start		=	(timerCnt == (T_INTERVAL-1'b1));
	assign	timerEnd			=	(timerCnt == (T_INTERVAL-1'b1)); 
	
//////////////////////////////////////////////////////////////////////////////////稳瞄
	//接收数据赋值
	reg[455:0]		wenmiao_rx_frame_r;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			wenmiao_rx_frame_r	<=	0;
		else if(wenmiao_rx_frame_done)
			wenmiao_rx_frame_r	<=	wenmiao_rx_frame;
		//else if(wenmiao_check_sum_error || wenmiao_comNoResponse)
		//	wenmiao_rx_frame_r	<= 0;
	//接收异常处理
	
	
	
	
	//发送数据组包，从ADT过来的命令数据
	//tx_busy下降沿，开始组包，在下一次tx_start前必能组完
	//tx_busy	___-----------------_______________________________--------------
	//tx_start	___-_______________________________________________-_____________
	//			xxxxxxxxxxxxxxxxxxxx(组包)xxxxxxxxxxxxxxxxxxxx
	//不论ADT是否在接收中，都用之前一次接收成功的数据
	//怎么是之前一次成功的数据呢？每个接收完成信号才把接收的数据放在本模块
	
	reg[1:0]		wenmiao_tx_busy_r;
	wire			wenmiao_tx_busy_neg;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			wenmiao_tx_busy_r	<=	0;
		else
			wenmiao_tx_busy_r	<=	{wenmiao_tx_busy_r[0],	wenmiao_tx_busy};
	assign	wenmiao_tx_busy_neg	=	wenmiao_tx_busy_r[1]	&	~wenmiao_tx_busy_r[0];
	

	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			begin
			wenmiao_tx_frame	<=	0;
			wm_start_cal_sum	<= 	0;
			end
		else	if(wenmiao_tx_busy_neg)
			begin
			wenmiao_tx_frame[7  -: 8]				<=	`WM_TX_SOF_L;
			wenmiao_tx_frame[15 -: 8]				<=	`WM_TX_SOF_H;
			wenmiao_tx_frame[`WM_TX_STATUS -: 8]	<=	adt_rx_frame_r[`WM_TX_STATUS -: 8];	
			wenmiao_tx_frame[`WM_TX_SW1 -: 8]		<=	adt_rx_frame_r[`WM_TX_SW1 -: 8];		
			wenmiao_tx_frame[`WM_TX_SW2 -: 8]		<=	adt_rx_frame_r[`WM_TX_SW2 -: 8];		
			wenmiao_tx_frame[`WM_TX_SW3 -: 8]		<=	adt_rx_frame_r[`WM_TX_SW3 -: 8];		
			wenmiao_tx_frame[`WM_TX_SW4 -: 8]		<=	adt_rx_frame_r[`WM_TX_SW4 -: 8];		
			wenmiao_tx_frame[`WM_TX_HPARA_L8 -: 8]	<=	adt_rx_frame_r[`WM_TX_HPARA_L8 -: 8];		
			wenmiao_tx_frame[`WM_TX_HPARA_H4 -: 8]	<=	adt_rx_frame_r[`WM_TX_HPARA_H4 -: 8];			
			wenmiao_tx_frame[`WM_TX_VPARA_H8 -: 8]	<=	adt_rx_frame_r[`WM_TX_VPARA_H8 -: 8];		
			wenmiao_tx_frame[`WM_TX_RDER_L -: 8]	<=	adt_rx_frame_r[`WM_TX_RDER_L -: 8];		
			wenmiao_tx_frame[`WM_TX_RDER_H -: 8]	<=	adt_rx_frame_r[`WM_TX_RDER_H -: 8];		
			wenmiao_tx_frame[`WM_TX_LSER -: 8]		<=	adt_rx_frame_r[`WM_TX_LSER -: 8];		
			wenmiao_tx_frame[`WM_TX_TV_L -: 8]		<=	adt_rx_frame_r[`WM_TX_TV_L -: 8];		
			wenmiao_tx_frame[`WM_TX_TV_H -: 8]		<=	adt_rx_frame_r[`WM_TX_TV_H -: 8];
			wenmiao_tx_frame[127-:8]				<= 	adt_rx_frame_r[127-:8];
			wenmiao_tx_frame[135-:8]				<= 	adt_rx_frame_r[135-:8];
			wenmiao_tx_frame[143-:8]				<= 	adt_rx_frame_r[143-:8];
			wenmiao_tx_frame[151-:8]				<= 	adt_rx_frame_r[151-:8];
			wm_start_cal_sum		<= 1'b1;
			end
		else if(wm_cal_sum_state == 4'h2)
			wenmiao_tx_frame[`WM_TX_CHECK_SUM -: 8]	<= wm_sum;
		else
			wm_start_cal_sum		<= 0;
		
	reg[3:0]		wm_cal_sum_state;
	reg				wm_start_cal_sum;
	always	@ (posedge	clk or negedge reset_n)
		if(!reset_n)
			wm_cal_sum_state		<= 0;
		else
		case(wm_cal_sum_state)
		0:
			if(wm_start_cal_sum)
				wm_cal_sum_state	<= 4'h1;			
		1:	wm_cal_sum_state		<= 4'h2;
		2:	wm_cal_sum_state		<= 4'h3;
		3:	wm_cal_sum_state		<= 0;
		default:wm_cal_sum_state	<= 0;
		endcase;
	
	reg[7:0]		wm_cnt;
	reg[7:0]		wm_sum;
	always	@ (posedge	clk or negedge reset_n)
		if(!reset_n)
			wm_sum		= 0;
		else
		case(wm_cal_sum_state)
		1:
			for(wm_cnt=0; wm_cnt<19; wm_cnt=wm_cnt+1)
				wm_sum 	= wm_sum + wenmiao_tx_frame[((wm_cnt<<3)+7) -: 8];
		3:	wm_sum		= 0;
		default:;
		endcase;
	
//////////////////////////////////////////////////////////////////////////////////飞控
	//接收数据赋值
	reg[319:0]	feikong_rx_frame_r;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			feikong_rx_frame_r	<=	0;
		else if(feikong_rx_frame_done)
			begin
			feikong_rx_frame_r	<=	feikong_rx_frame;
			//fak_tx_hang	<= feikong_rx_frame[191:175]/1000/3.14*1800;
			end
	//接收异常处理
	
	
//////////////////////////////////////////////////////////////////////////////////发控
	//接收数据赋值
	reg[71:0]		fakong_rx_frame_r;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			fakong_rx_frame_r	<=	0;
		else if(fakong_rx_frame_done)
			fakong_rx_frame_r	<=	fakong_rx_frame;
	//接收异常处理
	
	
	
	//发送数据组包
	reg[1:0]		fakong_tx_busy_r;
	wire			fakong_tx_busy_neg;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			fakong_tx_busy_r	<=	0;
		else
			fakong_tx_busy_r	<=	{fakong_tx_busy_r[0],	fakong_tx_busy};
	assign	fakong_tx_busy_neg	=	fakong_tx_busy_r[1]	&	~fakong_tx_busy_r[0];
	//reg[15:0]		fak_tx_hang;
	//reg[15:0]		fak_tx_fu;
	//reg[15:0]		fak_tx_gun;
	
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			begin
			fakong_tx_frame		<=	0;
			fak_start_cal_sum	<= 	1'b0;
			end
		else	if(fakong_tx_busy_neg)
			begin
			fakong_tx_frame[7:0]	<= `FAK_TX_SOF_L;
			fakong_tx_frame[15:8]	<= `FAK_TX_SOF_H;
			fakong_tx_frame[`FAK_TX_HANG_L -:8]	<= feikong_rx_frame_r[175:168];//fak_tx_hang[7:0];//feikong_rx_frame_r[175:168];
			fakong_tx_frame[`FAK_TX_HANG_H -:8]	<= {feikong_rx_frame_r[191],feikong_rx_frame_r[182:176]};//fak_tx_hang[15:8];//{feikong_rx_frame_r[191],feikong_rx_frame_r[182:176]};
			fakong_tx_frame[`FAK_TX_FU_L -:8]	<= feikong_rx_frame_r[151:144];
			fakong_tx_frame[`FAK_TX_FU_H -:8]	<= {feikong_rx_frame_r[167],feikong_rx_frame_r[158:152]};
			fakong_tx_frame[`FAK_TX_GUN_L -:8]	<= feikong_rx_frame_r[127:120];
			fakong_tx_frame[`FAK_TX_GUN_H -:8]	<= {feikong_rx_frame_r[143],feikong_rx_frame_r[134:128]};
			fakong_tx_frame[`FAK_TX_DVEL_L -:8]	<= feikong_rx_frame_r[87:80];
			fakong_tx_frame[`FAK_TX_DVEL_H -:8]	<= feikong_rx_frame_r[95:88];
			fakong_tx_frame[`FAK_TX_DHANG_L -:8]	<= 8'h55;
			fakong_tx_frame[`FAK_TX_DHANG_H -:8]	<= 8'h55;
			fakong_tx_frame[`FAK_TX_HEIGHT_L -:8]	<= feikong_rx_frame_r[103:96];
			fakong_tx_frame[`FAK_TX_HEIGHT_H -:8]	<= {feikong_rx_frame_r[119],feikong_rx_frame_r[110:104]};
			fakong_tx_frame[`FAK_TX_WM_PHANG_L -:8]	<= wenmiao_rx_frame_r[39:32];
			fakong_tx_frame[`FAK_TX_WM_PHANG_H -:8]	<= wenmiao_rx_frame_r[47:40];
			fakong_tx_frame[`FAK_TX_WM_FU_L -:8]	<= wenmiao_rx_frame_r[55:48];
			fakong_tx_frame[`FAK_TX_WM_FU_H -:8]	<= wenmiao_rx_frame_r[63:56];
			fakong_tx_frame[`FAK_TX_WM_DIS_L -:8]	<= wenmiao_rx_frame_r[119:112];
			fakong_tx_frame[`FAK_TX_WM_DIS_H -:8]	<= wenmiao_rx_frame_r[127:120];
			fakong_tx_frame[`FAK_TX_WIND_L -:8]	<= 8'hAA;
			fakong_tx_frame[`FAK_TX_WIND_H -:8]	<= 8'hAA;
			fakong_tx_frame[`FAK_TX_MISSILE_CON_L -:8]	<= adt_rx_frame_r[167:160];
			fakong_tx_frame[`FAK_TX_MISSILE_CON_H -:8]	<= adt_rx_frame_r[175:168];
			fak_start_cal_sum	<= 1'b1;
			end
		else if(fak_cal_sum_state == 4'h2)
			fakong_tx_frame[`FAK_TX_CHECK_SUM -: 8]	<= fak_sum;
		else
			fak_start_cal_sum	<= 1'b0;
	
	reg[3:0]		fak_cal_sum_state;
	reg				fak_start_cal_sum;
	always	@ (posedge	clk or negedge reset_n)
		if(!reset_n)
			fak_cal_sum_state		<= 0;
		else
		case(fak_cal_sum_state)
		0:
			if(fak_start_cal_sum)
				fak_cal_sum_state	<= 4'h1;			
		1:	fak_cal_sum_state		<= 4'h2;
		2:	fak_cal_sum_state		<= 4'h3;
		3:	fak_cal_sum_state		<= 0;
		default:fak_cal_sum_state	<= 0;
		endcase;
	
	reg[7:0]		fak_cnt;
	reg[7:0]		fak_sum;
	always	@ (posedge	clk or negedge reset_n)
		if(!reset_n)
			fak_sum		= 0;
		else
		case(fak_cal_sum_state)
		1:
			for(fak_cnt=0; fak_cnt<31; fak_cnt=fak_cnt+1)
				fak_sum = fak_sum + fakong_tx_frame[((fak_cnt<<3)+7) -: 8];
		3:	fak_sum		= 0;
		default:;
		endcase;
	
//////////////////////////////////////////////////////////////////////////////////ADT	
	//接收数据的处理
	reg[199:0]		adt_rx_frame_r;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			adt_rx_frame_r	<=	0;
		else if(adt_rx_frame_done)
			adt_rx_frame_r	<=	adt_rx_frame;
	
	//ADT发送数据，各部分接收的数据先存入ram
	//tx_busy下降沿开始写入ram
	//且稳瞄、飞控要收完,不能是在接收中,(接收不同步，偏差也不确定)所以用tx_busy前收完的这次
	
	//写完ram再给开始信号
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			adt_tx_frame_start	<= 0;
		else if(adt_addr_ram == T_FRAME_LEN_ADT)
			adt_tx_frame_start	<= 1'b1;
		else
			adt_tx_frame_start	<= 0;
	//4分频	
	reg[3:0]		clkCnt;
	wire			clk_25M;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			clkCnt 	<= 0;
		else
			clkCnt	<= clkCnt + 1'b1;
	assign	clk_25M	= clkCnt[1];//clk_12P5M
	//adt_wr_ram_r用clk_25M时钟同步成 adt_wr_ram ，使adt_addr_ram==0时，adt_wr_ram也为1，确保写0地址正确
	reg		adt_wr_ram_r;
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			adt_wr_ram_r	<= 1'b0;
		else if(timerEnd)
			adt_wr_ram_r	<= 1'b1;
		else if(adt_addr_ram == (T_FRAME_LEN_ADT-1'b1))
			adt_wr_ram_r	<= 1'b0;
	
	always	@	(posedge	clk_25M	or	negedge	reset_n)
		if(!reset_n)
			adt_wr_ram		<= 0;
		else
			adt_wr_ram		<= adt_wr_ram_r;
	
	always	@	(posedge	clk_25M	or	negedge	reset_n)
		if(!reset_n)
			adt_addr_ram	<= 0;
		else if(adt_wr_ram)
			adt_addr_ram	<= adt_addr_ram	+ 1'b1;
		else
			adt_addr_ram	<= 0;
			
	always	@	(posedge	clk	or	negedge	reset_n)
		if(!reset_n)
			adt_data_ram	<= 0;
		else
		case(adt_addr_ram)
		0:	adt_data_ram 	<= wenmiao_rx_frame_r[7:0];
		1:	adt_data_ram	<= wenmiao_rx_frame_r[15:8];
		2:	adt_data_ram	<= wenmiao_rx_frame_r[23:16];
		3:	adt_data_ram	<= wenmiao_rx_frame_r[31:24];
		4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,
		21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,
		41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56:
			adt_data_ram	<= wenmiao_rx_frame_r[((adt_addr_ram<<3)+7) -: 8];
		57,58,59,60,61,62,63,64,65:
			adt_data_ram	<= fakong_rx_frame_r[(((adt_addr_ram-57)<<3)+7) -: 8];
		default:adt_data_ram	<= 0;
		endcase;
	
endmodule
