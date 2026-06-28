

module memory(
		
	// signals from APB completer
		
		input enable_DMA,

		input wire enable,
		output reg ready,
		input wire[7:0] addr,
		input wire[7:0] data_w,
		output reg[7:0] data_r,
		input wire dir,
		output reg error
	
);


//reg ready_internal;
reg[7:0] mem[255:0];



always @(posedge enable)
begin


case(dir)

0 : mem[addr] <= data_w;

1 : data_r <= mem[addr];


endcase

//ready_internal <= 1;

end

/*
always @(posedge ready_internal)
begin

ready <= 0;
ready_internal <= 0;

end
*/


always @(enable_DMA)
begin

if(enable_DMA==1)
begin

error <= 0;

ready <= 1;
//ready_internal <= 1;

end


end







endmodule