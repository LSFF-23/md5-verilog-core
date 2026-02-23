module md5_padding (clk, rst, start, resume, input_data, input_size, padded_data, status);
input clk, rst, start, resume;
input [0:511] input_data;
input [63:0] input_size;
output reg [0:511] padded_data;
output [1:0] status;

wire [8:0] remainder = input_size[8:0];

localparam IDLE = 3'h0;
localparam COPY_INPUT = 3'h1;
localparam APPEND_STEP = 3'h2;
localparam WAIT_SIGNAL = 3'h4;
localparam COMPLETE = 3'h7;

reg [2:0] state, next_state;

// status tells if there are two padded blocks to output
function [1:0] status_code (input [2:0] state);
begin
	case (state)
		WAIT_SIGNAL: status_code = 2'b10;
		COMPLETE: status_code = 2'b11;
		default: status_code = 2'b00;
	endcase
end
endfunction

// fix endian order (64 bits)
function [63:0] feo64 (input [63:0] v);
	feo64 = {v[7:0], v[15:8], v[23:16], v[31:24], 
				v[39:32], v[47:40], v[55:48], v[63:56]};
endfunction

assign status = status_code(state);

always @(posedge clk or posedge rst) begin
    if (rst)
        state <= IDLE;
    else
        state <= next_state;
end

always @* begin
    next_state = state;
    case (state)
        IDLE: next_state = (start) ? COPY_INPUT : IDLE;
        COPY_INPUT: next_state = APPEND_STEP;
        APPEND_STEP: next_state = (remainder < 440) ? COMPLETE : WAIT_SIGNAL;
        WAIT_SIGNAL: next_state = (resume) ? COMPLETE : WAIT_SIGNAL;
        COMPLETE: next_state = (start) ? COPY_INPUT : COMPLETE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    case (state)
        IDLE: padded_data <= 512'b0;
        COPY_INPUT: padded_data <= input_data;
        APPEND_STEP: begin
            padded_data[remainder] <= 1'b1;
            if (remainder < 440) padded_data[447:511] <= feo64(input_size);
        end
        WAIT_SIGNAL: if (resume) padded_data <= {448'b0, feo64(input_size)};
    endcase
end

endmodule