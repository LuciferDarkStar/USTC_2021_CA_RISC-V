`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/25 10:55:54
// Design Name: 
// Module Name: BTB
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


module BTB #( //Branch Target Buffer������ֱ��ӳ��
	parameter  BUFFER_ADDR_LEN = 12//������Buffer�ж��
)(
	input  clk, rst,

	input [31:0] rd_PC,					//����PC
	output reg rd_predicted,				//����������ź�, ��ʾrd_PC����תָ���ʱrd_predicted_PC����Ч����
	output reg [31:0] rd_predicted_PC,	//��buffer�еõ���Ԥ��PC
	input wr_req,						//д�����ź�
	input [31:0] wr_PC,					//Ҫд��ķ�֧PC
	input [31:0] wr_predicted_PC,		//Ҫд���Ԥ��PC
	input wr_predicted_state_bit		//Ҫд���Ԥ��״̬λ
);

localparam TAG_ADDR_LEN = 32 - BUFFER_ADDR_LEN - 2;	//����tag������λ��
localparam BUFFER_SIZE = 1 << BUFFER_ADDR_LEN;		//����buffer�Ĵ�С

reg [TAG_ADDR_LEN - 1 : 0] PCTag			[0 : BUFFER_SIZE - 1];//BUFFER_SIZE����֧PC��TAG
reg [              31 : 0] PredictPC		[0 : BUFFER_SIZE - 1];//BUFFER_SIZE��Ԥ��PC
reg                        PredictStateBit	[0 : BUFFER_SIZE - 1];//BUFFER_SIZE��Ԥ��״̬λ

wire [BUFFER_ADDR_LEN - 1 : 0] rd_buffer_addr;//�������ַ��ֳ�3������
wire [   TAG_ADDR_LEN - 1 : 0] rd_tag_addr;
wire [              2 - 1 : 0] rd_word_addr; //PC��4�ı�����ĩ2λ��Ϊ0

wire [BUFFER_ADDR_LEN - 1 : 0] wr_buffer_addr;//�������ַ��ֳ�3������
wire [   TAG_ADDR_LEN - 1 : 0] wr_tag_addr;
wire [              2 - 1 : 0] wr_word_addr; //PC��4�ı�����ĩ2λ��Ϊ0

assign {rd_tag_addr, rd_buffer_addr, rd_word_addr} = rd_PC; //��� 32bit rd_PC
assign {wr_tag_addr, wr_buffer_addr, wr_word_addr} = wr_PC; //��� 32bit wr_PC

always @ (*) begin //�ж������ PC �Ƿ��� buffer ������
	if(PCTag[rd_buffer_addr] == rd_tag_addr && PredictStateBit[rd_buffer_addr])//���tag�������ַ�е�tag���������buffer�ĸ�����Ч��������
		rd_predicted = 1'b1;
	else
		rd_predicted = 1'b0;
	rd_predicted_PC = PredictPC[rd_buffer_addr];
end

always @ (posedge clk or posedge rst) begin//д��buffer
	if(rst) begin
		for(integer i = 0; i < BUFFER_SIZE; i = i + 1) begin
			PCTag[i] = 0;
			PredictPC[i] = 0;
			PredictStateBit[i] = 1'b0;
		end
		rd_predicted = 1'b0;
		rd_predicted_PC = 0;
	end else begin
		if(wr_req) begin
			PCTag[wr_buffer_addr] <= wr_tag_addr;
			PredictPC[wr_buffer_addr] <= wr_predicted_PC;
			PredictStateBit[wr_buffer_addr] <= wr_predicted_state_bit;
		end
	end
end

endmodule
