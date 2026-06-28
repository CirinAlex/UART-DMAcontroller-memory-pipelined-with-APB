


//top module of uart

module uart(
	input wire master_clk,	//master clock
	input reg[7:0] timerInitVal,

	input wire[7:0] TXbuff, //Transmit byte input signal
	input reg TE,		//TX enable signal
	output wire TI,		//Transmission complete interrupt
	input wire TI_in,	//signal to CLEAR TI externally
	output wire TX,		// output to TX pin

	input wire pwrite,	//signal that trigger to start TX, this signal comes
				//from APB interface and TX uses this as a trigger to detect arrival of new data to transmit


	output wire[7:0] RXbuff, //Recieved byte output signal
	input reg RE,		//RX enable signal
	output wire RI,		//Reception interrupt
	input wire RI_in,	//signal to CLEAR RI externally
	input reg RX		// input from RX pin
	);


/* =============INSTANTIATIONS============== */



//clock divider instantiation, this block divides the master clock by 32
clk_divider C0(.master_clk(master_clk), .uart_clk(uart_clk_div), .RE(RE), .TE(TE));

wire uart_clk;
assign uart_clk = uart_clk_div;


//uart timer instantiation, this block takes the divided clock output from clk_divider(C0) and increments timer synchronously
wire[7:0] timerCurrentValwire;
uart_timer U0(.uart_clk(uart_clk), .timerInitVal(timerInitVal), .timerCurrentVal(timerCurrentValwire));




//TX top module instantiation
TXtop T0(.timerInitVal(timerInitVal), .timerCurrentVal(timerCurrentValwire), .TXbuff(TXbuff), .TE(TE), .TI_in(TI_in), .TI(TI), .TX(TX), .clk(master_clk));//, .pwrite(pwrite));


//RX top module instantiation
RXtop R0(.timerCurrentVal(timerCurrentValwire), .timerInitVal(timerInitVal), .RE(RE), .RX(RX), .RI(RI), .RXbuff(RXbuff), .RI_in(RI_in));





endmodule