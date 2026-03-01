module md5_core (clk, rst_n, start, resume, input_data, hash, done);
input clk, rst_n, start, resume;
input [0:511] input_data;
output [0:127] hash;
output done;

localparam A0 = 32'h67452301;
localparam B0 = 32'hefcdab89;
localparam C0 = 32'h98badcfe;
localparam D0 = 32'h10325476;

reg [0:31] A, B, C, D;
reg [0:31] a, b, c, d;
reg [5:0] step;

localparam IDLE = 3'b000;
localparam INIT_ABCD = 3'b001;
localparam COPY_ABCD = 3'b010;
localparam PROCESSING = 3'b011;
localparam SUM_ABCD = 3'b100;
localparam FINISHED = 3'b101;

reg [2:0] state, next_state;

assign hash = {feo32(A), feo32(B), feo32(C), feo32(D)};
assign done = state == FINISHED;

// processing variables
reg [31:0] f_picker;
reg [31:0] shifted_sum;
wire [8:0] j = {block32_index(step), 5'b0};
wire [0:31] M_j = feo32(input_data[j +: 32]);
wire [31:0] sum_internal = (f_picker + a) + (M_j + asct(step));

// processing combs
always @* begin
    case (step[5:4])
        2'b00: f_picker = (b & c) | (~b & d);
        2'b01: f_picker = (b & d) | (c & ~d);
        2'b10: f_picker = b ^ c ^ d;
        2'b11: f_picker = c ^ (b | ~d);
        default: f_picker = 32'h0;
    endcase
end

always @* begin
    case (step[5:0])
        6'd0, 6'd4, 6'd8, 6'd12:   shifted_sum = {sum_internal[24:0], sum_internal[31:25]};
        6'd1, 6'd5, 6'd9, 6'd13:   shifted_sum = {sum_internal[19:0], sum_internal[31:20]};
        6'd2, 6'd6, 6'd10, 6'd14:  shifted_sum = {sum_internal[14:0], sum_internal[31:15]};
        6'd3, 6'd7, 6'd11, 6'd15:  shifted_sum = {sum_internal[9:0],  sum_internal[31:10]};
        6'd16, 6'd20, 6'd24, 6'd28: shifted_sum = {sum_internal[26:0], sum_internal[31:27]};
        6'd17, 6'd21, 6'd25, 6'd29: shifted_sum = {sum_internal[22:0], sum_internal[31:23]};
        6'd18, 6'd22, 6'd26, 6'd30: shifted_sum = {sum_internal[17:0], sum_internal[31:18]};
        6'd19, 6'd23, 6'd27, 6'd31: shifted_sum = {sum_internal[11:0], sum_internal[31:12]};
        6'd32, 6'd36, 6'd40, 6'd44: shifted_sum = {sum_internal[27:0], sum_internal[31:28]};
        6'd33, 6'd37, 6'd41, 6'd45: shifted_sum = {sum_internal[20:0], sum_internal[31:21]};
        6'd34, 6'd38, 6'd42, 6'd46: shifted_sum = {sum_internal[15:0], sum_internal[31:16]};
        6'd35, 6'd39, 6'd43, 6'd47: shifted_sum = {sum_internal[8:0],  sum_internal[31:9]};
        6'd48, 6'd52, 6'd56, 6'd60: shifted_sum = {sum_internal[25:0], sum_internal[31:26]};
        6'd49, 6'd53, 6'd57, 6'd61: shifted_sum = {sum_internal[21:0], sum_internal[31:22]};
        6'd50, 6'd54, 6'd58, 6'd62: shifted_sum = {sum_internal[16:0], sum_internal[31:17]};
        6'd51, 6'd55, 6'd59, 6'd63: shifted_sum = {sum_internal[10:0], sum_internal[31:11]};
        default: shifted_sum = sum_internal;
    endcase
end

// finite state machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        state <= IDLE;
    else
        state <= next_state;
end

always @* begin
    next_state = state;
    case (state)
        IDLE: next_state = (start) ? INIT_ABCD : IDLE;
        INIT_ABCD: next_state = COPY_ABCD;
        COPY_ABCD: next_state = PROCESSING;
        PROCESSING: next_state = (step == 63) ? SUM_ABCD : PROCESSING;
        SUM_ABCD: next_state = FINISHED;
        FINISHED: begin
            if (start)
                next_state = INIT_ABCD;
            else if (resume)
                next_state = COPY_ABCD;
            else
                next_state = FINISHED;
        end
        default: next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    case (state)
        INIT_ABCD: begin
            A <= A0;
            B <= B0;
            C <= C0;
            D <= D0;
        end
        COPY_ABCD: begin
            a <= A;
            b <= B;
            c <= C;
            d <= D;
            step <= 0;
        end
        PROCESSING: begin
            b <= b + shifted_sum;
            a <= d;
            d <= c;
            c <= b;
            step <= step + 1'b1;
        end
        SUM_ABCD: begin
            A <= A + a;
            B <= B + b;
            C <= C + c;
            D <= D + d;
        end
    endcase
end

// abs-sine constants table
function [0:31] asct (input [5:0] step);
    case (step)
        0: asct = 32'hd76aa478;
        1: asct = 32'he8c7b756;
        2: asct = 32'h242070db;
        3: asct = 32'hc1bdceee;
        4: asct = 32'hf57c0faf;
        5: asct = 32'h4787c62a;
        6: asct = 32'ha8304613;
        7: asct = 32'hfd469501;
        8: asct = 32'h698098d8;
        9: asct = 32'h8b44f7af;
        10: asct = 32'hffff5bb1;
        11: asct = 32'h895cd7be;
        12: asct = 32'h6b901122;
        13: asct = 32'hfd987193;
        14: asct = 32'ha679438e;
        15: asct = 32'h49b40821;
        16: asct = 32'hf61e2562;
        17: asct = 32'hc040b340;
        18: asct = 32'h265e5a51;
        19: asct = 32'he9b6c7aa;
        20: asct = 32'hd62f105d;
        21: asct = 32'h02441453;
        22: asct = 32'hd8a1e681;
        23: asct = 32'he7d3fbc8;
        24: asct = 32'h21e1cde6;
        25: asct = 32'hc33707d6;
        26: asct = 32'hf4d50d87;
        27: asct = 32'h455a14ed;
        28: asct = 32'ha9e3e905;
        29: asct = 32'hfcefa3f8;
        30: asct = 32'h676f02d9;
        31: asct = 32'h8d2a4c8a;
        32: asct = 32'hfffa3942;
        33: asct = 32'h8771f681;
        34: asct = 32'h6d9d6122;
        35: asct = 32'hfde5380c;
        36: asct = 32'ha4beea44;
        37: asct = 32'h4bdecfa9;
        38: asct = 32'hf6bb4b60;
        39: asct = 32'hbebfbc70;
        40: asct = 32'h289b7ec6;
        41: asct = 32'heaa127fa;
        42: asct = 32'hd4ef3085;
        43: asct = 32'h04881d05;
        44: asct = 32'hd9d4d039;
        45: asct = 32'he6db99e5;
        46: asct = 32'h1fa27cf8;
        47: asct = 32'hc4ac5665;
        48: asct = 32'hf4292244;
        49: asct = 32'h432aff97;
        50: asct = 32'hab9423a7;
        51: asct = 32'hfc93a039;
        52: asct = 32'h655b59c3;
        53: asct = 32'h8f0ccc92;
        54: asct = 32'hffeff47d;
        55: asct = 32'h85845dd1;
        56: asct = 32'h6fa87e4f;
        57: asct = 32'hfe2ce6e0;
        58: asct = 32'ha3014314;
        59: asct = 32'h4e0811a1;
        60: asct = 32'hf7537e82;
        61: asct = 32'hbd3af235;
        62: asct = 32'h2ad7d2bb;
        63: asct = 32'heb86d391;
    endcase
endfunction

// fix endian order: abc = 61626380, but must be = 80636261
function [0:31] feo32 (input [0:31] v);
    feo32 = {v[24:31], v[16:23], v[8:15], v[0:7]};
endfunction

// which from 16 blocks must be accessed on each round
function [63:0] block32_index (input [5:0] i);
    case (i)
        0: block32_index = 4'd0;
        1: block32_index = 4'd1;
        2: block32_index = 4'd2;
        3: block32_index = 4'd3;
        4: block32_index = 4'd4;
        5: block32_index = 4'd5;
        6: block32_index = 4'd6;
        7: block32_index = 4'd7;
        8: block32_index = 4'd8;
        9: block32_index = 4'd9;
        10: block32_index = 4'd10;
        11: block32_index = 4'd11;
        12: block32_index = 4'd12;
        13: block32_index = 4'd13;
        14: block32_index = 4'd14;
        15: block32_index = 4'd15;
        16: block32_index = 4'd1;
        17: block32_index = 4'd6;
        18: block32_index = 4'd11;
        19: block32_index = 4'd0;
        20: block32_index = 4'd5;
        21: block32_index = 4'd10;
        22: block32_index = 4'd15;
        23: block32_index = 4'd4;
        24: block32_index = 4'd9;
        25: block32_index = 4'd14;
        26: block32_index = 4'd3;
        27: block32_index = 4'd8;
        28: block32_index = 4'd13;
        29: block32_index = 4'd2;
        30: block32_index = 4'd7;
        31: block32_index = 4'd12;
        32: block32_index = 4'd5;
        33: block32_index = 4'd8;
        34: block32_index = 4'd11;
        35: block32_index = 4'd14;
        36: block32_index = 4'd1;
        37: block32_index = 4'd4;
        38: block32_index = 4'd7;
        39: block32_index = 4'd10;
        40: block32_index = 4'd13;
        41: block32_index = 4'd0;
        42: block32_index = 4'd3;
        43: block32_index = 4'd6;
        44: block32_index = 4'd9;
        45: block32_index = 4'd12;
        46: block32_index = 4'd15;
        47: block32_index = 4'd2;
        48: block32_index = 4'd0;
        49: block32_index = 4'd7;
        50: block32_index = 4'd14;
        51: block32_index = 4'd5;
        52: block32_index = 4'd12;
        53: block32_index = 4'd3;
        54: block32_index = 4'd10;
        55: block32_index = 4'd1;
        56: block32_index = 4'd8;
        57: block32_index = 4'd15;
        58: block32_index = 4'd6;
        59: block32_index = 4'd13;
        60: block32_index = 4'd4;
        61: block32_index = 4'd11;
        62: block32_index = 4'd2;
        63: block32_index = 4'd9;
    endcase
endfunction

endmodule