module md5_top (clk, rst_n, start, data_sel, hex_sel, hex0, hex1, hex2, hex3, hex4, hex5, done);
input clk, rst_n, start;
input [1:0] data_sel;
input [3:0] hex_sel;
output [6:0] hex0, hex1, hex2, hex3, hex4, hex5;
output reg done;

wire core_start, core_resume, core_done;
wire [0:511] core_input;
wire [0:127] core_hash;
wire pad_start, pad_resume;
wire [0:511] pad_in, pad_out;
wire [63:0] pad_size;
wire pad_waiting, pad_done;
wire [0:23] selector_block;
wire is_last_block;
wire [1:0] block_amount;
reg [1:0] block_count;
reg padding_round;
reg [3:0] state, next_state;

localparam RESET = 4'hF;
localparam IDLE = 4'h0;
localparam INIT_COUNTER = 4'hA;
localparam PAD_START1 = 4'h1;
localparam PAD_START2 = 4'h2;
localparam PAD_RESUME1 = 4'h3;
localparam PAD_RESUME2 = 4'h4;
localparam PAD_WAIT = 4'h5;
localparam CORE_START1 = 4'h6;
localparam CORE_START2 = 4'h7;
localparam CORE_RESUME1 = 4'h8;
localparam CORE_RESUME2 = 4'h9;
localparam CORE_WAIT = 4'hB;
localparam CORE_COUNTER = 4'hC;
localparam CORE_EVAL = 4'hD;
localparam FINISHED = 4'hE;

md5_padding p (clk, rst_n, pad_start, pad_resume, pad_in, pad_size, pad_out, pad_waiting, pad_done);
md5_core core (clk, rst_n, core_start, core_resume, core_input, core_hash, core_done);

assign selector_block = segments_selector(core_hash, hex_sel);
assign hex0 = segments_decoder(selector_block[0:3]);
assign hex1 = segments_decoder(selector_block[4:7]);
assign hex2 = segments_decoder(selector_block[8:11]);
assign hex3 = segments_decoder(selector_block[12:15]);
assign hex4 = segments_decoder(selector_block[16:19]);
assign hex5 = segments_decoder(selector_block[20:23]);

assign block_amount = (data_sel == 2'b11) ? 2'b11 : 2'b01;
assign is_last_block = (block_count + 1'b1 == block_amount);
assign pad_in = input_selector(data_sel, block_count);
assign pad_size = size_selector(data_sel);
assign pad_start = (state == PAD_START1) | (state == PAD_START2);
assign pad_resume = (state == PAD_RESUME1) | (state == PAD_RESUME2);

assign core_input = is_last_block ? pad_out : pad_in;
assign core_start = (state == CORE_START1) | (state == CORE_START2);
assign core_resume = (state == CORE_RESUME1) | (state == CORE_RESUME2);

// finite state machine
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
        IDLE: next_state = (start) ? INIT_COUNTER : IDLE;
        INIT_COUNTER: next_state = (is_last_block) ? PAD_START1 : CORE_START1;
        PAD_START1: next_state = PAD_START2;
        PAD_START2: next_state = PAD_WAIT;
        PAD_RESUME1: next_state = PAD_RESUME2;
        PAD_RESUME2: next_state = PAD_WAIT;
        PAD_WAIT: begin
            if (pad_waiting || pad_done)
                if (block_count == 0 && block_amount == 1 && padding_round == 0)
                    next_state = CORE_START1;
                else
                    next_state = CORE_RESUME1;
            else
                next_state = PAD_WAIT;
        end
        CORE_START1: next_state = CORE_START2;
        CORE_START2: next_state = CORE_WAIT;
        CORE_RESUME1: next_state = CORE_RESUME2;
        CORE_RESUME2: next_state = CORE_WAIT;
        CORE_WAIT: next_state = (core_done) ? CORE_EVAL : CORE_WAIT;
        CORE_COUNTER: next_state = CORE_EVAL;
        CORE_EVAL: begin
            if (is_last_block)
                if (pad_waiting)
                    next_state = PAD_RESUME1;
                else
                    next_state = FINISHED;
            else if (block_count + 2'b10 == block_amount)
                next_state = PAD_START1;
            else
                next_state = CORE_RESUME1;
        end
        FINISHED: next_state = IDLE;
    endcase
end

always @(posedge clk) begin
    case (state)
        RESET, INIT_COUNTER: begin
            done <= 0;
            block_count <= 0;
            padding_round <= 0;
        end
        CORE_EVAL: begin
            if (!is_last_block) block_count <= block_count + 1'b1;
            if (is_last_block && pad_waiting) padding_round <= 1;
        end
        FINISHED: done <= 1;
    endcase
end

// functions definitions
// borrowed 7-segments decoder (common anode)
function [6:0] segments_decoder (input [3:0] hex);
    case (hex)
        // Segments:  g f e d c b a
        4'h0: segments_decoder = 7'b1000000; // 0
        4'h1: segments_decoder = 7'b1111001; // 1
        4'h2: segments_decoder = 7'b0100100; // 2
        4'h3: segments_decoder = 7'b0110000; // 3
        4'h4: segments_decoder = 7'b0011001; // 4
        4'h5: segments_decoder = 7'b0010010; // 5
        4'h6: segments_decoder = 7'b0000010; // 6
        4'h7: segments_decoder = 7'b1111000; // 7
        4'h8: segments_decoder = 7'b0000000; // 8
        4'h9: segments_decoder = 7'b0010000; // 9
        4'hA: segments_decoder = 7'b0001000; // A
        4'hB: segments_decoder = 7'b0000011; // b
        4'hC: segments_decoder = 7'b1000110; // C
        4'hD: segments_decoder = 7'b0100001; // d
        4'hE: segments_decoder = 7'b0000110; // E
        4'hF: segments_decoder = 7'b0001110; // F
        default: segments_decoder = 7'b1111111; // All OFF
    endcase
endfunction

function [0:23] segments_selector (input [0:127] data, input [3:0] sel);
    segments_selector = data[sel*24 +: 24];
endfunction

function [0:511] input_selector (input [1:0] sel, input [1:0] bc);
    case (sel)
        2'b00: input_selector = 512'b0;
        2'b01: input_selector = {"Softex", 464'b0};
        2'b10: input_selector = {"UEMA/PECS/CI DIGITAL - Trabalho Orientado I - Hashing: MD5", 48'b0};
        2'b11: begin
            case (bc)
                2'b00: input_selector = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do ";
                2'b01: input_selector = "eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut e";
                2'b10: input_selector = {"nim ad minim veniam, quis nostrud exercitation ullamco laboris", 16'b0};
                default: input_selector = 512'b0;
            endcase 
        end
        default: input_selector = 512'b0;
    endcase
endfunction

function [63:0] size_selector (input [1:0] sel);
    case (sel)
        2'b00: size_selector = 64'h0;
        2'b01: size_selector = 64'h30;
        2'b10: size_selector = 64'h1d0;
        2'b11: size_selector = 64'h5f0;
        default: size_selector = 64'h0;
    endcase
endfunction

endmodule