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

input clk;			// 50MHz��ʱ��
input rst_n;		//�͵�ƽ��λ�ź�
input clk_bps;		// clk_bps_r�ߵ�ƽΪ��������λ���м������,ͬʱҲ��Ϊ�������ݵ����ݸı��
input[7:0] tx_data;	//�������ݼĴ���;
input tx_int;		//���ʹ��� ������
output rs232_tx;	// RS232���������ź�
output bps_start;	//���ջ���Ҫ�������ݣ�������ʱ�������ź���λ
output tx_done;

//---------------------------------------------------------
reg[7:0] tx_data_buf;	//���������ݵļĴ���
//---------------------------------------------------------
reg tx_int_1, tx_int_2;
reg bps_start_r;
reg tx_en;	//��������ʹ���źţ�����Ч
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
	else if(tx_int_1 && ~tx_int_2) begin	//����������ϣ�׼���ѽ��յ������ݷ���ȥ
			bps_start_r <= 1'b1;
			tx_data_buf <= tx_data;	//�ѽ��յ������ݴ��뷢�����ݼĴ���
			tx_en <= 1'b1;		//���뷢������״̬��
		end
	else if(num==4'd12) begin	//���ݷ�����ɣ���λ
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
						4'd0: rs232_tx_r <= 1'b0; 	//������ʼλ
						4'd1: rs232_tx_r <= tx_data_buf[0];	//����bit0
						4'd2: rs232_tx_r <= tx_data_buf[1];	//����bit1
						4'd3: rs232_tx_r <= tx_data_buf[2];	//����bit2
						4'd4: rs232_tx_r <= tx_data_buf[3];	//����bit3
						4'd5: rs232_tx_r <= tx_data_buf[4];	//����bit4
						4'd6: rs232_tx_r <= tx_data_buf[5];	//����bit5
						4'd7: rs232_tx_r <= tx_data_buf[6];	//����bit6
						4'd8: rs232_tx_r <= tx_data_buf[7];	//����bit7
						4'd9: rs232_tx_r <= 1'b1;	//���ͽ���λ
						4'd10: rs232_tx_r <= 1'b1;	//����2nd����λ
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
