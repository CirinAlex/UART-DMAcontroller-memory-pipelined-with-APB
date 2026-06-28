

// APB completer module

module APB_completer(

		input reg PCLK, //clock signal

		input reg enable_DMA,	// to initialize state variable and other signals

	// ports to memory manager
		output reg enable,	// enable for mem manager, forwards PENABLE
		input reg ready,	// ready driven by mem manager, forwarded to PREADY
		output reg[7:0] addr,	// address bus for mem manager
		output reg[7:0] data_w,	// data write bus for mem manager
		input reg[7:0] data_r,	// data read bus
		output reg dir,		// r/w signal
		input reg error,	// error signal from mem manager


	// buses and signals to requester, APB
		input reg[7:0] PWDATA,  // data write bus (incoming)
		output reg[7:0] PRDATA, // data read bus(outgoing)
		input reg[7:0] PADDR, 	// address bus
		input reg PSEL, 	// select line for this peripheral
		input reg PWRITE, 	// r/w control line, write=1, read=0
		input reg PENABLE, 	// enable signal for APB r/w
		output wire PREADY,	// ready signal		
		output reg PSLVERR	// signals error when invalid addr or restricted r/w


);


reg[1:0] state; // state variable for FSM


// initializing state variable and other buses and signals.
always @(posedge enable_DMA)
begin
	
	state <= 2'b00;

	enable <= 0;
	addr <= 8'bz;
	data_w <= 8'bz;
	dir <= 1'bz;
	PRDATA <= 8'bz;

	PSLVERR <= 0;

end




assign PREADY = ready;

// enable ready complementing logic
always @(posedge ready)
begin
	PSLVERR <= error;
	if(PWRITE==0)
	begin
	PRDATA <= data_r;
	end
end




// APB completer FSM
always @(posedge PCLK)
begin
	
	case(state)
		// IDLE state
		2'b00 : begin

			PSLVERR <= 0; // pulls down PSLVERR enabled in previous transfer

			// when this peripheral is selected, forwards address, operation, data write bus to peripheral memory manager and
			// enables it. Also moves to SETUP state
			if(PSEL==1)
				begin

				addr <= PADDR;
				dir <= PWRITE;
				if(PWRITE==1)
					begin
					data_w <= PWDATA;
					end

				enable <= 1;

				state <= 2'b01;
				end
			end
		
		// SETUP state
		2'b01 : begin	// PENABLE is HIGH here, which means any bus or control signal cannot be changed
				// this time is utilized to perform r/w to peripheral
			
			// goes to next state when peripheral finish the operation (ready signal)
			if(ready==1)
				begin
				state <= 2'b00;
				enable <=0;
				data_w <= 8'bz;
				addr <= 8'bz;
				dir <= 1'bz;
				end

			end
/*
		 ACCESS state
		2'b10 : begin goes to IDLE and enable of peripheral is made LOW
				enable <= 0;
				state <= 2'b00;
			end
*/

	endcase

end



endmodule




