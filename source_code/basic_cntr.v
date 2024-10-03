module edge_detector_p(
        input clk, reset_p,
        input cp, //입력되는 클록펄스(그림의 btn) 
        output p_edge, n_edge); // 상승엣지에서 언사이클 펄스를 출력
        
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
                        //if의 조건문이 아닌 always문에서 사용하면 비교연산자가 아니라 개형문자,,? 로 사용
                        // 화살표쓰면 넌블로킹문(위에 실행되고 밑에 실행됨),,,,, 이퀄쓰면 블로킹문 (위에실행되면 밑에 실행안함)
                 end
         end
         assign p_edge = ({ff_cur, ff_old} ==2'b10) ? 1 : 0;
         assign n_edge = ({ff_cur, ff_old} ==2'b01) ? 1 : 0;
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//하강엣지 디텍터\
module edge_detector_n(
        input clk, reset_p,
        input cp, //입력되는 클록펄스(그림의 btn) 
        output p_edge, n_edge); // 상승엣지에서 언사이클 펄스를 출력
        
        reg ff_cur, ff_old; //
        always @(negedge clk or posedge reset_p)begin
                if(reset_p)begin
                        ff_cur <=0;
                        ff_old <=0;
                end
                else begin             
                        ff_cur <= cp;
                        ff_old <= ff_cur;
                        //if의 조건문이 아닌 always문에서 사용하면 비교연산자가 아니라 개형문자,,? 로 사용
                        // 화살표쓰면 넌블로킹문(위에 실행되고 밑에 실행됨),,,,, 이퀄쓰면 블로킹문 (위에실행되면 밑에 실행안함)
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
            edge_detector_p        ed( .clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge)); //보통 1ms 안에서 체터ㅋ링이 끝남
            
            reg debounced_btn;
            always @(posedge clk or posedge reset_p) begin
                    if(reset_p)debounced_btn =0;
                    else if(clk_div_nedge) debounced_btn =btn;
            end
            
            edge_detector_p        ed1(.clk(clk), .reset_p(reset_p), .cp(debounced_btn), .n_edge( btn_nedge), .p_edge( btn_pedge));
endmodule   

//////////////////////////////////////////////////////////////////////////////////
// t플립플롭 파지티브 모델링
module T_flip_flop_p(
            input clk, reset_p,
            input t,
            output reg q);
            
            always @(posedge clk or posedge reset_p)begin
                    if(reset_p)q=0;         //reset이 1이면 출력없음
                    else begin
                            if(t) q=~q;         //t가 1이면 토글
                            else q=q;       //t가 0이면 현재값 유지, 플립플롭에서는 생략할 수 있음
                     end
             end
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//10 분주기 인스턴스 만들기
module clock_div_10(
            input clk, reset_p,
            input clk_source, 
            output clk_div_10,
            output clk_div_10_nedge);
            
            reg [3:0] cnt_clksource;   //10분주를 하기 위함
            //integer cnt_clksource;   //위와 동일
             
            wire clk_source_nedge;
            
             edge_detector_n    ed_source( .clk(clk), .reset_p(reset_p), . cp(clk_source), .n_edge(clk_source_nedge));   //1us 마다 엣지디텍터 발생
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_clksource = 0;
                    else if(clk_source_nedge)begin
                            if(cnt_clksource>=9)  cnt_clksource = 0;
                            else cnt_clksource = cnt_clksource +1;  //1씩 증가하는 카운터
                    end
             end
             
             assign clk_div_10 = (cnt_clksource <5) ? 0:1;
             
             edge_detector_n ed( .clk(clk), .reset_p(reset_p), . cp(clk_div_10), .n_edge(clk_div_10_nedge));                    
endmodule  


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//sysclk 100분주
//시간을 다루다,,, 실습보드는 클락이 10ns 주파수는 100메가
// 100개로 분주하면 1us 클락을 만들 수 있음. (카운터로 타이머 만들기~)
module clock_div_100(
            input clk, reset_p,
            output clk_div_100,
            output clk_div_100_nedge);
            
            reg [6:0] cnt_sysclk;
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_sysclk = 0;
                    else begin
                            if(cnt_sysclk>=99)  cnt_sysclk = 0;
                            else cnt_sysclk = cnt_sysclk +1;  //1씩 증가하는 카운터
                    end
             end
             
             assign clk_div_100 = (cnt_sysclk <50) ? 0:1;   // 1us 동안 1주기가 발생하는 clk_dic_100 설정
             // 50번동안 0, 50번동안 1, 총 100번 주기, 1회는 10ns 100번 반복하면 1000ns = 1us
             // 1us 마다 언사이클펄스 만들기(엣지디텍터)
             
             edge_detector_n ed( //엣지디텍터 인스턴스 가져오기
                    .clk(clk), .reset_p(reset_p), . cp(clk_div_100),
                   .n_edge(clk_div_100_nedge));   
                  
endmodule


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module clock_div_1000(
            input clk, reset_p,
            input clk_source, //1us
            output clk_div_1000,
            output clk_div_1000_nedge);
            
            reg [9:0] cnt_clksource;   //1000분주를 하기 위함
            
            wire clk_source_nedge;
            
             edge_detector_n ed_source( //엣지디텍터 인스턴스 가져오기
                    .clk(clk), .reset_p(reset_p), . cp(clk_source),
                   .n_edge(clk_source_nedge));   //1us 마다 엣지디텍터 발생
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_clksource = 0;
                    else if(clk_source_nedge)begin // 엣지티텍터가 발생할때 마다 if문이 실행 즉 1us 마다 cnt_clksource증가
                            if(cnt_clksource>=999)  cnt_clksource = 0;
                            else cnt_clksource = cnt_clksource +1;  //1씩 증가하는 카운터
                    end
             end  // 즉 , 1us 마다 1000개를 카운트 하기에 1000us = 1ms
             
             assign clk_div_1000 = (cnt_clksource <500) ? 0:1;   // 1ms 동안 1주기가 발생하는 clk_div_100 설정
             // 50번동안 0, 50번동안 1, 총 100번 주기, 1회는 1us 1000번 반복하면 1000us = 1ms
             // 1ms 마다 언사이클펄스 만들기(엣지디텍터)
             
             edge_detector_n ed( //엣지디텍터 인스턴스 가져오기
                    .clk(clk), .reset_p(reset_p), . cp(clk_div_1000),
                   .n_edge(clk_div_1000_nedge));                    
endmodule 


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//60 분주기 인스턴스 만들기
module clock_div_60(
            input clk, reset_p,
            input clk_source, //1분 카운트하기 위해서는 1초를 소스로 줘야함
            output clk_div_60,
            output clk_div_60_nedge);
            
            reg [9:0] cnt_clksource;   //1000분주를 하기 위함
            //integer cnt_clksource;   //위와 동일
             
            wire clk_source_nedge;
            
             edge_detector_n ed_source( //엣지디텍터 인스턴스 가져오기
                    .clk(clk), .reset_p(reset_p), . cp(clk_source),
                   .n_edge(clk_source_nedge));   //1us 마다 엣지디텍터 발생
            
            always @(negedge clk or posedge reset_p) begin
                    if(reset_p) cnt_clksource = 0;
                    else if(clk_source_nedge)begin
                            if(cnt_clksource>=59)  cnt_clksource = 0;
                            else cnt_clksource = cnt_clksource +1;  //1씩 증가하는 카운터
                    end
             end
             
             assign clk_div_60 = (cnt_clksource <30) ? 0:1;
             
             edge_detector_n ed(
                    .clk(clk), .reset_p(reset_p), . cp(clk_div_60),
                   .n_edge(clk_div_60_nedge));                    
endmodule  

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//시계만들기 카운터 인스턴스 만들기 reset우선
module counter_bcd_60(
            input clk, reset_p,
            input clk_time,
            output reg [3:0] bcd1, bcd10); //십의 자리와 일의 자리를 따로 출력
            
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
//ㅣloadable counter,,,, 동기 맞추기,,? 로드 가 가능   //reset우선과 반대개념
module loadable_counter_bcd_60(
            input clk, reset_p,
            input clk_time,
            input load_enable,
            input  [3:0] load_bcd1, load_bcd10,
            output reg [3:0] bcd1, bcd10); //십의 자리와 일의 자리를 따로 출력
            
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
//ㅣloadable counter down(240719)
module loadable_down_counter_bcd_60(
            input clk, reset_p,
            input clk_time,
            input load_enable,
            input  [3:0] load_bcd1, load_bcd10,
            output reg [3:0] bcd1, bcd10,
             output reg dec_clk); //십의 자리와 일의 자리를 따로 출력
            
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
                else dec_clk =0;  // 여기다가 놓으면 엣지디텍더 없어도 원사이클 펄스가 된다.
             end
       end
endmodule
 

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//타이머를 클리어하기 위한 클리어 60진 카운터
module counter_bcd_60_clear(
            input clk, reset_p,
            input clk_time,
            input clear,
            output reg [3:0] bcd1, bcd10); //십의 자리와 일의 자리를 따로 출력
            
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
//bcd 100진 카운터
module counter_bcd_100_clear(
            input clk, reset_p,
            input clk_time,
            input clear,
            output reg [3:0] bcd1, bcd10); //십의 자리와 일의 자리를 따로 출력
            
             wire clk_time_nedge;
             edge_detector_n(.clk(clk), .reset_p(reset_p), .cp(clk_time),  .n_edge(clk_time_nedge));
            
    always @(posedge clk or posedge reset_p)begin
                    if(reset_p)begin   //reset_p 누르면 리셋된다
                        bcd1 =0;
                        bcd10 =0;
                     end
            
            else begin
                    if(clear) begin     // clear 누르면 리셋된다.
                            bcd1 =0;
                            bcd10 =0;
                     end
                     
                    else if(clk_time_nedge) begin     // 클럭타임의 엣지에서 동작
                            if(bcd1>=9) begin
                                   bcd1 =0;
                                   if(bcd10>=9) bcd10 =0;
                                   else bcd10 = bcd10 +1;     //10의 자리수 출력
                            end
                            else bcd1 = bcd1 + 1;     //1의 자리수 출력
                    end
            end
       end
 endmodule
 


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fnd_cntr라는 이름으로 인스턴스 만들기
module fnd_cntr(
            input clk, reset_p,
            input [15:0] value,
            output [3:0] com,       //공통에노드
            output [7:0] seg_7);  //세그먼트
            
            ring_counter_fnd        rc( clk, reset_p,com);  //인스턴스명이 없으면 알아서 이름붙여둠
            
            reg [3:0] hex_value;
            always @(posedge clk)begin
                    case(com)
                            4'b1110: hex_value = value[3:0];
                            4'b1101: hex_value = value[7:4];
                            4'b1011: hex_value = value[11:8];
                            4'b0111: hex_value = value[15:12];
                     endcase 
              end
                     
            decoder_7seg(.hex_value(hex_value),.seg_7(seg_7)); //4비트 2진수로 헥사값 표현
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FPGA 실습 (f커먼 에노드 링 카운터)
module ring_counter_fnd(    
        input clk, reset_p,
        output reg [3:0] com);
        
        reg [20:0] clk_div =0; //회로상으로는 구현이 안되지만 시뮬레이션 할때만 사용
        always @(posedge clk) clk_div = clk_div +1;
        
        wire clk_div_nedge;
        edge_detector_p ed( .clk(clk), .reset_p(reset_p), .cp(clk_div[16]), .n_edge(clk_div_nedge));  //약 1ms로 분주하기
        //1ms 동안 시프트된다, 우리 눈에는 깜빡이는게 보이지는 않는다.
        
        always @(posedge clk or posedge reset_p) begin
                if(reset_p) com = 4'b1110;
                else if(clk_div_nedge)begin
                        if(com == 4'b0111)  com = 4'b1110;
                        else  com[3:0] = {com[2:0], 1'b1};
                end
        end
 endmodule
 
 ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 세그먼트 16진수 할당
module decoder_7seg(
           input [3:0] hex_value,
           output reg [7:0] seg_7);
           
           always @(hex_value)begin
                    case(hex_value)   //abcd_efgp
                           0 : seg_7 = 8'b0000_0011; //fnd에 0 표시
                           1 : seg_7 = 8'b1001_1111; //fnd에 1 표시
                           2 : seg_7 = 8'b0010_0101; //fnd에 2 표시
                           3 : seg_7 = 8'b0000_1101; //fnd에 3 표시
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


 

