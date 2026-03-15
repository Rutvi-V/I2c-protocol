`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    17:11:51 08/04/2025 
// Design Name: 
// Module Name:    i2c 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module i2c(
    input clk,
    input rst,
    input enable,
    input [6:0] addr,
    input [7:0] wdata,
    input rw,                 // 0 = write, 1 = read
    output reg [7:0] data_out,
    output reg ready,
    inout i2c_sda,
    inout i2c_scl
);

// FSM states
localparam IDLE = 0, START = 1, SEND_ADDR = 2, ADDR_ACK = 3,
           WRITE = 4, WRITE_ACK = 5, READ = 6, READ_ACK = 7, STOP = 8;

reg [3:0] state = IDLE;
reg [3:0] bit_cnt;
reg [7:0] shift_reg;
reg [7:0] saved_addr;
reg sda_out = 1;
reg sda_oe = 0;
reg scl_out = 1;

// Clock division
reg clk_div = 0;
always @(posedge clk) clk_div <= ~clk_div;

// SDA & SCL assignments
assign i2c_sda = (sda_oe == 1) ? sda_out : 1'bz;
assign i2c_scl = scl_out;

always @(posedge clk_div or posedge rst) begin
    if (rst) begin
        state <= IDLE;
        ready <= 1;
        sda_oe <= 0;
        sda_out <= 1;
        scl_out <= 1;
        bit_cnt <= 0;
        data_out <= 8'd0;
    end else begin
        case (state)
            IDLE: begin
                ready <= 1;
                if (enable == 1) begin
                    shift_reg <= {addr, rw};
                    saved_addr <= {addr, rw};
                    bit_cnt <= 7;
                    ready <= 0;
                    state <= START;
                end
            end

            START: begin
                sda_oe <= 1;
                sda_out <= 0;
                scl_out <= 1;
                state <= SEND_ADDR;
            end

            SEND_ADDR: begin
                scl_out <= 0;
                sda_out <= shift_reg[bit_cnt];
                scl_out <= 1;
                if (bit_cnt == 0)
                    state <= ADDR_ACK;
                else
                    bit_cnt <= bit_cnt - 1;
            end

            ADDR_ACK: begin
                scl_out <= 0;
                sda_oe <= 0; // release SDA
                scl_out <= 1;
                bit_cnt <= 7;
                shift_reg <= wdata;

                if (saved_addr[0] == 0)
                    state <= WRITE;
                else
                    state <= READ;
            end

            WRITE: begin
                sda_oe <= 1;
                scl_out <= 0;
                sda_out <= shift_reg[bit_cnt];
                scl_out <= 1;
                if (bit_cnt == 0)
                    state <= WRITE_ACK;
                else
                    bit_cnt <= bit_cnt - 1;
            end

            WRITE_ACK: begin
                sda_oe <= 0;
                scl_out <= 0;
                scl_out <= 1;
                state <= STOP;
            end

            READ: begin
                sda_oe <= 0;
                scl_out <= 0;
                scl_out <= 1;
                data_out[bit_cnt] <= i2c_sda;
                if (bit_cnt == 0)
                    state <= READ_ACK;
                else
                    bit_cnt <= bit_cnt - 1;
            end

            READ_ACK: begin
                sda_oe <= 1;
                sda_out <= 0;
                scl_out <= 1;
                state <= STOP;
            end

            STOP: begin
                sda_out <= 1;
                scl_out <= 1;
                sda_oe <= 1;
                state <= IDLE;
                ready <= 1;
            end
        endcase
    end
end

endmodule
