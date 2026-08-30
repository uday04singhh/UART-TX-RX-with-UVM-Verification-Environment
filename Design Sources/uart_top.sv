`timescale 1ns/1ps

module uart_top(
    input clk,rst,
    input tx_start,rx_start,
    input [7:0] tx_data,
    input [16:0] baud,
    input [3:0] length,
    input parity_type, parity_en,
    input stop2,
    output tx_done,rx_done,tx_err,rx_err,
    output [7:0] rx_out
);

wire tx_clk,rx_clk;
wire tx_rx;

clk_gen clk_gen_inst(
    .clk(clk),
    .rst(rst),
    .baud(baud),
    .tx_clk(tx_clk),
    .rx_clk(rx_clk)
);

uart_tx uart_tx_inst(
    .tx_clk(tx_clk),
    .rst(rst),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .length(length),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .stop2(stop2),
    .tx(tx_rx),
    .tx_error(tx_err),
    .tx_done(tx_done)
);

uart_rx uart_rx_inst(
    .rx_clk(rx_clk),
    .rst(rst),
    .rx_start(rx_start),
    .length(length),
    .parity_en(parity_en),
    .parity_type(parity_type),
    .stop2(stop2),
    .rx(tx_rx),
    .rx_out(rx_out),
    .rx_error(rx_err),
    .rx_done(rx_done)
);

endmodule 