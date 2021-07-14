`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/05/08 19:37:21
// Design Name: 
// Module Name: CSR_ALU
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


module CSR_ALU(
    input wire [31:0] op1,
    input wire [31:0] op2,
    input wire [1:0] csrALU_ctrl,
    output reg [31:0] ALU_out
    );
    always @ (*)
    begin
    case(csrALU_ctrl)
        2'b01:ALU_out = op2;
        2'b10:ALU_out = op1 | op2;
        2'b11:ALU_out = op1 & (~ op2);
        default:
        ALU_out = 32'h0;
    endcase
    end
endmodule
