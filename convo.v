module convo #(
parameter integer KERNEL_MODE = 3)(
    input clk,i_valid,
    input [71:0] i_pixels,
    output reg [7:0] o_pixel,
    output reg o_valid
    );
    reg signed [7:0] kernel [0:8];
    reg signed [15:0] mult_data [0:8]; 
    reg [31:0] sum_data;
    integer i,j,k;
    reg signed [31:0] filtered_value;
    reg signed [31:0] abs_value;

     initial begin

        for (k = 0; k < 9; k = k + 1)
            kernel[k] = 8'sd0;

        case (KERNEL_MODE)

            // Box blur
            0: begin
                for (k = 0; k < 9; k = k + 1)
                    kernel[k] = 8'sd1;
            end

            // Gaussian blur
            1: begin
                kernel[0] = 8'sd1;
                kernel[1] = 8'sd2;
                kernel[2] = 8'sd1;

                kernel[3] = 8'sd2;
                kernel[4] = 8'sd4;
                kernel[5] = 8'sd2;

                kernel[6] = 8'sd1;
                kernel[7] = 8'sd2;
                kernel[8] = 8'sd1;
            end

            // Identity filter
            2: begin
                kernel[4] = 8'sd1;
            end

            // Sharpen
            3: begin
                kernel[0] =  8'sd0;
                kernel[1] = -8'sd1;
                kernel[2] =  8'sd0;

                kernel[3] = -8'sd1;
                kernel[4] =  8'sd5;
                kernel[5] = -8'sd1;

                kernel[6] =  8'sd0;
                kernel[7] = -8'sd1;
                kernel[8] =  8'sd0;
            end

            // Sobel X: detects vertical edges
            4: begin
                kernel[0] = -8'sd1;
                kernel[1] =  8'sd0;
                kernel[2] =  8'sd1;

                kernel[3] = -8'sd2;
                kernel[4] =  8'sd0;
                kernel[5] =  8'sd2;

                kernel[6] = -8'sd1;
                kernel[7] =  8'sd0;
                kernel[8] =  8'sd1;
            end

            // Sobel Y: detects horizontal edges
            5: begin
                kernel[0] = -8'sd1;
                kernel[1] = -8'sd2;
                kernel[2] = -8'sd1;

                kernel[3] =  8'sd0;
                kernel[4] =  8'sd0;
                kernel[5] =  8'sd0;

                kernel[6] =  8'sd1;
                kernel[7] =  8'sd2;
                kernel[8] =  8'sd1;
            end

            // Laplacian edge detection
            6: begin
                kernel[0] =  8'sd0;
                kernel[1] =  8'sd1;
                kernel[2] =  8'sd0;

                kernel[3] =  8'sd1;
                kernel[4] = -8'sd4;
                kernel[5] =  8'sd1;

                kernel[6] =  8'sd0;
                kernel[7] =  8'sd1;
                kernel[8] =  8'sd0;
            end

            // Default: box blur
            default: begin
                for (k = 0; k < 9; k = k + 1)
                    kernel[k] = 8'sd1;
            end

        endcase
    end
    always@(posedge clk) begin
        for(i=0;i<9;i=i+1) begin
            mult_data[i]<= $signed({{8{kernel[i][7]}}, kernel[i]}) *$signed({8'b0, i_pixels[i*8 +: 8]});
            o_valid<=i_valid;
        end
    end
    always@(*)begin
        sum_data=0;
        for(j=0;j<9;j=j+1) begin
            sum_data=sum_data+$signed({{16{mult_data[j][15]}}, mult_data[j]});
        end
        filtered_value = 32'sd0;
    abs_value = 32'sd0;

    case (KERNEL_MODE)

        0: filtered_value = sum_data / 32'sd9;   // Box blur

        1: filtered_value = sum_data / 32'sd16;  // Gaussian blur

        2: filtered_value = sum_data;            // Identity

        3: filtered_value = sum_data;            // Sharpen

        4, 5, 6: begin                            // Edge detection
            if (sum_data < 0)
                abs_value = -sum_data;
            else
                abs_value = sum_data;

            filtered_value = abs_value/ 32'sd4;
        end

        default: filtered_value = sum_data / 32'sd9;

    endcase

    // Clamp output to the valid 8-bit intensity range
    if (filtered_value < 0)
        o_pixel = 8'd0;
    else if (filtered_value > 255)
        o_pixel = 8'd255;
    else
        o_pixel = filtered_value[7:0];
    end     
endmodule
