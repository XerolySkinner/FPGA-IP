////////////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------------------------------------------------------------
module sccb #(
	parameter			address=8'H03C
)(
	input		[15: 0]	in_reg			,
	input		[ 7: 0]	in_data			,
	
	input					in_valid			,
	output				out_ready		,

	output	reg		sccb_scl			,
	output	reg		sccb_sda			,

	input		wire		clk				,
	input		wire		rst_n
);
////////////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------------------------------------------------------------
	reg		[ 7: 0]	chip_addr		;
	reg		[15: 0]	chip_reg			;
	reg		[ 7: 0]	chip_data		;
////////////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------------------------------------------------------------
//	FSM	State
	reg		[4:0]	state;
	reg		[4:0]	state_cnt;
	reg				state_finish;
	
	parameter	IDLE 				= 0;
	parameter	STATE_S 			= 1;
	parameter	STATE_PHASE1 	= 2;
	parameter	STATE_PHASE2 	= 3;
	parameter	STATE_PHASE3 	= 4;
	parameter	STATE_PHASE4 	= 5;
	parameter	STATE_P 			= 6;
	
	assign	out_ready=(state[4:0]==IDLE);
////////////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------------------------------------------------------------
//	FSM	状态寄存器处理
//		1:	同步时序描述状态转移
always @ (posedge clk or negedge rst_n) begin
		if (!rst_n)
			begin
				state[4:0] 			<= IDLE;
				state_cnt[4:0]		<=	0;
				
				state_finish		<= 0;
				chip_reg				<= 0;
				chip_data			<= 0;
				chip_addr			<= address;
			end
		else
			case (state[4:0])
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				IDLE:
					if (in_valid)
						begin
							chip_reg[15:0]		=in_reg[15:0];
							chip_data[ 7:0]	=in_data[ 7:0];
							
							state_cnt[4:0] <= 0;
							state[4:0] <= STATE_S;
						end
					else
						begin
							state[4:0] <= IDLE;
						end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_S:
					if (state_cnt[4:0]>=2)
						begin
							state_cnt[4:0] <= 0;
							state[4:0] <= STATE_PHASE1;
						end
					else
						begin
							state_cnt[4:0] <= state_cnt[4:0] + 1;
							state[4:0] <= STATE_S;
						end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_PHASE1:
					if (state_cnt[4:0]>=26)
						begin
							state_cnt[4:0] <= 0;
							state[4:0] <= STATE_PHASE2;
						end
					else
						begin
							state_cnt[4:0] <= state_cnt[4:0] + 1;
							state[4:0] <= STATE_PHASE1;
						end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_PHASE2:
					if (state_cnt[4:0]>=26)
						begin
							state_cnt[4:0] <= 0;
							state[4:0] <= STATE_PHASE3;
						end
					else
						begin
							state_cnt[4:0] <= state_cnt[4:0] + 1;
							state[4:0] <= STATE_PHASE2;
						end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_PHASE3:
					if (state_cnt[4:0]>=26)
						begin
							state_cnt[4:0] <= 0;
							state[4:0] <= STATE_PHASE4;
						end
					else
						begin
							state_cnt[4:0] <= state_cnt[4:0] + 1;
							state[4:0] <= STATE_PHASE3;
						end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_PHASE4:
					if (state_cnt[4:0]>=26)
						begin
							state_cnt[4:0] <= 0;
							state[4:0] <= STATE_P;
						end
					else
						begin
							state_cnt[4:0] <= state_cnt[4:0] + 1;
							state[4:0] <= STATE_PHASE4;
						end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_P:
					if (state_cnt[4:0]>=2)
						begin
							state_cnt[4:0] <= 0;
							state[4:0] <= IDLE;
						end
					else
						begin
							state_cnt[4:0] <= state_cnt[4:0] + 1;
							state[4:0] <= STATE_P;
						end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			endcase
	end
////////////////////////////////////////////////////////////////////////////////////////////////////
//--------------------------------------------------------------------------------------------------
//	FSM	产生输出的组合逻辑
//		1:组合逻辑判断状态转移条件
//		2:描述状态转移规律
//		3:输出
always @ (*)
	begin
			case (state[4:0])
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				IDLE:
					begin
						sccb_scl				<= 1;
						sccb_sda				<= 1;
					end
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_S:
					case(state_cnt[4:0])
						0:
							begin
							sccb_scl=1;
							sccb_sda=1;
							end
						1:
							begin
							sccb_scl=1;
							sccb_sda=0;
							end
						2:
							begin
							sccb_scl=0;
							sccb_sda=0;
							end
						default:
							begin
							end
					endcase
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_PHASE1:
					case(state_cnt[4:0])
						0:
							begin
							sccb_scl=0;
							sccb_sda=chip_addr[6];
							end
						1:
							sccb_scl=1;
						2:
							sccb_scl=0;
						
						3:
							begin
							sccb_scl=0;
							sccb_sda=chip_addr[5];
							end
						4:
							sccb_scl=1;
						5:
							sccb_scl=0;
						
						6:
							begin
							sccb_scl=0;
							sccb_sda=chip_addr[4];
							end
						7:
							sccb_scl=1;
						8:
							sccb_scl=0;
						
						9:
							begin
							sccb_scl=0;
							sccb_sda=chip_addr[3];
							end
						10:
							sccb_scl=1;
						11:
							sccb_scl=0;
						
						12:
							begin
							sccb_scl=0;
							sccb_sda=chip_addr[2];
							end
						13:
							sccb_scl=1;
						14:
							sccb_scl=0;
						
						15:
							begin
							sccb_scl=0;
							sccb_sda=chip_addr[1];
							end
						16:
							sccb_scl=1;
						17:
							sccb_scl=0;
						
						18:
							begin
							sccb_scl=0;
							sccb_sda=chip_addr[0];
							end
						19:
							sccb_scl=1;
						20:
							sccb_scl=0;
						
						21:
							begin
							sccb_scl=0;
							sccb_sda=0;
							end
						22:
							sccb_scl=1;
						23:
							sccb_scl=0;
						
						24:
							begin
							sccb_scl=0;
							sccb_sda=1'bz;
							end
						25:
							sccb_scl=1;
						26:
							sccb_scl=0;
						
						default:
							begin
							end
					endcase
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_PHASE2:
					case(state_cnt[4:0])
						0:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[15];
							end
						1:
							sccb_scl=1;
						2:
							sccb_scl=0;
						
						3:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[14];
							end
						4:
							sccb_scl=1;
						5:
							sccb_scl=0;
						
						6:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[13];
							end
						7:
							sccb_scl=1;
						8:
							sccb_scl=0;
						
						9:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[12];
							end
						10:
							sccb_scl=1;
						11:
							sccb_scl=0;
						
						12:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[11];
							end
						13:
							sccb_scl=1;
						14:
							sccb_scl=0;
						
						15:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[10];
							end
						16:
							sccb_scl=1;
						17:
							sccb_scl=0;
						
						18:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[9];
							end
						19:
							sccb_scl=1;
						20:
							sccb_scl=0;
						
						21:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[8];
							end
						22:
							sccb_scl=1;
						23:
							sccb_scl=0;
							
						24:
							begin
							sccb_scl=0;
							sccb_sda=1'bz;
							end
						25:
							sccb_scl=1;
						26:
							sccb_scl=0;
						
						default:
							begin
							end
					endcase
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_PHASE3:
					case(state_cnt[4:0])
						0:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[7];
							end
						1:
							sccb_scl=1;
						2:
							sccb_scl=0;
						
						3:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[6];
							end
						4:
							sccb_scl=1;
						5:
							sccb_scl=0;
						
						6:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[5];
							end
						7:
							sccb_scl=1;
						8:
							sccb_scl=0;
						
						9:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[4];
							end
						10:
							sccb_scl=1;
						11:
							sccb_scl=0;
						
						12:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[3];
							end
						13:
							sccb_scl=1;
						14:
							sccb_scl=0;
						
						15:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[2];
							end
						16:
							sccb_scl=1;
						17:
							sccb_scl=0;
						
						18:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[1];
							end
						19:
							sccb_scl=1;
						20:
							sccb_scl=0;
						
						21:
							begin
							sccb_scl=0;
							sccb_sda=chip_reg[0];
							end
						22:
							sccb_scl=1;
						23:
							sccb_scl=0;
							
						24:
							begin
							sccb_scl=0;
							sccb_sda=1'bz;
							end
						25:
							sccb_scl=1;
						26:
							sccb_scl=0;
						
						default:
							begin
							end
					endcase
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_PHASE4:
					case(state_cnt[4:0])
						0:
							begin
							sccb_scl=0;
							sccb_sda=chip_data[7];
							end
						1:
							sccb_scl=1;
						2:
							sccb_scl=0;
						
						3:
							begin
							sccb_scl=0;
							sccb_sda=chip_data[6];
							end
						4:
							sccb_scl=1;
						5:
							sccb_scl=0;
						
						6:
							begin
							sccb_scl=0;
							sccb_sda=chip_data[5];
							end
						7:
							sccb_scl=1;
						8:
							sccb_scl=0;
						
						9:
							begin
							sccb_scl=0;
							sccb_sda=chip_data[4];
							end
						10:
							sccb_scl=1;
						11:
							sccb_scl=0;
						
						12:
							begin
							sccb_scl=0;
							sccb_sda=chip_data[3];
							end
						13:
							sccb_scl=1;
						14:
							sccb_scl=0;
						
						15:
							begin
							sccb_scl=0;
							sccb_sda=chip_data[2];
							end
						16:
							sccb_scl=1;
						17:
							sccb_scl=0;
						
						18:
							begin
							sccb_scl=0;
							sccb_sda=chip_data[1];
							end
						19:
							sccb_scl=1;
						20:
							sccb_scl=0;
						
						21:
							begin
							sccb_scl=0;
							sccb_sda=chip_data[0];
							end
						22:
							sccb_scl=1;
						23:
							sccb_scl=0;
							
						24:
							begin
							sccb_scl=0;
							sccb_sda=1'bz;
							end
						25:
							sccb_scl=1;
						26:
							sccb_scl=0;
						
						default:
							begin
							end
					endcase
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
				STATE_P:
					case(state_cnt[4:0])
						0:
							begin
							sccb_scl=0;
							sccb_sda=0;
							end
						1:
							begin
							sccb_scl=1;
							sccb_sda=0;
							end
						2:
							begin
							sccb_scl=1;
							sccb_sda=1;
							end
						default:
							begin
							end
					endcase
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
			endcase
	end
////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule
