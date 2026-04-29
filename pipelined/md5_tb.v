`timescale 1ns/1ps

module md5_tb;
reg clk;
reg [511:0] msg;
reg msg_valid;
wire [127:0] hash;
wire hash_valid;

md5_top uut (
    .clk(clk),
    .msg(msg),
    .msg_valid(msg_valid),
    .hash(hash),
    .hash_valid(hash_valid)
);

always #5 clk = ~clk;
localparam [511:0] MSG_EMPTY = {8'h80, 504'h0}; 
localparam [511:0] MSG_A = {8'h61, 8'h80, 432'h0, 64'h0800000000000000};
localparam [511:0] MSG_ABC = {8'h61, 8'h62, 8'h63, 8'h80, 416'h0, 64'h1800000000000000};

always @(posedge clk) begin
    if (hash_valid)
        $display("Time: %t | Hash Out: %h", $time, hash);
end

initial begin
    clk = 0; msg = 0; msg_valid = 0;
    repeat (2) @(posedge clk);

    msg <= MSG_EMPTY; msg_valid <= 1;
    @(posedge clk);
    
    msg <= MSG_A; msg_valid <= 1;
    @(posedge clk);

    msg <= MSG_ABC; msg_valid <= 1;
    @(posedge clk);

    msg_valid <= 0; msg <= 0;
    @(posedge clk);

    /*
    Expected hashes:
    '' : d41d8cd98f00b204e9800998ecf8427e
    'a': 0cc175b9c0f1b6a831c399e269772661
    'abc': 900150983cd24fb0d6963f7d28e17f72
    */

    wait(hash_valid);
    repeat (3) @(posedge clk);

    $finish(0);
end

endmodule