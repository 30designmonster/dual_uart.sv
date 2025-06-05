// ===================================================================
// TOP MODULE - DUAL UART CONTROLLER
//AUTHOR:Praveen Saravanan
// ===================================================================
module top(
    // APB Bus Interface (from CPU/Bus Matrix)
    input  logic        clk,          // APB clock
    input  logic        reset,        // Reset (active high)
    input  logic [11:0] paddr,        // Address (12 bits = 4KB space)
    input  logic        psel,         // Select this peripheral
    input  logic        penable,      // Enable (2nd phase of APB)
    input  logic        pwrite,       // Write=1, Read=0
    input  logic [31:0] pwdata,       // Write data
    output logic [31:0] prdata,       // Read data
    output logic        pready,       // Transfer complete
    
    // External UART pins
    output logic        uart0_txd,    // Channel 0 TX
    input  logic        uart0_rxd,    // Channel 0 RX
    output logic        uart1_txd,    // Channel 1 TX
    input  logic        uart1_rxd,    // Channel 1 RX
    
    // Interrupts
    output logic        uart0_interrupt,
    output logic        uart1_interrupt
);

    // Internal signals for channel selection
    logic channel_sel;
    logic [3:0] reg_offset;
    logic apb_valid;
    
    // Channel 0 signals
    logic ch0_req, ch0_write, ch0_read, ch0_ready;
    logic [31:0] ch0_wdata, ch0_rdata;
    
    // Channel 1 signals  
    logic ch1_req, ch1_write, ch1_read, ch1_ready;
    logic [31:0] ch1_wdata, ch1_rdata;
    
    // Address decode
    assign channel_sel = paddr[4];        // 0=Channel0, 1=Channel1
    assign reg_offset = paddr[3:0];       // Register offset within channel
    assign apb_valid = psel & penable;    // Valid APB transaction
    
    // Channel request generation
    assign ch0_req = apb_valid & ~channel_sel;
    assign ch1_req = apb_valid & channel_sel;
    
    // Channel control signals
    assign ch0_write = ch0_req & pwrite;
    assign ch0_read = ch0_req & ~pwrite;
    assign ch0_wdata = pwdata;
    
    assign ch1_write = ch1_req & pwrite;
    assign ch1_read = ch1_req & ~pwrite;
    assign ch1_wdata = pwdata;
    
    // Response multiplexing
    assign prdata = channel_sel ? ch1_rdata : ch0_rdata;
    assign pready = channel_sel ? ch1_ready : ch0_ready;
    
    // UART Channel 0 instantiation
    uart_0 u_uart0 (
        .clk(clk),
        .rst(reset),
        .ch_req(ch0_req),
        .ch_addr(reg_offset),
        .ch_write(ch0_write),
        .ch_read(ch0_read),
        .ch_wdata(ch0_wdata),
        .ch_rdata(ch0_rdata),
        .ch_ready(ch0_ready),
        .uart_txd(uart0_txd),
        .uart_rxd(uart0_rxd)
    );
    
    // UART Channel 1 instantiation
    uart_1 u_uart1 (
        .clk(clk),
        .rst(reset),
        .ch_req(ch1_req),
        .ch_addr(reg_offset),
        .ch_write(ch1_write),
        .ch_read(ch1_read),
        .ch_wdata(ch1_wdata),
        .ch_rdata(ch1_rdata),
        .ch_ready(ch1_ready),
        .uart_txd(uart1_txd),
        .uart_rxd(uart1_rxd)
    );
    
    // Interrupt assignments (for now, just tie to ground)
    assign uart0_interrupt = 1'b0;
    assign uart1_interrupt = 1'b0;

endmodule
