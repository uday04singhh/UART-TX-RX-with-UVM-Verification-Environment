`timescale 1ns/1ps

module uart_tx (
    input wire tx_clk,
    input wire rst,
    input wire [7:0] tx_data,
    input wire tx_start, [3:0] length,
    input wire parity_en, parity_type, stop2,

    output reg tx, tx_error, tx_done
);

logic[7:0] tx_data_reg; //stores the incoming parallel data 

logic stop_b = 1;
logic start_bit = 0;
logic parity_bit = 0;
int count = 0; //DATA ki kitni bits chali gayi hai ?

typedef enum bit [2:0] {
    IDLE = 0,
    START = 1,
    DATA = 2,
    PARITY = 3,
    STOP_1 = 4,
    STOP_2 = 5,
    DONE = 6
} state_t;

state_t state = IDLE, next_state = IDLE;

//parity generator 
always @(posedge tx_clk) begin
    if (parity_type == 1) begin //ODD PARITY 
        case (length) 
            5: parity_bit <= ^tx_data_reg[7:3]; //bitwise XOR
            6: parity_bit <= ^tx_data_reg[7:2];
            7: parity_bit <= ^tx_data_reg[7:1];
            8: parity_bit <= ^tx_data_reg[7:0];
            default : parity_bit <= 0;
        endcase
    end

    else if (parity_type == 0) begin    //even parity 
        case (length) 
            5: parity_bit <= ~^tx_data_reg[7:3]; //bitwise XNOR
            6: parity_bit <= ~^tx_data_reg[7:2];
            7: parity_bit <= ~^tx_data_reg[7:1];
            8: parity_bit <= ~^tx_data_reg[7:0];
            default : parity_bit <= 1;
        endcase
    end
end

//SEQUENTIAL PATH ( state assignment at clk edges)
always @(posedge tx_clk) begin 
    if (rst) begin
        state <= IDLE;
    end 
    else 
    state <= next_state;
end 

//COMBINATIONAL PATH + DATA PATH 
always @(*) begin 
    case(state)
        IDLE: begin
            tx_data_reg = 8'b0;
            tx_done = 0;
            tx = 1'b1; //idle 
            tx_error = 0;
            if (tx_start) 
                next_state = START;
            else
                next_state = IDLE;
        end 

        START: begin
            tx_data_reg = tx_data;
            tx = start_bit; //start bit = 0
            next_state = DATA;
        end

        DATA: begin
            if(count < length -1 ) begin 
                next_state = DATA;
                tx = tx_data_reg[count];
            end 
            else if (parity_en) begin       //Basically len-1 tak toh le hi liya, last vale ke time dekh liya ki agar paroty en hai 
                next_state = PARITY;        // toh next state parity hoga, else stop_1 hoga
                tx = tx_data_reg[count];
            end 
            else begin 
                next_state = STOP_1;
                tx = tx_data_reg[count];
            end
        end 

        PARITY: begin
            next_state = STOP_1;
            tx = parity_bit;
        end

        STOP_1: begin
            tx = stop_b; //stop bit = 1
            if (stop2 == 1)  
                next_state = STOP_2;
            else 
                next_state = DONE;
        end 

        STOP_2: begin
            tx = stop_b; //stop bit = 1
            next_state = DONE;
        end

        DONE: begin
            tx_done = 1;
            next_state = IDLE;
        end

        default : next_state = IDLE;
        
    endcase 
end 

always @(posedge tx_clk)
  begin
    if(state == DATA)
      count <= count + 1;
    else
      count <= 0;
  end

endmodule 





                
            
                


