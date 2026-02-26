module tb_md5_core;
reg clk, rst, start, resume;
reg [0:511] input_data;
wire [0:127] hash;
wire done;

md5_core dut (clk, rst, start, resume, input_data, hash, done);

always #5 clk = !clk;

initial begin
    clk = 0; rst = 0; start = 0; resume = 0; #10
    rst = 1; #10
    
    input_data = 512'h58585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858585858;
    start = 1; #10
    start = 0; #690

    input_data = 512'h58585858585858585858585858585858585858585858585858585858585858585858585880000000000000000000000000000000000000002003000000000000;
    resume = 1; #10
    resume = 0; #690
    $stop(0);
end

endmodule