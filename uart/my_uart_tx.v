`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    13:56:57 06/27/2014 
// Design Name: 
// Module Name:    my_uart_tx 
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
module my_uart_tx(
				clk,rst_n,
				tx_data,tx_int,rs232_tx,
				clk_bps, bps_start, tx_done
			);

input clk;			// 50MHz主时钟
input rst_n;		//低电平复位信号
input clk_bps;		// clk_bps_r高电平为接收数据位的中间采样点,同时也作为发送数据的数据改变点
input[7:0] tx_data;	//接收数据寄存器;
input tx_int;		//发送触发 上升沿
output rs232_tx;	// RS232发送数据信号
output bps_start;	//接收或者要发送数据，波特率时钟启动信号置位
output tx_done;

//---------------------------------------------------------
reg[7:0] tx_data_buf;	//待发送数据的寄存器
//---------------------------------------------------------
reg tx_int_1, tx_int_2;
reg bps_start_r;
reg tx_en;	//发送数据使能信号，高有效
reg[3:0] num;
reg tx_done;

always @ (posedge clk or negedge rst_n) begin
	if (~rst_n) begin
		tx_int_1 <= 1'b0;
		tx_int_2 <= 1'b0;
	end
	else begin
		tx_int_1 <= tx_int;
		tx_int_2 <= tx_int_1;
	end
end	

always @ (posedge clk or negedge rst_n) begin
	if(~rst_n) begin
			bps_start_r <= 1'b0;
			tx_en <= 1'b0;
			tx_data_buf <= 8'd0;
		end
	else if(tx_int_1 && ~tx_int_2) begin	//接收数据完毕，准备把接收到的数据发回去
			bps_start_r <= 1'b1;
			tx_data_buf <= tx_data;	//把接收到的数据存入发送数据寄存器
			tx_en <= 1'b1;		//进入发送数据状态中
		end
	else if(num==4'd12) begin	//数据发送完成，复位
			bps_start_r <= 1'b0;
			tx_en <= 1'b0;
		end
end

assign bps_start = bps_start_r;

//---------------------------------------------------------
reg rs232_tx_r;

always @ (posedge clk or negedge rst_n) begin
	if(!rst_n) begin
			num <= 4'd0;
			rs232_tx_r <= 1'b1;
			tx_done <= 1'b0;
	end
	else if(tx_en) begin
			if(clk_bps)	begin
					num <= num+1'b1;
					case (num)
						4'd0: rs232_tx_r <= 1'b0; 	//发送起始位
						4'd1: rs232_tx_r <= tx_data_buf[0];	//发送bit0
						4'd2: rs232_tx_r <= tx_data_buf[1];	//发送bit1
						4'd3: rs232_tx_r <= tx_data_buf[2];	//发送bit2
						4'd4: rs232_tx_r <= tx_data_buf[3];	//发送bit3
						4'd5: rs232_tx_r <= tx_data_buf[4];	//发送bit4
						4'd6: rs232_tx_r <= tx_data_buf[5];	//发送bit5
						4'd7: rs232_tx_r <= tx_data_buf[6];	//发送bit6
						4'd8: rs232_tx_r <= tx_data_buf[7];	//发送bit7
						4'd9: rs232_tx_r <= 1'b1;	//发送结束位
						4'd10: rs232_tx_r <= 1'b1;	//发送2nd结束位
						default: rs232_tx_r <= 1'b1;
					endcase
			end
			else begin
				if (num == 4'd12) begin
					num <= 4'd0;
					tx_done <= 1'b1;
				end
			end
	end
	else begin
		tx_done <= 1'b0;
	end
end

assign rs232_tx = rs232_tx_r;

endmodule
