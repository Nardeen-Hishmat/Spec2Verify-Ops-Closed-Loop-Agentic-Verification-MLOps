module adder (
    input  clk,
    input  reset,
    input  signed [3:0] A,
    input  signed [3:0] B,
    output reg signed [4:0] C
);

    // Registered output with asynchronous active-high reset
    always @(posedge clk or posedge reset) begin
        if (reset)
            C <= 5'b0;
        else
            C <= A + B;
    end

endmodule
