module image_processing_top(
    input clk,rst,i_valid,
    input [7:0] i_pixel,
    output o_valid,
    output [7:0] o_pixel
    );
    wire [71:0]ic_data;
    wire ic_valid;
    image_control ic(clk,rst,i_valid,i_pixel,ic_data,ic_valid);
    convo(clk,ic_valid,ic_data,ic_valid,o_pixel,o_valid);
endmodule
