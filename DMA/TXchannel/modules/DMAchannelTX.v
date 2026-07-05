




// DMA channel that handles RX of UART

module DMAchannelTX(

	input wire master_clk,
	
	input wire enable_DMA,
	input wire TI,
	output reg TI_in,
	output reg BUS_request,
	input wire BUS_grant,
	output reg error_reg,

	input wire half_buffer_in,
	input wire full_buffer_in,
	output reg half_buffer,
	output reg full_buffer,

	input wire[7:0] memory_start_address,
	input wire[7:0] memory_buffer_offset,

	// BUS control signals
	input wire ready_transfer,
	output reg enable_transfer,
	output wire[7:0] addr_transfer_out,
	input wire[7:0] data_r,
	output reg[7:0] data_w,
	output reg dir_transfer,
	input reg error

	);


reg[7:0] DATA; // stores read data from RXbuff to write to the memory
reg[2:0] state; // state variable
reg start;

wire half_buffer_internal;
wire full_buffer_internal;

wire[7:0] addr_transfer_internal;

assign addr_transfer_out = addr_transfer_internal;



//================================================================================================================================



reg enable_addr_mng; 	// enable signal for this circuit
reg[7:0] addr;	// address

// CLR the half and full buffer signal "inside the addr_mng"
reg rst_hb;
reg rst_fb;




addr_mng_TX addr_mng_TX(.enable(enable_addr_mng), .rw(dir_transfer), .addr(addr_transfer_internal), .half_buffer(half_buffer_internal), .full_buffer(full_buffer_internal), .enable_DMA(enable_DMA), .memory_start_address(memory_start_address), .memory_buffer_offset(memory_buffer_offset), .rst_hb(rst_hb), .rst_fb(rst_fb));



//================================================================================================================================






// FSM

always @(posedge master_clk)
begin

case(state)
	// IDLE
	3'b000 : begin
		BUS_request <= 0;
		if(start==1 && error_reg!= 1)
		begin
			state <= 3'b001;
		end
		end


	// WAIT_INT_TX
	3'b001 : begin
		if(TI==1)
		begin
			state <= 3'b010;
		end
		 end


	// READ_ADDR_FETCH
	3'b010 : begin
	
	// enables addr_mng. It will place address to the bus
		dir_transfer <= 1;	// inputs to the addr_mng, also acts as control signal to the BUS
		enable_addr_mng <= 1;	// enables addr_mng

		BUS_request <= 1;

		state <= 3'b011;
		end


	// READ OPERATION
	3'b011 : begin
		
		enable_addr_mng <= 0;
		
		// transfer
		if(BUS_grant==1 && ready_transfer==1 && enable_transfer==0)
		begin

		enable_transfer <= 1;
		end

		if(BUS_grant==1 && ready_transfer==1 && enable_transfer==1)
		begin

		if(error==1)
		begin
			error_reg <= 1;
			state <= 3'b000;
			start <= 0;
			enable_transfer <= 0;
		end

		else
		begin
			enable_transfer <= 0;
			DATA <= data_r;
			state <= 3'b100;
		end
		end

		end


	// WRITE_ADDR_FETCH
	3'b100 : begin
		
		// enables addr_mng. It will place address to the bus
		dir_transfer <= 0;	// inputs to the addr_mng, also acts as control signal to the BUS
		enable_addr_mng <= 1;	// enables addr_mng



		state <= 3'b101;

		end


	// WRITE OPERATION
	3'b101 : begin
		
		enable_addr_mng <= 0;

		// transfer
		if(BUS_grant==1 && ready_transfer==1 && enable_transfer==0)
		begin

		data_w <= DATA;
		enable_transfer <= 1;
		end

		if(BUS_grant==1 && ready_transfer==1 && enable_transfer==1)
		begin

			if(error==1)
			begin
				error_reg <= 1;
				state <= 3'b000;
				start <= 0;
				enable_transfer <= 0;
			end
	
			else
			begin
				TI_in <= 0; // CLR RI, RX interrupt
				enable_transfer <= 0;
				state <= 3'b110;
			end
		end

		end

	// CHECK for half or full buffer interrupt, passes the interrupt and goes to WAIT_CONFIG state if true.
	3'b110 : begin
	
		BUS_request <= 0;

		if(half_buffer_internal==1)
		begin
		half_buffer <= 1;
		end

		case(full_buffer_internal)

			0 : begin
				state <= 3'b001; // back to WAIT_INT_RX
			end

			1 : begin
				full_buffer <= 1;
				state <= 3'b111; // to WAIT_CONFIG
			end
		endcase
		end

	// WAIT_CONFIG, waits in this stage until CPU manually pulls down interrupt register full_buffer
	3'b111 : begin
		if(full_buffer==0)
		begin
		rst_hb <= 1;
		rst_fb <= 1;
		state <= 3'b001;
		end
		end



endcase

end


// part of the FSM that handles disabling of DMA
always @(master_clk)
begin

if(enable_DMA==0)
begin
	state <= 3'b000;
	half_buffer <= 0;
	full_buffer <= 0;
end


end




//handling of interrupt from RX; keeps RI_in updated according to RI
always @(TI)
begin
if(TI==1)
begin
TI_in <= 1;
end

end





// initialization on enable_DMA
always @(enable_DMA)
begin

if(enable_DMA==1)
begin

error_reg <= 0;
state <= 3'b000;
enable_transfer <= 0;
BUS_request <= 0;
enable_addr_mng <= 0;

start <= 1;

rst_hb <= 1;
rst_fb <= 1;

TI_in <= 0;

end

else if(enable_DMA==0)
begin

start <= 0;

end

end




//==============================================================================================================================

// CLEAR buffer flag block
always @(half_buffer_in, full_buffer_in)
begin

// CLR half buffer if half or full buffer is CLEARed
if(half_buffer_in==0 || full_buffer_in==0)
begin
	half_buffer <= 0;
	rst_hb <= 0;
end

// if fullbuffer is CLRed it means the CPU has written new data to the buffer and DMA must continue the transfers.
// for this, current_addr is RST to origin_addr
if(full_buffer_in==0)
begin
	full_buffer <= 0;
	rst_fb <= 0;
end

end

//==============================================================================================================================






endmodule