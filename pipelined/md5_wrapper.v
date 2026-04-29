module md5_wrapper (
    input clk,
    input [31:0] data_in,
    input start,
    output reg [31:0] data_out
);

reg [511:0] msg_reg;
reg valid_reg;
wire [127:0] hash_out;
wire hash_valid;

md5_top dut (
    .clk(clk),
    .msg(msg_reg),
    .msg_valid(valid_reg),
    .hash(hash_out),
    .hash_valid(hash_valid)
);

always @(posedge clk) begin
    if (start) msg_reg <= {msg_reg[479:0], data_in};
    valid_reg <= start;
end

always @(posedge clk) begin
    if (hash_valid) data_out <= hash_out;
end

endmodule