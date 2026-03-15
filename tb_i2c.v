`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   18:32:48 08/04/2025
// Design Name:   i2c
// Module Name:   D:/i2c/tb_i2c.v
// Project Name:  i2c
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: i2c
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////
`timescale 1ns / 1ps

module tb_i2c;

reg clk;
reg rst;
reg enable;
reg [6:0] addr;
reg [7:0] wdata;
reg rw;
wire [7:0] data_out;
wire ready;
wire i2c_sda;
wire i2c_scl;

reg sda_slave;
wire sda_line;

// Instantiate DUT
i2c uut (
    .clk(clk),
    .rst(rst),
    .enable(enable),
    .addr(addr),
    .wdata(wdata),
    .rw(rw),
    .data_out(data_out),
    .ready(ready),
    .i2c_sda(sda_line),
    .i2c_scl(i2c_scl)
);

// Slave side SDA behavior
assign sda_line = uut.sda_oe ? uut.sda_out : sda_slave;

initial begin
    // Generate clock
    clk = 0;
    forever #10 clk = ~clk; // 50 MHz
end

initial begin
    // Initialize
    rst = 1;
    enable = 0;
    addr = 7'b1010101;
    wdata = 8'hA5;
    rw = 0;  // Write

    sda_slave = 1;

    #100;
    rst = 0;

    // Wait a bit and start I2C
    #100;
    enable = 1;

    #20;
    enable = 0;

    // Simulate ACK from slave (pull SDA low)
    wait (uut.state == 3); // ADDR_ACK
    #20 sda_slave = 0;
    #40 sda_slave = 1;

    wait (uut.state == 5); // WRITE_ACK
    #20 sda_slave = 0;
    #40 sda_slave = 1;

    // Wait for transaction to finish
    wait (ready);

end

endmodule
