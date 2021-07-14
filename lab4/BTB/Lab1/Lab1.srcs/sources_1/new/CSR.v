`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/08 19:33:26
// Design Name: 
// Module Name: CSR
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


module CSR(
    input wire clk,
    input wire rst,
    input wire read_en,
    input wire write_en,
    input wire [4:0] addr, wb_addr,
    input wire [31:0] wb_data,
    output wire [31:0] csr_out
    );
    reg [31:0] RegFile[31:0];
    integer i;
    initial
    begin
        for(i = 0; i < 32; i = i + 1) 
            RegFile[i][31:0] <= 32'b0;
    end
    always@(negedge clk or posedge rst) 
    begin 
        if (rst)
            for (i = 0; i < 32; i = i + 1) 
                RegFile[i][31:0] <= 32'b0;
        else if(write_en==1'b1)
            RegFile[wb_addr] <= wb_data;   
    end
    assign csr_out =(read_en==1'b1)?RegFile[addr]:32'b0;
endmodule
