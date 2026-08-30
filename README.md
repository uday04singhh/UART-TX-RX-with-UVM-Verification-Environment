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
