module tb_dual_uart;

    // Testbench signals
    logic        clk;
    logic        reset;
    logic [11:0] paddr;
    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [31:0] pwdata;
    logic [31:0] prdata;
    logic        pready;
    
    // UART external signals
    logic uart0_txd, uart0_rxd;
    logic uart1_txd, uart1_rxd;
    logic uart0_interrupt, uart1_interrupt;
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100MHz clock (10ns period)
    end
    
    // DUT instantiation
    top u_dut (
        .clk(clk),
        .reset(reset),
        .paddr(paddr),
        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .pwdata(pwdata),
        .prdata(prdata),
        .pready(pready),
        .uart0_txd(uart0_txd),
        .uart0_rxd(uart0_rxd),
        .uart1_txd(uart1_txd),
        .uart1_rxd(uart1_rxd),
        .uart0_interrupt(uart0_interrupt),
        .uart1_interrupt(uart1_interrupt)
    );
    
    // APB transaction task
    task apb_write(input [11:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            paddr = addr;
            pwdata = data;
            pwrite = 1;
            psel = 1;
            penable = 0;
            
            @(posedge clk);
            penable = 1;
            
            @(posedge clk);
            wait(pready);
            
            @(posedge clk);
            psel = 0;
            penable = 0;
            pwrite = 0;
            
            $display("APB WRITE: Addr=0x%03h, Data=0x%08h at time %0t", addr, data, $time);
        end
    endtask
    
    task apb_read(input [11:0] addr, output [31:0] data);
        begin
            @(posedge clk);
            paddr = addr;
            pwrite = 0;
            psel = 1;
            penable = 0;
            
            @(posedge clk);
            penable = 1;
            
            @(posedge clk);
            wait(pready);
            data = prdata;
            
            @(posedge clk);
            psel = 0;
            penable = 0;
            
            $display("APB READ:  Addr=0x%03h, Data=0x%08h at time %0t", addr, data, $time);
        end
    endtask
    
    // Test stimulus
    logic [31:0] read_data;
    
    initial begin
        // Initialize signals
        reset = 1;
        paddr = 0;
        psel = 0;
        penable = 0;
        pwrite = 0;
        pwdata = 0;
        uart0_rxd = 1; // Idle state
        uart1_rxd = 1; // Idle state
        
        // Reset sequence
        #20;
        reset = 0;
        #20;
        
        $display("=== Starting Dual UART Test ===");
        
        // Test Channel 0 (UART0) - Address 0x000-0x00F
        $display("\n--- Testing UART Channel 0 ---");
        
        // Write to UART0 DATA register (simulate sending data)
        apb_write(12'h008, 32'h48); // Send 'H' (0x48)
        apb_write(12'h008, 32'h65); // Send 'e' (0x65)
        apb_write(12'h008, 32'h6C); // Send 'l' (0x6C)
        apb_write(12'h008, 32'h6C); // Send 'l' (0x6C)
        apb_write(12'h008, 32'h6F); // Send 'o' (0x6F)
        
        // Try to read from UART0 DATA register
        apb_read(12'h008, read_data);
        
        // Test Channel 1 (UART1) - Address 0x010-0x01F  
        $display("\n--- Testing UART Channel 1 ---");
        
        // Write to UART1 DATA register
        apb_write(12'h018, 32'h57); // Send 'W' (0x57)
        apb_write(12'h018, 32'h6F); // Send 'o' (0x6F)
        apb_write(12'h018, 32'h72); // Send 'r' (0x72)
        apb_write(12'h018, 32'h6C); // Send 'l' (0x6C)
        apb_write(12'h018, 32'h64); // Send 'd' (0x64)
        
        // Try to read from UART1 DATA register  
        apb_read(12'h018, read_data);
        
        // Test address decode - make sure channels are independent
        $display("\n--- Testing Channel Independence ---");
        apb_write(12'h008, 32'hAA); // Write to Channel 0
        apb_write(12'h018, 32'h55); // Write to Channel 1
        
        apb_read(12'h008, read_data); // Should get different data from each channel
        apb_read(12'h018, read_data);
        
        // Test other register addresses (even though they're not implemented yet)
        $display("\n--- Testing Other Register Addresses ---");
        apb_write(12'h000, 32'h0000000F); // UART0 CTRL
        apb_read(12'h004, read_data);      // UART0 STATUS
        apb_write(12'h00C, 32'h00001388); // UART0 BAUD
        
        apb_write(12'h010, 32'h0000000F); // UART1 CTRL
        apb_read(12'h014, read_data);      // UART1 STATUS
        apb_write(12'h01C, 32'h00001388); // UART1 BAUD
        
        // Monitor FIFO behavior
        $display("\n--- FIFO Status Monitoring ---");
        $display("UART0 TX FIFO: Full=%b, Empty=%b, Count=%d", 
                 u_dut.u_uart0.tx_full, u_dut.u_uart0.tx_empty, u_dut.u_uart0.tx_count);
        $display("UART0 RX FIFO: Full=%b, Empty=%b, Count=%d", 
                 u_dut.u_uart0.rx_full, u_dut.u_uart0.rx_empty, u_dut.u_uart0.rx_count);
        $display("UART1 TX FIFO: Full=%b, Empty=%b, Count=%d", 
                 u_dut.u_uart1.tx_full, u_dut.u_uart1.tx_empty, u_dut.u_uart1.tx_count);
        $display("UART1 RX FIFO: Full=%b, Empty=%b, Count=%d", 
                 u_dut.u_uart1.rx_full, u_dut.u_uart1.rx_empty, u_dut.u_uart1.rx_count);
        
        #100;
        $display("\n=== Test Completed ===");
        $finish;
    end
    
    // Monitor transactions
    always @(posedge clk) begin
        if (psel && penable && pready) begin
            if (pwrite) begin
                $display("MONITOR: WRITE to 0x%03h = 0x%08h (Channel %0d)", 
                        paddr, pwdata, paddr[4]);
            end else begin
                $display("MONITOR: READ from 0x%03h = 0x%08h (Channel %0d)", 
                        paddr, prdata, paddr[4]);
            end
        end
    end
    
    // Generate VCD for waveform viewing
    initial begin
        $dumpfile("dual_uart.vcd");
        $dumpvars(0, tb_dual_uart);
    end

endmodule
