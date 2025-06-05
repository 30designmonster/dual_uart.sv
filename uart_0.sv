module uart_0(
    // Clock/Reset
    input  logic        clk,
    input  logic        rst,
    
    // From Top Module (APB interface)
    input  logic        ch_req,       // Request valid
    input  logic [3:0]  ch_addr,      // Register offset
    input  logic        ch_write,
    input  logic        ch_read,      // Read enable
    input  logic [31:0] ch_wdata,     // Write data
    output logic [31:0] ch_rdata,     // Read data
    output logic        ch_ready,     // Response valid
    
    // External UART pins
    output logic        uart_txd,
    input  logic        uart_rxd
);   
  
  // Internal signals
  logic [7:0] cpu_data_to_tx, cpu_data_from_rx;
  logic [7:0] uart_data_from_tx, uart_data_to_rx;
  logic cpu_write, cpu_read, uart_write, uart_read;
  logic tx_full, tx_empty, rx_full, rx_empty;
  logic [4:0] tx_count, rx_count;
  
  // Register decode and control logic
  always_ff @(posedge clk) begin
    if (rst) begin
      ch_rdata <= 0;
      ch_ready <= 0;
    end else if (ch_req) begin
      ch_ready <= 1;
      if (ch_write) begin
        cpu_data_to_tx <= ch_wdata[7:0];
        cpu_write <= 1;
      end else if (ch_read) begin
        ch_rdata <= {24'b0, cpu_data_from_rx};
        cpu_read <= 1;
      end
    end else begin
      ch_ready <= 0;
      cpu_write <= 0;
      cpu_read <= 0;
    end
  end
  
  // RX FIFO instantiation
  rx_fifo #(.DEPTH(16)) fiforx0 (
    .clk      (clk),
    .rst_n    (~rst),
    .uart_write    (uart_write),
    .uart_data  (uart_data_to_rx),
    .cpu_read   (cpu_read),
    .cpu_data   (cpu_data_from_rx),
    .rx_full     (rx_full),
    .rx_empty    (rx_empty),
    .rx_count     (rx_count)
  );
      
  // TX FIFO instantiation  
  tx_fifo #(.DEPTH(16)) fifotx0 (
    .clk      (clk),
    .rst_n    (~rst),
    .cpu_write    (cpu_write),
    .cpu_data    (cpu_data_to_tx),
    .uart_read     (uart_read),
    .uart_data     (uart_data_from_tx),
    .tx_full     (tx_full),
    .tx_empty    (tx_empty),
    .tx_count     (tx_count)
  );
  
endmodule
