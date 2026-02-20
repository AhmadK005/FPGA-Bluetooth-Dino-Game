module rx (Clk,Rst_n,RxEn,RxData,RxDone,Rx,Tick,NBits);

//inputs
input Clk;		//clock
input Rst_n; 	//reset
input RxEn;		//enbale bit
input Rx;		//where data is bein recived (tx pin on blutooth module)
input Tick;		//Tick bit
input [3:0]NBits; //Number of bits to capture

output RxDone; //1 bit output
output [7:0]RxData; //8 bits output


//setting up parameter
parameter  IDLE = 1'b0, READ = 1'b1; //2 states for READ adn IDLE
reg [1:0] State, Next; //registers for state machines
reg  read_enable = 1'b0; //Variable that will enable data in read
reg  start_bit = 1'b1; //Notify when the start bit was detected 
reg  RxDone = 1'b0; //Notify when the data read process is done
reg [4:0]Bit = 5'b00000; //Variable used for the bit by bit read loop
reg [3:0] counter = 4'b0000; //Counter variable 
reg [7:0] Read_data= 8'b00000000; //Buffer Rx input bits 
reg [7:0] RxData; //Final output register





//FSM

//ReseT
always @ (posedge Clk or negedge Rst_n)			
begin
if (!Rst_n)	State <= IDLE; //sets state IDLE on reset
else 		State <= Next; //else go to next stage
end





//Next step decision

//Each time "State or Rx or RxEn or RxDone" will change their value we decide which is the next step

always @ (State or Rx or RxEn or RxDone)
begin
    case(State)	
	IDLE:	if(!Rx & RxEn)		Next = READ; //If not Rx but Rx_EN is 1 go read
		else			Next = IDLE;
	READ:	if(RxDone)		Next = IDLE; //If RxDone go IDLE
		else			Next = READ;
	default 			Next = IDLE;
    endcase
end


//Read Enable logic
always @ (State or RxDone)
begin
    case (State)
	READ: begin
		read_enable <= 1'b1; //If we are in the Read state we enable the read process
	      end
	
	IDLE: begin
		read_enable <= 1'b0; //If we get back to IDLE, we desable the read process
    endcase
end


//Read the input data
// When the counter is 8 (4'b1000) we are in the middle of the start bit
// When the counter is 16 (4'b1111) we are in the middle of one of the bits
// We store the data by shifting the Rx input bit into the Read_data register 

always @ (posedge Tick)

	begin
	if (read_enable)
	begin
	RxDone <= 1'b0; //Set the RxDone register to low since the process is still going
	counter <= counter+1; //Increase the counter by 1 with each Tick detected
	

	if ((counter == 4'b1000) & (start_bit)) //if Coutner = 8 set start bit to 1
	begin
	start_bit <= 1'b0;
	counter <= 4'b0000;
	end

	if ((counter == 4'b1111) & (!start_bit) & (Bit < NBits))	//We make 8 loop and we read all 8 bits
	begin
	Bit <= Bit+1;
	Read_data <= {Rx,Read_data[7:1]};
	counter <= 4'b0000;
	end
	
	if ((counter == 4'b1111) & (Bit == NBits)  & (Rx)) //Then we count to 16 once again and detect the stop bit (Rx input must be high)
	begin
	Bit <= 4'b0000;
	RxDone <= 1'b1;
	counter <= 4'b0000;
	start_bit <= 1'b1; //We reset all values for next data input and set RxDone to high
	end
	end
	
	

end


//Assign the Read_data register values to the RxData output
always @ (posedge Clk)
begin

if (NBits == 4'b1000)
begin
RxData[7:0] <= Read_data[7:0];	
end

if (NBits == 4'b0111)
begin
RxData[7:0] <= {1'b0,Read_data[7:1]};	
end

if (NBits == 4'b0110)
begin
RxData[7:0] <= {1'b0,1'b0,Read_data[7:2]};	
end
end




//End of the RX mdoule
endmodule



