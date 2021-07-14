`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: HarzardUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Deal with harzards in pipline
//////////////////////////////////////////////////////////////////////////////////
//鍔熻兘璇存槑
    //HarzardUnit鐢ㄦ潵澶勭悊娴佹按绾垮啿绐侊紝閫氳繃鎻掑叆姘旀场锛宖orward浠ュ強鍐插埛娴佹按娈佃В鍐虫暟鎹浉鍏冲拰鎺у埗鐩稿叧锛岀粍鍚堥?昏緫鐢佃矾
    //鍙互鏈?鍚庡疄鐜般?傚墠鏈熸祴璇旵PU姝ｇ‘鎬ф椂锛屽彲浠ュ湪姣忎袱鏉℃寚浠ら棿鎻掑叆鍥涙潯绌烘寚浠わ紝鐒跺悗鐩存帴鎶婃湰妯″潡杈撳嚭瀹氫负锛屼笉forward锛屼笉stall锛屼笉flush 
//杈撳叆
    //CpuRst                                    澶栭儴淇″彿锛岀敤鏉ュ垵濮嬪寲CPU锛屽綋CpuRst==1鏃禖PU鍏ㄥ眬澶嶄綅娓呴浂锛堟墍鏈夋瀵勫瓨鍣╢lush锛夛紝Cpu_Rst==0鏃禼pu寮?濮嬫墽琛屾寚浠?
    //ICacheMiss, DCacheMiss                    涓哄悗缁疄楠岄鐣欎俊鍙凤紝鏆傛椂鍙互鏃犺锛岀敤鏉ュ鐞哻ache miss
    //BranchE, JalrE, JalD                      鐢ㄦ潵澶勭悊鎺у埗鐩稿叧
    //Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW     鐢ㄦ潵澶勭悊鏁版嵁鐩稿叧锛屽垎鍒〃绀烘簮瀵勫瓨鍣?1鍙风爜锛屾簮瀵勫瓨鍣?2鍙风爜锛岀洰鏍囧瘎瀛樺櫒鍙风爜
    //RegReadE RegReadD[1]==1                   琛ㄧずA1瀵瑰簲鐨勫瘎瀛樺櫒鍊艰浣跨敤鍒颁簡锛孯egReadD[0]==1琛ㄧずA2瀵瑰簲鐨勫瘎瀛樺櫒鍊艰浣跨敤鍒颁簡锛岀敤浜巉orward鐨勫鐞?
    //RegWriteM, RegWriteW                      鐢ㄦ潵澶勭悊鏁版嵁鐩稿叧锛孯egWrite!=3'b0璇存槑瀵圭洰鏍囧瘎瀛樺櫒鏈夊啓鍏ユ搷浣?
    //MemToRegE                                 琛ㄧずEx娈靛綋鍓嶆寚浠? 浠嶥ata Memory涓姞杞芥暟鎹埌瀵勫瓨鍣ㄤ腑
//杈撳嚭
    //StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW    鎺у埗浜斾釜娈靛瘎瀛樺櫒杩涜stall锛堢淮鎸佺姸鎬佷笉鍙橈級鍜宖lush锛堟竻闆讹級
    //Forward1E, Forward2E                                                              鎺у埗forward
//瀹為獙瑕佹眰  
    //琛ュ叏妯″潡  
    
    
module HarzardUnit(
    input wire CpuRst, ICacheMiss, DCacheMiss, 
    input wire BranchE, JalrE, JalD, BranchPredictedE,
    input wire [4:0] Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW,
    input wire [1:0] RegReadE,
    input wire MemToRegE,
    input wire [2:0] RegWriteM, RegWriteW,
    output reg StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW,
    output reg [1:0] Forward1E, Forward2E,
    //csr
    output reg [1:0] csr_Forward,
    input wire [4:0] csr_op_11, csr_dest_MEM, csr_dest_WB,
    input wire csr_write_MEM,csr_write_WB,
    output reg [1:0]csr_op_Forward
    );
    
	
	always @ (*)
        if(CpuRst)
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b0101010101;
        else if(DCacheMiss | ICacheMiss)
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b1010101010;
        else if((BranchPredictedE ^ BranchE) | JalrE) //BranchPredictedE ^ BranchE为1表示预测结果与实际跳转结果不同
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b0001010000;
        else if(MemToRegE & ((RdE==Rs1D)||(RdE==Rs2D)) )
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b1010010000;
        else if(JalD)
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b0001000000;
        else
            {StallF,FlushF,StallD,FlushD,StallE,FlushE,StallM,FlushM,StallW,FlushW} <= 10'b0000000000;
	
	
	
	always@(*) begin
		//当前指令在EX阶段
		//默认forward=2'b00
		//如果RegWriteM不为0，说明上一条指令（此时在MEM阶段）的ALU结果要写回寄存器----情况1----forward=2'b01
		//如果RegWriteW不为0，说明上上一条指令（此时在WB阶段）的访存结果要写回寄存器----情况2----forward=2'b11
		//应该注意。某些指令写0号寄存器，这是不起作用的，也就无需forward
		//Forward Register Source 1
		Forward1E[0] <= RdW != 0 && |RegWriteW && RegReadE[1] && (RdW == Rs1E) && ~(|RegWriteM && RegReadE[1] && (RdM == Rs1E));//如果上上条指令写回位置是Rs1E，上条指令也是，则应该取上条指令写的值
		Forward1E[1] <= RdM != 0 && |RegWriteM && RegReadE[1] && (RdM == Rs1E);
		//Forward Register Source 2
		Forward2E[0] <= RdW != 0 && |RegWriteW && RegReadE[0] && (RdW == Rs2E) && ~(|RegWriteM && RegReadE[0] && (RdM == Rs2E));//如果上上条指令写回位置是Rs2E，上条指令也是，则应该取上条指令写的值
		Forward2E[1] <= RdM != 0 && |RegWriteM && RegReadE[0] && (RdM == Rs2E);
	end
    // 璇疯ˉ鍏ㄦ澶勪唬鐮?
   
    //CSR
    always@(*) begin
    if(csr_op_11==csr_dest_MEM&&csr_write_MEM)
        csr_op_Forward<=2'b10;
    else if(csr_op_11==csr_dest_WB&&csr_write_WB)
        csr_op_Forward<=2'b01;
    else
        csr_op_Forward<=2'b00;
    end
    //csr
    always@(*) begin
    if(RdM!=5'b0&&RdM==Rs1E&&RegWriteM!=3'b0)
        csr_Forward<=2'b10;
    else if(RdW!=5'b0&&RdW==Rs1E&&RegWriteW!=3'b0)
        csr_Forward<=2'b01;
    else  
        csr_Forward<=2'b00;
    end
endmodule

  