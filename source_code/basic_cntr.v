module edge_detector_p(
        input clk, reset_p,
        input cp, //�ԷµǴ� Ŭ���޽�(�׸��� btn) 
        output p_edge, n_edge); // ��¿������� �����Ŭ �޽��� ���
        
        reg ff_cur, ff_old; //
        always @(posedge clk or posedge reset_p)begin
                if(reset_p)begin
                        ff_cur <=0;
                        ff_old <=0;
                end
                else begin
                        //ff_old = ff_cur;
                        //ff_cur = cp;                    
                        //ff_cur = cp;
                        //ff_old = ff_cur;               
                        ff_cur <= cp;
                        ff_old <= ff_cur;
                        //if�� ���ǹ��� �ƴ� always������ ����ϸ� �񱳿����ڰ� �ƴ϶� ��������,,? �� ���
                        // ȭ��ǥ���� �ͺ��ŷ��(���� ����ǰ� �ؿ� �����),,,,, �������� ���ŷ�� (��������Ǹ� �ؿ� �������)
                 end
         end
         assign p_edge = ({ff_cur, ff_old} ==2'b10) ? 1 : 0;
         assign n_edge = ({ff_cur, ff_old} ==2'b01) ? 1 : 0;
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//�ϰ����� ������\
module edge_detector_n(
        input clk, reset_p,
        input cp, //�ԷµǴ� Ŭ���޽�(�׸��� btn) 
        output p_edge, n_edge); // ��¿������� �����Ŭ �޽��� ���
        
        reg ff_cur, ff_old; //
        always @(negedge clk or posedge reset_p)begin
                if(reset_p)begin
                        ff_cur <=0;
                        ff_old <=0;
                end
                else begin             
                        ff_cur <= cp;
                        ff_old <= ff_cur;
                        //if�� ���ǹ��� �ƴ� always������ ����ϸ� �񱳿����ڰ� �ƴ϶� ��������,,? �� ���
                        // ȭ��ǥ���� �ͺ��ŷ��(���� ����ǰ� �ؿ� �����),,,,, �������� ���ŷ�� (��������Ǹ� �ؿ� �������)
                 end
         end
         assign p_edge = ({ff_cur, ff_old} ==2'b10) ? 1 : 0;
         assign n_edge = ({ff_cur, ff_old} ==2'b01) ? 1 : 0;         
endmodule

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
module button_cntr(
            input clk, reset_p,
            input btn,
            output btn_nedge, btn_pedge);
            
            reg [20:0] clk_div =0;
            always @(posedge clk) clk_div = clk_div +1;
            
            wire clk_div_nedge;
            edge_detector_p        ed( .clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge)); //���� 1ms �ȿ��� ü�ͤ����� ����
            
            reg debounced_btn;
            always @(posedge clk or posedge reset_p) begin
                    if(reset_p)debounced_btn =0;
                    else if(clk_div_nedge) debounced_btn =btn;
            end
            
            edge_detector_p        ed1(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .n_edge( btn_nedge), .p_edge( btn_pedge));
endmodule   

//////////////////////////////////////////////////////////////////////////////////
// t�ø��÷� ����Ƽ�� �𵨸�
module T_flip_flop_p(
            input clk, reset_p,
            input t,
            output reg q);
            
            always @(posedge clk or posedge reset_p)begin
                    if(reset_p)q=0;         //reset�� 1�̸� ��¾���
                    else begin
                            if(t) q=~q;         //t�� 1�̸� ���
                            else q=q;       //t�� 0�̸� ���簪 ����, �ø��÷ӿ����� ������ �� ����
                     end
             end
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//10 ���ֱ� �ν��Ͻ� �����
module clock_div_10(
            input clk, reset_p,
            input clk_source, 
            output clk_div_10,
            output clk_div_10_nedge);
            
            reg [3:0] cnt_clksource;   //10���ָ� �ϱ� ����
            //integer cnt_clksource;   //���� ����
             
            wire clk_source_nedge;
            
             edge_detector_n    ed_source( .clk(clk), .reset_p(reset_p), . cp(clk_source), .n_edge(clk_source_nedge));   //1us ���� ���������� �߻�
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_clksource = 0;
                    else if(clk_source_nedge)begin
                            if(cnt_clksource>=9)  cnt_clksource = 0;
                            else cnt_clksource = cnt_clksource +1;  //1�� �����ϴ� ī����
                    end
             end
             
             assign clk_div_10 = (cnt_clksource <5) ? 0:1;
             
             edge_detector_n ed( .clk(clk), .reset_p(reset_p), . cp(clk_div_10), .n_edge(clk_div_10_nedge));                    
endmodule  


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//sysclk 100����
//�ð��� �ٷ��,,, �ǽ������ Ŭ���� 10ns ���ļ��� 100�ް�
// 100���� �����ϸ� 1us Ŭ���� ���� �� ����. (ī���ͷ� Ÿ�̸� �����~)
module clock_div_100(
            input clk, reset_p,
            output clk_div_100,
            output clk_div_100_nedge);
            
            reg [6:0] cnt_sysclk;
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_sysclk = 0;
                    else begin
                            if(cnt_sysclk>=99)  cnt_sysclk = 0;
                            else cnt_sysclk = cnt_sysclk +1;  //1�� �����ϴ� ī����
                    end
             end
             
             assign clk_div_100 = (cnt_sysclk <50) ? 0:1;   // 1us ���� 1�ֱⰡ �߻��ϴ� clk_dic_100 ����
             // 50������ 0, 50������ 1, �� 100�� �ֱ�, 1ȸ�� 10ns 100�� �ݺ��ϸ� 1000ns = 1us
             // 1us ���� �����Ŭ�޽� �����(����������)
             
             edge_detector_n ed( //���������� �ν��Ͻ� ��������
                    .clk(clk), .reset_p(reset_p), . cp(clk_div_100),
                   .n_edge(clk_div_100_nedge));   
                  
endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module clock_div_1000(
            input clk, reset_p,
            input clk_source, //1us
            output clk_div_1000,
            output clk_div_1000_nedge);
            
            reg [9:0] cnt_clksource;   //1000���ָ� �ϱ� ����
            
            wire clk_source_nedge;
            
             edge_detector_n ed_source( //���������� �ν��Ͻ� ��������
                    .clk(clk), .reset_p(reset_p), . cp(clk_source),
                   .n_edge(clk_source_nedge));   //1us ���� ���������� �߻�
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_clksource = 0;
                    else if(clk_source_nedge)begin // ����Ƽ���Ͱ� �߻��Ҷ� ���� if���� ���� �� 1us ���� cnt_clksource����
                            if(cnt_clksource>=999)  cnt_clksource = 0;
                            else cnt_clksource = cnt_clksource +1;  //1�� �����ϴ� ī����
                    end
             end  // �� , 1us ���� 1000���� ī��Ʈ �ϱ⿡ 1000us = 1ms
             
             assign clk_div_1000 = (cnt_clksource <500) ? 0:1;   // 1ms ���� 1�ֱⰡ �߻��ϴ� clk_div_100 ����
             // 50������ 0, 50������ 1, �� 100�� �ֱ�, 1ȸ�� 1us 1000�� �ݺ��ϸ� 1000us = 1ms
             // 1ms ���� �����Ŭ�޽� �����(����������)
             
             edge_detector_n ed( //���������� �ν��Ͻ� ��������
                    .clk(clk), .reset_p(reset_p), . cp(clk_div_1000),
                   .n_edge(clk_div_1000_nedge));                    
endmodule 


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//60 ���ֱ� �ν��Ͻ� �����
module clock_div_60(
            input clk, reset_p,
            input clk_source, //1�� ī��Ʈ�ϱ� ���ؼ��� 1�ʸ� �ҽ��� �����
            output clk_div_60,
            output clk_div_60_nedge);
            
            reg [9:0] cnt_clksource;   //1000���ָ� �ϱ� ����
            //integer cnt_clksource;   //���� ����
             
            wire clk_source_nedge;
            
             edge_detector_n ed_source( //���������� �ν��Ͻ� ��������
                    .clk(clk), .reset_p(reset_p), . cp(clk_source),
                   .n_edge(clk_source_nedge));   //1us ���� ���������� �߻�
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_clksource = 0;
                    else if(clk_source_nedge)begin
                            if(cnt_clksource>=59)  cnt_clksource = 0;
                            else cnt_clksource = cnt_clksource +1;  //1�� �����ϴ� ī����
                    end
             end
             
             assign clk_div_60 = (cnt_clksource <30) ? 0:1;
             
             edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), . cp(clk_div_60),
                   .n_edge(clk_div_60_nedge));                    
endmodule  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//�ð踸��� ī���� �ν��Ͻ� ����� reset�켱
module counter_bcd_60(
            input clk, reset_p,
            input clk_time,
            output reg [3:0] bcd1, bcd10); //���� �ڸ��� ���� �ڸ��� ���� ���
            
             wire clk_time_nedge;
             edge_detector_n(.clk(clk), .reset_p(reset_p), .cp(clk_time),  .n_edge(clk_time_nedge));
            
    always @(posedge clk or posedge reset_p)begin
                    if(reset_p)begin
                        bcd1 =0;
                        bcd10 =0;
                     end
            
            else if(clk_time_nedge) begin
                    if(bcd1>=9) begin
                           bcd1 =0;
                           if(bcd10>=5) bcd10 =0;
                           else bcd10 = bcd10 +1;
                    end
                    else bcd1 = bcd1 + 1;
             end
       end
endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//��loadable counter,,,, ���� ���߱�,,? �ε� �� ����   //reset�켱�� �ݴ밳��
module loadable_counter_bcd_60(
            input clk, reset_p,
            input clk_time,
            input load_enable,
            input  [3:0] load_bcd1, load_bcd10,
            output reg [3:0] bcd1, bcd10); //���� �ڸ��� ���� �ڸ��� ���� ���
            
             wire clk_time_nedge;
             edge_detector_n        ed_clk      (.clk(clk), .reset_p(reset_p), .cp(clk_time),  .n_edge(clk_time_nedge));
            
    always @(posedge clk or posedge reset_p)begin
                    if(reset_p)begin
                        bcd1 =0;
                        bcd10 =0;
                     end
            
            else begin
                if(load_enable)begin
                        bcd1 = load_bcd1;
                        bcd10 = load_bcd10;
                end
                
                else if(clk_time_nedge) begin
                    if(bcd1>=9) begin
                           bcd1 =0;
                           if(bcd10>=5) bcd10 =0;
                           else bcd10 = bcd10 +1;
                    end
                    else bcd1 = bcd1 + 1;
                end
             end
       end
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//��loadable counter down(240719)
module loadable_down_counter_bcd_60(
            input clk, reset_p,
            input clk_time,
            input load_enable,
            input  [3:0] load_bcd1, load_bcd10,
            output reg [3:0] bcd1, bcd10,
             output reg dec_clk); //���� �ڸ��� ���� �ڸ��� ���� ���
            
             wire clk_time_nedge;
             edge_detector_n        ed_clk      (.clk(clk), .reset_p(reset_p), .cp(clk_time),  .n_edge(clk_time_nedge));
            
    always @(posedge clk or posedge reset_p)begin
                    if(reset_p)begin
                        bcd1 =0;
                        bcd10 =0;
                        dec_clk =1;
                     end
            
            else begin
                if(load_enable)begin
                        bcd1 = load_bcd1;
                        bcd10 = load_bcd10;
                end
                
                else if(clk_time_nedge) begin
                    if(bcd1==0) begin
                           bcd1 =9;
                           if(bcd10==0) begin
                                    bcd10 =5;
                                    dec_clk =1;
                           end
                           else bcd10 = bcd10 - 1;
                    end
                    else bcd1 = bcd1 - 1;
                end
                else dec_clk =0;  // ����ٰ� ������ �������ش� ��� ������Ŭ �޽��� �ȴ�.
             end
       end
endmodule
 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Ÿ�̸Ӹ� Ŭ�����ϱ� ���� Ŭ���� 60�� ī����
module counter_bcd_60_clear(
            input clk, reset_p,
            input clk_time,
            input clear,
            output reg [3:0] bcd1, bcd10); //���� �ڸ��� ���� �ڸ��� ���� ���
            
             wire clk_time_nedge;
             edge_detector_n(.clk(clk), .reset_p(reset_p), .cp(clk_time),  .n_edge(clk_time_nedge));
            
    always @(posedge clk or posedge reset_p)begin
                    if(reset_p)begin
                        bcd1 =0;
                        bcd10 =0;
                     end
                     
            else begin
                    if(clear) begin
                            bcd1 =0;
                            bcd10 =0;
                     end
                     
                    else if(clk_time_nedge) begin
                            if(bcd1>=9) begin
                                   bcd1 =0;
                                   if(bcd10>=5) bcd10 =0;
                                   else bcd10 = bcd10 +1;
                            end
                            else bcd1 = bcd1 + 1;
                     end
              end
       end
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//bcd 100�� ī����
module counter_bcd_100_clear(
            input clk, reset_p,
            input clk_time,
            input clear,
            output reg [3:0] bcd1, bcd10); //���� �ڸ��� ���� �ڸ��� ���� ���
            
             wire clk_time_nedge;
             edge_detector_n(.clk(clk), .reset_p(reset_p), .cp(clk_time),  .n_edge(clk_time_nedge));
            
    always @(posedge clk or posedge reset_p)begin
                    if(reset_p)begin   //reset_p ������ ���µȴ�
                        bcd1 =0;
                        bcd10 =0;
                     end
            
            else begin
                    if(clear) begin     // clear ������ ���µȴ�.
                            bcd1 =0;
                            bcd10 =0;
                     end
                     
                    else if(clk_time_nedge) begin     // Ŭ��Ÿ���� �������� ����
                            if(bcd1>=9) begin
                                   bcd1 =0;
                                   if(bcd10>=9) bcd10 =0;
                                   else bcd10 = bcd10 +1;     //10�� �ڸ��� ���
                            end
                            else bcd1 = bcd1 + 1;     //1�� �ڸ��� ���
                    end
            end
       end
 endmodule
 


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fnd_cntr��� �̸����� �ν��Ͻ� �����
module fnd_cntr(
            input clk, reset_p,
            input [15:0] value,
            output [3:0] com,       //���뿡���
            output [7:0] seg_7);  //���׸�Ʈ
            
            ring_counter_fnd        rc( clk, reset_p,com);  //�ν��Ͻ����� ������ �˾Ƽ� �̸��ٿ���
            
            reg [3:0] hex_value;
            always @(posedge clk)begin
                    case(com)
                            4'b1110: hex_value = value[3:0];
                            4'b1101: hex_value = value[7:4];
                            4'b1011: hex_value = value[11:8];
                            4'b0111: hex_value = value[15:12];
                     endcase 
              end
                     
            decoder_7seg(.hex_value(hex_value),.seg_7(seg_7)); //4��Ʈ 2������ ��簪 ǥ��
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FPGA �ǽ� (fĿ�� ����� �� ī����)
module ring_counter_fnd(    
        input clk, reset_p,
        output reg [3:0] com);
        
        reg [20:0] clk_div =0; //ȸ�λ����δ� ������ �ȵ����� �ùķ��̼� �Ҷ��� ���
        always @(posedge clk) clk_div = clk_div +1;
        
        wire clk_div_nedge;
        edge_detector_p ed( .clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));  //�� 1ms�� �����ϱ�
        //1ms ���� ����Ʈ�ȴ�, �츮 ������ �����̴°� �������� �ʴ´�.
        
        always @(posedge clk or posedge reset_p) begin
                if(reset_p) com = 4'b1110;
                else if(clk_div_nedge)begin
                        if(com == 4'b0111)  com = 4'b1110;
                        else  com[3:0] = {com[2:0], 1'b1};
                end
        end
 endmodule
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ���׸�Ʈ 16���� �Ҵ�
module decoder_7seg(
           input [3:0] hex_value,
           output reg [7:0] seg_7);
           
           always @(hex_value)begin
                    case(hex_value)   //abcd_efgp
                           0 : seg_7 = 8'b0000_0011; //fnd�� 0 ǥ��
                           1 : seg_7 = 8'b1001_1111; //fnd�� 1 ǥ��
                           2 : seg_7 = 8'b0010_0101; //fnd�� 2 ǥ��
                           3 : seg_7 = 8'b0000_1101; //fnd�� 3 ǥ��
                           4 : seg_7 = 8'b1001_1001;
                           5 : seg_7 = 8'b0100_1001;
                           6 : seg_7 = 8'b0100_0001;
                           7 : seg_7 = 8'b0001_1011;
                           8 : seg_7 = 8'b0000_0001;
                           9 : seg_7 = 8'b0000_1001;
                           10 : seg_7 = 8'b0001_0001;  //A
                           11 : seg_7 = 8'b1100_0001;  //b
                           12 : seg_7 = 8'b0110_0011; //C
                           13 : seg_7 = 8'b1000_0101; //d
                           14 : seg_7 = 8'b0110_0001; //E
                           15 : seg_7 = 8'b0111_0001; //F
                   endcase  
           end
endmodule


 

