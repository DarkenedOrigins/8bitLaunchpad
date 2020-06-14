/*
 *		This is a module we found from online, to pulse a signal for one
 *		clock cycle.		
 */
 
 //NOTE: WE DID NOT MAKE THIS!!!
module control
(
    output logic pcEn,
    input clock, ready
);
    reg r1, r2, r3;

    always @(posedge clock) begin
        r1 <= ready;    // first stage of 2-stage synchronizer
        r2 <= r1;       // second stage of 2-stage synchronizer
        r3 <= r2;       // edge detector memory
		  pcEn <= r2 && !r3;   // pulse on rising edge
    end

    
endmodule
