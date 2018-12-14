 `timescale 1ns / 1ps

module CPU(
	input clk,
	output wire [7:0] c_addr, // Direccion de memoria
	output [15:0] c_read_data // Contenido leido
	);
	 
	memory ROM(
		.clk(clk),
		.read_data(c_read_data),
		.addr(c_addr)
	);
	
	reg [7:0] registers[0:15];
	reg [15:0] pc = 0; // Contador de programa
	reg skip = 0; // Permite saltar la siguiente instruccion
	reg [15:0] stack[0:15]; 
	reg [3:0] stack_pointer = 0; // Profundidad actual del stack.
	reg [7:0] delay_timer = 0;
	reg [15:0] I = 0;
	assign c_addr = pc;

	//Instrucciones
	reg [3:0]op = 0; 
	reg [3:0]arg_x = 0;
	reg [3:0]arg_y = 0;
	reg [3:0]arg_z = 0;
		
	initial begin
		registers[0] = 0;
		registers[1] = 0;
		registers[2] = 0;
		registers[3] = 0;
		registers[4] = 0;
		registers[5] = 0;
		registers[6] = 0;
		registers[7] = 0;
		registers[8] = 0;
		registers[9] = 0;
		registers[10] = 0;
		registers[11] = 0;
		registers[12] = 0;
		registers[13] = 0;
		registers[14] = 0;
		registers[15] = 0;
		stack[0] = 0;
		stack[1] = 0;
		stack[2] = 0;
		stack[3] = 0;
		stack[4] = 0;
		stack[5] = 0;
		stack[6] = 0;
		stack[7] = 0;
		stack[8] = 0;
		stack[9] = 0;
		stack[10] = 0;
		stack[11] = 0;
		stack[12] = 0;
		stack[13] = 0;
		stack[14] = 0;
		stack[15] = 0;
	end
	
	always @(posedge clk)
		begin
			pc <= pc + 'b10;
			{op, arg_x, arg_y, arg_z} <= c_read_data;
			
			// Explicacion de las instrucciones de: http://devernay.free.fr/hacks/chip8/C8TECH10.HTM
			if(skip == 0)
				begin
					case(op)
						4'd0: // The interpreter sets the program counter to the address at the top of the stack, then subtracts 1 from the stack pointer.
							if (arg_z == 4'hE) begin
								pc <= stack[stack_pointer - 3'd1];
								stack_pointer <= stack_pointer - 3'd1;
							end
						4'd1: pc <= {arg_x, arg_y, arg_z}; // 1nnn - Jump to location nnn.
						4'd2: // The interpreter increments the stack pointer, then puts the current PC on the top of the stack. The PC is then set to nnn.
							begin
								stack[stack_pointer] <= pc;
								pc <= {arg_x, arg_y, arg_z};
								stack_pointer <= stack_pointer + 3'd1;
							end
						4'd3: if (registers[arg_x] == {arg_y, arg_z}) skip <= 1;  // The interpreter compares register Vx to kk, and if they are equal, increments the program counter by 2.
						4'd4: if (registers[arg_x] != {arg_y, arg_z}) skip <= 1; //  The interpreter compares register Vx to kk, and if they are not equal, increments the program counter by 2.
						4'd5: if (registers[arg_x] == registers[arg_y]) skip <= 1; //  The interpreter compares register Vx to register Vy, and if they are equal, increments the program counter by 2.
						4'd6: registers[arg_x] <= {arg_y, arg_z}; // The interpreter puts the value kk into register Vx.
						4'd7: registers[arg_x] <= registers[arg_x] + {arg_y, arg_z}; // Adds the value kk to the value of register Vx, then stores the result in Vx. 
						4'd8: 
							case(arg_z)
								4'd0: registers[arg_x] <= registers[arg_y]; // Stores the value of register Vy in register Vx.
								4'd1: registers[arg_x] <= registers[arg_x] | registers[arg_y]; // Performs a bitwise OR on the values of Vx and Vy, then stores the result in Vx.
								4'd2: registers[arg_x] <= registers[arg_x] & registers[arg_y]; // Performs a bitwise AND on the values of Vx and Vy, then stores the result in Vx.
								4'd3: registers[arg_x] <= registers[arg_x] ^ registers[arg_y]; // Performs a bitwise exclusive OR on the values of Vx and Vy, then stores the result in Vx.
								4'd4: {registers[15], registers[arg_x]} <= registers[arg_x] + registers[arg_y]; // he values of Vx and Vy are added together. If the result is greater than 8 bits VF is set to 1, otherwise 0.
								4'd5: {registers[15], registers[arg_x]} <= registers[arg_x] - registers[arg_y]; // If Vx > Vy, then VF is set to 1, otherwise 0. Then Vy is subtracted from Vx, and the results stored in Vx.
								4'd6: //  If the least-significant bit of Vx is 1, then VF is set to 1, otherwise 0. Then Vx is divided by 2.
									begin
										registers[15] <= 'b00000001 & registers[arg_x];
										registers[arg_x] <= registers[arg_x] >> 1;
									end
								4'd7: {registers[15], registers[arg_x]} <= registers[arg_y] - registers[arg_x]; //  If Vy > Vx, then VF is set to 1, otherwise 0. Then Vx is subtracted from Vy, and the results stored in Vx.
								4'hE: //  If the most-significant bit of Vx is 1, then VF is set to 1, otherwise to 0. Then Vx is multiplied by 2.
									begin
										registers[15] <= 'b00000001 & registers[arg_x];
										registers[arg_x] <= registers[arg_x] << 1;
									end
							endcase
						4'd9: if(registers[arg_x] != registers[arg_y]) skip <= 1; //  The values of Vx and Vy are compared, and if they are not equal, the program counter is increased by 2.
						4'hA: I <= {arg_x, arg_y, arg_z};
						4'hB: pc <= {arg_x, arg_y, arg_z} + registers[0]; //  The program counter is set to nnn plus the value of V0.
						4'hC: 
							begin // Implementar número aleatorio
								registers[arg_x] <= 'b00001001 & {arg_y, arg_z};
							end
						4'hF:
							case(arg_z)
								4'd5: delay_timer <= registers[arg_x]; // DT is set equal to the value of Vx.
								4'd7: registers[arg_x] <= delay_timer; // The value of DT is placed into Vx.
								4'hE: I <= I + registers[arg_x];
							endcase	
					endcase
				end
				else skip <= 0;
				$monitor("clk=%b, PC=%hex, OP=%h V0=%b, V1=%b, V2=%b, V3=%b, V4=%b, carry=%b, skip=%b, stack_pointer=%b, stack_0=%h, I=%h", clk, pc, c_read_data, registers[0], registers[1], registers[2], registers[3], registers[4], registers[15], skip, stack_pointer, stack[0], I);
		end


endmodule