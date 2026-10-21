`timescale 1ns/1ps

module image_processingtb;
    localparam IMAGE_WIDTH       = 512;
    localparam IMAGE_HEIGHT      = 512;
    localparam EXPECTED_OUT_PIXELS = IMAGE_WIDTH * (IMAGE_HEIGHT - 2);

    reg clk;
    reg rst;
    reg i_valid;
    reg [7:0] i_pixel;

    wire [71:0] ic_pixels;
    wire ic_valid;
    wire [7:0] o_pixel;
    wire o_valid;

    integer in_file;
    integer out_file;
    integer scan_status;
    integer input_value;
    integer input_index;
    integer output_count;
    integer flush_count;

    image_control u_image_control (
        .clk(clk),
        .rst(rst),
        .i_valid(i_valid),
        .i_pixel(i_pixel),
        .o_pixels(ic_pixels),
        .o_valid(ic_valid)
    );

    convo u_convo (
        .clk(clk),
        .i_valid(ic_valid),
        .i_pixels(ic_pixels),
        .o_pixel(o_pixel),
        .o_valid(o_valid)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1'b1;
        i_valid = 1'b0;
        i_pixel = 8'd0;
        output_count = 0;

        in_file = $fopen("pixels_in.txt", "r");
        if (in_file == 0) begin
            $display("ERROR: Cannot open pixels_in.txt.");
            $display("Put pixels_in.txt in the simulator working directory.");
            $finish;
        end

        out_file = $fopen("pixels_out.txt", "w");
        if (out_file == 0) begin
            $display("ERROR: Cannot create pixels_out.txt.");
            $fclose(in_file);
            $finish;
        end

        repeat (5) @(negedge clk);
        rst = 1'b0;

        // Drive one pixel per clock, in raster order (left-to-right, row-by-row).
        for (input_index = 0;
             input_index < IMAGE_WIDTH * IMAGE_HEIGHT;
             input_index = input_index + 1) begin
            @(negedge clk);
            scan_status = $fscanf(in_file, "%d", input_value);
            if (scan_status != 1) begin
                $display("ERROR: Failed to read pixel %0d from pixels_in.txt.", input_index);
                $display("Expected %0d decimal pixel values.", IMAGE_WIDTH * IMAGE_HEIGHT);
                $fclose(in_file);
                $fclose(out_file);
                $finish;
            end
            i_pixel = input_value[7:0];
            i_valid = 1'b1;
        end

        // Stop the input stream after the last pixel is accepted.
        @(negedge clk);
        i_valid = 1'b0;
        i_pixel = 8'd0;

        // The controller inserts an idle cycle between output rows, so it can
        // finish the final output row after input has stopped. Wait until the
        // expected number of outputs arrives, with a timeout to avoid hanging.
        flush_count = 0;
        while ((output_count < EXPECTED_OUT_PIXELS) && (flush_count < 3000)) begin
            @(negedge clk);
            flush_count = flush_count + 1;
        end
        repeat (2) @(negedge clk);

        $fclose(in_file);
        $fclose(out_file);

        $display("Simulation finished.");
        $display("Input pixels : %0d", IMAGE_WIDTH * IMAGE_HEIGHT);
        $display("Output pixels: %0d", output_count);
        $display("Expected     : %0d", EXPECTED_OUT_PIXELS);
        if (output_count != EXPECTED_OUT_PIXELS)
            $display("WARNING: Output count differs from expected. Inspect the RTL and waveform.");
        else
            $display("Output count matches the expected 510 x 512 image.");

        $finish;
    end

    // Sample the stable output/valid pair before nonblocking updates on each rising edge.
    always @(posedge clk) begin
        if (o_valid === 1'b1) begin
            $fwrite(out_file, "%0d\n", o_pixel);
            output_count = output_count + 1;
        end
    end
endmodule

