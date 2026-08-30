
interface uart_if;
    logic clk,rst;
    logic tx_start,rx_start;
    logic [7:0] tx_data;
    logic [16:0] baud;
    logic [3:0] length;
    logic parity_type, parity_en;
    logic stop2;
    logic tx_done,rx_done,tx_err,rx_err;
    logic [7:0] rx_out;

endinterface