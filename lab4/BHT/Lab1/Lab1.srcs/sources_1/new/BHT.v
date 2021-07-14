`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/25 19:10:02
// Design Name: 
// Module Name: BHT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module BHT #( //Branch History Table������ֱ��ӳ��
	parameter  TABLE_ADDR_LEN = 12//������Table�ж�󣬴˴�Ӧ����BTB�е�BUFFER_ADDR_LENһ��
)(
	input  clk, rst,
	input [31:0] rd_PC,					//����PC
	output reg rd_predicted_taken,		//����������ź�, ��ʾԤ��rd_PC��ת
	input wr_req,						//д�����ź�
	input [31:0] wr_PC,					//Ҫ���µķ�֧PC
	input [31:0] wr_taken				//Ҫ���µķ�֧PCʵ���Ƿ���ת
);

localparam TABLE_SIZE = 1 << TABLE_ADDR_LEN;		//����buffer�Ĵ�С

reg [1 : 0] Table [0 : TABLE_SIZE - 1];//TABLE_SIZE����֧PC��״̬

wire [TABLE_ADDR_LEN - 1 : 0] rd_table_addr;
wire [TABLE_ADDR_LEN - 1 : 0] wr_table_addr;


assign rd_table_addr = rd_PC[TABLE_ADDR_LEN + 1 : 2]; //ȡPC��Ϊ���ַ������ĩ2λ
assign wr_table_addr = wr_PC[TABLE_ADDR_LEN + 1 : 2]; //ȡPC��Ϊ���ַ������ĩ2λ 

always @ (*) begin //״̬0/1Ԥ�ⲻ��ת��2/3Ԥ����ת
	rd_predicted_taken = Table[rd_table_addr] >= 2'b10;
end

always @ (posedge clk or posedge rst) begin//д��buffer
	if(rst) begin
		for(integer i = 0; i < TABLE_SIZE; i = i + 1) begin
			Table[i] = 2'b00;
		end
		rd_predicted_taken = 2'b00;
	end else begin
		if(wr_req) begin//����PC��Ӧ�����״̬�����ʵ��taken:0->1->2->3->...->3�����ʵ��not taken: 3->2->1->0->...->0
			if(wr_taken) begin
				if(Table[wr_table_addr] != 2'b11) 
					Table[wr_table_addr] <= Table[wr_table_addr] + 2'b01;
				else
					Table[wr_table_addr] <= Table[wr_table_addr];
			end else begin
				if(Table[wr_table_addr] != 2'b00) 
					Table[wr_table_addr] <= Table[wr_table_addr] - 2'b01;
				else
					Table[wr_table_addr] <= Table[wr_table_addr];
			end
		end
	end
end

endmodule
