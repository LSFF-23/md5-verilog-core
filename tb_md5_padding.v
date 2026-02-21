module tb_md5_padding;
reg clk, h_rst, s_rst;
reg [0:511] input_data;
reg [63:0] input_size;
wire [0:511] padded_data;
wire [1:0] status;

md5_padding dut (clk, h_rst, s_rst, input_data, input_size, padded_data, status);

always #5 clk = !clk;

initial begin
    clk = 0; h_rst = 0; s_rst = 0; #10

    input_data = 512'b0;
    input_data[0:23] = "abc";
    input_size = 64'h18; // 3 bytes = 24 bits
    h_rst = 1; #10
    h_rst = 0; #100

    input_data[0:479] = "AAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF";
    input_size = 64'h1e0; // 60 bytes = 480 bits
    h_rst = 1; #10
    h_rst = 0; #100
    s_rst = 1; #10
    s_rst = 0; #100

    $stop(0);
end

endmodule