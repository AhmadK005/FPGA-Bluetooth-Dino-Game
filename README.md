# 🦖 FPGA Bluetooth-Controled Dino Runner  
**Verilog | DE10-Lite | VGA | UART | Bluetooth | Quartus**

---

## 📌 Overview

This project is a fully hardware-implemented 2D obstacle avoidance game built entirely in **Verilog HDL** on the **DE10-Lite FPGA**.

The system integrates:

- 🎥 Real-time **640×480 @ 60Hz VGA graphics**
- 🧠 FSM-based gameplay logic
- 📡 Bluetooth wireless control (HC-05 module)
- 📱 Custom Android controller (MIT App Inventor)
- 🔄 UART receiver with oversampling
- 🎲 LFSR-based randomized obstacle spawning
- 🏆 Persistent high-score tracking on 7-segment displays

The entire game runs directly on the FPGA without a CPU or embedded OS.

---

## 🎮 Features

### 🎥 Real-Time VGA Rendering
- 640×480 resolution @ 60Hz
- Pixel-level rendering pipeline
- Player sprite, ground, sky, and obstacles
- Hitbox-based collision detection
- LED-based visual feedback on game over

---

### 📡 Bluetooth Wireless Control
- HC-05 Bluetooth module
- Custom Android controller built with MIT App Inventor
- Jump signal transmitted wirelessly
- UART RX with oversampling + mid-bit sampling FSM
- 2-flip-flop synchronization + rising-edge detection for clean jump pulses

---

### 🎲 Randomized Gameplay
- LFSR-based pseudo-random generator
- Randomized obstacle spawn timing
- Three obstacle slots for dynamic gameplay
- Random LED pattern on player death
- Switch-controlled randomized player color

---

### 🏆 Scoring System
- Time-based scoring using hardware counters
- Persistent high score tracking
- Switch-selectable high score display
- Output to onboard 7-segment displays

---

## 🧠 System Architecture

Top Module (FinalProject.v)
│
├── VGA Controller (vga_controller.v)
│   └── Rendering + Game Logic (vga.v)
│
├── UART Receiver (rx.v)
│   └── Baud Generator (BaudRate.v)
│
└── Score + Display Modules
Each module was developed and validated independently before full system integration.

---

## 🔧 Hardware Used

- DE10-Lite FPGA Board  
- HC-05 Bluetooth Module  
- VGA Monitor  
- Android Phone (custom controller app)

---

## 🛠 Tools & Technologies

- Verilog HDL  
- Intel Quartus Prime  
- ModelSim  
- MIT App Inventor  

---

## ⚙️ Key Technical Highlights

- Designed UART receiver using oversampling and mid-bit sampling FSM  
- Implemented clock-domain synchronization using double-flop technique  
- Developed LFSR-based randomness for gameplay variability  
- Achieved stable synthesis and hardware validation on FPGA  
- Built complete real-time embedded system without external processor  

---
