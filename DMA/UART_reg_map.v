


// memory manager for UART peripheral

module UART_reg_map(
		
		input enable_DMA,

	// signals from APB completer
		input wire enable,
		output reg ready,
		input wire[7:0] addr,
		input wire[7:0] data_w,
		output reg[7:0] data_r,
		input wire dir,
		output reg error,
		input wire select_per,

	// UART buffers
		output reg[7:0] TXbuff,
		input wire[7:0] RXbuff
	
);




always @(posedge enable)
begin

if(select_per==1)
begin

ready <= 1;

case(addr)
	// RXbuff
	8'h81 : begin
		case(dir)
			0 : error <= 1;
			1 : data_r <= RXbuff;
		endcase
		end

	// TXbuff
	8'h82 : begin
		case(dir)
			0 : TXbuff <= data_w;
			1 : error <= 1;
		
		endcase

		end

endcase
end


end


always @(negedge enable)
begin

ready <= 0;

end


always @(posedge enable_DMA)
begin

error <= 0;
ready <= 0;

end



endmodule