`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    11:38:51 02/15/2016 
// Design Name: 
// Module Name:    can_rw 
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
module can_rw(
	input		clk,
	input 		reset_n,
	input		rd_start,
	input		wr_start,
	input[7:0]	address,
	input[7:0]	tx_data,
	
	input[7:0]	can_in,
	output reg[7:0]	rx_data,
	output reg		en_out,		//表明双向口是高阻态还是输出
	output reg[7:0]	can_out,
	output reg		rd_valid,
	output reg		convert_dir,
	output reg 		can_ale,
	output reg 		can_wr_n,can_rd_n,can_cs_n,
	
	//output reg 		can_rst,
	
	output reg		rd_done,wr_done
    );
	
	reg[3:0] 	op_state;
	
	always @ (posedge clk or negedge reset_n)
		if(!reset_n)
			begin
			op_state		<= 4'd0;
			convert_dir		<= 1'b1;
			en_out			<= 1'b0;
			can_out			<= 8'd0;
			can_ale			<= 1'b0;
			can_cs_n		<= 1'b1;
			can_rd_n		<= 1'b1;
			rd_valid		<= 1'b0;
			rx_data			<= 8'd0;
			rd_done			<= 1'b0;
			
			can_wr_n		<= 1'b1;
			end
		else if(rd_start)
			case(op_state)
			4'd0:
				begin
				convert_dir	<= 1'b0;
				op_state	<= op_state + 1'b1;
				end
			4'd1,4'd6:
				op_state	<= op_state + 1'b1;
			4'd2:
				begin
				can_out		<= address;
				en_out		<= 1'b1;
				can_ale		<= 1'b1;
				op_state	<= op_state + 1'b1;
				end
			4'd3:
				begin
				can_ale		<= 1'b0;
				op_state	<= op_state + 1'b1;
				end
			4'd4:
				begin
				can_cs_n	<= 1'b0;
				en_out		<= 1'b0;
				convert_dir	<= 1'b1;
				op_state	<= op_state + 1'b1;
				end
			4'd5:
				begin
				can_rd_n	<= 1'b0;
				op_state	<= op_state + 1'b1;
				end
			
			4'd7:
				begin
				rd_valid	<= 1'b1;
				op_state	<= op_state + 1'b1;
				end
			4'd8:
				begin
				rd_valid	<= 1'b0;
				op_state	<= op_state + 1'b1;
				end
			4'd9:
				begin
				rx_data		<= can_in;
				can_rd_n	<= 1'b1;
				op_state	<= op_state + 1'b1;
				end
			4'd10:
				begin
				can_cs_n	<= 1'b1;
				op_state	<= op_state + 1'b1;
				rd_done		<= 1'b1;
				end
			4'd11:
				begin
				op_state	<= 4'd0;
				rd_done		<= 1'b0;
				end
			default:;
			endcase
		else if(wr_start)
			case(op_state)
			4'd0,4'd1:
				begin
				convert_dir	<= 1'b0;
				op_state	<= op_state + 1'b1;
				end
			4'd2:
				begin
				can_out		<= address;
				can_ale		<= 1'b1;
				en_out		<= 1'b1;
				op_state	<= op_state + 1'b1;				
				end
			4'd3:
				begin
				can_ale		<= 1'b10;
				op_state	<= op_state + 1'b1;
				end
			4'd4:
				begin
				can_cs_n	<= 1'b0;
				op_state	<= op_state + 1'b1;
				end
			4'd5:
				begin
				can_wr_n	<= 1'b0;
				op_state	<= op_state + 1'b1;
				end
			4'd6:
				begin
				can_out		<= tx_data;
				op_state	<= op_state + 1'b1;
				end
			4'd7:
				op_state	<= op_state + 1'b1;
			4'd8:
				begin
				can_wr_n	<= 1'b1;
				op_state	<= op_state + 1'b1;
				end
			4'd9:
				begin
				can_cs_n	<= 1'b1;
				wr_done		<= 1'b1;
				en_out		<= 1'b0;
				convert_dir	<= 1'b1;
				op_state	<= op_state + 1'b1;
				end
			4'd10:
				begin
				wr_done		<= 1'b0;
				op_state	<= 4'd0;
				end
			default:;
			endcase
		else
			begin
			op_state		<= 0;
			convert_dir		<= 1'b1;
			en_out			<= 1'b0;
			can_out			<= 8'd0;
			can_ale			<= 1'b0;
			can_cs_n		<= 1'b1;
			can_rd_n		<= 1'b1;
			rd_valid		<= 1'b0;
			rx_data			<= 8'd0;
			rd_done			<= 1'b0;
			can_wr_n		<= 1'b1;
			end
			
			
endmodule
