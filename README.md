🦖 FPGA Bluetooth-Controlled Dino Runner

Verilog | DE10-Lite | VGA | UART | Bluetooth | Quartus
________________________________________
📌 Overview

This project is a fully hardware-implemented 2D obstacle avoidance game built entirely in Verilog HDL on the DE10-Lite FPGA.

The system integrates:
•	Real-time 640×480 @ 60Hz VGA graphics
•	FSM-based gameplay logic
•	Bluetooth-based wireless control (HC-05 module)
•	Custom Android controller (MIT App Inventor)
•	UART receiver with oversampling
•	LFSR-based randomized obstacle spawning
•	Persistent high-score tracking on 7-segment displays

The entire game runs directly on the FPGA without a CPU or embedded OS.
________________________________________
🎮 Features

🎥 Real-Time VGA Rendering
•	640×480 resolution @ 60Hz
•	Pixel-level rendering pipeline
•	Player sprite, ground, sky, and obstacles
•	Hitbox-based collision detection
•	LED-based visual feedback on game over
________________________________________
📡 Bluetooth Wireless Control
•	HC-05 Bluetooth module
•	Custom Android controller built with MIT App Inventor
•	Jump signal transmitted wirelessly
•	UART RX with oversampling + mid-bit sampling FSM
•	2-flip-flop synchronization + rising-edge detection for clean jump pulses
________________________________________
🎲 Randomized Gameplay
•	LFSR-based pseudo-random generator
•	Randomized obstacle spawn timing
•	Three obstacle slots for dynamic gameplay
•	Random LED pattern on player death
•	Switch-controlled randomized player color
________________________________________
🏆 Scoring System
•	Time-based scoring using hardware counters
•	Persistent high score tracking
•	Switch-selectable high score display
•	Output to onboard 7-segment displays
________________________________________
🧠 System Architecture

The design follows a modular architecture:
•	FinalProject.v → Top-level integration
•	vga_controller.v → VGA timing generation
•	vga.v → Rendering + game logic
•	rx.v → UART receiver
•	BaudRate.v → Baud tick generator
•	Score + display modules

Each module was developed and tested independently before full integration.
________________________________________
🔧 Hardware Used
•	DE10-Lite FPGA Board
•	HC-05 Bluetooth Module
•	VGA Monitor
•	Android Phone (custom controller app)
________________________________________
🛠 Tools & Technologies
•	Verilog HDL
•	Intel Quartus Prime
•	ModelSim (simulation)
•	MIT App Inventor (Android controller)
________________________________________
⚙️ Key Technical Highlights
•	Designed a UART receiver using oversampling and mid-bit sampling FSM
•	Implemented clock-domain synchronization using double-flop technique
•	Developed LFSR-based randomness for gameplay variability
•	Achieved stable synthesis and hardware validation on FPGA
•	Built complete system without external processor
