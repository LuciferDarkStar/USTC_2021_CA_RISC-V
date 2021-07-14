`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: NPC_Generator
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Choose Next PC value
//////////////////////////////////////////////////////////////////////////////////
//功能说明
    //NPC_Generator是用来生成Next PC值的模块，根据不同的跳转信号选择不同的新PC�?
//输入
    //PCF              旧的PC�?
    //JalrTarget       jalr指令的对应的跳转目标
    //BranchTarget     branch指令的对应的跳转目标
    //JalTarget        jal指令的对应的跳转目标
    //BranchE==1       Ex阶段的Branch指令确定跳转
    //JalD==1          ID阶段的Jal指令确定跳转
    //JalrE==1         Ex阶段的Jalr指令确定跳转
//输出
    //PC_In            NPC的�??
//实验要求  
    //补全模块  

module NPC_Generator(
    input wire [31:0] PCF,JalrTarget, BranchTarget, JalTarget,BranchPredictedTargetF,PCE,
    input wire BranchE,JalD,JalrE,BranchPredictedF,BranchPredictedE,
    output reg [31:0] PC_In
    );
    always @(*)
    begin
        if(JalrE)
            PC_In <= JalrTarget;
        else if(BranchE && ~BranchPredictedE) //Ԥ�ⲻ��ת��ʵ����ת
            PC_In <= BranchTarget;
		else if(~BranchE && BranchPredictedE) //Ԥ����ת��ʵ�ʲ���ת
			PC_In <= PCE + 4;
        else if(JalD)
            PC_In <= JalTarget;
        else if(BranchPredictedF)
			PC_In <= BranchPredictedTargetF;
		else
            PC_In <= PCF + 4;
    end
endmodule
