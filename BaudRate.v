module BaudRate
(
    input        Clk,			//clock
    input        Rst_n,			//reset key
    output       Tick,			//single bit output for completiion of each period
    input [15:0] BaudRate		//divisor for getting 9600 baudrate
);

    reg [15:0] baudRateReg; // Register used to count

	 //sequential logic for baudrate
    always @(posedge Clk or negedge Rst_n)
		  
		  //if baud rate is reached or reset is pressed said count to 1 else iterate count by 1 each cycle
        if (!Rst_n)          baudRateReg <= 16'b1;
        else if (Tick)       baudRateReg <= 16'b1;
        else                 baudRateReg <= baudRateReg + 1'b1;

	  //combinational logic to update tick
    assign Tick = (baudRateReg == BaudRate);
endmodule
