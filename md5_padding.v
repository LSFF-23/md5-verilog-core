module md5_padding (clk, rst_n, start, resume, input_data, input_size, padded_data, waiting, done);
input clk, rst_n, start, resume;
input [0:511] input_data;
input [63:0] input_size;
output reg [0:511] padded_data;
output reg done;
output waiting;

wire [8:0] remainder;

localparam RESET = 3'h3;
localparam IDLE = 3'h0;
localparam COPY_INPUT = 3'h1;
localparam APPEND_STEP = 3'h2;
localparam WAIT_SIGNAL = 3'h4;
localparam COMPLETE = 3'h6;

reg [2:0] state, next_state;

assign remainder = input_size[8:0];
assign waiting = state == WAIT_SIGNAL;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= RESET;
    else
        state <= next_state;
end

always @* begin
    next_state = state;
    case (state)
        RESET: next_state = IDLE;
        IDLE: next_state = (start) ? COPY_INPUT : IDLE;
        COPY_INPUT: next_state = APPEND_STEP;
        APPEND_STEP: next_state = (remainder < 440) ? COMPLETE : WAIT_SIGNAL;
        WAIT_SIGNAL: begin
            if (start)
                next_state = IDLE;
            else if (resume)
                next_state = COMPLETE;
            else
                next_state = WAIT_SIGNAL;
        end
        COMPLETE: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    case (state)
        RESET: done <= 0;
        COPY_INPUT: begin
            done <= 0;
            padded_data <= input_data;
        end
        APPEND_STEP: begin
            padded_data[remainder] <= 1'b1;
            if (remainder < 440) padded_data[447:511] <= feo64(input_size);
        end
        WAIT_SIGNAL: if (resume) padded_data <= {448'b0, feo64(input_size)};
        COMPLETE: done <= 1;
    endcase
end

// fix endian order (64 bits)
function [63:0] feo64 (input [63:0] v);
	feo64 = {v[7:0], v[15:8], v[23:16], v[31:24], 
			 v[39:32], v[47:40], v[55:48], v[63:56]};
endfunction

endmodule