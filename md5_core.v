module md5_core (clk, h_rst, s_rst, input_data, hash, done);
localparam A0 = 32'h67452301;
localparam B0 = 32'hefcdab89;
localparam C0 = 32'h98badcfe;
localparam D0 = 32'h10325476;

input clk, h_rst, s_rst;
input [0:511] input_data;
output [0:127] hash;
output reg done;

reg [0:31] A, B, C, D;
reg [0:31] a, b, c, d;
reg [5:0] step;
reg flag;

function [0:31] F (input [0:31] X, Y, Z);
    F = (X & Y) | (~X & Z);
endfunction

function [0:31] G (input [0:31] X, Y, Z);
    G = (X & Z) | (Y & ~Z);
endfunction

function [0:31] H (input [0:31] X, Y, Z);
    H = X ^ Y ^ Z;
endfunction

function [0:31] I (input [0:31] X, Y, Z);
    I = Y ^ (X | ~Z);
endfunction

// left circular shift
function [0:31] lcs (input [0:31] v, input[4:0] s);
begin
    lcs = ((v << s) | (v >> (32 - s)));
end
endfunction

// per-round shift
function [4:0] prs (input [5:0] step);
begin
    case (step)
        0, 4, 8, 12: prs = 5'd7;
        1, 5, 9, 13: prs = 5'd12;
        2, 6, 10, 14: prs = 5'd17;
        3, 7, 11, 15: prs = 5'd22;
        16, 20, 24, 28: prs = 5'd5;
        17, 21, 25, 29: prs = 5'd9;
        18, 22, 26, 30: prs = 5'd14;
        19, 23, 27, 31: prs = 5'd20;
        32, 36, 40, 44: prs = 5'd4;
        33, 37, 41, 45: prs = 5'd11;
        34, 38, 42, 46: prs = 5'd16;
        35, 39, 43, 47: prs = 5'd23;
        48, 52, 56, 60: prs = 5'd6;
        49, 53, 57, 61: prs = 5'd10;
        50, 54, 58, 62: prs = 5'd15;
        51, 55, 59, 63: prs = 5'd21;
    endcase
end
endfunction

// abs-sine constants table
function [0:31] asct (input [5:0] step);
begin
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
end
endfunction

// fix endian order: abc = 61626380, but must be = 80636261
function [0:31] feo32 (input [0:31] v);
begin
    feo32 = {v[24:31], v[16:23], v[8:15], v[0:7]};
end
endfunction

always @(posedge clk or posedge h_rst) begin
    if (h_rst) begin
        step <= 0;
        flag <= 0;
        done <= 0;
        A <= A0;
        B <= B0;
        C <= C0;
        D <= D0;
        a <= A0;
        b <= B0;
        c <= C0;
        d <= D0;
    end else if (s_rst && done) begin
        step <= 0;
        flag <= 0;
        done <= 0;
        a <= A;
        b <= B;
        c <= C;
        d <= D;
    end else if (!flag) begin
        if (step >= 0 && step <= 15)
            b <= b + lcs(a + F(b, c, d) + feo32(input_data[32*step +: 32]) + asct(step), prs(step));
        else if (step >= 16 && step <= 31)
            b <= b + lcs(a + G(b, c, d) + feo32(input_data[32*((5*step+1) & 4'b1111) +: 32]) + asct(step), prs(step));
        else if (step >= 32 && step <= 47)
            b <= b + lcs(a + H(b, c, d) + feo32(input_data[32*((3*step+5) & 4'b1111) +: 32]) + asct(step), prs(step));
        else
            b <= b + lcs(a + I(b, c, d) + feo32(input_data[32*((7*step) & 4'b1111) +: 32]) + asct(step), prs(step));  
          
        a <= d;
        d <= c;
        c <= b;
        {flag, step} <= step + 1'b1;
    end else begin
        done <= 1;
        A <= A + a;
        B <= B + b;
        C <= C + c;
        D <= D + d;
        a <= 32'b0;
        b <= 32'b0;
        c <= 32'b0;
        d <= 32'b0;
    end
end

assign hash = {feo32(A), feo32(B), feo32(C), feo32(D)};

endmodule