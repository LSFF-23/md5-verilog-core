module tb_md5_padding;
reg clk, rst, start, resume;
reg [0:511] input_data;
reg [63:0] input_size;
wire [0:511] padded_data;
wire [1:0] status;

md5_padding dut (clk, rst, start, resume, input_data, input_size, padded_data, status);

always #5 clk = !clk;

initial begin
    clk = 0; rst = 0; start = 0; resume = 0; #10
    rst = 1; #10

    input_data = 512'b0;
    input_data[0:23] = "abc";
    input_size = 64'h18; // 3 bytes = 24 bits
    start = 1; #10
    start = 0; #100

    input_data[0:479] = "AAAAAAAAAABBBBBBBBBBCCCCCCCCCCDDDDDDDDDDEEEEEEEEEEFFFFFFFFFF";
    input_size = 64'h1e0; // 60 bytes = 480 bits
    start = 1; #10
    start = 0; #100
    resume = 1; #10
    resume = 0; #100

    $stop(0);
end

endmodule