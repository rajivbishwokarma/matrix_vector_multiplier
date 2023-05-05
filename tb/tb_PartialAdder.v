`timescale 1ns / 1ps

module tb_PartialAdder();
    parameter D_WIDTH = 32;
    parameter M_SIZE = 2;
    
    reg aclk;
    reg aresetn;
    
    reg s_receiver_ready;
    reg w_partial_matrix_valid;
    reg w_last_data_to_acumulator;
    
    
    wire s_accumulator_is_ready_for_data;
    wire m_output_result_valid;
    wire m_this_is_last_result;
    
    reg  [(D_WIDTH * M_SIZE * M_SIZE)-1:0] i_partial_matrix;
    wire [(D_WIDTH * M_SIZE)-1:0]          o_accumulator_result;
    
    initial begin
        aclk = 0;
        forever aclk = #5 ~aclk;
    end
    
    
    PartialAdder #(.D_WIDTH(D_WIDTH), .M_SIZE(M_SIZE)) PartialAdder_Inst (
    .aclk                       ( aclk      ),
    .aresetn                    ( aresetn   ),
    
    .s_receiver_ready           ( s_receiver_ready          ),
    .w_partial_matrix_valid     ( w_partial_matrix_valid    ),
    .w_last_data_to_acumulator  ( w_last_data_to_acumulator ),
    
    
    .s_accumulator_is_ready_for_data    ( s_accumulator_is_ready_for_data   ),
    .m_output_result_valid              ( m_output_result_valid             ),
    .m_this_is_last_result              ( m_this_is_last_result             ),
    
    .i_partial_matrix                   ( i_partial_matrix                  ),
    .o_accumulator_result               ( o_accumulator_result              )
    );
    
    initial begin
    
    aresetn = 1'b1; #10; aresetn = 1'b0; #10; aresetn = 1'b1; # 10;
    i_partial_matrix = {((D_WIDTH * M_SIZE * M_SIZE)-1){1'b0}};
    
    // control signal configuration
    #20;
    
//    i_partial_matrix = {{32'b00111111_110000000_000000000_000000}, {32'b01000010_11001000_01000000_00000000}, // // 1.5 + 100.125 = 101.625
//                        {32'b00111111_00000000_00000000_00000000}, {32'b01000011_01001000_10100000_00000000}}; // // 0.5 + 200.625 = 201.125
                        
    i_partial_matrix = {{32'b00111111_100000000_000000000_000000}, {32'b01000000_00000000_00000000_00000000}, // 1 + 2 = 3
                        {32'b01000000_10000000_00000000_00000000}, {32'b01000001_00000000_00000000_00000000}}; // 4 + 8 = 12
    if (s_accumulator_is_ready_for_data) begin
        w_partial_matrix_valid = 1'b1;
        w_last_data_to_acumulator = 1'b0;
    end else begin
        w_partial_matrix_valid = 1'b0;
        w_last_data_to_acumulator = 1'b0;
    end
    
    #20;
    s_receiver_ready = 1'b1;
    
    #20;
    if (m_output_result_valid) begin
        $display("Result Available Status: %b", m_output_result_valid);
        $display("Result: %b", o_accumulator_result);
    end else begin
    end
    
    end
    
       
endmodule
