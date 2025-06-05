//RX FIFO inside each channel 
//Author:Praveen Saravanan
module rx_fifo #(
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // UART Interface
    input  logic                    uart_write,
    input  logic [7:0]              uart_data,
    
    // CPU Interface
    input  logic                    cpu_read,
    output logic [7:0]              cpu_data,
    
    // Status
    output logic                    rx_full,
    output logic                    rx_empty,
    output logic [ADDR_WIDTH:0]     rx_count
);

    logic [7:0] memory [0:DEPTH-1];
    logic [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (uart_write && !rx_full)
                wr_ptr <= wr_ptr + 1'b1;
            if (cpu_read && !rx_empty)
                rd_ptr <= rd_ptr + 1'b1;
        end
    end
    
    always_ff @(posedge clk) begin
        if (uart_write && !rx_full)
            memory[wr_ptr[ADDR_WIDTH-1:0]] <= uart_data;
    end
    
    assign cpu_data = memory[rd_ptr[ADDR_WIDTH-1:0]];
    assign rx_count = wr_ptr - rd_ptr;
    assign rx_empty = (wr_ptr == rd_ptr);
    assign rx_full = (rx_count == DEPTH);

endmodule
