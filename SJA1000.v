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
	//can_tx_start��������ģ����ƣ�������ɾͷ�����SJA1000�Ķ�д�����÷ֿ�������ͬʱ
	input[39:0]	 can_tx_data,
	
	//pin
	output	convert_dir,//��ƽת����ķ������ݡ���ַ
	inout[7:0] can_add_data,
	output can_ale,
	output can_wr_n,can_rd_n,can_cs_n,
	output can_rst
    );
	
	//can_rw.v������ģ��
	//rd_start,wr_start
	//rd_done,wr_done
	
	//can_ctrl.v����״̬����Э������7��״̬
	//ÿ��״̬ģ���п�ʼ�ͽ����ӿ�
	
	//can_init.v����ʼ��״̬��1
	
	//can_SR_RBS.v����ѯ���ձ�־λ��2
	
	//can_rd_data.v�����������ݣ�3
	
	//can_CMR_RRB.v������ջ��棬4

	//can_SR_TBS.v����ѯ���ͱ�־λ��5������ջ���Ϳ�ʼ��ѯ������
	
	//can_wr_data.v��д�������ݣ�6

	//can_CMR_TR.v���������ͣ�7
	

endmodule
