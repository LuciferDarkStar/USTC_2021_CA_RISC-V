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
//功能说明
    //HarzardUnit用来处理流水线冲突，通过插入气泡，forward以及冲刷流水段解决数据相关和控制相关，组合�?�辑电路
    //可以�?后实现�?�前期测试CPU正确性时，可以在每两条指令间插入四条空指令，然后直接把本模块输出定为，不forward，不stall，不flush 
//输入
    //CpuRst                                    外部信号，用来初始化CPU，当CpuRst==1时CPU全局复位清零（所有段寄存器flush），Cpu_Rst==0时cpu�?始执行指�?
    //ICacheMiss, DCacheMiss                    为后续实验预留信号，暂时可以无视，用来处理cache miss
    //BranchE, JalrE, JalD                      用来处理控制相关
    //Rs1D, Rs2D, Rs1E, Rs2E, RdE, RdM, RdW     用来处理数据相关，分别表示源寄存�?1号码，源寄存�?2号码，目标寄存器号码
    //RegReadE RegReadD[1]==1                   表示A1对应的寄存器值被使用到了，RegReadD[0]==1表示A2对应的寄存器值被使用到了，用于forward的处�?
    //RegWriteM, RegWriteW                      用来处理数据相关，RegWrite!=3'b0说明对目标寄存器有写入操�?
    //MemToRegE                                 表示Ex段当前指�? 从Data Memory中加载数据到寄存器中
//输出
    //StallF, FlushF, StallD, FlushD, StallE, FlushE, StallM, FlushM, StallW, FlushW    控制五个段寄存器进行stall（维持状态不变）和flush（清零）
    //Forward1E, Forward2E                                                              控制forward
//实验要求  
    //补全模块  
    
    
module HarzardUnit(
    input wire CpuRst, ICacheMiss, DCacheMiss, 
    input wire BranchE, JalrE, JalD, 
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
    always@(*) 
    begin
        if(DCacheMiss | ICacheMiss)
        begin
            StallF<=1'b1;
            StallD<=1'b1;
            FlushD<=1'b0;
            FlushE<=1'b0;
            StallE<=1'b1;
            StallM<=1'b1;
            StallW<=1'b1;
            FlushF<=1'b0;
            FlushW<=1'b0;
            FlushM<=1'b0;
        end
        else
        begin
		FlushF <= CpuRst;//IF�Ĵ�����PC�Ĵ�����ֻ�г�ʼ��ʱ��Ҫ���
		FlushD <= CpuRst || (BranchE || JalrE || JalD);//ID�Ĵ���������IF/ID֮��ļĴ������ڷ���3����תʱ���
		FlushE <= CpuRst || (MemToRegE && (RdE == Rs1D || RdE == Rs2D)) || (BranchE || JalrE);//EX�Ĵ����ڷ���2����ת���޷�ת�����������ʱ���
		FlushM <= CpuRst;//MEM�Ĵ���������EX/MEM֮��ļĴ�����ֻ�г�ʼ��ʱ��Ҫ���
		FlushW <= CpuRst;//WB�Ĵ���������MEM/WB֮��ļĴ�����ֻ�г�ʼ��ʱ��Ҫ���
		StallF <= (~CpuRst && (MemToRegE && (RdE == Rs1D || RdE == Rs2D)));
		StallD <= (~CpuRst && (MemToRegE && (RdE == Rs1D || RdE == Rs2D)));
		StallE <= 1'b0;
		StallM <= 1'b0;
		StallW <= 1'b0;
        end
		//���ǵ�ǰָ����ID�׶�
		//��һ��ָ��ô沢д�� �� ��ǰָ��ID�׶ζ�����ͬһ���Ĵ�������ͣ�٣�����bubble��
		//���ﲢ����Forward�����ж�RegWriteE��0����Ϊд��Ĵ��������ݿ�����ALU�Ľ��Ҳ�����Ƿô�Ľ��
		//ֻ����һ��ָ��д�ؼĴ����Ľ���Ƿô�Ľ��----���3������Ҫͣ�٣������MemToRegE�ж�
		//�����һ��ָ��д�ؼĴ����Ľ����ALU�Ľ������ô��͵ȼ������1������Forward����
	end
	
	always@(*) begin
		//��ǰָ����EX�׶�
		//Ĭ��forward=2'b00
		//���RegWriteM��Ϊ0��˵����һ��ָ���ʱ��MEM�׶Σ���ALU���Ҫд�ؼĴ���----���1----forward=2'b01
		//���RegWriteW��Ϊ0��˵������һ��ָ���ʱ��WB�׶Σ��ķô���Ҫд�ؼĴ���----���2----forward=2'b11
		//Ӧ��ע�⡣ĳЩָ��д0�żĴ��������ǲ������õģ�Ҳ������forward
		//Forward Register Source 1
		Forward1E[0] <= RdW != 0 && |RegWriteW && RegReadE[1] && (RdW == Rs1E) && ~(|RegWriteM && RegReadE[1] && (RdM == Rs1E));//���������ָ��д��λ����Rs1E������ָ��Ҳ�ǣ���Ӧ��ȡ����ָ��д��ֵ
		Forward1E[1] <= RdM != 0 && |RegWriteM && RegReadE[1] && (RdM == Rs1E);
		//Forward Register Source 2
		Forward2E[0] <= RdW != 0 && |RegWriteW && RegReadE[0] && (RdW == Rs2E) && ~(|RegWriteM && RegReadE[0] && (RdM == Rs2E));//���������ָ��д��λ����Rs2E������ָ��Ҳ�ǣ���Ӧ��ȡ����ָ��д��ֵ
		Forward2E[1] <= RdM != 0 && |RegWriteM && RegReadE[0] && (RdM == Rs2E);
	end
    // 请补全此处代�?
   
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

  