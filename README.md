# 🚀 Tejas-RV32-LinuxCPU

🧠 An open-source, research-oriented RISC-V CPU RTL project inspired by SHAKTI IIT Madras, aimed at evolving from a minimal multicycle RV32I core into a full-fledged Linux-capable, multicore SoC, including MMU, caches, and advanced pipelines.

---

## 📌 Project Goals

This repository is dedicated to designing a synthesizable, modular RISC-V CPU RTL starting from a **multicycle RV32I core**, and systematically evolving through stages to:

- ✔️ Support RV32IMFAC ISA
- ✔️ Integrate a pipelined FPU for floating-point workloads
- ✔️ Implement byte-addressable dual-port BRAM memory
- ✔️ Pass all [riscv-arch-test](https://github.com/riscv/riscv-arch-test) ISA testbenches
- ✔️ Add AXI + UART peripherals for Hello World and I/O debugging
- ✔️ Boot FreeRTOS and eventually a full Linux build
- 🧩 Transition from in-order to out-of-order superscalar pipeline
- 🧠 Support multi-core scalability with cache coherence and NoC interconnect

---

## 🧭 Processor / SoC Details

### Multi-Cycle Single-Core RV32IMFAC CPU
- Implements fetch-decode-execute-memory-writeback for educational clarity.
- Modules:
  - `core.v`: Top-level CPU instantiation
  - `fetch.v`: Program counter and instruction fetch
  - `decoder.v`: Instruction decoding to control signals
  - `alu.v`: Integer ALU operations (add, sub, logic)
  - `fpu.v`: Floating-point operations (RV32F)
  - `control_unit.v`: Multicycle FSM control
  - `decompresser.v`: RV32C compressed instruction decoding
  - `dual_port_cache.v`: Dual-port memory interface
  - `register_file.v`: 32x32 registers with multi-port reads/writes
  - `uart.v`: AXI-lite UART interface

---

### Five-Stage Pipelined RV32 Processor
- Classic IF–ID–EX–MEM–WB pipeline for higher instruction throughput.
- Includes forwarding and hazard detection.
- Modules:
  - `RISC_V_Processor_Pipelined.v`: Top-level pipeline CPU
  - Pipeline registers: `IFID.v`, `id_ex.v`, `EXMEM.v`, `WB.v`
  - ALU modules: `ALU.v`, `ALU_Control.v`
  - Forwarding and hazard units: `forwarding_unit.v`, `hazard_unit.v`
  - Branch evaluation: `branching_unit.v`
  - Memories: `instr_mem.v`, `data_memory.v`
  - Program counter: `program_counter.v`

---

### Superscalar In-Order Processor
- Dual-issue pipeline enabling two instructions per cycle.
- Dual decode and execution pipelines with dispatch buffer.
- Modules:
  - `Fetch.v`, `IFIDReg.v`: Frontend fetch and buffers
  - `Decoder.v`, `DispatchBuffer.v`: Dual instruction decode/dispatch
  - `ExecuteBuffer.v`, `ALU.v`: Execution pipelines
  - `BranchUnit.v`: Branch resolution
  - `Control_Unit.v`: Global pipeline control

---

### Linux-Capable Multi-Core RV32GC SoC
- Each core: RV32GC with pipeline, ALU, FPU, CSR/trap logic, privilege modes.
- Memory hierarchy:
  - VIPT L1 instruction/data caches per core
  - Shared inclusive L2 cache with MESI coherence
  - Multi-level TLB hierarchy (L1/L2) + Page Table Walker (SV32)
- Ring-based NoC with wormhole routing between cores and caches
- Can boot FreeRTOS and Linux SMP via Buildroot
- Modules:
  - **Core**: `core_top.v`, `csr.v`, `tlb.v`, `ptw.v`
  - **Cache**: `icache.v`, `dcache.v`, `l2_cache.v`, `directory.v`, `write_buffer.v`
  - **NoC**: `router.v`, `axi_bridge.v`, `coherence_messages.v`
  - **MMU**: `l1_tlb.v`, `l2_tlb.v`, `ptw.v`
  - **Top SoC**: `top_soc.v`

---

## 🔍 Advanced SoC Features

- Branch prediction: BHT, BTB, Return Address Stack
- Forwarding and hazard detection
- Supervisor / User privilege modes
- MMU: SV32 translation, multi-level TLBs, PTW
- Cache coherence: MESI protocol in shared L2
- Ring-based NoC interconnect
- Out-of-order CPU support (research stage)
- Clock gating and low-power optimization

---

## 🛠️ Toolchain & Simulation

- RISC-V ISA compliance testing (`RV32IMAC`)  
- GNU RISC-V toolchain  
- ModelSim / Verilator for RTL simulation  
- AXI interfaces + UART integration  
- FreeRTOS and Buildroot integration for OS bring-up  

---

## 🧑‍💻 How to Contribute

- Pull requests for RTL modules, AXI interfaces, and testbenches
- Documentation contributions for hardware/software stack
- Multi-core SoC development and Linux bring-up

---

## 📚 References

- [Tejas RISC-V Architecture, IIT Madras](https://www.cse.iitm.ac.in/~tejas/)
- [RISC-V Privileged Architecture v1.12](https://github.com/riscv/riscv-isa-manual)
- [Buildroot Linux](https://buildroot.org/)
- [riscv-arch-test](https://github.com/riscv/riscv-arch-test)
- [CVA6](https://github.com/openhwgroup/cva6)
- [BlackParrot](https://github.com/black-parrot/black-parrot)

---

## 🔐 License

Released under [MIT License](LICENSE).

---

## 📬 Contact

Maintained by: [Namaniit297](https://github.com/Namaniit297)  
Open an issue or discussion to collaborate.
