`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: IDSegReg
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: IF-ID Segment Register
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //IDSegReg是IF-ID段寄存器，同时包含了�?个同步读写的Bram（此处你可以调用我们提供的InstructionRam�?
    //它将会自动综合为block memory，你也可以替代�?�的调用xilinx的bram ip核）�?
    //同步读memory 相当�? 异步读memory 的输出外接D触发器，�?要时钟上升沿才能读取数据�?
    //此时如果再�?�过段寄存器缓存，那么需要两个时钟上升沿才能将数据传递到Ex�?
    //因此在段寄存器模块中调用该同步memory，直接将输出传�?�到ID段组合�?�辑
    //调用mem模块后输出为RD_raw，�?�过assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );
    //从�?�实现RD段寄存器stall和clear功能
//实验要求  
    //补全IDSegReg模块，需补全的片段截取如�?
    //InstructionRam InstructionRamInst (
    //     .clk    (),                        //请完善代�?
    //     .addra  (),                        //请完善代�?
    //     .douta  ( RD_raw     ),
    //     .web    ( |WE2       ),
    //     .addrb  ( A2[31:2]   ),
    //     .dinb   ( WD2        ),
    //     .doutb  ( RD2        )
    // );
//注意事项
    //输入到DataRam的addra是字地址，一个字32bit

module IDSegReg(
    input wire clk,
    input wire clear,
    input wire en,
    //Instrution Memory Access
    input wire [31:0] A,
    output wire [31:0] RD,
    //Instruction Memory Debug
    input wire [31:0] A2,
    input wire [31:0] WD2,
    input wire [3:0] WE2,
    output wire [31:0] RD2,
    //
    input wire [31:0] PCF,
    output reg [31:0] PCD,
    //BTB
    input wire BranchPredictedF,
	output reg BranchPredictedD,
	//BHT
	input wire BranchPredictedTakenF,
	output reg BranchPredictedTakenD
    );
    
    initial 
    begin
        PCD = 0;
        BranchPredictedD = 1'b0;
        BranchPredictedTakenD = 1'b0;
    end
    
    always@(posedge clk)
        if(en)
        begin
            PCD <= clear ? 0: PCF;
            BranchPredictedD <= clear ? 1'b0 : BranchPredictedF;
            BranchPredictedTakenD <= clear ? 1'b0 : BranchPredictedTakenF;
        end
    wire [31:0] RD_raw;

    reg stall_ff= 1'b0;
    reg clear_ff= 1'b0;
    reg [31:0] RD_old=32'b0;
    always @ (posedge clk)
    begin
        stall_ff<=~en;
        clear_ff<=clear;
        RD_old<=RD;
    end    
    assign RD = stall_ff ? RD_old : (clear_ff ? 32'b0 : RD_raw );
   
   InstructionCache_M InstructionRam (
         .clk    ( clk        ),
         .write_en    ( 0        ),
         .addr  ( A[31:2]          ),
         .data  ( RD_raw     )
     );
     /*btb_inst InstructionRam (
         .clk    ( clk        ),
         .write_en    ( 0        ),
         .addr  ( A[31:2]          ),
         .data  ( RD_raw     )
     );*/
     
endmodule