module tb_md5_top;
reg clk, rst_n, start;
reg [1:0] data_sel;
reg [3:0] hex_sel;
wire [6:0] hex0, hex1, hex2, hex3, hex4, hex5;
wire done;

md5_top dut (clk, rst_n, start, data_sel, hex_sel, hex0, hex1, hex2, hex3, hex4, hex5, done);

always #5 clk = !clk;

initial begin
    clk = 0; rst_n = 0; start = 0; hex_sel = 4'b0000; #10
    rst_n = 1; #10

    data_sel = 2'b00;
    start = 1; #10
    start = 0; #800

    data_sel = 2'b01;
    start = 1; #10
    start = 0; #800
    
    data_sel = 2'b10;
    start = 1; #10
    start = 0; #1600

    data_sel = 2'b11;
    start = 1; #10
    start = 0; #4000;

    $stop(0);
end

endmodule