module line_buffer(
    input clk,rst,valid,rd_valid,
    input [7:0]i_pixel,
    output [23:0] o_pixels
    );
    reg [7:0] line [0:511] ;
    reg [8:0]curr_w,curr_r;
    integer i;
    always@(posedge clk or posedge rst) begin 
        if(rst) begin
            curr_w<=0;
        end
        else if(valid) begin
            line[curr_w]<=i_pixel;
            curr_w<=curr_w+1;
        end 
    end
   reg [7:0] p0, p1, p2;

always @(*) begin
    p0 = line[curr_r];
    p1 = 8'd0;
    p2 = 8'd0;

    if (curr_r < 9'd511)
        p1 = line[curr_r + 9'd1];

    if (curr_r < 9'd510)
        p2 = line[curr_r + 9'd2];
end

assign o_pixels = {p2, p1, p0};
    always@(posedge clk or posedge rst) begin 
        if(rst) begin
            curr_r<=0;
        end
        else if(rd_valid) begin
            curr_r<=curr_r +1;
        end 
    end
endmodule
