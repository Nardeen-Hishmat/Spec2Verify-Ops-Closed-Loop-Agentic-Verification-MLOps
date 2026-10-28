`timescale 1ns/1ps

module tb_adder;

    reg clk;
    reg reset;
    reg signed [3:0] A;
    reg signed [3:0] B;
    wire signed [4:0] C;

    integer i;
    integer j;
    integer checks;
    integer failures;

    reg signed [4:0] expected;
    reg signed [4:0] held_value;

    // Device Under Test (DUT)
    adder dut (
        .clk   (clk),
        .reset (reset),
        .A     (A),
        .B     (B),
        .C     (C)
    );

    // 10 ns clock period
    always #5 clk = ~clk;

    // Compare actual output against expected output.
    task check_output;
        input signed [4:0] expected_value;
        begin
            checks = checks + 1;

            if (C !== expected_value) begin
                failures = failures + 1;

                $display(
                    "FAIL: time=%0t A=%0d B=%0d reset=%b expected=%0d actual=%0d",
                    $time, A, B, reset, expected_value, C
                );
            end
        end
    endtask

    initial begin
        clk      = 1'b0;
        reset    = 1'b0;
        A        = 4'sd0;
        B        = 4'sd0;
        checks   = 0;
        failures = 0;

        // Test 1: Assert reset before the first clock edge.
        #1;
        reset = 1'b1;
        #1;
        check_output(5'sd0);

        // Release reset away from the rising clock edge.
        @(negedge clk);
        reset = 1'b0;

        // Test 2: Exhaustively test all 256 input combinations.
        for (i = 0; i < 16; i = i + 1) begin
            for (j = 0; j < 16; j = j + 1) begin

                // Save the previously registered output.
                held_value = C;

                // Drive inputs on the falling edge.
                @(negedge clk);
                A = i;
                B = j;

                // Inputs changed, but C must not change yet.
                #1;
                check_output(held_value);

                // C should update on the next rising edge.
                @(posedge clk);
                #1;

                // Explicitly sign-extend each input to 5 bits.
                expected =
                    $signed({A[3], A}) +
                    $signed({B[3], B});

                check_output(expected);
            end
        end

        // Test 3: Assert asynchronous reset between clock edges.
        @(negedge clk);
        #1;
        reset = 1'b1;
        #1;
        check_output(5'sd0);

        // Reset must remain effective at the next rising edge.
        @(posedge clk);
        #1;
        check_output(5'sd0);

        // Test 4: Release reset and verify normal operation resumes.
        @(negedge clk);
        reset = 1'b0;
        A = 4'sd7;
        B = 4'sd3;

        // The registered output must still be zero before the clock.
        #1;
        check_output(5'sd0);

        // After the rising edge, 7 + 3 must equal 10.
        @(posedge clk);
        #1;
        check_output(5'sd10);

        // Final regression status.
        if (failures == 0) begin
            $display("CHECKS=%0d FAILURES=0", checks);
            $display("REGRESSION_STATUS=PASS");
            $finish;
        end else begin
            $fatal(
                1,
                "REGRESSION_STATUS=FAIL checks=%0d failures=%0d",
                checks, failures
            );
        end
    end

endmodule
