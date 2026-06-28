


// APB interface module
module APB_requester(

	input reg PCLK,	// clock signal

	input reg ENABLE_DMA,	// to initialize state variable, buses and signals

// ports for master peripheral (here master is DMA)
	input reg[7:0] data_w, 	// data to write to the peripheral
	output reg[7:0] data_r, // data read from the peripheral
	input reg[7:0] addr, 	// address of memory or register to r/w data
	input reg dir,		// direction of data transfer write=1, read=0
	output reg error,	// error signal for invalid address or direction
	input reg enable,	// enable signal to begin transfer, initialize state variable, masterclock gating
	output reg ready, 	// signals the completion of transfer

// APB buses and control signals
	output reg[7:0] PWDATA, // data write bus
	input reg[7:0] PRDATA,  // data read bus
	output reg[7:0] PADDR,	 // address bus
	output reg[1:0] PSEL,	 // select lines, 1 for each peripheral. here, PSEL[1] for UART and PSEL[0] for memory
	output reg PWRITE,	 // read/write control line, write=1, read=0
	output reg PENABLE, 	 // enable signal for APB
	input reg[1:0] PREADY,	 // ready signals, PREADY[1] for UART and PREADY[0] for memory
	input reg[1:0] PSLVERR		// error response, used to indicate invalid address or direction.
);



// MEMORY_X_ADDR => memory address range
// UART_X_ADDR => UART TX and RX reg addresses
parameter MEMORY_STRT_ADDR = 8'h00, MEMORY_END_ADDR = 8'h7f, UART_TX_ADDR = 8'h80, UART_RX_ADDR = 8'h81, WIDTH = 7;



reg[1:0] state; //state variable
reg PERIPHERAL_INDEX; // used as index for PREADY and PSLVERR


// initializing state variable on ENABLE_DMA, DMA is enabled once and not disabled even if TXI or RXI is raised
always @(posedge ENABLE_DMA)
begin
	state <= 2'b00;
	ready <= 1'b1;
	PSEL <= 2'b00;
	PWRITE <= 1'bz;
	PWDATA <= 8'bz;
	PADDR <= 8'bz;
	error <= 0;
	data_r <= 8'bz;
end

always @(enable)
begin
if(enable==1)
ready <= 0;

end



/*
always @(posedge enable)
begin
	error <= 0;
	ready <= 0;
	PWRITE <= dir; 	// setting PWRITE
	
	// setting data bus according to dir input by master peripheral.
	case(dir)
		1 : PWDATA <= data_w;
	endcase
	PADDR <= addr;
	PENABLE <= 0;

end
*/
/*

always @(posedge enable)
begin
	if(addr[WIDTH:0] >= MEMORY_STRT_ADDR && addr[WIDTH:0] <= MEMORY_END_ADDR)
	begin
		PSEL[0] = 1;
		PERIPHERAL_INDEX = 1'b0;
	end

	else if(addr == UART_RX_ADDR || addr == UART_TX_ADDR)
	begin
		PSEL[1] = 1;
		PERIPHERAL_INDEX = 1'b1;
	end
	else
	begin
		error <= 1;
	end
	
	ready <= 1;
end
*/


// FSM
always @(posedge PCLK, posedge PENABLE)
begin
	
	case(state)
		// IDLE
		2'b00 : begin
			// goes to next state when transfer is initiated
			if(enable==1)
				begin
				state <= 2'b01;
				end
			end

		// SETUP declare PSEL
		2'b01 : begin
			if(addr[WIDTH:0] >= MEMORY_STRT_ADDR && addr[WIDTH:0] <= MEMORY_END_ADDR)
				begin
				PSEL[0] = 1;
				PERIPHERAL_INDEX = 1'b0;
				end

			else if(addr == UART_RX_ADDR || addr == UART_TX_ADDR)
				begin
				PSEL[1] = 1;
				PERIPHERAL_INDEX = 1'b1;
				end
			/*else
				begin
				error <= 1;
				ready <= 1;
				end
			*/
			error <= 0;
			ready <= 0;
			PWRITE <= dir; 	// setting PWRITE
		
			// setting data bus according to dir input by master peripheral.
			case(dir)
				1 : PWDATA <= data_w;
			endcase
			PADDR <= addr;
			PENABLE <= 0;
			state <= 2'b10;

			end

		// ACCESS
		// transfer complete and requester pulls up PREADY and PSLVERR(if address or operation on an address is invalid) to indicate this
		2'b10 : begin
			PENABLE <= 1;
			// for optional wait state
			if(PREADY[PERIPHERAL_INDEX]==1)
				begin
				// checks only the specific line to the selected peripheral
				case({PREADY[PERIPHERAL_INDEX], PSLVERR[PERIPHERAL_INDEX]})
				2'b10 : begin
				
					case(PWRITE)
						1 : begin
							// keeping data bus in high impedance after transfer
							PWDATA <= 8'bz;
						end

						0 : begin
							// reading data to data_r (giving to master peripheral)
							data_r <= PRDATA;
						end
					endcase
					// pulling addr bus and pwrite to high impedance after transfer is complete, also signalling
					// transfer complete to master peripheral by pulling ready HIGH
					PADDR <= 8'bz;
					PWRITE <= 1'bz;
					ready <= 1;
					state <= 2'b00;
					PSEL <= 2'b00;
					PENABLE <= 0;
					PADDR <= 8'bz;
					PWDATA <= 8'bz;
					end

				// error HIGH, forwards to master and goes to state 00
				2'b11 : begin 
						state <= 2'b00;
						PSEL <= 2'b00;
						PENABLE <= 0;
						ready <= 1;
						error <= 1; // propogated to the CPU
						PADDR <= 8'bz;
						PWDATA <= 8'bz;
						PWRITE <= 1'bz;
					end

				// remains in ACCESS state
				2'b0x : begin
					state <= 2'b10;
					end
				endcase
				end
				
			end

	endcase

end




endmodule