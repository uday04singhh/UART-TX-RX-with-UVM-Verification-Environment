`include "uvm_macros.svh"
import uvm_pkg::*;

//configuration information that all other uvm components can use
class uart_config extends uvm_object;
    `uvm_object_utils(uart_config)

    function new(string name = "uart_config");  //constructor 
        super.new(name);    //calls the parent's constructor (uvm_object)
    endfunction 

    uvm_active_passive_enum is_active = UVM_ACTIVE; //inbuilt enum in UVM which has two types ACTIVE and PASSIVE
endclass                                            //Active me sequencer, driver, monitor sab hote hai, passive me sirf monitor hota hai

//different operational modes of the uart
typedef enum bit[3:0] {
    rand_baud_1_stop=0,
    rand_length_1_stop=1,
    length5wp=2,   //length 5 with parity
    length6wp=3,
    length7wp=4,
    length8wp=5,
    length5wop=6,  //length 5 without parity
    length6wop=7,
    length7wop=8,
    length8wop=9,
    rand_baud_2_stop=11,
    rand_length_2_stop=12
} oper_mode;

//TRANSACTION CLASS 
class transaction extends uvm_sequence_item;
    `uvm_object_utils(transaction)

    //all the fields definintion 
    rand oper_mode op;  //operation mode obj handle 
    logic tx_start,rx_start;
    logic rst;
    rand logic [7:0] tx_data;
    rand logic [16:0] baud;
    rand logic [3:0] length;
    rand logic parity_type, parity_en;
    logic stop2;
    logic tx_done, rx_done, tx_error, rx_error;
    logic [7:0] rx_out;

    constraint baud_c{
    baud inside {4800,9600,14400,19200,38400,57600};    //baud values from one of these values only 
    }

    constraint length_c{
        length inside {5,6,7,8};
    }

    function new(string name = "transaction");
        super.new(name);
    endfunction
endclass: transaction 





    //SEQUENCES 

    /*
    //baud = rand , lenght = 8, parity en = 1, parity type = rand, single stop 
    class rand_baud extends uvm_sequence #(transaction);
    `uvm_object_utils(rand_baud)

    transaction tr;

    function new(string name = "rand_baud");
        super.new(name);
    endfunction

    virtual task body();
        repeat(5)
            begin 
                tr = transaction::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize);   //saare rand fields ko randomize kardiya

                tr.op = rand_baud_1_stop;
                tr.length = 8;
                //tr.baud = 9600;
                tr.rst = 1'b0;
                tr.tx_start = 1'b1;
                tr.rx_start = 1'b1;
                tr.parity_en = 1'b1;
                tr.stop2 = 1'b0
                //randomised jo fields thi unme agar value set kardi toh voh value voh le lete hai, except parity type is still random
                finish_item(tr);
            end 
    endtask 
    endclass 

    //baud = rand , lenght = 8, parity en = 1, parity type = rand, double stop 
    class rand_baud_with_stop extends uvm_sequence #(transaction);
    `uvm_object_utils(rand_baud)

    transaction tr;

    function new(string name = "rand_baud_with_stop");
        super.new(name);
    endfunction

    virtual task body();
        repeat(5)
            begin 
                tr = transaction::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize);   //saare rand fields ko randomize kardiya

                tr.op = rand_baud_2_stop;
                tr.length = 8;
                //tr.baud = 9600;
                tr.rst = 1'b0;
                tr.tx_start = 1'b1;
                tr.rx_start = 1'b1;
                tr.parity_en = 1'b1;
                tr.stop2 = 1'b1;
                //randomised jo fields thi unme agar value set kardi toh voh value voh le lete hai, except parity type is still random
                finish_item(tr);
            end 
    endtask 
    endclass 


    //baud = rand , lenght = 5, parity en = 1, parity type = rand, double stop 
    class rand_baud_with_len5wp extends uvm_sequence #(transaction);
    `uvm_object_utils(rand_baud)

    transaction tr;

    function new(string name = "rand_baud_with_len5wp");
        super.new(name);
    endfunction

    virtual task body();
        repeat(5)
            begin 
                tr = transaction::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize);   //saare rand fields ko randomize kardiya

                tr.op = length5wp;
                tr.length = 5;
                //tr.baud = 9600;
                tr.rst = 1'b0;
                tr.tx_data = tx.data[7:8-length];
                tr.tx_start = 1'b1;
                tr.rx_start = 1'b1;
                tr.parity_en = 1'b1;
                tr.stop2 = 1'b0;
                //randomised jo fields thi unme agar value set kardi toh voh value voh le lete hai, except parity type is still random
                finish_item(tr);
            end 
    endtask 
    endclass 
    */ 

////////////////////////
//AISE TOH CASES BANATE REH JAOGE, BETTER HAI TO MAKE CONFIGURABLE SEQUENCE CLASS, CAUSE ONLY BAUD, LENGTH AND STOP2 CHANGES, AND THEN CHANGE THEM WHILE INSTANTIATING IT IN TEST CLASS
////////////////////////


//SEQUENCE CLASS
//baud = rand , lenght = rand, parity en = rand, parity type = rand, stop rand 
class uart_seq extends uvm_sequence #(transaction);
    `uvm_object_utils(uart_seq)

    transaction tr;

    //fields whose values will be variable according test case
    oper_mode mode;
    int length = 8; //default value 
    bit stop2 = 0;   
    bit parity_en = 1;

    function new(string name = "uart_seq");
        super.new(name);
    endfunction

    virtual task body();
        repeat(5)
            begin 
                tr = transaction::type_id::create("tr");
                start_item(tr);
                assert(tr.randomize);   //saare rand fields ko randomize kardiya

                tr.op = mode;   
                tr.length = length;
                tr.parity_en = parity_en;
                tr.stop2 = stop2;
               // tr.tx_data = tx_data[7:8-length];

                tr.rst = 1'b0;
                tr.tx_start = 1'b1;
                tr.rx_start = 1'b1;
                
                finish_item(tr);
            end 
    endtask 
endclass 


//DRIVER CLASS 
class driver extends uvm_driver#(transaction);
    `uvm_component_utils(driver);

    virtual uart_if vif; //The virtual keyword creates a handle/pointer that lets a class-based object (your driver) 
                                //reference an interface instance that was created in the static (module) world.
    transaction tr;             

    function new(input string path="drv", uvm_component parent=null); //driver constructor 
        super.new(path,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);   //parent (uvm_driver) ka build phase 
        tr=transaction::type_id::create("tr");

        //config_db "getting" the interface, error if it not found
        if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif))
            `uvm_error("drv","unable to access interface");
    endfunction

    task reset_dut();
        repeat(5)
            begin
                vif.rst<=1'b1;
                vif.tx_start<=1'b0;
                vif.rx_start<=1'b0;
                vif.tx_data<=8'h00;
                vif.baud<=16'h0;
                vif.length<=4'h0;
                vif.parity_type<=1'b0;
                vif.parity_en<=1'b0;
                vif.stop2<=1'b0;
                `uvm_info("DRV","System reset:Start of simulation", UVM_MEDIUM);
                @(posedge vif.clk);
            end
    endtask

    task drive();
        reset_dut();
        forever begin   //infinite loop
            seq_item_port.get_next_item(tr);    //TLM ports 

            vif.rst<=1'b0;
            vif.tx_start<=tr.tx_start;
            vif.rx_start<=tr.rx_start;
            vif.tx_data<=tr.tx_data;
            vif.baud<=tr.baud;
            vif.length<=tr.length;
            vif.parity_type<=tr.parity_type;
            vif.parity_en<=tr.parity_en;
            vif.stop2<=tr.stop2;

            `uvm_info("DRV",$sformatf("Baud:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d",
            tr.baud,tr.length,tr.parity_type,tr.parity_en,tr.stop2, tr.tx_data & (8'hFF >> (8-tr.length))),UVM_NONE);

            @(posedge vif.clk);         //wait for one clk edge after driving signal values
            @(posedge vif.tx_done);     //wait for tx and rx done, rx ka negedge so that we capture full pulse 
            @(negedge vif.rx_done);
            seq_item_port.item_done();  //tells sequencer that i am done with this item, send next

        end
    endtask

virtual task run_phase(uvm_phase phase);
    drive();
endtask

endclass


//MONITOR CLASS 
class mon extends uvm_monitor;
    `uvm_component_utils(mon);

    uvm_analysis_port#(transaction) send;   //push based TLM connection
    transaction tr;
    virtual uart_if vif;

    function new(input string inst="mon", uvm_component parent=null);   //monitor constructor 
        super.new(inst,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        tr=transaction::type_id::create("tr");
        send=new("send",this);      //constructs the TLM analysis port
        if(!uvm_config_db#(virtual uart_if)::get(this,"","vif",vif))
            `uvm_error("MON","unable to access interface");
    endfunction
    
    virtual task run_phase(uvm_phase phase);
    forever begin
        @(posedge vif.clk);
        if(vif.rst)
        begin
            tr.rst=1'b1;
            `uvm_info("MON","System Reset Detected ",UVM_NONE);
            send.write(tr);     //sends the handle to the object "tr"
        end
        else
        begin
            @(posedge vif.tx_done);
            tr.rst=1'b0;
            tr.tx_start=vif.tx_start;
            tr.rx_start=vif.rx_start;
            tr.tx_data=vif.tx_data;
            tr.baud=vif.baud;
            tr.length=vif.length;
            tr.parity_type=vif.parity_type;
            tr.parity_en=vif.parity_en;
            tr.stop2=vif.stop2;

            @(negedge vif.rx_done);

            tr.rx_out=vif.rx_out;

            `uvm_info("MON",$sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d RX_DATA:%0d",
            tr.baud, tr.length, tr.parity_type, tr.parity_en,
            tr.stop2, tr.tx_data & (8'hFF >> (8-tr.length)), tr.rx_out & (8'hFF >> (8-tr.length))), UVM_NONE);

            send.write(tr);
        end
    end
endtask
endclass


//SCOREBOARD
class sco extends uvm_scoreboard;
    `uvm_component_utils(sco)

    uvm_analysis_imp#(transaction,sco) recv;    //TLM implementation port (data type, implementation)
    //sco component implements write(), class sco knows what to do when transaction reaches at recv.
    bit [31:0] arr[32] = '{default:0};
    bit [31:0] addr=0;
    bit [31:0] data_rd=0;

    function new(input string inst="sco", uvm_component parent=null);
        super.new(inst,parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        recv=new("recv",this);
    endfunction

    virtual function void write(transaction tr);
        bit [7:0] mask;
        mask = (8'hFF >> (8 - tr.length));

        `uvm_info("SCO", $sformatf("BAUD:%0d LEN:%0d PAR_T:%0d PAR_EN:%0d STOP:%0d TX_DATA:%0d RX_DATA:%0d",
        tr.baud, tr.length, tr.parity_type, tr.parity_en, tr.stop2,
        tr.tx_data & mask, tr.rx_out & mask), UVM_NONE);

        if(tr.rst == 1'b1)
            `uvm_info("SCO", "System Reset", UVM_NONE)
        else if((tr.tx_data & mask) == (tr.rx_out & mask))
            `uvm_info("SCO", "Test Passed", UVM_NONE)
        else
            `uvm_info("SCO", "Test Failed", UVM_NONE)

        $display("........................................");
endfunction

endclass


//AGENT 
class agent extends uvm_agent;
    `uvm_component_utils(agent)
    uart_config cfg;

    function new(input string inst = "agent", uvm_component parent=null);   //agent ka constructor
        super.new(inst,parent);
    endfunction

    driver d;
    uvm_sequencer#(transaction) seqr;
    mon m;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cfg=uart_config::type_id::create("cfg");    //config_db object, sets to default value
        m=mon::type_id::create("m",this);           //monitor obj created

        if(cfg.is_active==UVM_ACTIVE)               //checks if config is active or not
        begin
            d=driver::type_id::create("d",this);
            seqr=uvm_sequencer#(transaction)::type_id::create("seqr",this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(cfg.is_active==UVM_ACTIVE) begin
            d.seq_item_port.connect(seqr.seq_item_export);  //pull based
        end
    endfunction

endclass


//ENVIRONMENT 
class env extends uvm_env;
    `uvm_component_utils(env)

    function new(input string inst="env", uvm_component c);
        super.new(inst,c);
    endfunction

    agent a;
    sco s;

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        a=agent::type_id::create("a",this);
        s=sco::type_id::create("s",this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        a.m.send.connect(s.recv);
    endfunction

endclass


//TEST 
class test extends uvm_test;
    `uvm_component_utils(test)

    function new(input string inst="test", uvm_component c);
        super.new(inst,c);
    endfunction

    env e;
    uart_seq seq;   

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        e = env::type_id::create("env", this);
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);    //raise an objection, sim runs till objection raised

        seq = uart_seq::type_id::create("seq1");
        seq.mode  = rand_baud_1_stop;
        seq.length   = 8;
        seq.stop2 = 0;
        seq.start(e.a.seqr);

        seq = uart_seq::type_id::create("seq2");
        seq.mode  = rand_baud_2_stop;
        seq.length   = 8;
        seq.stop2 = 1;
        seq.start(e.a.seqr);

        seq = uart_seq::type_id::create("seq3");
        seq.mode      = length6wp;
        seq.length      = 6;
        seq.parity_en = 1;
        seq.start(e.a.seqr);

        seq = uart_seq::type_id::create("seq4");
        seq.mode      = length5wop;
        seq.length      = 5;
        seq.parity_en = 0;
        seq.start(e.a.seqr);
        
        #20;
        phase.drop_objection(this);     //drops objection, sim ends 
    endtask 

endclass


module tb;
    uart_if vif();  //interface instantiation

    uart_top dut(
        .clk(vif.clk),
        .rst(vif.rst),
        .tx_start(vif.tx_start),
        .rx_start(vif.rx_start),
        .tx_data(vif.tx_data),
        .baud(vif.baud),
        .length(vif.length),
        .parity_type(vif.parity_type),
        .parity_en(vif.parity_en),
        .stop2(vif.stop2),
        .tx_done(vif.tx_done),
        .rx_done(vif.rx_done),
        .tx_err(vif.tx_err),
        .rx_err(vif.rx_err),
        .rx_out(vif.rx_out)
    );

    initial begin
        vif.clk <= 0;
    end

    always #10 vif.clk <= ~vif.clk;

    initial begin
        uvm_config_db#(virtual uart_if)::set(null, "*", "vif", vif);
        run_test("test");
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars;
    end

endmodule