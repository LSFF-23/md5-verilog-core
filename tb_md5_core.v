module tb_md5_core;
reg clk, rst;
reg [0:511] input_data;
wire [0:127] hash;
wire done;

md5_core dut (clk, rst, input_data, hash, done);

always #5 clk = !clk;

initial begin
    clk = 0; rst = 0; #10
    rst = 1; #10
    // input_data = 'abc'
    rst = 0; input_data = 512'h61626380000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001800000000000000;
    #700 $stop(0);
end

endmodule