`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: USTC ESLAB 
// Engineer: Wu Yuzhang
// 
// Design Name: RISCV-Pipline CPU
// Module Name: ControlUnit
// Target Devices: Nexys4
// Tool Versions: Vivado 2017.4.1
// Description: RISC-V Instruction Decoder
//////////////////////////////////////////////////////////////////////////////////
//功能和接口说�?
    //ControlUnit       是本CPU的指令译码器，组合�?�辑电路
//输入
    // Op               是指令的操作码部�?
    // Fn3              是指令的func3部分
    // Fn7              是指令的func7部分
//输出
    // JalD==1          表示Jal指令到达ID译码阶段
    // JalrD==1         表示Jalr指令到达ID译码阶段
    // RegWriteD        表示ID阶段的指令对应的寄存器写入模�?
    // MemToRegD==1     表示ID阶段的指令需要将data memory读取的�?�写入寄存器,
    // MemWriteD        �?4bit，为1的部分表示有效，对于data memory�?32bit字按byte进行写入,MemWriteD=0001表示只写入最�?1个byte，和xilinx bram的接口类�?
    // LoadNpcD==1      表示将NextPC输出到ResultM
    // RegReadD         表示A1和A2对应的寄存器值是否被使用到了，用于forward的处�?
    // BranchTypeD      表示不同的分支类型，�?有类型定义在Parameters.v�?
    // AluContrlD       表示不同的ALU计算功能，所有类型定义在Parameters.v�?
    // AluSrc2D         表示Alu输入�?2的�?�择
    // AluSrc1D         表示Alu输入�?1的�?�择
    // ImmType          表示指令的立即数格式
//实验要求  
    //补全模块  

`include "Parameters.v"   
`define ControlOut {{JalD,JalrD},{MemToRegD},{RegWriteD},{MemWriteD},{LoadNpcD},{RegReadD},{BranchTypeD},{AluContrlD},{AluSrc1D,AluSrc2D},{ImmType}}
module ControlUnit(
    input wire [6:0] Op,
    input wire [2:0] Fn3,
    input wire [6:0] Fn7,
    output reg JalD,
    output reg JalrD,
    output reg [2:0] RegWriteD,
    output reg MemToRegD,
    output reg [3:0] MemWriteD,
    output reg LoadNpcD,
    output reg [1:0] RegReadD,
    output reg [2:0] BranchTypeD,
    output reg [3:0] AluContrlD,
    output reg [1:0] AluSrc2D,
    output reg AluSrc1D,
    output reg [2:0] ImmType,
    //CSR
    output wire csr_read_ID,
    output wire csr_write_ID,
    output wire csr_op_ID, //1- csr to reg  0 not csr to reg
    output reg [1:0] csr_AluFun,
    output wire csr_imm_ID
    ); 
    assign csr_write_ID=(Op[6:0]==7'b1110011);
    assign csr_read_ID=(Op[6:0]==7'b1110011);
    assign csr_op_ID=(Op[6:0]==7'b1110011);
    assign csr_imm_ID=(Op[6:0]==7'b1110011)&&(Fn3==3'b101||Fn3==3'b110||Fn3==3'b111);
    
    always@(*)//csr_alu
    begin
       if(Op[6:0]==7'b1110011)
       begin
               if(Fn3==3'b001||Fn3==3'b101)
               csr_AluFun=2'b01;//csrrw
               else if(Fn3==3'b010||Fn3==3'b110)
               csr_AluFun=2'b10;//csrrs
               else if(Fn3==3'b011||Fn3==3'b111)
               csr_AluFun=2'b11;//csrrc
               else
               csr_AluFun=2'b0;
       end
       else
       csr_AluFun=2'b0;
    end
    
    
    always@(*) 
		case(Op)
            7'b0010011: //REG-IMM
				case(Fn3)
					3'b000:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`ADD},{3'b0_10},{`ITYPE}};/* ADDI */
					3'b001:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`SLL},{3'b0_01},{`ITYPE}};/* SLLI */
					3'b010:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`SLT},{3'b0_10},{`ITYPE}};/* SLTI */
					3'b011:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`SLTU},{3'b0_10},{`ITYPE}};/* SLTIU */
					3'b100:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`XOR},{3'b0_10},{`ITYPE}};/* XORI */
					3'b101:
						case(Fn7)
							7'b0000000:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`SRL},{3'b0_01},{`ITYPE}};/* SRLI */
							7'b0100000:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`SRA},{3'b0_01},{`ITYPE}};/* SRAI */
						endcase
					3'b110:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`OR},{3'b0_10},{`ITYPE}};/* ORI */
					3'b111:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`AND},{3'b0_10},{`ITYPE}};/* ANDI */
				endcase
			7'b0110011: //REG-REG
				case(Fn3)
					3'b000: /*  */
						case(Fn7)
							7'b0000000:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`ADD},{3'b0_00},{`RTYPE}};/* ADD */
							7'b0100000:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`SUB},{3'b0_00},{`RTYPE}};/* SUB */
						endcase
					3'b001:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`SLL},{3'b0_00},{`RTYPE}};/* SLL */
					3'b010:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`SLT},{3'b0_00},{`RTYPE}};/* SLT */
					3'b011:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`SLTU},{3'b0_00},{`RTYPE}};/* SLTU */
					3'b100:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`XOR},{3'b0_00},{`RTYPE}};/* XOR */
					3'b101:
						case(Fn7)
							7'b0000000:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`SRL},{3'b0_00},{`RTYPE}};/* SRL */
							7'b0100000:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`SRA},{3'b0_00},{`RTYPE}};/* SRA */
						endcase
					3'b110:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`OR},{3'b0_00},{`RTYPE}};/* OR */
					3'b111:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b11},{`NOBRANCH},{`AND},{3'b0_00},{`RTYPE}};/* AND */
				endcase
			7'b0110111:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b00},{`NOBRANCH},{`LUI},{3'b0_10},{`UTYPE}};/* LUI */
			7'b0010111:  `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b00},{`NOBRANCH},{`ADD},{3'b1_10},{`UTYPE}};/* AUIPC */
				
			7'b0000011: //Load
				case(Fn3)
					3'b000:  `ControlOut = {{2'b0_0},{1'b1,`LB},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`ADD},{3'b0_10},{`ITYPE}};/* LB */
					3'b001:  `ControlOut = {{2'b0_0},{1'b1,`LH},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`ADD},{3'b0_10},{`ITYPE}};/* LH */
					3'b010:  `ControlOut = {{2'b0_0},{1'b1,`LW},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`ADD},{3'b0_10},{`ITYPE}};/* LW */
					3'b100:  `ControlOut = {{2'b0_0},{1'b1,`LBU},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`ADD},{3'b0_10},{`ITYPE}};/* LBU */
					3'b101:  `ControlOut = {{2'b0_0},{1'b1,`LHU},{4'b0000},{1'b0},{2'b10},{`NOBRANCH},{`ADD},{3'b0_10},{`ITYPE}};/* LHU */
				endcase
			7'b0100011: //Store
				case(Fn3)
					3'b000:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b0001},{1'b0},{2'b11},{`NOBRANCH},{`ADD},{3'b0_10},{`STYPE}};/* SB */
					3'b001:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b0011},{1'b0},{2'b11},{`NOBRANCH},{`ADD},{3'b0_10},{`STYPE}};/* SH */
					3'b010:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b1111},{1'b0},{2'b11},{`NOBRANCH},{`ADD},{3'b0_10},{`STYPE}};/* SW */
				endcase
			7'b1100011: //Branch
				case(Fn3)
					3'b000:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b0000},{1'b0},{2'b11},{`BEQ},{4'bxxxx},{3'b0_00},{`BTYPE}};/* BEQ */
					3'b001:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b0000},{1'b0},{2'b11},{`BNE},{4'bxxxx},{3'b0_00},{`BTYPE}};/* BNE */
					3'b100:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b0000},{1'b0},{2'b11},{`BLT},{4'bxxxx},{3'b0_00},{`BTYPE}};/* BLT */
					3'b101:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b0000},{1'b0},{2'b11},{`BGE},{4'bxxxx},{3'b0_00},{`BTYPE}};/* BGE */
					3'b110:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b0000},{1'b0},{2'b11},{`BLTU},{4'bxxxx},{3'b0_00},{`BTYPE}};/* BLTU */
					3'b111:  `ControlOut = {{2'b0_0},{1'b0,`NOREGWRITE},{4'b0000},{1'b0},{2'b11},{`BGEU},{4'bxxxx},{3'b0_00},{`BTYPE}};/* BGEU */
				endcase
			7'b1101111:  `ControlOut = {{2'b1_0},{1'b0,`LW},{4'b0000},{1'b1},{2'b00},{`NOBRANCH},{4'bxxxx},{3'bx_xx},{`JTYPE}};/* JAL */
			7'b1100111:  `ControlOut = {{2'b0_1},{1'b0,`LW},{4'b0000},{1'b1},{2'b10},{`NOBRANCH},{`ADD},{3'b0_10},{`ITYPE}};/* JALR */
			7'b1110011://CSR
			    case(Fn3)
			         3'b001: `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b00},{`NOBRANCH},{`CSR},{3'b0_00},{`RTYPE}};/*CSRRW*/
			         3'b010: `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b00},{`NOBRANCH},{`CSR},{3'b0_00},{`RTYPE}};/*CSRRS*/
			         3'b011: `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b00},{`NOBRANCH},{`CSR},{3'b0_00},{`RTYPE}};/*CSRRC*/
			         3'b101: `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b00},{`NOBRANCH},{`CSR},{3'b0_00},{`RTYPE}};/*CSRRWI*/
			         3'b110: `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b00},{`NOBRANCH},{`CSR},{3'b0_00},{`RTYPE}};/*CSRRSI*/
			         3'b111: `ControlOut = {{2'b0_0},{1'b0,`LW},{4'b0000},{1'b0},{2'b00},{`NOBRANCH},{`CSR},{3'b0_00},{`RTYPE}};/*CSRRCI*/
			    endcase
			default: `ControlOut = 26'b0;
		endcase
    // 请补全此处代�?
endmodule

