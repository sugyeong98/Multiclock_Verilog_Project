//////////////////////////////////////////////////////////////////////////////////
module project_top_module_multiclk_240726(
        input clk, reset_p,
        input [2:0] btn,
        input btn_state,
        input btn_alarm_off,
        output [3:0] com,
        output [7:0] seg_7,
        output [2:0] led_state,
        output [7:3] led, 
        output alarm, buzz);   
              
        parameter WATCH_SET                = 3'b001;
        parameter STOP_WATCH               = 3'b010;
        parameter COOK_TIMER               = 3'b100;
        
        reg [2:0] state_mode, next_state_mode;  
        assign led_state  =  state_mode;
        
                             
        wire btn_state_mode;
        wire [2:0]btn_watch, btn_stopwatch, btn_cooktimer;
        wire [7:0]seg_7_watch, seg_7_stopwatch, seg_7_cooktimer;  
        wire [7:3]led_watch, led_stopwatch, led_cooktimer;
        
        button_cntr         btn3_state_mode      (.clk(clk), .reset_p(reset_p), .btn(btn_state), .btn_pedge(btn_state_mode));                                              
       
        loadable_watch_top_btn_project       watch          (.clk(clk), .reset_p(reset_p), .btn(btn_watch),     .com(com), .seg_7(seg_7_watch),     .led(led_watch));
        stop_watch_top_sec_csec_project      stopwatch      (.clk(clk), .reset_p(reset_p), .btn(btn_stopwatch), .com(com), .seg_7(seg_7_stopwatch), .led(led_stopwatch));
        cook_timer_top_project               cooktimer      (.clk(clk), .reset_p(reset_p), .btn(btn_cooktimer), .com(com), .seg_7(seg_7_cooktimer), .led(led_cooktimer), 
                                                             .btn_alarm_off(btn_alarm_off), .alarm(alarm), .buzz(buzz));  
        
         
        assign btn_watch     = (state_mode == WATCH_SET)  ? btn : 0;                       
        assign btn_stopwatch = (state_mode == STOP_WATCH) ? btn : 0;
        assign btn_cooktimer = (state_mode == COOK_TIMER) ? btn : 0;
                              
        assign seg_7 = (state_mode == WATCH_SET)  ? seg_7_watch     :
                       (state_mode == STOP_WATCH) ? seg_7_stopwatch :
                       (state_mode == COOK_TIMER) ? seg_7_cooktimer : 0;
                                                       
        assign led   = (state_mode == WATCH_SET)  ? led_watch     :
                       (state_mode == STOP_WATCH) ? led_stopwatch :
                       (state_mode == COOK_TIMER) ? led_cooktimer : 0;                        
        
        
        
        
        always @(negedge clk or posedge reset_p) begin
                if(reset_p) state_mode  = WATCH_SET;
                else state_mode = next_state_mode;
        end                       
        
        always @(posedge clk or posedge reset_p) begin
                if(reset_p) begin
                    next_state_mode = WATCH_SET;
                end
                     
                else begin
                    case(state_mode) 
                        WATCH_SET : begin
                            if(btn_state_mode) begin
                                next_state_mode = STOP_WATCH;                                                                        
                            end
                        end 
                        
                       STOP_WATCH : begin;                                                                   
                            if(btn_state_mode) begin
                                next_state_mode = COOK_TIMER;                                                                        
                            end
                       end
                       
                       COOK_TIMER : begin                                                                  
                            if(btn_state_mode) begin
                                next_state_mode = WATCH_SET;                                                                        
                            end
                       end                                                                                                                                                                                      
                     endcase
                end
         end                                        
       
endmodule