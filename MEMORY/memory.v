

module memory(
		
	// signals from APB completer
		
		input enable_DMA,

		output wire[7:0] TXb_1[8:0],
		output wire[7:0] RXb_1[8:0],

		input wire enable,
		output reg ready,
		input wire[7:0] addr,
		input wire[7:0] data_w,
		output reg[7:0] data_r,
		input wire dir,
		output reg error,

		input select_per


	
);



//reg ready_internal;
reg[7:0] mem[255:0];
reg ready_internal;

assign TXb_1[0] = mem[10];
assign TXb_1[1] = mem[11];
assign TXb_1[2] = mem[12];
assign TXb_1[3] = mem[13];
assign TXb_1[4] = mem[14];
assign TXb_1[5] = mem[15];
assign TXb_1[6] = mem[16];
assign TXb_1[7] = mem[17];

assign RXb_1[0] = mem[30];
assign RXb_1[1] = mem[31];
assign RXb_1[2] = mem[32];
assign RXb_1[3] = mem[33];
assign RXb_1[4] = mem[34];
assign RXb_1[5] = mem[35];
assign RXb_1[6] = mem[36];
assign RXb_1[7] = mem[37];


always @(posedge enable)
begin

if(select_per==1)
begin
ready <= 1;
case(dir)
	0 : mem[addr] <= data_w;
	1 : data_r <= mem[addr];
endcase

end
end

always @(negedge enable)
begin



ready <= 0;
data_r <= 8'bz;

end


always @(enable_DMA)
begin

if(enable_DMA==1)
begin

error <= 0;

ready <= 0;

end


end







endmodule