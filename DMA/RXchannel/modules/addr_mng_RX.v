



// address manager module for a DMA channel
/*

this module keeps the address of peripheral and memory buffer assigned for that peripheral. when enable is high, it returns the address for the DMA channel to r/w from.

*/

module addr_mng_RX(
	
	// control and output signals for DMA channel
	input reg enable, 	// enable signal for this circuit
	input reg rw,		// r/w indicator 1=read, 0=write
	output reg[7:0] addr,	// address output
	output reg half_buffer,	// signals that half of the memory buffer has reached
	output reg full_buffer,	// signals full memory buffer reached
	input wire enable_DMA,

	input reg rst_hb,
	input reg rst_fb,

	// signals for memory buffer
	input wire[7:0] memory_start_address, 	// start address of memory buffer
	input wire[7:0] memory_buffer_offset	// size of memory buffer

	);


reg[7:0] origin_addr;	// internal register for memory_start_address
reg[7:0] offset;	// internal register for memory_buffer_offset
reg[7:0] current_addr;


parameter peripheral_addr = 8'h81;



// instantaneously updates the internal registers according to written values
always @(memory_start_address, memory_buffer_offset)
begin

origin_addr <= memory_start_address;
offset <= memory_buffer_offset;
current_addr <= memory_start_address;

end


always @(enable)
begin

if(enable==1)
begin
case(rw)
	// write
	0 : begin
		// checks whether current_addr has overflowed the buffer
		if(current_addr < origin_addr + offset)
		begin
			addr <= current_addr;
			current_addr <= current_addr + 1;
		end
	end

	1 : begin
		addr <= peripheral_addr;
	end

endcase




end

end



always @(current_addr)
begin

// controls full_buffer signal logic
if(current_addr == origin_addr + offset)
begin

	full_buffer <= 1;

end

// controls half_buffer signal logic
if(current_addr == origin_addr + (offset/8'h02))
begin

	half_buffer <= 1;

end

end






// full and half buffer interrupt CLR and current_addr reset to origin_addr
always @(rst_hb, rst_fb)
begin

if(rst_hb==0)
begin
half_buffer <= 0;
end

if(rst_fb==0)
begin
full_buffer <= 0;
current_addr <= origin_addr;
end

end





// initialization
always @(posedge enable_DMA)
begin

half_buffer <= 0;
full_buffer <= 0;

//initializing conf registers when DMA enabled. For the case when the user just need to restart the DMA to continue with old register values.
origin_addr <= memory_start_address;
offset <= memory_buffer_offset;
current_addr <= memory_start_address;


end


endmodule