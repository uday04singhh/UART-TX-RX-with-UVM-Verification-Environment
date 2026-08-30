`timescale 1ns/1ps

module uart_rx(
    input rx_clk, rst, rx_start, parity_en, parity_type, stop2,
    input [3:0] length, 
    input rx,

    output reg [7:0] rx_out,
    output reg rx_error, rx_done
);

logic [7:0] rx_data_reg; //stores the incoming data into a single byte for parallel output 
int parity = 0;
int count = 0;      //clk cycle count for 16 counts (to find middle bit)
int bit_count = 0;  //to count no. of bits received

typedef enum bit [2:0] {
    IDLE = 0,
    START = 1,  //start bit received
    DATA = 2,
    PARITY = 3,
    STOP_1 = 4,
    STOP_2 = 5,
    DONE = 6
} state_t;

state_t state = IDLE, next_state = IDLE;

always @(posedge rx_clk) begin
    if (rst) begin
        state <= IDLE;
    end 
    else begin
        state <= next_state;
    end
end

always @(*) begin
    case(state)
        IDLE : begin 
            rx_done = 0;
            rx_error = 0; 
            if (rx_start && !rx) begin  //jaise hi pehla LOW aaya rx pe
                next_state = START;
            end
            else begin
                next_state = IDLE;
            end
        end 

        START : begin 
            if (count == 7 && rx)   //ab check kar rahe hai yaha ki jo pehle LOW voh glitch toh nhi tha 
                next_state = IDLE;
            else if (count == 15)  //agar 16th cycle tak bhi then its START bit 
                next_state = DATA;
            else
                next_state = START;
        end 

        DATA : begin 
            if(count == 7)
                rx_data_reg = {rx, rx_data_reg[7:1]}; 
                // Before: rx_data_reg = [d7 d6 d5 d4 d3 d2 d1 d0]
                // After:  rx_data_reg = [rx d7 d6 d5 d4 d3 d2 d1]   (d0 falls off, rx enters at top)
                //UART sends LSB first, so essentially we right shift the data reg
            else if (count == 15 && bit_count == (length - 1) ) begin
                case(length) 
                    5: rx_out = rx_data_reg[7:3];
                    6: rx_out = rx_data_reg[7:2];
                    7: rx_out = rx_data_reg[7:1];
                    8: rx_out = rx_data_reg[7:0];
                    default: rx_out = 8'b0;
                endcase

                //Now that we have the data in a reg (parallel), we can find the parity bit (check its value)

                if (parity_type == 1) begin
                    case(length)
                        5: parity =^ rx_data_reg[7:3];
                        6: parity =^ rx_data_reg[7:2];
                        7: parity =^ rx_data_reg[7:1];
                        8: parity =^ rx_data_reg[7:0];
                        default: parity = 0;
                    endcase 
                end
                else if (parity_type == 0) begin
                    case(length)
                        5: parity = ~^ rx_data_reg[7:3];
                        6: parity = ~^ rx_data_reg[7:2];
                        7: parity = ~^ rx_data_reg[7:1];
                        8: parity = ~^ rx_data_reg[7:0];
                        default: parity = 0;
                    endcase
                end
                if (parity_en) begin
                        next_state = PARITY;
                    end
                    else begin
                        next_state = STOP_1;
                    end
            end 
            
            else 
                next_state = DATA;
        end 

        PARITY : begin
            if (count == 7) begin 
                if (rx == parity)
                    rx_error = 0;
                else
                    rx_error = 1;
            end 
            else if (count == 15)
                next_state = STOP_1;
            else 
                next_state = PARITY;
        end 

        STOP_1 : begin
            if (count == 7) begin 
                if (!rx) 
                    rx_error = 1;
                else
                    rx_error = 0;
            end 
            else if (count == 15) begin 
                if(stop2)
                    next_state = STOP_2;
                else
                    next_state = DONE;
            end 
            else 
                next_state = STOP_1;
        end

        STOP_2 : begin
            if (count == 7) begin 
                if (!rx) 
                    rx_error = 1;
                else
                    rx_error = 0;
            end 
            else if (count == 15) begin 
                next_state = DONE;
            end 
        end 

        DONE : begin
            rx_done = 1;
            rx_error = 0;
            next_state = IDLE;
        end
    endcase 
end 

//rx count logic 
always @(posedge rx_clk) begin
    case(state)
    IDLE: begin 
        count <= 0 ;
        bit_count <= 0;
    end

    START, PARITY, STOP_1, STOP_2 : begin
        if (count < 15) begin
            count <= count + 1;
        end
        else begin
            count <= 0;
        end
    end 

    DATA: begin
        if (count < 15) begin
            count <= count + 1;
        end
        else begin
            count <= 0;
            bit_count <= bit_count + 1;
        end
    end

    DONE : begin 
        count <= 0;
        bit_count <= 0;
    end
    endcase 
end 

endmodule 

        





            
            


            



