



module topmodule_tb;





reg master_clk;
wire XX;
reg[7:0] memory_start_address[1:0];
reg[7:0] memory_buffer_offset[1:0];
reg enable_DMA;
reg RST;
reg[7:0] timerInitVal;
reg TE;
reg RE;
wire[1:0] error_reg;
reg[1:0] half_buffer_in;
reg[1:0] full_buffer_in;

wire[1:0] half_buffer;
wire[1:0] full_buffer;


topmodule dut(

    .master_clk(master_clk),

    .RX(XX), .TX(XX),
    .memory_start_address(memory_start_address), .memory_buffer_offset(memory_buffer_offset),
    .enable_DMA(enable_DMA), .RST(RST), .timerInitVal(timerInitVal),
    .TE(TE), .RE(RE),
    .error_reg(error_reg),
    .half_buffer_in(half_buffer_in), .half_buffer(half_buffer),
    .full_buffer_in(full_buffer_in), .full_buffer(full_buffer)
);



always #10 master_clk = ~master_clk;

initial begin




$dumpfile("top.vcd");
$dumpvars();

RST = 1;
#1;
RST = 0;
#1;
RST = 1;
#1;

master_clk = 0;
enable_DMA = 0;

TE = 0;
RE = 0;

memory_start_address[0] = 8'd10;
memory_buffer_offset[0] = 8'd6;

memory_start_address[1] = 8'd30;
memory_buffer_offset[1] = 8'd6;;

timerInitVal = 8'd253;


$readmemh("val.hex", dut.memory.mem, 8'd10, 8'd17);

#2;

enable_DMA = 1;

#2;
TE = 1;
RE = 1;
#2;

#300000;
$writememh("valout.hex", dut.memory.mem, 8'd30, 8'd37);
$writememh("valin.hex", dut.memory.mem, 8'd10, 8'd20);

$finish;



end

endmodule