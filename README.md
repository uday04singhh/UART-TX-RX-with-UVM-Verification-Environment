# UART-TX-RX-with-UVM-Verification-Environment
A configurable UART (Universal Asynchronous Receiver/Transmitter) design in SystemVerilog, verified with a complete UVM (Universal Verification Methodology) testbench.
Features

UART Design

Configurable baud rate (tested: 4800, 9600, 14400, 19200, 38400, 57600)
Configurable data length: 5, 6, 7, or 8 bits
Optional parity (even/odd) with error detection
1 or 2 stop bits
Start-bit glitch filtering and mid-bit sampling (16x oversampling) on the receiver

UVM Verification Environment

Constrained-random transaction (sequence item) covering baud, length, parity, and stop-bit configuration
Single parameterized sequence class (uart_seq) that generates every test scenario by setting fields before .start(), instead of one class per test case
driver — pulls transactions from the sequencer and drives them onto the DUT interface, synchronized to tx_done/rx_done
mon — passively samples the interface and broadcasts completed transactions via a uvm_analysis_port
sco (scoreboard) — self-checking comparison of transmitted vs. received data, masked to the actual data length
agent — configurable active/passive via a uart_config object (UVM_ACTIVE builds driver+sequencer+monitor; UVM_PASSIVE builds monitor only)
Full phase-based construction: build_phase → connect_phase → run_phase, using uvm_config_db to distribute the virtual interface
Project Structure
uart_rx.sv        — UART receiver RTL
uart_tx.sv        — UART transmitter RTL
uart_top.sv       — top-level UART wrapper
uart_if.sv        — SystemVerilog interface bundling all DUT signals
uvm_tb/
  uvm.sv          — transaction, sequence, driver, monitor, scoreboard, agent, env, test
  tb_top.sv       — top-level testbench module (clock gen, uvm_config_db::set, run_test)
Running the Simulation
bash
# Example (Vivado xsim / similar simulators)
xelab -L uvm tb_top -s tb_behav
xsim tb_behav -R

Waveforms are dumped to dump.vcd for inspection.

A Bug Worth Documenting

Early runs passed cleanly at LEN=8 but reported false failures at LEN=5 (and other reduced lengths). Root cause: the scoreboard compared the full 8-bit tx_data against rx_out, but for length < 8, only the lower length bits are ever transmitted — leaving tx_data's upper bits as random, never-transmitted noise while rx_out's upper bits were correctly zero-padded by the receiver.

Fix: mask both sides to the actual transmitted width before comparing:

systemverilog
mask = (8'hFF >> (8 - tr.length));
if ((tr.tx_data & mask) == (tr.rx_out & mask))
    `uvm_info("SCO", "Test Passed", UVM_NONE)

This is a good example of how a passing simulation and a correct scoreboard are not the same thing — the RTL was correct the whole time; the checker was comparing the wrong bits.

Sample Log Output
[DRV] Baud:4800  LEN:8 PAR_T:0 PAR_EN:1 STOP:0 TX_DATA:211
[MON] BAUD:4800  LEN:8 PAR_T:0 PAR_EN:1 STOP:0 TX_DATA:211 RX_DATA:211
[SCO] BAUD:4800  LEN:8 PAR_T:0 PAR_EN:1 STOP:0 TX_DATA:211 RX_DATA:211
[SCO] Test Passed
Possible Extensions
Functional coverage collection (baud × length × parity × stop-bit cross coverage)
Constrain tx_data's unused upper bits to zero at generation time, rather than masking at comparison time
Move uart_rx's data shift register out of the combinational always block into a clocked block for cleaner synthesis behavior
Add a reference/golden model for parity error injection testing
