/*
 *		This is the control module for managing memory reads and getting them
 *		to the DAC.
 */
module audio_memory_control(
	input Clk, Reset, Start, INIT_FINISH, begin_lookup,
	output logic INIT, LD_sound_1, LD_sound_2, LD_sound_3, LD_sound_4, LD_addr_1, LD_addr_2, LD_addr_3, LD_addr_4,
	input  logic [11:0]	key_mask,
	output logic [3:0]	sound_num
);

enum logic [3:0] { WaitToStart, SendInit, WaitForACK, Standby, CheckKeys, LoadBogusVal, DoLookup, WaitforSRAM_1, WaitforSRAM_2, LoadSoundData, IncMask } curState, nextState;

logic [2:0] counter;
logic inc_counter, reset_counter;

logic [11:0] state_mask;
logic [3:0] mask_counter;
logic inc_mask_counter, reset_mask_counter;

always_ff @ (posedge Clk)
	begin
		if (Reset)
		begin
			counter <= 3'b000;
			curState <= WaitToStart;
		end
		else
		begin
			curState <= nextState;
			if(reset_counter)
				counter <= 3'b000;
			if(inc_counter)
				counter <= counter + 1;
			if(inc_mask_counter)
			begin
				mask_counter <= mask_counter + 1;
				state_mask <= { 1'b0, state_mask[11:1]};
			end
			if(reset_mask_counter)
			begin
				mask_counter <= 4'd0;
				state_mask <= 12'h800;
			end
		end
	end
	
	always_comb
	begin
		nextState = curState;
		unique case ( curState )
			WaitToStart : 
				if(Start)
					nextState = SendInit;
			SendInit : 
				nextState = WaitForACK;
			WaitForACK :
				if(INIT_FINISH)
					nextState = Standby;
			Standby :
				if(begin_lookup)
					nextState = CheckKeys;
			CheckKeys :
				if(mask_counter >= 4'd12 && counter >= 3'b011) 		// Reached the end of keys, and all audio channels have been loaded
					nextState = Standby;
				else if(mask_counter >= 4'd12 && counter != 3'b011) // Reached the end of keys, but not all audio channels have data
					nextState = LoadBogusVal;
				else if( (key_mask & state_mask) != 12'd0) 			// The current key needs to be played
					nextState = DoLookup;
				else																// Otherwise, no sound needs to be played
					nextState = IncMask;
			LoadBogusVal :
				nextState = CheckKeys;
			DoLookup :
				nextState = WaitforSRAM_1;
			WaitforSRAM_1 :
				nextState = WaitforSRAM_2;
			WaitforSRAM_2 :
				nextState = LoadSoundData;
			LoadSoundData :
				nextState = IncMask;
			IncMask :
				nextState = CheckKeys;
		endcase
		
		INIT = 0;
		LD_sound_1 = 0; 
		LD_sound_2 = 0;
		LD_sound_3 = 0;
		LD_sound_4 = 0;
		LD_addr_1 = 0; 
		LD_addr_2 = 0;
		LD_addr_3 = 0;
		LD_addr_4 = 0;
		inc_counter = 0;
		reset_counter = 0;
		
		inc_mask_counter = 0;
		reset_mask_counter = 0;
		sound_num = 4'd12;
		
		case ( curState )
			WaitToStart : ;
			SendInit :
			begin
				INIT = 1;
				reset_counter = 1;
			end
			WaitForACK : ;
			Standby : 
			begin
				reset_mask_counter = 1;
				reset_counter = 1;
			end
			CheckKeys : ;
			LoadBogusVal :
			begin
				sound_num = 4'hF; // this value tells us to load all 0s
				case (counter)
					3'b000 :
						LD_sound_1 = 1;
					3'b001 :
						LD_sound_2 = 1;
					3'b010 :
						LD_sound_3 = 1;
					3'b011 :
						LD_sound_4 = 1;
				endcase
				inc_counter = 1;
			end
			DoLookup : 
			begin
				sound_num = mask_counter; // tells us which sound to load
				case (counter)
					3'b000 :
						LD_addr_1 = 1;
					3'b001 :
						LD_addr_2 = 1;
					3'b010 :
						LD_addr_3 = 1;
					3'b011 :
						LD_addr_4 = 1;
				endcase
			end
			WaitforSRAM_1 : ;
			WaitforSRAM_2 : ;
			LoadSoundData : 
			begin
				case (counter)
					2'b00 :
						LD_sound_1 = 1;
					2'b01 :
						LD_sound_2 = 1;
					2'b10 :
						LD_sound_3 = 1;
					2'b11 :
						LD_sound_4 = 1;
				endcase
				inc_counter = 1;
			end
			IncMask : 
				inc_mask_counter = 1;
			
		endcase
	end
endmodule 
