
//`define LRU 1
module cache #(
    parameter  LINE_ADDR_LEN = 3, // line�ڵ�ַ���ȣ�������ÿ��line����2^3��word
    parameter  SET_ADDR_LEN  = 3, // ���ַ���ȣ�������һ����2^3=8��
    parameter  TAG_ADDR_LEN  = 7, // tag����
    parameter  WAY_CNT       = 4  // �������ȣ�������ÿ�����ж���·line��������ֱ��ӳ����cache����˸ò���û�õ�
)(
    input  clk, rst,
    output miss,               // ��CPU������miss�ź�
    input  [31:0] addr,        // ��д�����ַ
    input  rd_req,             // �������ź�
    output reg [31:0] rd_data, // ���������ݣ�һ�ζ�һ��word
    input  wr_req,             // д�����ź�
    input  [31:0] wr_data      // Ҫд������ݣ�һ��дһ��word
);

localparam MEM_ADDR_LEN    = TAG_ADDR_LEN + SET_ADDR_LEN ; // ���������ַ���� MEM_ADDR_LEN�������С=2^MEM_ADDR_LEN��line
localparam UNUSED_ADDR_LEN = 32 - TAG_ADDR_LEN - SET_ADDR_LEN - LINE_ADDR_LEN - 2 ;       // ����δʹ�õĵ�ַ�ĳ���

localparam LINE_SIZE       = 1 << LINE_ADDR_LEN  ;         // ���� line �� word ���������� 2^LINE_ADDR_LEN ��word ÿ line
localparam SET_SIZE        = 1 << SET_ADDR_LEN   ;         // ����һ���ж����飬�� 2^SET_ADDR_LEN ����

reg [            31:0] cache_mem    [SET_SIZE][WAY_CNT][LINE_SIZE]; // SET_SIZE���飬ÿ��WAY_CNT��line��ÿ��line��LINE_SIZE��word
reg [TAG_ADDR_LEN-1:0] cache_tags   [SET_SIZE][WAY_CNT];            // SET_SIZE��TAG,ÿ��WAY_CNT��TAG
reg                    valid        [SET_SIZE][WAY_CNT];            // SET_SIZE��valid(��Чλ),ÿ��WAY_CNT��valid(��Чλ)
reg                    dirty        [SET_SIZE][WAY_CNT];            // SET_SIZE��dirty(��λ),ÿ��WAY_CNT��dirty(��λ)


wire [              2-1:0]   word_addr;                   // �������ַaddr��ֳ���5������
wire [  LINE_ADDR_LEN-1:0]   line_addr;
wire [   SET_ADDR_LEN-1:0]    set_addr;
wire [   TAG_ADDR_LEN-1:0]    tag_addr;
wire [UNUSED_ADDR_LEN-1:0] unused_addr;

enum  {IDLE, SWAP_OUT, SWAP_IN, SWAP_IN_OK} cache_stat;    // cache ״̬����״̬����
                                                           // IDLE���������SWAP_OUT�������ڻ�����SWAP_IN�������ڻ��룬SWAP_IN_OK����������һ���ڵ�д��cache������

reg  [   SET_ADDR_LEN-1:0] mem_rd_set_addr = 0;
reg  [   TAG_ADDR_LEN-1:0] mem_rd_tag_addr = 0;
wire [   MEM_ADDR_LEN-1:0] mem_rd_addr = {mem_rd_tag_addr, mem_rd_set_addr};
reg  [   MEM_ADDR_LEN-1:0] mem_wr_addr = 0;

reg  [31:0] mem_wr_line [LINE_SIZE];
wire [31:0] mem_rd_line [LINE_SIZE];

wire mem_gnt;      // ������Ӧ��д�������ź�

assign {unused_addr, tag_addr, set_addr, line_addr, word_addr} = addr;  // ��� 32bit ADDR


reg cache_hit = 1'b0;
integer hit_way=-1;//��һ·������
always @ (*) begin              // �ж� �����address �Ƿ��� cache ������
    for(integer way = 0; way < WAY_CNT; way++)
		if(valid[set_addr][way] && cache_tags[set_addr][way] == tag_addr)   // ��� cache line��Ч������tag�������ַ�е�tag��ȣ�������
			begin
				cache_hit = 1'b1;
				hit_way = way;
				break;//�����˳�ѭ��
			end
		else
			begin
				cache_hit = 1'b0;
				hit_way = -1;
			end
end

integer swap_way[SET_SIZE];//(ÿ����)(��һ��)���л���/������·

`ifdef LRU
integer way_time[SET_SIZE][WAY_CNT];
integer long_time_way;
integer long_time;
`endif

always @ (posedge clk or posedge rst) begin     // ?? cache ???
    if(rst) begin
        cache_stat <= IDLE;
        for(integer i = 0; i < SET_SIZE; i++) begin
			swap_way[i] <= 0;//��ʼ��
			for(integer j = 0; j < WAY_CNT; j++) 
			begin
				dirty[i][j] = 1'b0;
				valid[i][j] = 1'b0;
`ifdef LRU
				way_time[i][j] <= 0;
`endif			
			end
		end
        for(integer k = 0; k < LINE_SIZE; k++)
            mem_wr_line[k] <= 0;
        mem_wr_addr <= 0;
        {mem_rd_tag_addr, mem_rd_set_addr} <= 0;
        rd_data <= 0;
`ifdef LRU
		long_time <= 0;
		long_time_way <= 0;
`endif
    end else begin
        case(cache_stat)
        IDLE:       begin
                        if(cache_hit) begin
                            if(rd_req) begin    // ���cache���У������Ƕ�����
                                rd_data <= cache_mem[set_addr][hit_way][line_addr];   //��ֱ�Ӵ�cache��ȡ��Ҫ��������
                            end else if(wr_req) begin // ���cache���У�������д����
                                cache_mem[set_addr][hit_way][line_addr] <= wr_data;   // ��ֱ����cache��д������
                                dirty[set_addr][hit_way] <= 1'b1;                     // д���ݵ�ͬʱ����λ
                            end



`ifdef LRU							
							if(rd_req | wr_req) 
							begin//���¸�wayʱ�䣬������һ���滻Ӧ��ѡ���way
								for(integer way = 0; way < WAY_CNT; way++)
									if(way == hit_way)
										way_time[set_addr][way] <= 0;//����ʱ�����
									else
										way_time[set_addr][way] <= way_time[set_addr][way] + 1;//����ʱ���1
								for(integer way = 0; way < WAY_CNT; way++)
									if(way_time[set_addr][way] > long_time) begin//�����ʱ�估�ʱ��δʹ��·
										long_time = way_time[set_addr][way];
										long_time_way = way;
									end
								swap_way[set_addr] <= long_time_way;//�����´�Ҫ������·
								long_time_way <= 0;
							end
`endif



                        end else begin
                            if(wr_req | rd_req) begin   // ��� cache δ���У������ж�д��������Ҫ���л���
                                if(valid[set_addr][swap_way[set_addr]] & dirty[set_addr][swap_way[set_addr]]) begin    // ��� Ҫ�����cache line ������Ч�����࣬����Ҫ�Ƚ�������
                                    cache_stat  <= SWAP_OUT;
                                    mem_wr_addr <= {cache_tags[set_addr][swap_way[set_addr]], set_addr};
                                    mem_wr_line <= cache_mem[set_addr][swap_way[set_addr]];
                                end else begin                                   // ��֮������Ҫ������ֱ�ӻ���
                                    cache_stat  <= SWAP_IN;
                                end
                                {mem_rd_tag_addr, mem_rd_set_addr} <= {tag_addr, set_addr};
                            end
                        end
                    end
        SWAP_OUT:   begin
                        if(mem_gnt) begin           // ������������ź���Ч��˵�������ɹ���������һ״̬
                            cache_stat <= SWAP_IN;
                        end
                    end
        SWAP_IN:    begin
                        if(mem_gnt) begin           // ������������ź���Ч��˵������ɹ���������һ״̬
                            cache_stat <= SWAP_IN_OK;
                        end
                    end
        SWAP_IN_OK: begin           // ��һ�����ڻ���ɹ��������ڽ����������lineд��cache��������tag���ø�valid���õ�dirty
                        for(integer i=0; i<LINE_SIZE; i++)  
							cache_mem[mem_rd_set_addr][swap_way[mem_rd_set_addr]][i] <= mem_rd_line[i];
                        cache_tags[mem_rd_set_addr][swap_way[mem_rd_set_addr]] <= mem_rd_tag_addr;
                        valid     [mem_rd_set_addr][swap_way[mem_rd_set_addr]] <= 1'b1;
                        dirty     [mem_rd_set_addr][swap_way[mem_rd_set_addr]] <= 1'b0;
                        cache_stat <= IDLE;        // �ص�����״̬
                    
`ifdef LRU
					for(integer way = 0; way < WAY_CNT; way++)//���¸�way���䣬������һ���滻Ӧ��ѡ���way
						if(way == hit_way)
							way_time[mem_rd_set_addr][way] <= 0;
						else
							way_time[mem_rd_set_addr][way] <= way_time[mem_rd_set_addr][way] + 1;
					for(integer way = 0; way < WAY_CNT; way++)
						if(way_time[mem_rd_set_addr][way] > long_time) begin
							long_time = way_time[mem_rd_set_addr][way];
							long_time_way = way;
						end
					swap_way[mem_rd_set_addr] <= long_time_way;
					long_time_way <= 0;
`else
					if(swap_way[mem_rd_set_addr] == WAY_CNT - 1)//���뵽���һ·���´λ����ľ��ǵ�һ·
						swap_way[mem_rd_set_addr] <= 0;
					else
						swap_way[mem_rd_set_addr] <= swap_way[mem_rd_set_addr] + 1;
`endif					
					
					
					end
        endcase
    end
end

wire mem_rd_req = (cache_stat == SWAP_IN );
wire mem_wr_req = (cache_stat == SWAP_OUT);
wire [   MEM_ADDR_LEN-1 :0] mem_addr = mem_rd_req ? mem_rd_addr : ( mem_wr_req ? mem_wr_addr : 0);

assign miss = (rd_req | wr_req) & ~(cache_hit && cache_stat==IDLE) ;     // �� �ж�д����ʱ�����cache�����ھ���(IDLE)״̬������δ���У���miss=1

main_mem #(     // ���棬ÿ�ζ�д��line Ϊ��λ
    .LINE_ADDR_LEN  ( LINE_ADDR_LEN          ),
    .ADDR_LEN       ( MEM_ADDR_LEN           )
) main_mem_instance (
    .clk            ( clk                    ),
    .rst            ( rst                    ),
    .gnt            ( mem_gnt                ),
    .addr           ( mem_addr               ),
    .rd_req         ( mem_rd_req             ),
    .rd_line        ( mem_rd_line            ),
    .wr_req         ( mem_wr_req             ),
    .wr_line        ( mem_wr_line            )
);

endmodule





