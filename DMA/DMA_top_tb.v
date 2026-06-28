
//=============================================================================================================
// handles APB interface signals and responses
module APB_side(input enable, output reg ready, input dir, input wire[7:0] addr, input wire[7:0] data_w,
output reg[7:0] data_r, output reg error);

reg[7:0] DATA;
reg[7:0] TXbuff;

always @(posedge enable)
begin
ready = 0;
error = 0;
data_r = 8'bz;
#4;

if(addr<8'h80)
	begin

	if(addr%2==1)
		begin
		if(dir==0)
			begin
			DATA = data_w;
			end
		else if(dir==1)
			begin
			data_r = 8'b00010001;
			end
		end

	if(addr%2==0)
		begin
		if(dir==0)
			begin
			DATA = data_w;
			end
		else if(dir==1)
			begin
			data_r = 8'b01110111;
			end
		end

	end


case(addr)
	// RXbuff
	8'h81 : begin
		if(dir==1)
			begin
				data_r = 8'b01010100;
			end
		else
			begin
				error = 1;
			end

		end



	// TXbuff
	8'h82 : begin
		if(dir==0)
			begin
				error = 1; //TXbuff = data_w;
			end
		else
			begin
				error = 1;
			end

		end

endcase

ready = 1;
end


always @(negedge enable)
begin
error = 0;

end




endmodule



//========================================================================================================




//========================================================================================================
// handles UART side signals
module UART_side(output reg RI, input wire RI_in,
		output reg TI, input wire TI_in, input wire enable_DMA);



initial begin

#10;
RI = 1;
#3;
TI = 1;

#30;
RI = 1;
TI = 1;

#30;
TI = 1;
#3;
RI = 1;



end





always @(enable_DMA)
begin

RI <= 0;
TI <= 0;

end


always @(RI_in, TI_in)
begin

RI <= RI_in;

TI <= TI_in;

end

endmodule

//========================================================================================================




//========================================================================================================
// handles ext sys side
module ext_sys_side(input wire[1:0] half_buffer, output reg[1:0] half_buffer_in,
		input wire[1:0] full_buffer, output reg[1:0] full_buffer_in, input reg[1:0] error_reg);

always @(posedge half_buffer[0], posedge half_buffer[1])
begin

#2;
half_buffer_in = 2'b00;

end

always @(posedge full_buffer[0], posedge full_buffer[1])
begin

#2;
full_buffer_in = 2'b00;

end

endmodule

//========================================================================================================




//========================================================================================================


module DMA_top_tb;



reg[7:0] memory_start_address[1:0];
reg[7:0] memory_buffer_offset[1:0];

reg master_clk;

reg  enable_DMA;
reg RST;
wire[1:0] error_reg;

wire[1:0] half_buffer;
wire[1:0] half_buffer_in;

wire[1:0] full_buffer;
wire[1:0] full_buffer_in;

wire[7:0] addr;
wire[7:0] data_r;
wire[7:0] data_w;

// instantiating dut
DMA_top dut(

    .master_clk(master_clk),

    // Configuration registers
    .memory_start_address(memory_start_address),
    .memory_buffer_offset(memory_buffer_offset),

    // Control signals
    . enable_DMA(enable_DMA),
    .RST(RST),

    // UART interrupt signals
    .RI(RI),
    .RI_in(RI_in),
    .TI(TI),
    .TI_in(TI_in),

    // Error register
    .error_reg(error_reg),

    // Half buffer signals
    .half_buffer(half_buffer),
    .half_buffer_in(half_buffer_in),

    // Full buffer signals
    .full_buffer(full_buffer),
    .full_buffer_in(full_buffer_in),

    // APB interface
    .enable_ext(enable),
    .ready_ext(ready),
    .addr_ext(addr),
    .dir_ext(dir),
    .data_r_ext(data_r),
    .data_w_ext(data_w),
    .error_ext(error)

);



ext_sys_side ext_sys_side_inst(.half_buffer(half_buffer), .half_buffer_in(half_buffer_in), .full_buffer(full_buffer), .full_buffer_in(full_buffer_in), .error_reg(error_reg));

UART_side UART_side_inst(.RI(RI), .RI_in(RI_in), .TI(TI), .TI_in(TI_in), .enable_DMA( enable_DMA));

APB_side APB_side_inst(.enable(enable), .ready(ready), .dir(dir), .addr(addr), .data_w(data_w), .data_r(data_r), .error(error));



always #1 master_clk = ~master_clk;

initial begin

master_clk = 0;

$dumpfile("DMA.vcd");
$dumpvars();

memory_start_address[0][7:0] = 8'h02;
memory_buffer_offset[0][7:0] = 8'b00000100;

memory_start_address[1][7:0] = 8'h12;
memory_buffer_offset[1][7:0] = 8'b00000100;

 enable_DMA = 0;
RST = 1;
#2;

RST = 0;
#2;
 enable_DMA = 1;

#300;

$finish;

end


endmodule