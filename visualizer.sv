module  visualizer ( input         Clk,                // 50 MHz clock
                             Reset,              // Active-high reset signal
                             frame_clk,          // The clock indicating a new frame (~60Hz)
               input [9:0]   DrawX, DrawY,       // Current pixel coordinates
					input [31:0]	 sound_data,			 // get the keyboard input
               output logic  is_rect             // Whether current pixel belongs to ball or background
              );

	parameter [9:0] Rect_1_start = 10'd20;
	parameter [9:0] Rect_1_end   = 10'd59;
	parameter [9:0] Rect_2_start = 10'd100;
	parameter [9:0] Rect_2_end   = 10'd139;
	parameter [9:0] Rect_3_start = 10'd180;
	parameter [9:0] Rect_3_end   = 10'd219;
	parameter [9:0] Rect_4_start = 10'd260;
	parameter [9:0] Rect_4_end   = 10'd299;
	parameter [9:0] Rect_5_start = 10'd340;
	parameter [9:0] Rect_5_end   = 10'd379;
	parameter [9:0] Rect_6_start = 10'd420;
	parameter [9:0] Rect_6_end   = 10'd459;
	parameter [9:0] Rect_7_start = 10'd500;
	parameter [9:0] Rect_7_end   = 10'd539;
	parameter [9:0] Rect_8_start = 10'd580;
	parameter [9:0] Rect_8_end   = 10'd619;
	
	
	logic [31:0] rect_data;
	logic [3:0]	 counter = 3'b000;
	
	// Detect rising edge of frame_clk
    logic frame_clk_delayed, frame_clk_rising_edge;
    always_ff @ (posedge Clk) begin
        frame_clk_delayed <= frame_clk;
        frame_clk_rising_edge <= (frame_clk == 1'b1) && (frame_clk_delayed == 1'b0);
    end
	 
	 always_ff @ (posedge frame_clk_rising_edge)
	 begin
		counter <= counter + 3'b001;
		if(counter == 3'd4)
			begin
			rect_data <= sound_data;
			counter <= 3'b000;
			end
	 end
	 
	 always_comb
	 begin
		is_rect = 1'b0;
		if(DrawX >= Rect_8_start && DrawX <= Rect_8_end && DrawY > (10'd479-rect_data[3:0]*10'd30))
			is_rect = 1'b1;
		if(DrawX >= Rect_7_start && DrawX <= Rect_7_end && DrawY > (10'd479-rect_data[7:4]*10'd30))
			is_rect = 1'b1;
		if(DrawX >= Rect_6_start && DrawX <= Rect_6_end && DrawY > (10'd479-rect_data[11:8]*10'd30))
			is_rect = 1'b1;
		if(DrawX >= Rect_5_start && DrawX <= Rect_5_end && DrawY > (10'd479-rect_data[15:12]*10'd30))
			is_rect = 1'b1;
		if(DrawX >= Rect_4_start && DrawX <= Rect_4_end && DrawY > (10'd479-rect_data[19:16]*10'd30))
			is_rect = 1'b1;
		if(DrawX >= Rect_3_start && DrawX <= Rect_3_end && DrawY > (10'd479-rect_data[23:20]*10'd30))
			is_rect = 1'b1;
		if(DrawX >= Rect_2_start && DrawX <= Rect_2_end && DrawY > (10'd479-rect_data[27:24]*10'd30))
			is_rect = 1'b1;
		if(DrawX >= Rect_1_start && DrawX <= Rect_1_end && DrawY > (10'd479-rect_data[31:28]*10'd30))
			is_rect = 1'b1;
		if( (DrawY >= 10'd27 && DrawY <= 10'd29) || (DrawY >= 10'd57 && DrawY <= 10'd59) || (DrawY >= 10'd87 && DrawY <= 10'd89) ||
			(DrawY >= 10'd117 && DrawY <= 10'd119) || (DrawY >= 10'd147 && DrawY <= 10'd149) || (DrawY >= 10'd177 && DrawY <= 10'd179) ||
			(DrawY >= 10'd207 && DrawY <= 10'd209) || (DrawY >= 10'd237 && DrawY <= 10'd239) || (DrawY >= 10'd267 && DrawY <= 10'd269) ||
			(DrawY >= 10'd297 && DrawY <= 10'd299) || (DrawY >= 10'd327 && DrawY <= 10'd329) || (DrawY >= 10'd357 && DrawY <= 10'd359) ||
			(DrawY >= 10'd387 && DrawY <= 10'd389) || (DrawY >= 10'd417 && DrawY <= 10'd419) || (DrawY >= 10'd447 && DrawY <= 10'd449) )
			is_rect = 1'b0;
	 end
	 
endmodule
