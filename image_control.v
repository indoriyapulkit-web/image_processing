module image_control(
    input clk,rst,i_valid,
    input [7:0] i_pixel,
    output reg [71:0] o_pixels,
    output o_valid
    );
    reg [8:0]buffer_counter;
    wire [3:0] valid;
    reg [3:0]rd_valid;
    reg [1:0]valid_check;
    reg[1:0] rd_check;
    wire [23:0] line_buffer_data[0:3];
    reg [8:0]rd_counter;
    reg rd_line_buffer;
    reg rd_state;
    reg [15:0] completed_rows;
    reg [15:0] processed_rows;

localparam IDLE = 1'b0,RD_BUFFER = 1'b1;
    
    always @(posedge clk or posedge rst) begin
    if (rst) begin
        buffer_counter <= 0;
        valid_check    <= 0;
        completed_rows <= 0;
    end
    else if (i_valid) begin
        if (buffer_counter == 9'd511) begin
            buffer_counter <= 0;
            valid_check    <= valid_check + 1'b1;
            completed_rows <= completed_rows + 1'b1;
        end
        else begin
            buffer_counter <= buffer_counter + 1'b1;
        end
    end
    end
    always @(posedge clk or posedge rst) begin
    if (rst) begin
        rd_state       <= IDLE;
        rd_line_buffer <= 1'b0;
        rd_counter     <= 0;
        rd_check       <= 0;
        processed_rows <= 0;
    end
    else begin
        case (rd_state)

            IDLE: begin
                rd_line_buffer <= 1'b0;
                rd_counter     <= 0;

                if (completed_rows >= processed_rows + 16'd3) begin
                    rd_line_buffer <= 1'b1;
                    rd_state       <= RD_BUFFER;
                end
            end

            RD_BUFFER: begin
                rd_line_buffer <= 1'b1;

                if (rd_counter == 9'd511) begin
                    rd_line_buffer <= 1'b0;
                    rd_state       <= IDLE;

                    rd_counter     <= 0;
                    rd_check       <= rd_check + 1'b1;
                    processed_rows <= processed_rows + 1'b1;
                end
                else begin
                    rd_counter <= rd_counter + 1'b1;
                end
            end

            default: begin
                rd_state       <= IDLE;
                rd_line_buffer <= 1'b0;
                rd_counter     <= 0;
            end

        endcase
    end
end
    assign valid =!i_valid ? 4'b0000 :(valid_check == 2'd0) ? 4'b0001 : (valid_check == 2'd1) ? 4'b0010 : (valid_check == 2'd2) ? 4'b0100 :4'b1000;
    always@(*) begin
        case(rd_check)
            0: o_pixels={line_buffer_data[2],line_buffer_data[1],line_buffer_data[0]};
            1: o_pixels={line_buffer_data[3],line_buffer_data[2],line_buffer_data[1]};
            2: o_pixels={line_buffer_data[0],line_buffer_data[3],line_buffer_data[2]};
            3: o_pixels={line_buffer_data[1],line_buffer_data[0],line_buffer_data[3]};
        endcase
    end
     
    always@(*) begin
        rd_valid=0;
        if(rd_line_buffer) begin
        case(rd_check)
             2'd0: rd_valid = 4'b0111;
            2'd1: rd_valid = 4'b1110;
            2'd2: rd_valid = 4'b1101;
            2'd3: rd_valid = 4'b1011;
        endcase
    end
    end
    line_buffer lb0(clk,rst,valid[0],rd_valid[0],i_pixel,line_buffer_data[0]);
    line_buffer lb1(clk,rst,valid[1],rd_valid[1],i_pixel,line_buffer_data[1]);
    line_buffer lb2(clk,rst,valid[2],rd_valid[2],i_pixel,line_buffer_data[2]);
    line_buffer lb3(clk,rst,valid[3],rd_valid[3],i_pixel,line_buffer_data[3]);
    assign o_valid = rd_line_buffer;
    
endmodule
