`timescale 1ns/1ps

//clk generator module for rx and tx 
module clk_gen (
    input  wire clk,
    input  wire rst,
    input  wire [16:0] baud,
    output reg tx_clk, rx_clk
);

int rx_max = 0, tx_max = 0; //These variables store the value of no. of system clks
// required to generate the baud rate for rx and tx respectively (assuming to be 50MHz)
int rx_cnt = 0, tx_cnt = 0; //These variables store the value of no. of system clks after which 
// the tx and rx clk will be toggled

always @(posedge clk) begin
    if (rst) begin
        rx_max <= 0;
        tx_max <= 0;
        rx_cnt <= 0;
        tx_cnt <= 0;
    end 
    else begin 
        case (baud) 
            4800: begin
                rx_max <= 14'd651;      // 50MHz/(4800*16) = 651.0416667
                tx_max <= 14'd10416;    // 50MHz/(4800*16) = 10416.66667
            end
            9600: begin
                rx_max <= 14'd325;      
                tx_max <= 14'd5208;     
            end
            14400: begin
                rx_max <= 14'd217;      
                tx_max <= 14'd3472;     
            end
            19200: begin
                rx_max <= 14'd162;      
                tx_max <= 14'd2604;     
            end
            38400: begin
                rx_max <= 14'd81;       
                tx_max <= 14'd1302;    
            end
            57600: begin
                rx_max <= 14'd54;      
                tx_max <= 14'd868;      
            end
            115200: begin   
                rx_max <= 14'd27;      
                tx_max <= 14'd434;      
            end
            128000: begin   
                rx_max <= 14'd24;      
                tx_max <= 14'd392;      
            end
            default: begin 
                rx_max <= 14'd325;      
                tx_max <= 14'd5208;    
            end
        endcase 
    end
end 

// This case statement gives us the max number of system clock counts for each bit for tx and rx
// Isko ab clock me convert karne ke liye we divide by it by 2, half time high, half time low, creates posedge and negedge 


//rx cloxk 
always @(posedge clk) begin
    if(rst) begin
        rx_cnt <= 0;
        rx_max <= 0; 
        rx_clk <= 0;
    end
    else begin 
        if(rx_cnt <= rx_max) begin
            rx_cnt <= rx_cnt + 1;
        end
        else begin
            rx_cnt <= 0;
            rx_clk <= ~rx_clk; //toggle the clock
        end
    end 
end 


//tx clock 
always @(posedge clk) begin
    if(rst) begin
        tx_cnt <= 0;
        tx_max <= 0; 
        tx_clk <= 0;
    end
    else begin 
        if(tx_cnt <= tx_max) begin
            tx_cnt <= tx_cnt + 1;
        end
        else begin
            tx_cnt <= 0;
            tx_clk <= ~tx_clk; //toggle the clock
        end
    end 
end 

endmodule 


    






