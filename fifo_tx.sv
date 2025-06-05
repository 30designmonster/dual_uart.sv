//Transmits data from UART channel
//Author:Praveen Saravanan
module tx_fifo #(
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
) (
    input  logic                    clk,
    input  logic                    rst_n,
    
    // CPU Interface
    input  logic                    cpu_write,
    input  logic [7:0]              cpu_data,
    
    // UART Interface  
    input  logic                    uart_read,
    output logic [7:0]              uart_data,
    
    // Status
    output logic                    tx_full,
    output logic                    tx_empty,
    output logic [ADDR_WIDTH:0]     tx_count
);

    logic [7:0] memory [0:DEPTH-1];
    logic [ADDR_WIDTH:0] wr_ptr, rd_ptr;
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
        end else begin
            if (cpu_write && !tx_full)
                wr_ptr <= wr_ptr + 1'b1;
            if (uart_read && !tx_empty)
                rd_ptr <= rd_ptr + 1'b1;
        end
    end
    
    always_ff @(posedge clk) begin
        if (cpu_write && !tx_full)
            memory[wr_ptr[ADDR_WIDTH-1:0]] <= cpu_data;
    end
    
    assign uart_data = memory[rd_ptr[ADDR_WIDTH-1:0]];
    assign tx_count = wr_ptr - rd_ptr;
    assign tx_empty = (wr_ptr == rd_ptr);
    assign tx_full = (tx_count == DEPTH);

endmodule
