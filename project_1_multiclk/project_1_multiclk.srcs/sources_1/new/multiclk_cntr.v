`timescale 1ns / 1ps
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//240726
module loadable_watch_top_btn_project(
            input clk, reset_p,
            input [2:0] btn,
            output [3:0] com,      
            output [7:0] seg_7,
            output [7:3] led,
            output[2:0] btn_all);  
            
            wire btn_mode, btn_sec, btn_min;
            wire set_watch;  
            wire watch_load_en, set_load_en;
            wire inc_sec, inc_min;  
            wire clk_usec, clk_msec, clk_sec, clk_min;
            wire [3:0] watch_sec1, watch_sec10, watch_min1, watch_min10;
            wire [3:0] set_sec1, set_sec10, set_min1, set_min10;
            
            assign  led [3]  = set_watch ? 0 : 1;
            assign  led [4]  = set_watch ? 1 : 0;
            
            button_cntr         btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_mode));
            button_cntr         btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_sec));
            button_cntr         btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_min));
                            
            T_flip_flop_p          t_mode       (.clk(clk), .reset_p(reset_p), .t(btn_mode), .q(set_watch));
            edge_detector_n        ed_source    (.clk(clk), .reset_p(reset_p), .cp(set_watch),  .n_edge( watch_load_en), .p_edge(set_load_en));
            
            assign inc_sec = set_watch ? btn_sec : clk_sec; 
            assign inc_min = set_watch ? btn_min : clk_min; 
            
            clock_div_100    usec_clock         (.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec));
            clock_div_1000   msec_clock         (.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));   
            clock_div_1000   sec_clock          (.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));        
            clock_div_60     min_clock          (.clk(clk), .reset_p(reset_p), .clk_source(inc_sec), .clk_div_60_nedge(clk_min));   
            
            
             loadable_counter_bcd_60       sec_watch    ( .clk(clk),.reset_p(reset_p), .clk_time(clk_sec), .load_enable(watch_load_en), 
                                                                                       .load_bcd1(set_sec1), .load_bcd10(set_sec10), .bcd1(watch_sec1), .bcd10(watch_sec10));
                                                                   
             loadable_counter_bcd_60       min_watch    ( .clk(clk),.reset_p(reset_p), .clk_time(clk_min), .load_enable(watch_load_en), 
                                                                                       .load_bcd1(set_min1), .load_bcd10(set_min10), .bcd1(watch_min1), .bcd10(watch_min10));
            
                                                                   
             loadable_counter_bcd_60       sec_set      ( .clk(clk),.reset_p(reset_p), .clk_time(btn_sec), .load_enable(set_load_en), 
                                                                                       .load_bcd1(watch_sec1), .load_bcd10(watch_sec10), .bcd1(set_sec1), .bcd10(set_sec10));                                                
            
             loadable_counter_bcd_60       min_set      ( .clk(clk),.reset_p(reset_p), .clk_time(btn_min), .load_enable(set_load_en), 
                                                                                       .load_bcd1(watch_min1), .load_bcd10(watch_min10), .bcd1(set_min1), .bcd10(set_min10)); 
            
            wire [15:0] value, watch_value, set_value;
            assign watch_value = { watch_min10, watch_min1, watch_sec10, watch_sec1};
            assign set_value = {set_min10, set_min1, set_sec10, set_sec1};
            assign value = set_watch ? set_value : watch_value;
                        
            fnd_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com),  .seg_7(seg_7));            
            
endmodule


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  240726  
module stop_watch_top_sec_csec_project(
                input clk, reset_p,
                input [2:0] btn,
                output [3:0] com,
                output [7:0] seg_7,
                output [7:3] led,
                output[2:0] btn_all);
                
                assign led[5] = led_start;
                assign led[6] = led_lap;
                
                wire clk_start,  start_stop;
                wire clk_usec, clk_msec, clk_sec, clk_csec, clk_min;
                wire btn_start, btn_clear;
                wire reset_start;
                wire btn_lap; 
                reg lap;
                wire [3:0] sec1, sec10, csec1, csec10;
                reg [15:0] lap_time; 
                wire [15:0] cur_time;
                wire [15:0] value;
                
                
                assign clk_start = start_stop ? clk :0; 
                
                clock_div_100        usec_clock      (.clk(clk_start), .reset_p(reset_start),.clk_div_100(clk_usec)); 
                clock_div_1000       msec_clock      (.clk(clk_start), .reset_p(reset_start), .clk_source(clk_usec), .clk_div_1000(clk_msec));    
                clock_div_10         csec_clock      (.clk(clk_start), .reset_p(reset_start), .clk_source(clk_msec), .clk_div_10_nedge(clk_csec));    
                clock_div_1000       sec_clock       (.clk(clk_start), .reset_p(reset_start), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));        
                clock_div_60         min_clock       (.clk(clk_start), .reset_p(reset_start), .clk_source(clk_sec), .clk_div_60_nedge(clk_min));   
               
                button_cntr         btn0(.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start));
                button_cntr         btn1(.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_lap));
                button_cntr         btn2(.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_clear));

                 assign reset_start = reset_p | btn_clear;
                 

                 T_flip_flop_p               t_start    ( .clk(clk), .reset_p(reset_start) , .t(btn_start), .q(start_stop));  //start_stop가 0이었으면 1, 1이었으면 0
                 assign led_start = start_stop;  
                
                 always @(posedge clk or posedge reset_p)begin
                    if(reset_p) lap=0;        
                    else begin
                            if(btn_lap)  lap=~lap;         
                            else if (btn_clear) lap =0;
                     end
                 end
                 
                assign led_lap = lap;  
                 
                counter_bcd_60_clear      counter_min     (.clk(clk), .reset_p(reset_p), .clear(btn_clear), .clk_time(clk_min), .bcd1(min1), .bcd10(min10));    
                counter_bcd_60_clear      counter_sec     (.clk(clk), .reset_p(reset_p), .clear(btn_clear), .clk_time(clk_sec), .bcd1(sec1), .bcd10(sec10));  
                counter_bcd_100_clear     counter_csec    (.clk(clk), .reset_p(reset_p), .clear(btn_clear), .clk_time(clk_csec), .bcd1(csec1), .bcd10(csec10));   
                
                assign cur_time = { sec10, sec1, csec10, csec1};
                always @(posedge clk or posedge reset_p)begin
                        if(reset_p) lap_time = 0;
                        else if (btn_lap) lap_time =  cur_time;
                        else if(btn_clear) lap_time =0;
                end
                 
                assign value = lap ? lap_time : cur_time;
                fnd_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com),  .seg_7(seg_7));       
endmodule

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//  240726  btn_alarm_off 외부로
module cook_timer_top_project(
                input clk, reset_p,
                input [3:0] btn,
                input btn_alarm_off,
                output [3:0] com,
                output [7:0] seg_7,
                output [7:3] led,
                output reg alarm, 
                output buzz);

                assign led [7] = led_start;
                
                wire clk_usec, clk_msec, clk_sec, clk_min;
                wire btn_start, btn_sec, btn_min;  
                wire [3:0] set_sec1, set_sec10, set_min1, set_min10;
                wire [3:0] cur_sec1, cur_sec10, cur_min1, cur_min10, dec_clk;
                reg start_set;
                wire [15:0] value, set_time, cur_time;
                
                
                clock_div_100       usec_clock      (.clk(clk), .reset_p(reset_p), .clk_div_100(clk_usec)); 
                clock_div_1000      msec_clock      (.clk(clk), .reset_p(reset_p), .clk_source(clk_usec), .clk_div_1000(clk_msec));   
                clock_div_1000      sec_clock       (.clk(clk), .reset_p(reset_p), .clk_source(clk_msec), .clk_div_1000_nedge(clk_sec));       
                clock_div_60        min_clock       (.clk(clk), .reset_p(reset_p), .clk_source(clk_sec), .clk_div_60_nedge(clk_min));   

                button_cntr         btn0            (.clk(clk), .reset_p(reset_p), .btn(btn[0]), .btn_pedge(btn_start));
                button_cntr         btn1            (.clk(clk), .reset_p(reset_p), .btn(btn[1]), .btn_pedge(btn_sec));
                button_cntr         btn2            (.clk(clk), .reset_p(reset_p), .btn(btn[2]), .btn_pedge(btn_min));

                counter_bcd_60      counter_sec     (.clk(clk), .reset_p(reset_p), .clk_time(btn_sec), .bcd1(set_sec1) , .bcd10(set_sec10));
                counter_bcd_60      counter_min     (.clk(clk), .reset_p(reset_p), .clk_time(btn_min), .bcd1(set_min1) , .bcd10(set_min10));

                loadable_down_counter_bcd_60        cur_sec     ( .clk(clk), .reset_p(reset_p), .clk_time(clk_sec), .load_enable(btn_start), 
                                                                                                .load_bcd1(set_sec1), .load_bcd10(set_sec10), .bcd1(cur_sec1), .bcd10(cur_sec10), .dec_clk(dec_clk)); //초에서 클럭내보내고 분에서 클럭받아서 카운트
                loadable_down_counter_bcd_60        cur_min     ( .clk(clk), .reset_p(reset_p), .clk_time(dec_clk), .load_enable(btn_start),
                                                                                                .load_bcd1(set_min1), .load_bcd10(set_min10), .bcd1(cur_min1), .bcd10(cur_min10));
                                             
                always @(posedge clk or posedge reset_p) begin
                            if(reset_p) begin
                                    start_set = 0;
                                    alarm =0;
                            end
                            
                            else begin
                                    if(btn_start) start_set = ~start_set;
                                    else if(cur_time ==0 && start_set) begin
                                            start_set =0;
                                            alarm =1;
                                    end
                                    else if(btn_alarm_off) alarm =0;
                            end
                            
                 end
                                
                assign led_start =start_set;
                assign buzz = alarm;
                
                assign set_time = {set_min10, set_min1, set_sec10, set_sec1};
                assign cur_time = {cur_min10, cur_min1, cur_sec10, cur_sec1};
                assign value = start_set ? cur_time : set_time;
                fnd_cntr fnd(.clk(clk), .reset_p(reset_p), .value(value), .com(com),  .seg_7(seg_7));       
                
                
endmodule
