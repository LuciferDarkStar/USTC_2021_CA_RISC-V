`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: RV32Core
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: Top level of our CPU Core
//////////////////////////////////////////////////////////////////////////////////
//鍔熻兘璇存槑
    //RV32I 鎸囦护闆咰PU鐨勯《灞傛ā鍧?
//瀹為獙瑕佹眰  
    //鏃犻渶淇敼

module RV32Core(
    input wire CPU_CLK,
    input wire CPU_RST,
    input wire [31:0] CPU_Debug_DataRAM_A2,
    input wire [31:0] CPU_Debug_DataRAM_WD2,
    input wire [3:0] CPU_Debug_DataRAM_WE2,
    output wire [31:0] CPU_Debug_DataRAM_RD2,
    input wire [31:0] CPU_Debug_InstRAM_A2,
    input wire [31:0] CPU_Debug_InstRAM_WD2,
    input wire [ 3:0] CPU_Debug_InstRAM_WE2,
    output wire [31:0] CPU_Debug_InstRAM_RD2
    );
	//wire values definitions
    wire StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW;
    wire [31:0] PC_In;
    wire [31:0] PCF;
    wire [31:0] Instr, PCD;
    wire JalD, JalrD, LoadNpcD, MemToRegD, AluSrc1D;
    wire [2:0] RegWriteD;
    wire [3:0] MemWriteD;
    wire [1:0] RegReadD;
    wire [2:0] BranchTypeD;
    wire [4:0] AluContrlD;
    wire [1:0] AluSrc2D;
    wire [2:0] RegWriteW;
    wire [4:0] RdW;
    wire [31:0] RegWriteData;
    wire [31:0] DM_RD_Ext;
    wire [2:0] ImmType;
    wire [31:0] ImmD;
    wire [31:0] JalNPC;
    wire [31:0] BrNPC; 
    wire [31:0] ImmE;
    wire [6:0] OpCodeD, Funct7D;
    wire [2:0] Funct3D;
    wire [4:0] Rs1D, Rs2D, RdD;
    wire [4:0] Rs1E, Rs2E, RdE;
    wire [31:0] RegOut1D;
    wire [31:0] RegOut1E;
    wire [31:0] RegOut2D;
    wire [31:0] RegOut2E;
    wire JalrE;
    wire [2:0] RegWriteE;
    wire MemToRegE;
    wire [3:0] MemWriteE;
    wire LoadNpcE;
    wire [1:0] RegReadE;
    wire [2:0] BranchTypeE;
    wire [3:0] AluContrlE;
    wire AluSrc1E;
    wire [1:0] AluSrc2E;
    wire [31:0] Operand1;
    wire [31:0] Operand2;
    wire BranchE;
    wire [31:0] AluOutE;
    wire [31:0] AluOutM; 
    wire [31:0] ForwardData1;
    wire [31:0] ForwardData2;
    wire [31:0] PCE;
    wire [31:0] StoreDataM; 
    wire [4:0] RdM;
    wire [31:0] PCM;
    wire [2:0] RegWriteM;
    wire MemToRegM;
    wire [3:0] MemWriteM;
    wire LoadNpcM;
    wire [31:0] DM_RD;
    wire [31:0] ResultM;
    wire [31:0] ResultW;
    wire MemToRegW;
    wire [1:0] Forward1E;
    wire [1:0] Forward2E;
    wire [1:0] LoadedBytesSelect;
    wire DCacheMiss;
    //CSR
    wire csr_read_ID,csr_write_ID;
    wire csr_read_enID;
    wire csr_write_enID,csr_write_enEX,csr_write_enMEM,csr_write_enWB;// csr write or not 
    wire [4:0] csr_dest_ID,csr_dest_EX,csr_dest_MEM,csr_dest_WB;//the addrass which be writen back
    wire [31:0] csr_Alu_out,csr_Alu_outMEM;
    wire [31:0] csr_WB;//write back to csr
    wire [31:0] csr_data_ID,csr_op1_EX,csr_op2_EX_IN;//read from csr; csralu op1,op2
    wire [31:0] csr_op2_EX,csr_op2_EX_IN_F;
    wire csr_op_ID,csr_op_EX;// need harzardUnit?
    wire [1:0] csr_AluFun_ID,csr_AluFun_EX;
    wire csr_imm_ID,csr_imm_EX;//1 -imm 0-rs1
    wire [1:0]csr_Forward;//harzard
    wire [1:0] csr_op_Forward;
    wire [31:0] csr_op_src1;
    wire [4:0] csr_op_EX_1;
    //BTB
    wire BranchPredictedF;
	wire BranchPredictedD;
	wire BranchPredictedE;
	wire [31:0] BranchPredictedPCF;
	//BHT
	wire BranchPredictedTakenF; //BHT命中，表示预测跳转
	wire BranchPredictedTakenD;
	wire BranchPredictedTakenE;
	//COUNT
	reg [31:0] all_instr_count;
	reg [31:0] branch_instr_count;
	reg [31:0] right_predict_count;
	reg [31:0] error_predict_count;
	
    assign csr_write_enID=(Rs1D==5'b0)?0:1;//0号寄存器,optional 
    assign csr_read_enID=((Funct3D==3'b001&&RdD==5'b0)||(Funct3D==3'b101&&RdD==5'b0))?0:1;
    assign csr_op2_EX_IN=(csr_imm_EX)?{27'h0,Rs1E}:csr_op2_EX_IN_F;
    assign csr_op2_EX_IN_F=(csr_Forward[1])?(AluOutM):(csr_Forward[0]?RegWriteData:csr_op2_EX);
    //wire values assignments
    assign {Funct7D, Rs2D, Rs1D, Funct3D, RdD, OpCodeD} = Instr;
    assign JalNPC=ImmD+PCD;
    assign ForwardData1 = Forward1E[1]?(AluOutM):( Forward1E[0]?RegWriteData:RegOut1E );
    assign csr_op_src1=csr_op_Forward[1]?(csr_Alu_outMEM):(csr_op_Forward[0]?csr_WB:csr_op1_EX);
    assign Operand1 = csr_op_EX?(csr_op_src1):(AluSrc1E?PCE:ForwardData1);
    assign ForwardData2 = Forward2E[1]?(AluOutM):( Forward2E[0]?RegWriteData:RegOut2E );
    assign Operand2 = AluSrc2E[1]?(ImmE):( AluSrc2E[0]?Rs2E:ForwardData2 );
    assign ResultM = LoadNpcM ? (PCM+4) : AluOutM;
    assign RegWriteData = ~MemToRegW?ResultW:DM_RD_Ext;
    
    
    // Count
	always @ (posedge CPU_CLK or posedge CPU_RST) begin 
		if(CPU_RST) begin
			all_instr_count <= 0;
			branch_instr_count <= 0;
			right_predict_count <= 0;
			error_predict_count <= 0;
		end else begin
			if(FlushE && FlushD)
				all_instr_count <= all_instr_count - 1;
			else if(FlushE || FlushD)
				all_instr_count <= all_instr_count;
			else
				all_instr_count <= all_instr_count + 1;
			if(BranchTypeE != 3'b000) begin
				branch_instr_count <= branch_instr_count + 1;
				if((BranchPredictedE && (BranchPredictedTakenE ^ BranchE)) || (~BranchPredictedE && BranchE))
					error_predict_count <= error_predict_count + 1;
				else 
					right_predict_count <= right_predict_count + 1;
			end
		end
	end
    
    
    //BTB
	BTB BTB1(
		.clk(~CPU_CLK),
		.rst(CPU_RST),
		.rd_PC(PCF), //输入当前PC
		.rd_predicted_PC(BranchPredictedPCF), //输出预测的下一个PC
		.rd_predicted(BranchPredictedF), //是否可以预测的标志
		.wr_req(BranchE), //实际有跳转就更新BTB
		.wr_PC(PCE), //wr_req为1才使用
		.wr_predicted_PC(BrNPC) //wr_req为1才使用
	);

	
	//BHT
	BHT BHT1(
		.clk(~CPU_CLK),
		.rst(CPU_RST),
		.rd_PC(PCF), //输入当前PC
		.rd_predicted_taken(BranchPredictedTakenF), //预测是否跳转的标志
		.wr_req(BranchTypeE != 3'b000), //是branch指令就要更新BHT，无论是否实际跳转
		.wr_PC(PCE), //wr_req为1才使用
		.wr_taken(BranchE) //wr_PC是否实际跳转，wr_req为1才使用
	);

    
    //Module connections
    // ---------------------------------------------
    // PC-IF
    // ---------------------------------------------
    NPC_Generator NPC_Generator1(
        .PCF(PCF),
        .PCE(PCE),
        .JalrTarget(AluOutE), 
        .BranchTarget(BrNPC), 
        .JalTarget(JalNPC),
        .BranchPredictedF(BranchPredictedF), //for BTB
		.BranchPredictedTargetF(BranchPredictedPCF), //for BTB
		.BranchPredictedE(BranchPredictedE), //for BTB
		.BranchPredictedTakenF(BranchPredictedTakenF), //for BHT
		.BranchPredictedTakenE(BranchPredictedTakenE), //for BHT
        .BranchE(BranchE),
        .JalD(JalD),
        .JalrE(JalrE),
        .PC_In(PC_In)
    );

    IFSegReg IFSegReg1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .en(~StallF),
        .clear(FlushF), 
        .PC_In(PC_In),
        .PCF(PCF)
    );

    // ---------------------------------------------
    // ID stage
    // ---------------------------------------------
    IDSegReg IDSegReg1(
        .clk(CPU_CLK),
        .clear(FlushD),
        .en(~StallD),
        .A(PCF),
        .RD(Instr),
        .A2(CPU_Debug_InstRAM_A2),
        .WD2(CPU_Debug_InstRAM_WD2),
        .WE2(CPU_Debug_InstRAM_WE2),
        .RD2(CPU_Debug_InstRAM_RD2),
        .PCF(PCF),
        .PCD(PCD),
        .BranchPredictedF(BranchPredictedF), //for BTB
		.BranchPredictedD(BranchPredictedD),  //for BTB 
        .BranchPredictedTakenF(BranchPredictedTakenF), //for BHT
		.BranchPredictedTakenD(BranchPredictedTakenD)  //for BHT
    );

    ControlUnit ControlUnit1(
        .Op(OpCodeD),
        .Fn3(Funct3D),
        .Fn7(Funct7D),
        .JalD(JalD),
        .JalrD(JalrD),
        .RegWriteD(RegWriteD),
        .MemToRegD(MemToRegD),
        .MemWriteD(MemWriteD),
        .LoadNpcD(LoadNpcD),
        .RegReadD(RegReadD),
        .BranchTypeD(BranchTypeD),
        .AluContrlD(AluContrlD),
        .AluSrc1D(AluSrc1D),
        .AluSrc2D(AluSrc2D),
        .ImmType(ImmType),
        .csr_write_ID(csr_write_ID),
        .csr_read_ID(csr_read_ID),
        .csr_op_ID(csr_op_ID),
        .csr_AluFun(csr_AluFun_ID),
        .csr_imm_ID(csr_imm_ID)
    );

    ImmOperandUnit ImmOperandUnit1(
        .In(Instr[31:7]),
        .Type(ImmType),
        .Out(ImmD)
    );

    RegisterFile RegisterFile1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .WE3(|RegWriteW),
        .A1(Rs1D),
        .A2(Rs2D),
        .A3(RdW),
        .WD3(RegWriteData),
        .RD1(RegOut1D),
        .RD2(RegOut2D)
    );
    
    CSR CSR1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .read_en(csr_read_enID),
        .write_en(csr_write_enWB),
        .addr(Instr[24:20]),
        .wb_addr(csr_dest_WB),
        .wb_data(csr_WB),
        .csr_out(csr_data_ID)
    );
    
    
    // ---------------------------------------------
    // EX stage
    // ---------------------------------------------
    EXSegReg EXSegReg1(
        .clk(CPU_CLK),
        .en(~StallE),
        .clear(FlushE),
        .PCD(PCD),
        .PCE(PCE), 
        .JalNPC(JalNPC),
        .BrNPC(BrNPC), 
        .ImmD(ImmD),
        .ImmE(ImmE),
        .RdD(RdD),
        .RdE(RdE),
        .Rs1D(Rs1D),
        .Rs1E(Rs1E),
        .Rs2D(Rs2D),
        .Rs2E(Rs2E),
        .RegOut1D(RegOut1D),
        .RegOut1E(RegOut1E),
        .RegOut2D(RegOut2D),
        .RegOut2E(RegOut2E),
        .JalrD(JalrD),
        .JalrE(JalrE),
        .RegWriteD(RegWriteD),
        .RegWriteE(RegWriteE),
        .MemToRegD(MemToRegD),
        .MemToRegE(MemToRegE),
        .MemWriteD(MemWriteD),
        .MemWriteE(MemWriteE),
        .LoadNpcD(LoadNpcD),
        .LoadNpcE(LoadNpcE),
        .RegReadD(RegReadD),
        .RegReadE(RegReadE),
        .BranchTypeD(BranchTypeD),
        .BranchTypeE(BranchTypeE),
        .AluContrlD(AluContrlD),
        .AluContrlE(AluContrlE),
        .AluSrc1D(AluSrc1D),
        .AluSrc1E(AluSrc1E),
        .AluSrc2D(AluSrc2D),
        .AluSrc2E(AluSrc2E),
        //csr
        .op1_csr_ID(csr_op_ID),
        .op1_csr_EX(csr_op_EX),
        .csr_Reg_1_ID(csr_data_ID),
        .csr_Reg_2_ID(RegOut1D),
        .csr_Reg_1_EX(csr_op1_EX),
        .csr_Reg_2_EX(csr_op2_EX),
        .csr_dest_ID(Instr[24:20]),
        .csr_dest_EX(csr_dest_EX),
        .csr_write_enID(csr_write_enID),
        .csr_write_enEX(csr_write_enEX),
        .csr_AluFun_ID(csr_AluFun_ID),
        .csr_AluFun_EX(csr_AluFun_EX),
        .csr_imm_ID(csr_imm_ID),
        .csr_imm_EX(csr_imm_EX),
        .csr_op_ID_1(Instr[24:20]),
        .csr_op_EX_1(csr_op_EX_1),
        
        .BranchPredictedD(BranchPredictedD), //for BTB
		.BranchPredictedE(BranchPredictedE),  //for BTB
		.BranchPredictedTakenD(BranchPredictedTakenD), //for BHT
		.BranchPredictedTakenE(BranchPredictedTakenE)  //for BHT
    	); 

    ALU ALU1(
        .Operand1(Operand1),
        .Operand2(Operand2),
        .AluContrl(AluContrlE),
        .AluOut(AluOutE)
    	);
   CSR_ALU CSR_ALU1(
        .op1(csr_op_src1),
        .op2(csr_op2_EX_IN),
        .csrALU_ctrl(csr_AluFun_EX),
        .ALU_out(csr_Alu_out)
        );

    BranchDecisionMaking BranchDecisionMaking1(
        .BranchTypeE(BranchTypeE),
        .Operand1(Operand1),
        .Operand2(Operand2),
        .BranchE(BranchE)
        );

    // ---------------------------------------------
    // MEM stage
    // ---------------------------------------------
    MEMSegReg MEMSegReg1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .en(~StallM),
        .clear(FlushM),
        .AluOutE(AluOutE),
        .AluOutM(AluOutM), 
        .ForwardData2(ForwardData2),
        .StoreDataM(StoreDataM), 
        .RdE(RdE),
        .RdM(RdM),
        .PCE(PCE),
        .PCM(PCM),
        .RegWriteE(RegWriteE),
        .RegWriteM(RegWriteM),
        .MemToRegE(MemToRegE),
        .MemToRegM(MemToRegM),
        .MemWriteE(MemWriteE),
        .MemWriteM(MemWriteM),
        .LoadNpcE(LoadNpcE),
        .LoadNpcM(LoadNpcM),
        //csr
        .csr_Alu_outEX(csr_Alu_out),
        .csr_Alu_outMEM(csr_Alu_outMEM),
        .csr_dest_EX(csr_dest_EX),
        .csr_dest_MEM(csr_dest_MEM),
        .csr_write_enEX(csr_write_enEX),
        .csr_write_enMEM(csr_write_enMEM)
    );

    // ---------------------------------------------
    // WB stage
    // ---------------------------------------------
    WBSegReg WBSegReg1(
        .clk(CPU_CLK),
        .rst(CPU_RST),
        .en(~StallW),
        .clear(FlushW),
        .A(AluOutM),
        .WD(StoreDataM),
        .WE(MemWriteM),
        .RD(DM_RD),
        .LoadedBytesSelect(LoadedBytesSelect),
        .A2(CPU_Debug_DataRAM_A2),
        .WD2(CPU_Debug_DataRAM_WD2),
        .WE2(CPU_Debug_DataRAM_WE2),
        .RD2(CPU_Debug_DataRAM_RD2),
        .ResultM(ResultM),
        .ResultW(ResultW), 
        .RdM(RdM),
        .RdW(RdW),
        .RegWriteM(RegWriteM),
        .RegWriteW(RegWriteW),
        .MemToRegM(MemToRegM),
        .MemToRegW(MemToRegW),
        .CacheMiss(DCacheMiss),
        //csr
        .csr_Alu_outMEM(csr_Alu_outMEM),
        .csr_WB(csr_WB),
        .csr_dest_WB(csr_dest_WB),
        .csr_dest_MEM(csr_dest_MEM),
        .csr_write_enWB(csr_write_enWB),
        .csr_write_enMEM(csr_write_enMEM)
    );
    
    DataExt DataExt1(
        .IN(DM_RD),
        .LoadedBytesSelect(LoadedBytesSelect),
        .RegWriteW(RegWriteW),
        .OUT(DM_RD_Ext)
    );
    // ---------------------------------------------
    // Harzard Unit
    // ---------------------------------------------
    HarzardUnit HarzardUnit1(
        .CpuRst(CPU_RST),
        .BranchE(BranchE),
        .JalrE(JalrE),
        .JalD(JalD),
        .Rs1D(Rs1D),
        .Rs2D(Rs2D),
        .Rs1E(Rs1E),
        .Rs2E(Rs2E),
        .RegReadE(RegReadE),
        .MemToRegE(MemToRegE),
        .RdE(RdE),
        .RdM(RdM),
        .RegWriteM(RegWriteM),
        .RdW(RdW),
        .RegWriteW(RegWriteW),
        .ICacheMiss(1'b0),
        .DCacheMiss(DCacheMiss),
        .StallF(StallF),
        .FlushF(FlushF),
        .StallD(StallD),
        .FlushD(FlushD),
        .StallE(StallE),
        .FlushE(FlushE),
        .StallM(StallM),
        .FlushM(FlushM),
        .StallW(StallW),
        .FlushW(FlushW),
        .Forward1E(Forward1E),
        .Forward2E(Forward2E),
        .csr_Forward(csr_Forward),
        .csr_op_11(csr_op_EX_1),
        .csr_dest_MEM(csr_dest_MEM),
        .csr_dest_WB(csr_dest_WB),
        .csr_write_MEM(csr_write_enMEM),
        .csr_write_WB(csr_write_enWB),
        .csr_op_Forward(csr_op_Forward) ,
        .BranchPredictedE(BranchPredictedE), //for BTB
        .BranchPredictedTakenE(BranchPredictedTakenE) //for BHT
    	);    
    	         
endmodule

