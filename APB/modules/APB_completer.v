

// APB completer module

module APB_completer(

		input reg PCLK, //clock signal

		input reg enable_DMA,	// to initialize state variable and other signals

	// ports to memory manager
		output wire enable,	// enable for mem manager, forwards PENABLE
		input reg ready,	// ready driven by mem manager, forwarded to PREADY
		output wire[7:0] addr,	// address bus for mem manager
		output wire[7:0] data_w,	// data write bus for mem manager
		input wire[7:0] data_r,	// data read bus
		output wire dir,	// r/w signal
		input reg error,	// error signal from mem manager
		output wire select_per,


	// buses and signals to requester, APB
		input reg[7:0] PWDATA,  // data write bus (incoming)
		output reg[7:0] PRDATA, // data read bus(outgoing)
		input reg[7:0] PADDR, 	// address bus
		input reg PSEL, 	// select line for this peripheral
		input reg PWRITE, 	// r/w control line, write=1, read=0
		input reg PENABLE, 	// enable signal for APB r/w
		output wire PREADY,	// ready signal		
		output wire PSLVERR	// signals error when invalid addr or restricted r/w


);


// reg[1:0] state; // state variable for FSM


// initializing state variable and other buses and signals.
always @(posedge enable_DMA)
begin

	PRDATA <= 8'bz;

end



always @(data_r)
begin


PRDATA <= data_r;

end


assign PREADY = ready;
assign enable = PENABLE;
assign select_per = PSEL;
assign PSLVERR = error;
assign data_w = PWDATA;

assign dir = PWRITE;
assign addr = PADDR;

always @(negedge PSEL)
begin

PRDATA = 8'bz;

end

// enable ready complementing logic




// APB completer FSM




endmodule




