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
//鍔熻兘璇存槑
    //NPC_Generator鏄敤鏉ョ敓鎴怤ext PC鍊肩殑妯″潡锛屾牴鎹笉鍚岀殑璺宠浆淇″彿閫夋嫨涓嶅悓鐨勬柊PC鍊?
//杈撳叆
    //PCF              鏃х殑PC鍊?
    //JalrTarget       jalr鎸囦护鐨勫搴旂殑璺宠浆鐩爣
    //BranchTarget     branch鎸囦护鐨勫搴旂殑璺宠浆鐩爣
    //JalTarget        jal鎸囦护鐨勫搴旂殑璺宠浆鐩爣
    //BranchE==1       Ex闃舵鐨凚ranch鎸囦护纭畾璺宠浆
    //JalD==1          ID闃舵鐨凧al鎸囦护纭畾璺宠浆
    //JalrE==1         Ex闃舵鐨凧alr鎸囦护纭畾璺宠浆
//杈撳嚭
    //PC_In            NPC鐨勫??
//瀹為獙瑕佹眰  
    //琛ュ叏妯″潡  

module NPC_Generator(
    input wire [31:0] PCF,JalrTarget, BranchTarget, JalTarget,BranchPredictedTargetF,PCE,
    input wire BranchE,JalD,JalrE,BranchPredictedF,BranchPredictedE,BranchPredictedTakenF,BranchPredictedTakenE,
    output reg [31:0] PC_In
    );
    always @(*)
    begin
        if(JalrE)
            PC_In <= JalrTarget;
        else if((~BranchPredictedE || BranchPredictedE && ~BranchPredictedTakenE) && BranchE) //之前没预测或者预测不跳转，但实际跳转了（在HazardUnit中进行了Flush）
            PC_In <= BranchTarget;
		else if(BranchPredictedE && BranchPredictedTakenE && ~BranchE) //之前预测跳转，但实际不跳转（在HazardUnit中进行了Flush）
			PC_In <= PCE + 4;
        else if(JalD)
            PC_In <= JalTarget;
        else if(BranchPredictedF && BranchPredictedTakenF) //本次进行预测且预测跳转
			PC_In <= BranchPredictedTargetF;
		else
            PC_In <= PCF + 4;
    end
endmodule
