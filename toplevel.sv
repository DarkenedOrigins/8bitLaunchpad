/*
 *		This is the toplevel of our Launchpad. This module does ALOT, so be prepared...
 */
module launchpad(
	input 					CLOCK_50,
	input [3:0] 		 	KEY,
	
	// VGA interface
	output logic [7:0]	VGA_R,
								VGA_B,
								VGA_G,
	output logic			VGA_CLK,
								VGA_SYNC_N,
								VGA_BLANK_N,
								VGA_VS,
								VGA_HS,
	
	// WM8731 Audio Codec Interface
	output logic 			AUD_DACDAT,	  	// DAC data line
	input  logic			AUD_DACLRCK,  	// DAC data left/right select
	input  logic			AUD_ADCDAT,  	// ADC data line 
	input  logic			AUD_ADCLRCK,  	// ADC data left/right select
	input  logic			AUD_BCLK,     	// Digital Audio bit clock
	output logic			AUD_XCK,      	// Codec master clock OUTPUT
	output logic			I2C_SDAT,	  	// serial interface data line
	output logic			I2C_SCLK,      // serial interface clock
	
	//SRAM Interface
	input  logic [15:0] 	SRAM_DQ,			// SRAM Data 16 Bits (if not inout -> READ ONLY)
	output logic [19:0] 	SRAM_ADDR,		// SRAM Address 20 Bits
	output logic			SRAM_WE_N,		// SRAM Write Enable
	output logic			SRAM_OE_N,		// SRAM Output Enable
	output logic			SRAM_CE_N,		// SRAM Clock Enable
	output logic			SRAM_LB_N,		// SRAM Lower Byte Enable
	output logic			SRAM_UB_N,		// SRAM Upper Byte Enable
	
	//PS2 Keyboard Interface
	
	inout						PS2_KBCLK,
	inout						PS2_KBDAT,
	
	// Various Other Peripherals
	output logic [17:0]	LEDR,
	output logic [7:0]	LEDG,
	input  logic [17:0]	SW
							
);

	logic Reset_h, Clk;
	logic [2:0] speed_factor = 3'd2;
	logic [19:0] current_SRAM_address = 20'b0;
	
	// A BUNCH OF SOUND EFFECT DECLARATIONS:
	logic [19:0] Q_sound_idx = 20'b0;
	logic [19:0] W_sound_idx = 20'b0;
	logic [19:0] E_sound_idx = 20'b0;
	logic [19:0] R_sound_idx = 20'b0;
	logic [19:0] T_sound_idx = 20'b0;
	logic [19:0] A_sound_idx = 20'b0;
	logic [19:0] S_sound_idx = 20'b0;
	logic [19:0] D_sound_idx = 20'b0;
	logic [19:0] F_sound_idx = 20'b0;
	logic [19:0] G_sound_idx = 20'b0;
	logic [19:0] H_sound_idx = 20'b0;
	logic [19:0] J_sound_idx = 20'b0;
	
	logic [19:0] Q_SOUND_START_ADDR, Q_SOUND_END_ADDR;
	logic [19:0] W_SOUND_START_ADDR, W_SOUND_END_ADDR;
	logic [19:0] E_SOUND_START_ADDR, E_SOUND_END_ADDR;
	logic [19:0] R_SOUND_START_ADDR, R_SOUND_END_ADDR;
	logic [19:0] T_SOUND_START_ADDR, T_SOUND_END_ADDR;
	logic [19:0] A_SOUND_START_ADDR, A_SOUND_END_ADDR;
	logic [19:0] S_SOUND_START_ADDR, S_SOUND_END_ADDR;
	logic [19:0] D_SOUND_START_ADDR, D_SOUND_END_ADDR;
	logic [19:0] F_SOUND_START_ADDR, F_SOUND_END_ADDR;
	logic [19:0] G_SOUND_START_ADDR, G_SOUND_END_ADDR;
	logic [19:0] H_SOUND_START_ADDR, H_SOUND_END_ADDR;
	logic [19:0] J_SOUND_START_ADDR, J_SOUND_END_ADDR;
	
	assign Q_SOUND_START_ADDR = 20'h00025;
	assign Q_SOUND_END_ADDR = 20'h0CCB3;
	assign W_SOUND_START_ADDR = 20'h0E125;
	assign W_SOUND_END_ADDR = 20'h19CA7;
	assign E_SOUND_START_ADDR = 20'h1C225;
	assign E_SOUND_END_ADDR = 20'h26F3C;
	assign R_SOUND_START_ADDR = 20'h2A325;
	assign R_SOUND_END_ADDR = 20'h36FB3;
	assign T_SOUND_START_ADDR = 20'h38425;
	assign T_SOUND_END_ADDR = 20'h46525;
	
	// second file loaded in at 0x50000
	
	assign A_SOUND_START_ADDR = 20'h50025;
	assign A_SOUND_END_ADDR = 20'h54DFB;
	assign S_SOUND_START_ADDR = 20'h54DFB;
	assign S_SOUND_END_ADDR = 20'h59BD1;
	assign D_SOUND_START_ADDR = 20'h59BD1;
	assign D_SOUND_END_ADDR = 20'h5E9A7;
	assign F_SOUND_START_ADDR = 20'h5E9A7;
	assign F_SOUND_END_ADDR = 20'h6377D;
	assign G_SOUND_START_ADDR = 20'h6377D;
	assign G_SOUND_END_ADDR = 20'h68553;
	assign H_SOUND_START_ADDR = 20'h68553;
	assign H_SOUND_END_ADDR = 20'h6D329;
	assign J_SOUND_START_ADDR = 20'h6D329;
	assign J_SOUND_END_ADDR = 20'h720FF;
	
	// TOP ROW KEYS ARE MEANT TO LOOP IF PRESSED ONCE, AND STOP PLAYING WHEN HIT AGAIN
	logic key_Q_pressed = 0;
	logic key_W_pressed = 0; 
	logic key_E_pressed = 0; 
	logic key_R_pressed = 0; 
	logic key_T_pressed = 0;
	
	// THE REPLAY KEY (Which also loops on the first press, and end on second press)
	logic key_tilde_pressed = 0;
	
	// MID ROW KEYS ARE SINGLE HITS, AND WILL LOOP IF HELD, BUT CUT OFF IMMEDIATELY WHEN RELEASED
	logic key_A_pressed = 0;
	logic key_S_pressed = 0;
	logic key_D_pressed = 0;
	logic key_F_pressed = 0;
	logic key_G_pressed = 0; 
	logic key_H_pressed = 0;
	logic key_J_pressed = 0; 
	
	// Make the Red LEDs reflect which keys are being used (for some nice visual flair)
	assign LEDR = {user_is_recording, 4'b0, key_tilde_pressed, key_Q_pressed, key_W_pressed, key_E_pressed, key_R_pressed, key_T_pressed, key_A_pressed, key_S_pressed, key_D_pressed, key_F_pressed, key_G_pressed, key_H_pressed, key_J_pressed};
	
	logic [15:0] sound_1_data, sound_2_data, sound_3_data, sound_4_data, total_data;

	
	// Get the SRAM into READ ONLY mode
	assign SRAM_WE_N = 1;		// Never Write
	assign SRAM_OE_N = 0;		// Always Read
	assign SRAM_CE_N = 0;		// CE, UB and LB should always be 0
	assign SRAM_UB_N = 0;
	assign SRAM_LB_N = 0;
	
	assign SRAM_ADDR = current_SRAM_address;
	
	assign Clk = CLOCK_50;
	always_ff @ (posedge Clk) 
	begin
		Reset_h <= ~(KEY[0]);

		// When recording, use the Green LEDs to reflect how much time is left
		if(user_is_recording)
		begin
			if(BRAM_address > 18'd32768)
				LEDG[0] <= 1;
			if(BRAM_address > 18'd65536)
				LEDG[1] <= 1;
			if(BRAM_address > 18'd98304)
				LEDG[2] <= 1;
			if(BRAM_address > 18'd131072)
				LEDG[3] <= 1;
			if(BRAM_address > 18'd163840)
				LEDG[4] <= 1;
			if(BRAM_address > 18'd196608)
				LEDG[5] <= 1;
			if(BRAM_address > 18'd229376)
				LEDG[6] <= 1;
			if(BRAM_address > 18'd262141)
				LEDG[7] <= 1;
		end
		else
		begin
			LEDG <= 8'h0;
		end

		// If the Sound ID is 0xF, then we need to load in blanks
		if(sound_ID == 4'hF)
		begin
			if(LD_sound_1)
				sound_1_data <= 16'h0000;
			if(LD_sound_2)
				sound_2_data <= 16'h0000;
			if(LD_sound_3)
				sound_3_data <= 16'h0000;
			if(LD_sound_4)
				sound_4_data <= 16'h0000;
		end
		else
		begin
			if(LD_sound_1)
				sound_1_data <= SRAM_DQ;
			if(LD_sound_2)
				sound_2_data <= SRAM_DQ;
			if(LD_sound_3)
				sound_3_data <= SRAM_DQ;
			if(LD_sound_4)
				sound_4_data <= SRAM_DQ;
		end
			
		// Based on what the sound ID is, where does the sound effect start in memory(SRAM)?
		case(sound_ID)
			4'h0 :
			begin
				if(LD_addr_1)
					current_SRAM_address <= Q_sound_idx + Q_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= Q_sound_idx + Q_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= Q_sound_idx + Q_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= Q_sound_idx + Q_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (Q_sound_idx + Q_SOUND_START_ADDR) > Q_SOUND_END_ADDR)
						Q_sound_idx <= 20'h00000; 
					else
						Q_sound_idx <= Q_sound_idx+speed_factor;
				end
			end
			4'h1 :
			begin
				if(LD_addr_1)
					current_SRAM_address <= W_sound_idx + W_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= W_sound_idx + W_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= W_sound_idx + W_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= W_sound_idx + W_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (W_sound_idx + W_SOUND_START_ADDR) > W_SOUND_END_ADDR)
						W_sound_idx <= 20'h00000; 
					else
						W_sound_idx <= W_sound_idx+speed_factor;
				end
			end
			4'h2 :
			begin
				if(LD_addr_1)
					current_SRAM_address <= E_sound_idx + E_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= E_sound_idx + E_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= E_sound_idx + E_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= E_sound_idx + E_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (E_sound_idx + E_SOUND_START_ADDR) > E_SOUND_END_ADDR)
						E_sound_idx <= 20'h00000; 
					else
						E_sound_idx <= E_sound_idx+speed_factor;
				end
			end
			4'h3 : 
			begin
				if(LD_addr_1)
					current_SRAM_address <= R_sound_idx + R_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= R_sound_idx + R_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= R_sound_idx + R_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= R_sound_idx + R_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (R_sound_idx + R_SOUND_START_ADDR) > R_SOUND_END_ADDR)
						R_sound_idx <= 20'h00000; 
					else
						R_sound_idx <= R_sound_idx+speed_factor;
				end
			end
			4'h4 :
			begin
				if(LD_addr_1)
					current_SRAM_address <= T_sound_idx + T_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= T_sound_idx + T_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= T_sound_idx + T_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= T_sound_idx + T_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (T_sound_idx + T_SOUND_START_ADDR) > T_SOUND_END_ADDR)
						T_sound_idx <= 20'h00000; 
					else
						T_sound_idx <= T_sound_idx+speed_factor;
				end
			end
			4'h5 :
			begin
				if(LD_addr_1)
					current_SRAM_address <= A_sound_idx + A_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= A_sound_idx + A_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= A_sound_idx + A_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= A_sound_idx + A_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (A_sound_idx + A_SOUND_START_ADDR) > A_SOUND_END_ADDR)
						A_sound_idx <= 20'h00000; 
					else
						A_sound_idx <= A_sound_idx+speed_factor;
				end
			end
			4'h6 :
			begin
				if(LD_addr_1)
					current_SRAM_address <= S_sound_idx + S_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= S_sound_idx + S_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= S_sound_idx + S_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= S_sound_idx + S_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (S_sound_idx + S_SOUND_START_ADDR) > S_SOUND_END_ADDR)
						S_sound_idx <= 20'h00000; 
					else
						S_sound_idx <= S_sound_idx+speed_factor;
				end
			end
			4'h7 :
			begin
				if(LD_addr_1)
					current_SRAM_address <= D_sound_idx + D_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= D_sound_idx + D_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= D_sound_idx + D_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= D_sound_idx + D_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (D_sound_idx + D_SOUND_START_ADDR) > D_SOUND_END_ADDR)
						D_sound_idx <= 20'h00000; 
					else
						D_sound_idx <= D_sound_idx+speed_factor;
				end
			end
			4'h8 : 
			begin
				if(LD_addr_1)
					current_SRAM_address <= F_sound_idx + F_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= F_sound_idx + F_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= F_sound_idx + F_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= F_sound_idx + F_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (F_sound_idx + F_SOUND_START_ADDR) > F_SOUND_END_ADDR)
						F_sound_idx <= 20'h00000; 
					else
						F_sound_idx <= F_sound_idx+speed_factor;
				end
			end
			4'h9 :
			begin
				if(LD_addr_1)
					current_SRAM_address <= G_sound_idx + G_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= G_sound_idx + G_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= G_sound_idx + G_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= G_sound_idx + G_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (G_sound_idx + G_SOUND_START_ADDR) > G_SOUND_END_ADDR)
						G_sound_idx <= 20'h00000; 
					else
						G_sound_idx <= G_sound_idx+speed_factor;
				end
			end
			4'hA :
			begin
				if(LD_addr_1)
					current_SRAM_address <= H_sound_idx + H_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= H_sound_idx + H_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= H_sound_idx + H_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= H_sound_idx + H_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (H_sound_idx + H_SOUND_START_ADDR) > H_SOUND_END_ADDR)
						H_sound_idx <= 20'h00000; 
					else
						H_sound_idx <= H_sound_idx+speed_factor;
				end
			end
			4'hB :
			begin
				if(LD_addr_1)
					current_SRAM_address <= J_sound_idx + J_SOUND_START_ADDR;
				if(LD_addr_2)
					current_SRAM_address <= J_sound_idx + J_SOUND_START_ADDR;
				if(LD_addr_3)
					current_SRAM_address <= J_sound_idx + J_SOUND_START_ADDR;
				if(LD_addr_4)
					current_SRAM_address <= J_sound_idx + J_SOUND_START_ADDR;
				if(byte_select)
				begin
					if( (J_sound_idx + J_SOUND_START_ADDR) > J_SOUND_END_ADDR)
						J_sound_idx <= 20'h00000; 
					else
						J_sound_idx <= J_sound_idx+speed_factor;
				end
			end
		endcase

// CUTE THING TO CHANGE SPEED OF SOUND PLAYING
			
		if(~KEY[1])
			speed_factor = 3'd1;
		if(~KEY[2])
			speed_factor = 3'd2;
		if(~KEY[3])
			speed_factor = 3'd3;
		if(~KEY[0])
			speed_factor = 3'd2;
			
// END OF SPEED CHANGING

// START OF KEY SETTING
		if(ps2_key_pressed)
		begin
			prevKey <= ps2_key_data;
			case(ps2_key_data)
			8'h0E :
			begin
				if(~key_release)
					key_tilde_pressed <= key_tilde_pressed ^ 1;
			end
			8'h15 : 
			begin
				if(~key_release)
					key_Q_pressed <= key_Q_pressed ^ 1;
				Q_sound_idx <= 20'h00000;
			end
			8'h1B : 
			begin
				if(key_release)
				begin
					key_S_pressed <= 0;
					S_sound_idx <= 20'h00000;
				end
				else
					key_S_pressed <= 1;
			end
			8'h1C :
			begin
				if(key_release)
				begin
					key_A_pressed <= 0;
					A_sound_idx <= 20'h00000;
				end
				else
					key_A_pressed <= 1;
			end
			8'h1D :
			begin
				if(~key_release)
					key_W_pressed <= key_W_pressed ^ 1;
				W_sound_idx <= 20'h00000;
			end
			8'h23 : 
			begin
				if(key_release)
				begin
					key_D_pressed <= 0;
					D_sound_idx <= 20'h00000;
				end
				else
					key_D_pressed <= 1;
			end
			8'h24 :
			begin
				if(~key_release)
					key_E_pressed <= key_E_pressed ^ 1;
				E_sound_idx <= 20'h00000;
			end
			8'h2B :
			begin
				if(key_release)
				begin
					key_F_pressed <= 0;
					F_sound_idx <= 20'h00000;
				end
				else
					key_F_pressed <= 1;
			end
			8'h2C :
			begin
				if(~key_release)
					key_T_pressed <= key_T_pressed ^ 1;
				T_sound_idx <= 20'h00000;
			end
			8'h2D :
			begin
				if(~key_release)
					key_R_pressed <= key_R_pressed ^ 1;
				R_sound_idx <= 20'h00000;
			end
			8'h33 :
			begin
				if(key_release)
				begin
					key_H_pressed <= 0;
					H_sound_idx <= 20'h00000;
				end
				else
					key_H_pressed <= 1;
			end
			8'h34 :
			begin
				if(key_release)
				begin
					key_G_pressed <= 0;
					G_sound_idx <= 20'h00000;
				end
				else
					key_G_pressed <= 1;
			end
			8'h3B :
			begin
				if(key_release)
				begin
					key_J_pressed <= 0;
					J_sound_idx <= 20'h00000;
				end
				else
					key_J_pressed <= 1;
			end
			endcase
		end

// END OF KEY SETTING
end

logic [7:0]prevKey;
logic key_release;
always_comb begin
	if( prevKey == 8'hf0 )
		key_release = 1'b1;
	else
		key_release = 1'b0;
		
end

	
	// Communicate with the Audio Driver
	
	//NOTE: WE DID NOT MAKE THIS AUDIO DRIVER, WE USED THE
	//		  ONE PROVIDED ON THE COURSE SITE!!!
	
	logic [15:0] LDATA, RDATA;
	logic INIT, INIT_FINISH, adc_full, data_over;
	logic [31:0] ADCDATA;
	
	audio_interface audio_driver(
		.LDATA(LDATA),
		.RDATA(RDATA),
		.clk(Clk),
		.reset(Reset_h),
		.INIT(INIT),
		.INIT_FINISH(INIT_FINISH),
		.adc_full(adc_full),
		.data_over(data_over),
		.AUD_MCLK(AUD_XCK),
		.AUD_BCLK(AUD_BCLK),
		.AUD_ADCDAT(AUD_ADCDAT),
		.AUD_DACDAT(AUD_DACDAT),
		.AUD_DACLRCK(AUD_DACLRCK),
		.AUD_ADCLRCK(AUD_ADCLRCK),
		.I2C_SDAT(I2C_SDAT),
		.I2C_SCLK(I2C_SCLK),
		.ADCDATA(ADCDATA)
	);
	

	// START OF BRAM STUFF (this is for recording user sound)
	
	logic BRAM_WE;
	logic [9:0] BRAM_in_data, BRAM_out_data, user_sound;
	logic [17:0] BRAM_address;
	logic [17:0] BRAM_sound_END_addr;
	logic user_is_recording;
	logic reset_BRAM_address;
	
	// When the first switch is flipped, we start recording data into BRAM
	assign user_is_recording = SW[0];
	

	big_ram bram(
		.Clk(Clk),
		.WE(BRAM_WE),
		.addr(BRAM_address),
		.read_data(BRAM_out_data),
		.write_data(BRAM_in_data)
	);
	
	control new_recording(
		.pcEn(reset_BRAM_address),
		.clock(data_over),
		.ready(user_is_recording|key_tilde_pressed)
	);
	
	
	
	//END OF BRAM STUFF

	//START OF GETTING SOUND INTO THE DAC

	logic begin_lookup, LD_sound_1, LD_sound_2, LD_sound_3, LD_sound_4, LD_addr_1, LD_addr_2, LD_addr_3, LD_addr_4;
	logic [11:0] key_mask;
	logic [3:0] sound_ID;
	assign key_mask = {key_Q_pressed, key_W_pressed, key_E_pressed, key_R_pressed, key_T_pressed, key_A_pressed, key_S_pressed, key_D_pressed, key_F_pressed, key_G_pressed, key_H_pressed, key_J_pressed};
	
	audio_memory_control audio_memory_control_instance(
		.Clk(Clk), 
		.Reset(Reset_h), 
		.Start(1), 
		.INIT_FINISH(INIT_FINISH), 
		.begin_lookup(begin_lookup),
		.INIT(INIT), 
		.LD_sound_1(LD_sound_1), 
		.LD_sound_2(LD_sound_2), 
		.LD_sound_3(LD_sound_3), 
		.LD_sound_4(LD_sound_4), 
		.LD_addr_1(LD_addr_1), 
		.LD_addr_2(LD_addr_2), 
		.LD_addr_3(LD_addr_3), 
		.LD_addr_4(LD_addr_4),
		.key_mask(key_mask),
		.sound_num(sound_ID)
	);
	
	logic [15:0] Upper_Byte, Lower_Byte, audio_data;
	logic byte_select = 0;

	// Because we are using 8-bit sound data, we need to split up the data, then add to avoid overflow
	assign Upper_Byte = sound_1_data[15:8] + sound_2_data[15:8] + sound_3_data[15:8] + sound_4_data[15:8] + user_sound;
	assign Lower_Byte = sound_1_data[7:0] + sound_2_data[7:0] + sound_3_data[7:0] + sound_4_data[7:0] + user_sound;
	
	//This pulses every time the DAC needs new data
	always_ff @ (posedge data_over)
	begin
		byte_select <= byte_select ^ 1;
		if(byte_select == 0)
		begin
			LDATA <= Upper_Byte;
			RDATA <= Upper_Byte;
			if(reset_BRAM_address)
				BRAM_address <= 18'h0;
			else if(user_is_recording && ( BRAM_address < 18'd262142 ) )
			begin
				BRAM_WE <= 1;
				BRAM_in_data <= Upper_Byte[9:0];
				BRAM_address <= BRAM_address + 1;
				BRAM_sound_END_addr <= BRAM_address;
			end
			if(~user_is_recording && key_tilde_pressed)
			begin
				BRAM_WE <= 0;
				if(BRAM_address < BRAM_sound_END_addr)
					BRAM_address <= BRAM_address + 1;
				else
					BRAM_address <= 18'h0000;
			end
		end
		else
		begin
			LDATA <= Lower_Byte;
			RDATA <= Lower_Byte;
			if(reset_BRAM_address)
				BRAM_address <= 18'h0;
			else if(user_is_recording && ( BRAM_address < 18'd262143 ) )
			begin
				BRAM_WE <= 1;
				BRAM_in_data <= Lower_Byte[9:0];
				BRAM_address <= BRAM_address + 1;
				BRAM_sound_END_addr <= BRAM_address;
			end
			if(~user_is_recording && key_tilde_pressed)
			begin
				BRAM_WE <= 0;
				if(BRAM_address < BRAM_sound_END_addr)
					BRAM_address <= BRAM_address + 1;
				else
					BRAM_address <= 18'h0000;
			end
		end
	end
	
	always_comb
	begin
		begin_lookup = 0;
		if(data_over)
			begin_lookup = 1;
		if(~user_is_recording && key_tilde_pressed)
			user_sound = BRAM_out_data;
		else
			user_sound = 8'h00;
	end
	
	//END OF STUFF RELATED TO THE DAC
	
	
	
	// Communcations with the VGA
	
	// PLL to generate 25MHz VGA_CLK
	vga_clk vga_clk_instance( .inclk0(Clk), .c0(VGA_CLK));
	
	logic [9:0] DrawX, DrawY;
	
	VGA_controller vga_controller_instance(
		.Clk(Clk), 
		.Reset(Reset_h), 
		.VGA_CLK(VGA_CLK), 
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS), 
		.VGA_BLANK_N(VGA_BLANK_N), 
		.VGA_SYNC_N(VGA_SYNC_N), 
		.DrawX(DrawX), 
		.DrawY(DrawY)
	);
	
	logic is_rect;
	
	visualizer good_visu( 
		.Clk(Clk), 
		.Reset(Reset_h), 
		.frame_clk( VGA_VS ), 
		.DrawX(DrawX), 
		.DrawY(DrawY), 
		.sound_data( {LDATA[7:0],LDATA[7:0], RDATA[7:0],RDATA[7:0] }), 
		.is_rect(is_rect)
	);
	
	color_mapper color_instance(
		.is_ball(is_rect), 
		.DrawX(DrawX), 
		.DrawY(DrawY), 
		.VGA_R(VGA_R), 
		.VGA_G(VGA_G), 
		.VGA_B(VGA_B)
	);
	
	
	// Communications with the PS2 Keyboard
	
	// NOTE: THIS KEYBOARD DRIVER WAS NOT MADE BY US!!!
	// WE GOT THIS FROM AN ALTERA DEMO ONLINE
	
	logic [7:0] ps2_key_data;
	logic			ps2_key_pressed;
	
	PS2_Controller PS2 (
		// Inputs
		.CLOCK_50(Clk),
		.reset(Reset_h),

		// Bidirectionals
		.PS2_CLK(PS2_KBCLK),
		.PS2_DAT(PS2_KBDAT),

		// Outputs
		.received_data(ps2_key_data),
		.received_data_en(ps2_key_pressed)
);

	
endmodule
