




// top module

module topmodule(
	
	input wire master_clk,

	input wire RX,
	output wire TX,

	output wire[7:0] TXb[8:0],
	output wire[7:0] RXb[8:0],

	input wire[7:0] memory_start_address[1:0],
	input wire[7:0] memory_buffer_offset[1:0],
	input wire enable_DMA,
	input wire RST,
	input wire[7:0] timerInitVal,
	input wire TE,
	input wire RE,
	
	output wire[1:0] error_reg,

	input wire[1:0] half_buffer_in,
	output wire[1:0] half_buffer,

	input wire[1:0] full_buffer_in,
	output wire[1:0] full_buffer

);






wire enable_dma;
wire ready_dma;
wire[7:0] addr_dma;
wire dir_dma;
wire[7:0] data_r_dma;
wire[7:0] data_w_dma;
wire error_dma;

wire RI;
wire RI_in;
wire TI;
wire TI_in;


//======================================================================

DMA_top DMA_top (
    .master_clk(master_clk),

    // Configuration registers
    .memory_start_address(memory_start_address),
    .memory_buffer_offset(memory_buffer_offset),

    // Control signals
    .enable_DMA(enable_DMA),
    .RST(RST),

    // UART interrupt signals
    .RI(RI), .RI_in(RI_in), .TI(TI), .TI_in(TI_in),

    // Error register
    .error_reg(error_reg),

    // Half buffer signals
    .half_buffer(half_buffer), .half_buffer_in(half_buffer_in),

    // Full buffer signals
    .full_buffer(full_buffer), .full_buffer_in(full_buffer_in),

    // APB interface
    .enable_ext(enable_dma), .ready_ext(ready_dma), .addr_ext(addr_dma), .dir_ext(dir_dma), .data_r_ext(data_r_dma), .data_w_ext(data_w_dma), .error_ext(error_dma)

);



wire[7:0] PWDATA;
wire[7:0] PRDATA;
wire[7:0] PADDR;
wire[1:0] PSEL;
wire PWRITE;
wire PENABLE;
wire[1:0] PREADY;
wire[1:0] PSLVERR;


//==============================================================================

APB_requester APB_requester_dma_side (

    .PCLK(master_clk),
    .ENABLE_DMA(enable_DMA),

    // Master peripheral (DMA) ports
    .data_w(data_w_dma),
    .data_r(data_r_dma),
    .addr(addr_dma),
    .dir(dir_dma),
    .error(error_dma),
    .enable(enable_dma),
    .ready(ready_dma),

    // APB buses and control signals
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PADDR(PADDR),
    .PSEL(PSEL),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PREADY(PREADY),
    .PSLVERR(PSLVERR)
);







wire enable_mem;
wire ready_mem;
wire[7:0] addr_mem;
wire dir_mem;
wire[7:0] data_r_mem;
wire[7:0] data_w_mem;
wire error_mem;
wire select_per_mem;

//=============================================================================

APB_completer APB_completer_memory_side(
    .PCLK(master_clk),
    .enable_DMA(enable_DMA),

    // Memory manager ports
    .enable(enable_mem),
    .ready(ready_mem),
    .addr(addr_mem),
    .data_w(data_w_mem),
    .data_r(data_r_mem),
    .dir(dir_mem),
    .error(error_mem),
    .select_per(select_per_mem),

    // APB buses and signals
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PADDR(PADDR),
    .PSEL(PSEL[0]),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PREADY(PREADY[0]),
    .PSLVERR(PSLVERR[0])
);










wire enable_uart;
wire ready_uart;
wire[7:0] addr_uart;
wire dir_uart;
wire[7:0] data_r_uart;
wire[7:0] data_w_uart;
wire error_uart;
wire select_per_uart;

//=======================================================================================


APB_completer APB_completer_uart_side (
    .PCLK(master_clk),
    .enable_DMA(enable_DMA),

    // Memory manager ports
    .enable(enable_uart),
    .ready(ready_uart),
    .addr(addr_uart),
    .data_w(data_w_uart),
    .data_r(data_r_uart),
    .dir(dir_uart),
    .error(error_uart),
    .select_per(select_per_uart),

    // APB buses and signals
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PADDR(PADDR),
    .PSEL(PSEL[1]),
    .PWRITE(PWRITE),
    .PENABLE(PENABLE),
    .PREADY(PREADY[1]),
    .PSLVERR(PSLVERR[1])
);





wire[7:0] TXbuff;
wire[7:0] RXbuff;

//=======================================================================================


UART_reg_map UART_reg_map(

    .enable_DMA(enable_DMA),

    .enable(enable_uart),
    .ready(ready_uart),
    .addr(addr_uart),
    .data_w(data_w_uart),
    .data_r(data_r_uart),
    .dir(dir_uart),
    .error(error_uart),
    .select_per(select_per_uart),

    // UART buffers
    .TXbuff(TXbuff),
    .RXbuff(RXbuff)
);


//=======================================================================================

uart uart(
    .master_clk(master_clk),
    .timerInitVal(timerInitVal),

    // Transmitter interface
    .TXbuff(TXbuff),
    .TE(TE),
    .TI(TI),
    .TI_in(TI_in),
    .TX(TX),

    // Receiver interface
    .RXbuff(RXbuff),
    .RE(RE),
    .RI(RI),
    .RI_in(RI_in),
    .RX(RX)
);


//=======================================================================================




memory memory(.enable(enable_mem), .ready(ready_mem), .addr(addr_mem), .data_w(data_w_mem), .data_r(data_r_mem),
.dir(dir_mem), .error(error_mem), .enable_DMA(enable_DMA), .select_per(select_per_mem), .TXb_1(TXb), .RXb_1(RXb));








endmodule