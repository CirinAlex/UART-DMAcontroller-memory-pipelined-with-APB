


// top module of DMA controller
// TX channel [0], RX channel [1]

module DMA_top(

	input reg master_clk,

	// configuration registers to each channels, TX channel [0], RX channel [1]
	input wire[7:0] memory_start_address[1:0],
	input wire[7:0] memory_buffer_offset[1:0],

	input reg  enable_DMA, // enable signal for DMA from external system (modelled as a bit in control register)
	input reg RST, // reset	

	// interrupt signals from and to UART module
	input RI,
	output RI_in,
	input TI,
	output TI_in,

	// error signal to external system
	output reg[1:0] error_reg,

	// half buffer signal to and from external system
	output wire[1:0] half_buffer,
	input wire[1:0] half_buffer_in,

	// full buffer signal to and from external system
	output wire[1:0] full_buffer,
	input wire[1:0] full_buffer_in,

	// APB control signals
	output reg enable_ext,
	input wire ready_ext,
	output reg[7:0] addr_ext,
	output reg dir_ext,
	input wire[7:0] data_r_ext,
	output reg[7:0] data_w_ext,
	input wire error_ext

);


reg[1:0] state;
reg start;

reg bus_priority; // stores which channel request was selected

wire[1:0] BUS_request_select;
reg[1:0] BUS_grant_select;
wire[1:0] error_select;

reg[1:0] ready_transfer;
wire[1:0] enable_transfer;
wire[7:0] addr_transfer_out[1:0];
reg[7:0] data_r[1:0];
wire[7:0] data_w[1:0];
wire[1:0] dir_transfer;
reg[1:0] error;




//============================= INSTANTIATIONS ==========================================

DMAchannelTX DMAchannelTX(
    .master_clk(master_clk),

    .enable_DMA(enable_DMA),
    .TI(TI),
    .TI_in(TI_in),
    .BUS_request(BUS_request_select[0]),
    .BUS_grant(BUS_grant_select[0]),
    .error_reg(error_select[0]),

    .half_buffer_in(half_buffer_in[0]),
    .full_buffer_in(full_buffer_in[0]),
    .half_buffer(half_buffer[0]),
    .full_buffer(full_buffer[0]),

    .memory_start_address(memory_start_address[0]),//[7:0]),
    .memory_buffer_offset(memory_buffer_offset[0]),//[7:0]),

    // BUS control signals
    .ready_transfer(ready_transfer[0]),
    .enable_transfer(enable_transfer[0]),
    .addr_transfer_out(addr_transfer_out[0]),//[7:0]),
    .data_r(data_r[0]),//[7:0]),
    .data_w(data_w[0]),//[7:0]),
    .dir_transfer(dir_transfer[0]),
    .error(error[0])
);




DMAchannelRX DMAchannelRX(
    .master_clk(master_clk),

    .enable_DMA(enable_DMA),
    .RI(RI),
    .RI_in(RI_in),
    .BUS_request(BUS_request_select[1]),
    .BUS_grant(BUS_grant_select[1]),
    .error_reg(error_select[1]),

    .half_buffer_in(half_buffer_in[1]),
    .full_buffer_in(full_buffer_in[1]),
    .half_buffer(half_buffer[1]),
    .full_buffer(full_buffer[1]),

    .memory_start_address(memory_start_address[1]),//[7:0]),
    .memory_buffer_offset(memory_buffer_offset[1]),//[7:0]),

    .ready_transfer(ready_transfer[1]),
    .enable_transfer(enable_transfer[1]),
    .addr_transfer_out(addr_transfer_out[1]),//[7:0]),
    .data_r(data_r[1][7:0]),//),
    .data_w(data_w[1][7:0]),//),
    .dir_transfer(dir_transfer[1]),
    .error(error[1])
);



//=======================================================================================




always @(posedge master_clk)
begin


case(state)

	// IDLE
	2'b00 : begin
		if(start==1)
		begin
			state <= 2'b01;
		end
		end

	// ARBITRATION
	2'b01 : begin

		// first priority for RX
		if(BUS_request_select[1]==1)
		begin
			bus_priority <= 1;
			BUS_grant_select[1] <= 1;
			state <= 2'b10;
		end

		// second priorty for TX
		else if(BUS_request_select[0]==1)
		begin
			bus_priority <= 0;
			BUS_grant_select[0] <= 1;
			state <= 2'b10;
		end

		end

	// BUS multiplexing state
	2'b10 : begin

		if(error_ext==1)
		begin
			error_reg[bus_priority] <= 1;
			state <= 2'b00;
			start <= 0;
		end

		else if(BUS_request_select[bus_priority]==0)
		begin
			BUS_grant_select[bus_priority] = 0;
			state <= 2'b01;
		end

		end

endcase


end


// bus transfer

always @(enable_transfer[bus_priority], addr_transfer_out[bus_priority], data_r_ext, data_w[bus_priority], dir_transfer[bus_priority], ready_ext, error_ext)
begin

	enable_ext <= enable_transfer[bus_priority];
	addr_ext <= addr_transfer_out[bus_priority];
	data_r[bus_priority] <= data_r_ext;
	data_w_ext <= data_w[bus_priority];
	dir_ext <= dir_transfer[bus_priority];
	ready_transfer[bus_priority] <= ready_ext;
	error[bus_priority] <= error_ext;


end








always @(enable_DMA)
begin

if(enable_DMA==0)
begin
state <= 2'b00;
end

if(enable_DMA==1)
begin
start <= 1;
end


end


// initialization on RST
always @(RST)
begin
if(RST==0)
begin

state <= 2'b00;
BUS_grant_select <= 2'b00;
error_reg <= 2'b00;
enable_ext <= 0;
start <= 0;

end

end



endmodule