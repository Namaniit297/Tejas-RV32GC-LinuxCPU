# 🚀 Tejas-RV32-LinuxCPU

🧠 An open-source, research-oriented RISC-V CPU RTL project inspired by SHAKTI IIT Madras, aimed at evolving from a minimal multicycle RV32I core into a full-fledged Linux-capable, multicore SoC, including MMU, caches, and out-of-order pipeline design.

---

## 📌 Project Goals

This repository is dedicated to designing a synthesizable, modular RISC-V CPU RTL starting from a **multicycle RV32I core**, and systematically evolving through stages to:

- ✔️ Support RV32IMAC ISA
- ✔️ Integrate a pipelined FPU for floating point workloads
- ✔️ Implement byte-addressable dual-port BRAM memory
- ✔️ Pass all [riscv-arch-test](https://github.com/riscv/riscv-arch-test) ISA testbenches
- ✔️ Add AXI + UART peripherals for Hello World and I/O debugging
- ✔️ Boot FreeRTOS and eventually a full Linux build
- 🧩 Transition from in-order to out-of-order superscalar pipeline

---

## 🧭 Project Roadmap: From RV32I Core ➜ Linux-Capable Multicore SoC

### ⚙️ STAGE 0: YOU ARE HERE – Non-Pipelined RV32I Core
- Multicycle, in-order RV32I core.
- No interrupts, no CSRs, no MMU.
- Runs basic bare-metal programs.

---

### ✅ Week-by-Week Plan (Deadline: June 25)

| Week | Deliverables |
|------|--------------|
| **Week 1** (✓) | Complete modularization: `fetch.v`, `decode.v`, `execute.v`, `mem_access.v`, `writeback.v` |
| **Week 2** | Add `RV32M`: hardware multiplier/divider unit. Integrate byte-addressable dual-port BRAM. |
| **Week 3** | Implement FPU (`RV32F`) + AXI UART + debug system interface. Run "Hello World" via UART. |
| **Week 4** | Pass full ISA tests (`RV32IMAC`), integrate compressed instruction support. |
| **Week 5** | Add CLINT + PLIC: timer, software + external interrupts. Add MMU with SV32, L1 TLB & PTW. |
| **Week 6** | Cache hierarchy: L1 I/D Cache per core, Shared L2 Cache, TLB hierarchy (L1, L2). |
| **Week 7** | Boot FreeRTOS on CPU. Begin Linux porting and RAM initialization + rootfs preparation. |
| **Week 8** | Linux SMP SoC integration planning begins: design multi-core interconnect + coherency protocol. |

---

## 🧩 Feature Implementation Tracker

| Feature | Status |
|--------|--------|
| RV32I multicycle CPU core | ✅ Done |
| Modular 5-stage pipeline | 🚧 In progress |
| Multiply/Divide unit (RV32M) | 🛠️ Week 2 |
| AXI UART interface | 🛠️ Week 3 |
| RV32F (FPU Unit) | 🛠️ Week 3 |
| Byte-addressable BRAM | ✅ Done |
| CSR Registers + Trap Logic | 🔜 Planned |
| CLINT / PLIC (Interrupt support) | 🔜 Planned |
| MMU + SV32 + TLB + PTW | 🔜 Planned |
| L1 ICache / DCache + L2 Shared Cache | 🔜 Planned |
| Compressed Instructions (RV32C) | 🔜 Planned |
| Debug Infrastructure + GDB | 🔜 Planned |
| Booting FreeRTOS | 🔜 June 2025 |
| Booting Linux via Buildroot | 🔜 Future |
| Out-of-Order CPU Architecture | 🧠 Research Phase |
| Clock Gating + Power Domains | 🔜 Future |
| Page Table Walker + Virtual Memory | 🔜 Future |

---

## 🔍 Advanced SoC Goals

Once the core reaches Linux boot capability, we'll extend to:

### 🧠 Supervisor/User Modes
- Full support for OS-kernel/user mode separation.
- Privilege control, page permission checks.

### 🧠 MMU and Memory Hierarchy
- SV32 support
- L1 TLB (per core), L2 shared TLB
- Page Table Walkers
- Memory-mapped DRAM via AXI

### 🔁 Multi-Core SoC (Like CVA6 / BlackParrot)
- L1 caches per core
- Shared L2 cache
- Inter-core coherency protocol
- AXI-based interconnect / NoC
- SMP Linux support

---

## 🛠️ Toolchain & Testbench Goals

- 🧪 RISC-V compliance test suite (RV32IMAC)
- 📦 [RISC-V GNU Toolchain](https://github.com/riscv-collab/riscv-gnu-toolchain)
- 🖥️ ModelSim / Verilator for simulation
- 📤 AXI interface + UART integration
- 🧵 Integration of FreeRTOS, Buildroot for OS testing

---

## 🧪 Research-Oriented Enhancements (Coming Soon)

- 🔍 Clock Gating and Idle Block Shutoff
- 🔒 Secure Boot Extensions
- 🔐 Physical/Virtual memory page tables
- 🧠 ISA Extension: Vector / Cryptographic
- 📡 Network Stack: Ethernet or USB-to-UART Linux drivers
- 🧬 Integration with ML Accelerators (Tensor Core)

---

## 🧑‍💻 How to Contribute

We welcome collaboration!

- 📥 Pull requests for RTL modules, AXI interfaces, and testbench improvements
- 🧪 Testing framework integration
- 📚 Documentation for hardware/software stack
- 🌐 SoC design with external memory/peripheral controllers

---

## 📚 References & Acknowledgements

- [Tejas RISC-V Architecture, IIT Madras](https://www.cse.iitm.ac.in/~tejas/)
- [RISC-V Privileged Architecture v1.12](https://github.com/riscv/riscv-isa-manual)
- [Buildroot Linux](https://buildroot.org/)
- [riscv-arch-test](https://github.com/riscv/riscv-arch-test)
- [CVA6](https://github.com/openhwgroup/cva6) and [BlackParrot](https://github.com/black-parrot/black-parrot)

---

## 🔐 License

This project is released under the [MIT License](LICENSE).

---

## 📬 Contact

Maintained by: [Namaniit297](https://github.com/Namaniit297)

Open an issue or discussion to get involved!
