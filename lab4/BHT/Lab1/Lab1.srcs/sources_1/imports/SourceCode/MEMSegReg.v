`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: MEMSegReg
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: EX-MEM Segment Register
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //MEMSegReg是EX-MEM段寄存器
//实验要求  
    //无需修改
    
module MEMSegReg(
    input wire clk,
    input wire rst,
    input wire en,
    input wire clear,
    //Data Signals
    input wire [31:0] AluOutE,
    output reg [31:0] AluOutM, 
    input wire [31:0] ForwardData2,
    output reg [31:0] StoreDataM, 
    input wire [4:0] RdE,
    output reg [4:0] RdM,
    input wire [31:0] PCE,
    output reg [31:0] PCM,
    //Control Signals
    input wire [2:0] RegWriteE,
    output reg [2:0] RegWriteM,
    input wire MemToRegE,
    output reg MemToRegM,
    input wire [3:0] MemWriteE,
    output reg [3:0] MemWriteM,
    input wire LoadNpcE,
    output reg LoadNpcM,
    //csr   
    input wire [31:0] csr_Alu_outEX,
    output reg [31:0]   csr_Alu_outMEM,
    input wire [4:0] csr_dest_EX,
    output reg [4:0]  csr_dest_MEM,
    input wire  csr_write_enEX,
    output reg csr_write_enMEM
    );
    initial begin
        AluOutM    = 0;
        StoreDataM = 0;
        RdM        = 5'h0;
        PCM        = 0;
        RegWriteM  = 3'h0;
        MemToRegM  = 1'b0;
        MemWriteM  = 4'b0;
        LoadNpcM   = 0;
        //csr
        csr_Alu_outMEM=32'b0;   
        csr_dest_MEM=5'b0;     
        csr_write_enMEM=1'b0;
    end
    
    always@(posedge clk or posedge rst)
    begin
        if(rst)
        begin
            AluOutM<=32'b0;
            StoreDataM<=32'b0;
            RdM<=5'b0;
            PCM<=32'b0;
            RegWriteM<=1'b0;
            MemToRegM<=1'b0;
            MemWriteM<=1'b0;
            LoadNpcM<=1'b0;   
        end
        else if(en) 
        begin
            AluOutM    <= clear ?     0 : AluOutE;
            StoreDataM <= clear ?     0 : ForwardData2;
            RdM        <= clear ?  5'h0 : RdE;
            PCM        <= clear ?     0 : PCE;
            RegWriteM  <= clear ?  3'h0 : RegWriteE;
            MemToRegM  <= clear ?  1'b0 : MemToRegE;
            MemWriteM  <= clear ?  4'b0 : MemWriteE;
            LoadNpcM   <= clear ?     0 : LoadNpcE;
            //csr
            csr_Alu_outMEM<=clear? 32'b0:csr_Alu_outEX;   
            csr_dest_MEM<=clear? 5'b0:csr_dest_EX;     
            csr_write_enMEM<=clear?1'b0:csr_write_enEX;
        end
    end
endmodule