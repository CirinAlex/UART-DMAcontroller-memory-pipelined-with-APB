


# SoC subsystem : UART, DMA controller and Memory, interconnected via APB
An RTL design project using verilog. It aims to model an SoC subsystem mainly including UART, DMA controller and memory interfaced with APB.\
\
NB : *The documentation and directories are not complete. They are updated as the project developes.*

# Project progress : 100%

## Table of Contents


- [Overview](#overview)
- [System Architecture](#system-architecture)
- [Module Descriptions](#module-descriptions)
  - [UART](#uart)
  - [APB Interface](#apb-interface)
  - [DMA Controller](#dma-controller)
  - [Memory](#memory)
- [Directory Structure](#directory-structure)
- [Verification](#verification)
- [Simulation Results](#simulation-results)
- [LinkedIn Series](#linkedin-series)



## Overview

This project is an RTL implementation of an SoC subsystem featuring a UART, DMA Controller, and Memory Module, all interconnected through the AMBA APB (Advanced Peripheral Bus) protocol. The design focuses on scalable modular architecture, clean RTL coding practices, and subsystem-level integration concepts commonly used in digital IC design.

The key objective of this project is to showcase my independent design and engineering process. **The system architecture, pipelining, RTL implementation, debugging, verification strategy, and problem-solving decisions were developed manually WITHOUT following any tutorial or using ANY AI-assisted coding or design tools.** This repository reflects my personal understanding, research, and hands-on learning throughout the development cycle.

## System Architecture

### Overview
The system consist of a UART module, dual channel DMA controller, memory module all of these interconnected with AMBA APB interface. The system is designed to significantly lower the unwanted CPU attention during the use of UART. The CPU just have to do an initial configuration to UART module and DMA controller; the rest of the data transfer through UART will be handled by DMA controller autonomously.

### Basic Block Diagram
<img width="1095" height="792" alt="UART DMA block diagram" src="https://github.com/user-attachments/assets/306b294f-bb98-4c94-a931-55bd096fde3a" alt="Basic block diagram"/>


### Detailed Architecture Diagram
<img width="1968" height="1865" alt="UART DMA Detailed Architecture" src="https://github.com/user-attachments/assets/deb42bb2-00c8-4cef-a26a-8cebd0b6e40a" alt="Detailed architecture diagram"/>




### Components
- **APB master and slave interfaces** : serves the purpose of data transfer between external system, DMA controller, UART and memory.

- **UART** : Universal Asynchronous Serial Transmitter core implementation.
    - **CLK DIVIDER** : Divides external clock by 32.
    - **UART-TIMER** : 8-bit timer, used to produce baud rate. baud rate is fixed according to the value initialized to this timer through timerInitVal[8-bit].
    - **TX** : contains TX FSM and shift register.
    - **RX** : contains RX FSM and shift register.

- **DMA CONTROLLER** : Direct Memory Access controller handles data transfer between UART and memory.
    - **TX CHANNEL** : It handles data transfer from memory buffer allocated for transmission to TX of UART.
    - **RX CHANNEL** : It handles data transfer from RX of UART to memory buffer allocated to store the recieved data.

- **MEMORY** : Represents the main memory of the external system. The buffers for TX and RX are allocated within this memory.

### Registers
#### Control registers
  - **TE** : Enables transmission through UART.
  - **RE** : Enables reception through UART.
  - **DMA_enable** : Enables DMA controller. The DMA should be enabled only after TE and RE are enabled.

#### Configuration registers
  - **timerInitVal** : the value in this register determines baud rate. Baud rate = Fosc/(32 x (256-timerInitVal))
  - **Memory_buff_strt_addr** : Starting address of the buffer allocated for TX or RX.
  - **Memory_buff_offset** : Size of the buffer allocated for TX or RX.

#### Control signals *or also internal register*
  - **TI** : Transmission completed Interrupt signal. Driven by UART TX.
  - **TI_in** : signal driven by DMA controller to clear TI
  - **RI** : Reception completed interrupt driven by UART RX.
  - **RI_in** : signal driven by DMA controller to clear RI.
  - **TXI** : Driven by DMA. Signals the external system that all the bytes from allocated memory buffer has been transmitted (transmission complete).
  - **RXI** : Driven by DMA. Signals the external system that the allocated buffer for reception is full.

### Design and Dataflow
The system is designed to operate at a clock frequency of 11.0592MHz. This frequency makes it easy to produce standard baud rates after divisions.\
The CLK_DIVIDER divides clock frequency by 32 and the divided clock functions as the clock of UART-TIMER. The real-time value of UART-TIMER (timerCurrentVal) is given to the RX and TX shift registers to recieve and transmit data with respect to the baud rate.\
\
Baud rate = Fosc/(32 x (256-timerInitVal))\
\
The external system follows these steps in order
- Writes values to the configuration registers according to the need.
- Enables RE and TE
- Enables the DMA controller through DMA_enable

After this the DMA controller takes over the handling of data transfer to and from UART.\
In case of TX, the DMA controller starts to read the bytes from Memory_buff_strt_addr and write to the TXbuff(*internal buffer of UART to write the byte to transmit*). From there the TX of UART moves this byte to an internal shift register, adds start and stop bits to create UART frame. The shift register shifts according to the baud rate provided from UART-TIMER. After 1 byte is transferred, the UART TX pulls up the TI, on the positive edge of this TI, the DMA controller increments the internal address pointer register that stores the address of memory to be transmitted. DMA reads the byte from this memory address, writes to UART TXbuff and pulls down TI through TI_in and continues this process until all the bytes in memory buffer for TX is transmitted.\
In case of RX, when RX pin recieves a start-bit, the time to sample RX is calculated from value of timer at that instant and the timerInitVal. The shift register then samples and shifts RX on this time. The timer value to sample RX is calculated such that the sampling is done at the middle of the bit. On completing one full byte, the UART RX writes the byte to RXbuff and pulls up the RI. The DMA controller reads the byte from RXbuff, writes to the memory buffer for RX by incrementing internal address pointer register. It then pulls down the RI through RI_in to resume reception.\
The data transfer between DMA controller, UART and memory are carried out via AMBA APB interface.

The DMA controller signals the external system when\
- RX memory buffer is full (RXI)
- All bytes in TX memory buffer is finished transmitting. (TXI).

This helps the external system to update the memory buffer to continue data transfer.

## Module Descriptions
### UART
The top module and all the instantiations in each of the module is shown below.

  - <ins>UARTtop</ins> *(master_clk, timerInitVal[7:0], TXbuff[7:0], TE, TI, TI_in, TX, pwrite, RXbuff[7:0], RE, RI, RI_in, RX)*
    - <ins>RXtop</ins> *(RE, RX, RI, RXbuff[7:0], timerCurrentVal[7:0], timerInitVal[7:0], RI_in)*
      - <ins>RXshift</ins> *(enableIN, ready, timerCurrentVal[7:0], timerInitVal[7:0], RX, RXbuff[7:0])*
    - <ins>TXtop</ins> *(timerCurrentVal[7:0], TXbuff[7:0], TE, TI_in, TI, TX, clk, pwrite)*
      - <ins>TXshift</ins> *(timerCurrentVal[7:0], TXbuff[7:0], TXshiftenable, clk, TXshiftready, TX)*
    - <ins>uart_timer</ins> *(uart_clk, timerInitVal[7:0], timerCurrentVal[7:0])*
    - <ins>clk_divider</ins> *(master_clk, uart_clk, RE, TE)*



The UART module handles the data transfer in accordance with UART protocol. The RXtop and TXtop are the implementation of FSMs for the reception and transmission of data respectively in accordance with the baud rate generated by uart_timer. The clock that drives uart_timer is produced by clk_divider which functions as a clock divider that divides the master clock by 32. The RXshift and TXshift are the internal shift registers that carries out the reception and transmission.

### APB Interface
- <ins>APB_requester</ins> *(PCLK, ENABLE_DMA, data_w[7:0], data_r[7:0], addr[7:0], dir, error, enable, ready, PWDATA[7:0], PRDATA[7:0], PADDR[7:0], PSEL[1:0], PWRITE, PENABLE, PREADY[1:0], PSLVERR[1:0])*
- <ins>APB_completer</ins> *(PCLK, ENABLE_DMA, enable, ready, addr[7:0], data_w[7:0], data_r[7:0], dir, error, PWDATA[7:0], PRDATA[7:0], PADDR[7:0], PSEL, PWRITE, PENABLE, PREADY, PSLVERR)*

To implement the interface, these two modules are instantiated and the APB bus and control signals are connected together. There must be an instantiation of the completer for each slave peripheral (In the context of this project, one instantiation for memory and one for UART). The requester must be controlled by the master (here, DMA controller).

The requester is given the operation (dir; 1=write, 0=read), data to write (data_w of requester) for write operation, address (addr) and then enabled (enable). Then the requester will perform the handshake and transfer with the completer. When transfer is complete, the data_r loaded with read data(on read operation) and the requester pulls up the ready signal. In case of error, the error signal is also pulled up.\

During the transfer, in the completer side, the data_w (of completer; only on write operation) is loaded with data to write, dir (of completer) with 1 for write and 0 for read and then, enable is pulled up. If dir is 0 (read operation), the peripheral must provide the data at addr (if addr and operation is valid; if invalid, error = 1) to the completer data_r.

### DMA Controller
This is a dual channel circular mode DMA controller hardwired for RX and TX of UART. One channel for RX and other for TX. The top module of DMA controller handles the bus multiplexing of APB bus for the channels through fixed priority based arbitration. It raises the error interrupt to external system if any channel recieves it. Each channel has two registers, memory_buff_strt_addr and memory_buff_offset. These are configurable registers that store the start address and size of the memory buffer allocated for each channels respectively.
#### DMA channel
The DMA channel handles the data transfer between peripheral(UART) and memory on each interrupt (RI/TI). Each channel has an 8 state FSM. The external system first need to configure the memory_buff_strt_addr and memory_buff_offset, then enable the DMA. The DMA channel will give an interrupt when memory buffer is half, and another interrupt when memory buffer is full. When the memory buffer is full, the FSM enters a waiting to configure state. The external system can either disable the DMA and then reconfigure the registers or just disable and enable the DMA to resume the transfers.
### Memory
Memory module is created only for the purpose of simulation.

## Directory Structure
```
UART-DMAcontroller-Memory-pipelined-with-APB/
│   .gitignore
│   README.md
│   top.vcd
│   topmodule.v
│   topmodule_tb.v
│   val.hex
│   valin.hex
│   valout.hex
│
├───APB/
│   │   README.md
│   │
│   ├───modules/
│   │       APB_completer.v
│   │       APB_requester.v
│   │
│   ├───testbenches/
│   │       APB_requester_tb.v
│   │       APB_req_comp_tb.v
│   │
│   └───VCD/
│           APB.vcd
│           APB_requester.vcd
│
├───DMA/
│   │   DMA.vcd
│   │   DMA_top.v
│   │   DMA_top_tb.v
│   │   README.md
│   │   UART_reg_map.v
│   │
│   ├───RXchannel/
│   │   │   DMARX.vcd
│   │   │   README.md
│   │   │
│   │   ├───modules/
│   │   │       addr_mng_RX.v
│   │   │       DMAchannelRX.v
│   │   │
│   │   ├───testbenches/
│   │   │       addr_mng_tb.v
│   │   │       DMAchannelRX_tb.v
│   │   │
│   │   └───VCD/
│   │           addr_mng.vcd
│   │           DMARX.vcd
│   │
│   └───TXchannel/
│       │
│       ├───modules/
│       │       addr_mng_TX.v
│       │       DMAchannelTX.v
│       │
│       ├───testbenches/
│       │       addr_mng_tb.v
│       │       DMAchannelTX_tb.v
│       │
│       └───VCD/
│               DMATX.vcd
│
├───MEMORY/
│       memory.v
│
└───UART/
    │   README.md
    │
    ├───modules/
    │   │   clk_divider.v
    │   │   README.md
    │   │   UARTtop.v
    │   │   uart_timer.v
    │   │
    │   ├───RX/
    │   │       RXshift.v
    │   │       RXtop.v
    │   │
    │   └───TX/
    │           TXshift.v
    │           TXtop.v
    │
    ├───testbenches/
    │   │   clk_divider_tb.v
    │   │   UART_tb.v
    │   │   uart_timer_tb.v
    │   │
    │   ├───RX/
    │   │       RXshift_tb.v
    │   │       RXtop_tb.v
    │   │
    │   └───TX/
    │           TXshift_tb.v
    │           TXtop_tb.v
    │
    └───VCD/
        │   clk_divider.vcd
        │   uart.vcd
        │   uart_timer.vcd
        │
        ├───RX/
        │       RXshift.vcd
        │       RXtop.vcd
        │
        └───TX/
                TXshift.vcd
                TXtop.vcd

```
## Verification
To be updated

## Simulation Results
### UART
<img width="1920" height="1080" alt="Screenshot 2026-06-05 022958" src="https://github.com/user-attachments/assets/a0b73915-4dfb-4fd9-8b42-8dc909b9b009" />

### APB Interface
<table>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/8dd106de-5e15-4c0a-a990-bc71e693e04e" width="500"><br>
      <b>Read Transaction (No Error)</b>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/461cf884-1810-4722-bbc9-03db6b20c6e1" width="500"><br>
      <b>Read Transaction (Error Response)</b>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/beb374f2-637d-4d56-98bf-a4ff231db13d" width="500"><br>
      <b>Write Transaction (No Error)</b>
    </td>
    <td align="center">
      <img src="https://github.com/user-attachments/assets/7f831376-e359-4465-a2b5-93deb91d78c3" width="500"><br>
      <b>Write Transaction (Error Response)</b>
    </td>
  </tr>
</table>

### DMA controller
#### DMA RX channel
<img width="1334" height="761" alt="Screenshot 2026-06-23 181521" src="https://github.com/user-attachments/assets/476ea867-f9b7-404b-9c4a-6b7471c94881" />

#### DMA TX channel
<img width="1368" height="750" alt="Screenshot 2026-06-23 220416" src="https://github.com/user-attachments/assets/ce30de7b-d445-4646-b59f-195540e5d06b" />

### top module
<img width="1031" height="630" alt="Screenshot 2026-07-05 185834" src="https://github.com/user-attachments/assets/a482c00f-6e41-4c99-8c2b-ce91b60f025b" />

## LinkedIn Series
