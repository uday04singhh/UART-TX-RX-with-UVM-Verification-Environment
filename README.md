# UART TX/RX with UVM Verification Environment

A configurable UART (Universal Asynchronous Receiver/Transmitter) design in SystemVerilog, verified using a complete UVM (Universal Verification Methodology) testbench.

---

## ✦ Overview

This project implements a UART transmitter and receiver with configurable baud rate, data length, parity, and stop bits — verified through a self-checking UVM environment built from scratch (driver, monitor, scoreboard, sequencer, agent).

---

## ✦ Features

**UART Design**
- Configurable baud rate — tested at 4800, 9600, 14400, 19200, 38400, 57600
- Configurable data length — 5, 6, 7, or 8 bits
- Optional parity (even/odd) with error detection
- 1 or 2 stop bits
- 16x oversampling with mid-bit sampling and start-bit glitch filtering on the receiver

**UVM Verification Environment**
- Constrained-random `transaction` class covering baud, length, parity, and stop-bit fields
- Single parameterized `uart_seq` sequence class generating every test scenario — no per-case sequence classes
- `driver` — pulls transactions from the sequencer, drives the interface, synchronizes on `tx_done` / `rx_done`
- `mon` — passively samples the interface, broadcasts transactions via `uvm_analysis_port`
- `sco` — self-checking scoreboard comparing TX vs RX data, masked to the actual transmitted length
- `agent` — active/passive configurable via a `uart_config` object
- Full phase-based construction (`build_phase` → `connect_phase` → `run_phase`), interface distributed via `uvm_config_db`

---

## ✦ Project Structure
- uart_rx.sv        — UART receiver RTL
- uart_tx.sv        — UART transmitter RTL
- uart_top.sv       — top-level UART wrapper
- uart_if.sv        — SystemVerilog interface bundling all DUT signals
- uvm_tb/
  uvm.sv          — transaction, sequence, driver, monitor, scoreboard, agent, env, test
  tb_top.sv       — top-level testbench module (clock gen, uvm_config_db::set, run_test)

---

---

## ✦ Running the Simulation

```bash
xelab -L uvm tb_top -s tb_behav
xsim tb_behav -R
```

Waveforms are dumped to `dump.vcd` for inspection.

---

## ✦ A Bug Worth Documenting

Simulations passed cleanly at `LEN=8` but failed at `LEN=5` and other reduced lengths — even though the RTL was correct.

**Root cause:** the scoreboard compared the full 8-bit `tx_data` against `rx_out`. At `length < 8`, only the lower `length` bits are ever transmitted — leaving `tx_data`'s upper bits as random noise that never crossed the wire, while `rx_out`'s upper bits were correctly zero-padded by the receiver.

**Fix** — mask both sides to the actual transmitted width before comparing:

```systemverilog
mask = (8'hFF >> (8 - tr.length));
if ((tr.tx_data & mask) == (tr.rx_out & mask))
    `uvm_info("SCO", "Test Passed", UVM_NONE)
```

A good reminder that a passing simulation and a correct scoreboard aren't the same thing.

---

## ✦ Possible Extensions

- Functional coverage (baud × length × parity × stop-bit cross coverage)
- Constrain `tx_data`'s unused upper bits to zero at generation, rather than masking at comparison
- Move `uart_rx`'s shift register into a clocked block for cleaner synthesis behavior
- Golden reference model for parity error-injection testing
