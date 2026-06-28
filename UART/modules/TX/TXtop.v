
//TX top module

module TXtop(
	input reg[7:0] timerCurrentVal, //real-time output of uart-timer
	input reg[7:0] timerInitVal,
	input reg[7:0] TXbuff,		//buffer for TX, data to transmit is written to this buffer
	input reg TE,			//TX enable
	input wire TI_in, 		//External line that pulls TI low, pulled low for short time
	output reg TI,			//TX interrupt
	output wire TX,			//TX pin
	input clk,			//master clock signal
	input wire pwrite		//pwrite line from APB interface, used to signal the change in TXbuff
);

reg[1:0] state; //TX FSM state variable

reg TXCH; //internal register that signals change in TXbuff
reg TXshiftenable; //enable signal, input for TXshift
wire TXshiftready; //ready signal output from TXshift
	
//instantiation of TXshift module
TXshift A1(.timerInitVal(timerInitVal), .timerCurrentVal(timerCurrentVal), .TXbuff(TXbuff), .TXshiftenable(TXshiftenable), .clk(clk), .TXshiftready(TXshiftready), .TX(TX));


//TXCH made HIGH after when there is a write operation on TXbuff
always @(TXbuff) //negedge pwrite)
begin
//if(pwrite==0)
TXCH <= 1;
end

//initialization of some reg
always @(posedge TE)
begin
state <= 2'b00;
TXshiftenable <= 0;
TI <= 1;
end


//keeps the TXshiftenable complementary to TXshiftready of TXshift module
//
always @(TXshiftready)
begin
if(TXshiftready==1)
	TXshiftenable <= 0;
end


//TI (output) made LOW externally, done by pulling down TI_in
always @(negedge TI_in)
begin
	TI <= 0;
end



//TX FSM
always @(clk)
begin

case(state)

// IDLE state
2'b00 : begin
	if(TE==1) //goes to state START when TE enabled
		state <= 2'b01;

end

// START state
2'b01 : begin

	//goes to state IDLE whenever TE disabled
	if(TE==0)
		state <= 2'b00;

	//goes to next state (TRANSMIT) after there is a write operation to TXbuff
	else if(TXCH==1)
		begin
			state <= 2'b10;
			TXshiftenable <= 0; //disabled TXshift
		end
	end

// TRANSMIT state
2'b10 : begin

	//goes to state IDLE
	if(TE==0)
		state <= 2'b00;

	//enables TXshift & pulls down TXCH when TXshift is ready to take data
	else if(TXshiftenable==0 && TXCH==1)
		begin
		TXshiftenable <= 1;
		TXCH <= 0;
		end

	//goes to state START if TXshift is already enabled, that state further disables the TXshift and settles to state TRANSMIT, this is done to restart
	//the transmission with new data even in the middle of an ongoing transmission.
	else if(TXshiftenable==1 && TXCH==1)
		state <= 2'b01;

	//normal case when TXshift finish transmission, interrupt generated and goes to START state and wait there for change in TXbuff
	else if(TXshiftready==1)
		begin
		TI <= 1;
		state <= 2'b01;
		end

end

endcase

end



endmodule