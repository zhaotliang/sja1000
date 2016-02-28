`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 		Inspur Chaoyue
// Engineer: 
// 
// Create Date:    16:53:59 01/13/2016 
// Design Name: 
// Module Name:    adt_term 
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
module adt_term(
	input			clk,
	input			reset_n,
	input			rx,
	input			tx_frame_start,		
	input[7:0]		data_ram,		
	input[15:0]		addr_ram,
	input			wr_ram,
	
	output 			tx,
	output reg		tx_busy,			//��ǰ֡��δ�������
	
	output reg			rx_frame_done,		//���յ�һ����ȷ������֡
	output reg[199:0]	rx_frame,			//
	output  			comNoResponse,
	output reg			check_sum_error
    );
	//Ports
	
	//Para
	parameter		R_SOF_L			=	8'h64;
	parameter 		R_SOF_H			= 	8'h00;
	parameter		T1S 			=	32'd50_000_000;
	parameter		T100NS			=	5;
	parameter		T_FRAME_LEN		=	16'd66;
	parameter		R_FRAME_LEN		= 	8'd25;
	
//////////////////////////////////////////////////////////////////////////////////��������
	//��д��ram���ٸ����Ϳ�ʼ�źţ�����dataControl����
	//Ȼ���͵�ʱ���ram����dataControlû��дram���������ʱ�䣨5ms�������һ�ο�ʼдram��70ms����ʱ����㣩
	//��ģ����dataControl��������ԣ���dataControl��ɶʱ��ʼд��ram������ģ���ź�
	
	
	//��ram�ж������ݷ���
	//��ʾ�ڷ���״̬
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			tx_busy	<= 1'b0; 
		else if(tx_frame_start)
			tx_busy	<= 1'b1;
		else if(tx_byte_cnt == T_FRAME_LEN)
			tx_busy	<= 1'b0; 
	//���ͼ���
	reg[15:0]		tx_byte_cnt;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			tx_byte_cnt	<= 0;
		else if(tx_byte_done)
			tx_byte_cnt <= tx_byte_cnt + 1'b1;
		else if(tx_byte_cnt == T_FRAME_LEN)
			tx_byte_cnt <= 0;
	//�ֽڼ��
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
	//���ֽڷ��Ϳ�ʼ
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			tx_byte_start 	<= 1'b0;
		else if(tx_byte_done)
			tx_byte_start 	<= 1'b0;
		else if((intervalCnt > T100NS) && tx_busy)
			tx_byte_start	<= 1'b1;

	wire[7:0]		tx_byte_data;
adt_tx_ram adt_tx_ram_inst (
		.clka(clk), // input clka
		.ena(wr_ram), // input ena
		.wea(wr_ram), // input [0 : 0] wea
		.addra(addr_ram[9:0]), // input [9 : 0] addra
		.dina(data_ram), // input [7 : 0] dina
		
		.clkb(clk), // input clkb
		.rstb((tx_byte_cnt==T_FRAME_LEN)), // input rstb
		.enb(tx_busy), // input enb
		.addrb(tx_byte_cnt[9:0]), // input [9 : 0] addrb
		.doutb(tx_byte_data) // output [7 : 0] doutb
		);
			
			
//////////////////////////////////////////////////////////////////////////////////��������
	//֡ͷ�ݶ�0x55��0xAA��֡β��У���
	//֡�����ݶ�200Bits
	
	//һֱУ��֡ͷ������ȷ�İ��Ͳ��������գ���ȷ����������
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
			rx_data1 	<= 0;//ʹsof_okֻ��һ������
	assign 	sof_ok 		= (rx_data0==R_SOF_H) && (rx_data1==R_SOF_L);
	
	//�������24���ֽڣ���25���ֽ�ΪУ��ͣ��ͱ�ģ������rx_check_sum�Ƚ�
	//reg				rx_frame_done;
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			rx_frame_done <= 1'b0;		
		else if((rx_byte_cnt==R_FRAME_LEN) && (rx_check_sum==rx_byte_data))
			rx_frame_done <= 1'b1;
		else
			rx_frame_done <= 1'b0;
			
	//����״̬��	
	reg[3:0]		rx_state;				
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			rx_state 	<= 4'b0000;
		else if(sof_ok && (rx_byte_cnt<3))//(rx_byte_cnt<3)��ֹ��һ���չ������������ֽں�֡ͷ�����ֽ�һ��
			rx_state 	<= 4'b0001;
		else if(rx_byte_cnt == (R_FRAME_LEN-1'b1))
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
			rx_frame 		<= 0;
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
					8'd8	:	rx_frame[71:64] <= rx_byte_data;
					8'd9	:	rx_frame[79:72] <= rx_byte_data;
					8'd10	:	rx_frame[87:80] <= rx_byte_data;
					8'd11	:	rx_frame[95:88] <= rx_byte_data;
					8'd12	:	rx_frame[103:96] <= rx_byte_data;
					8'd13	:	rx_frame[111:104] <= rx_byte_data;
					8'd14	:	rx_frame[119:112] <= rx_byte_data;
					8'd15	:	rx_frame[127:120] <= rx_byte_data;
					8'd16	:	rx_frame[135:128] <= rx_byte_data;
					8'd17	:	rx_frame[143:136] <= rx_byte_data;
					8'd18	:	rx_frame[151:144] <= rx_byte_data;
					8'd19	:	rx_frame[159:152] <= rx_byte_data;
					8'd20	:	rx_frame[167:160] <= rx_byte_data;
					8'd21	:	rx_frame[175:168] <= rx_byte_data;
					8'd22	:	rx_frame[183:176] <= rx_byte_data;
					8'd23	:	rx_frame[191:184] <= rx_byte_data;
					
					endcase;
					//rx_frame[({(rx_byte_cnt+1),3'b000}-1) :- 8] <= rx_byte_data;
					//if(rx_byte_cnt == )//�����ض��ֽ�
					end
			4'b0010:
				if(rx_valid)
					begin
					rx_byte_cnt 		<= rx_byte_cnt + 1'b1;
					rx_frame[199:192] 	<= rx_byte_data;
					end
			default:;
			endcase;
	
	
	//�����쳣����
	//ԭ��		:1�����лָ����������յȴ�״̬��2��ָʾ��˭����ָʾ������ģ��
	//
	//�쳣���	��
	//
	//			1��	����֡ͷУ��ͨ����û���յ��㹻���ֽ�
	//			��ʱ��1s�����н�����������¼�������Ӱ�����״̬�����1sû�н��������ͨ���жϣ��ָ�����������״̬
	//			2��	���յ��㹻���ֽ��������ݺ�У�����
	//			ͨ�Ŵ��󣬻ָ�����������״̬

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
		else if((rx_byte_cnt==R_FRAME_LEN) && (rx_check_sum!=rx_byte_data))
			check_sum_error 	<= 1'b1;
		else
			check_sum_error 	<= 1'b0;

//////////////////////////////////////////////////////////////////////////////////���ֽ��շ�
	wire			rx_bps_start;
	wire			rx_clk_bps;
	wire[7:0]		rx_byte_data;
	wire 			rx_valid;
speed_select		adt_rx_speed	(	 .clk			(clk),
										 .rst_n			(reset_n),
										 .bps_start		(rx_bps_start),
										 .clk_bps		(rx_clk_bps));	
my_uart_rx			adt_rx			(	 .clk   		(clk),
										 .rst_n			(reset_n),
										 .rs232_rx		(rx),
										 .rx_data		(rx_byte_data),
										 .rx_int		(),
										 .clk_bps		(rx_clk_bps),
										 .bps_start		(rx_bps_start),
										 .rx_data_valid	(rx_valid));
	wire			tx_bps_start;
	wire			tx_clk_bps;
	//reg[7:0]		tx_byte_data;
	wire			tx_byte_done;	//�����ź�
	reg				tx_byte_start;
speed_select		adt_tx_speed	(	 .clk			(clk),
										 .rst_n			(reset_n),
										 .bps_start		(tx_bps_start),
										 .clk_bps		(tx_clk_bps));
my_uart_tx			adt_tx			(	 .clk			(clk),
										 .rst_n   		(reset_n),
										 .tx_data		(tx_byte_data),
										 .tx_int		(tx_byte_start),
										 .rs232_tx		(tx),
										 .clk_bps		(tx_clk_bps),
										 .bps_start		(tx_bps_start),
										 .tx_done		(tx_byte_done));	

	
endmodule
