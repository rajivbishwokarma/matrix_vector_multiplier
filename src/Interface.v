`timescale 1ns / 1ps


module Interface #(parameter D_WIDTH=32, M_SIZE=10) (
    input  aclk,
    input  aresetn,
    
    // AXI CONTROLS 
    input   i_matrix_is_valid,
    input   i_vector_is_valid,
    input   i_receiver_ready_for_result, // input to the accumulator
    input   i_accumulator_waiting_for_data, // output from accumulator
    output  o_ready_to_accept_matrix,
    output  o_ready_to_accept_vector,
    output  o_result_is_valid,
    output  o_this_is_the_last_result,
    
    input  [D_WIDTH-1:0] i_matrix_element,
    input  [D_WIDTH-1:0] i_vector_element,
    output [D_WIDTH-1:0] o_result_element
    );
    
    reg  [(D_WIDTH) * (M_SIZE) * (M_SIZE) - 1:0]  i_matrix;
    reg  [(D_WIDTH) * (M_SIZE)            - 1:0]  i_vector;
    wire [(D_WIDTH) * (M_SIZE)            - 1:0]  o_vector;
    
    /* The interface will have a logic to take the 32-bit elements as a stream
     * and then store that stream in the matrix and vector, so that I/Os are not
     * overutilized.
     */
    
    TensorUnit #(.D_WIDTH(32), .M_SIZE(10)) TensorUnit_Inst (
    .aclk                           ( aclk                          ),
    .aresetn                        ( aresetn                       ), 
    .i_matrix_is_valid              ( i_matrix_is_valid             ),
    .i_vector_is_valid              ( i_vector_is_valid             ),
    .i_receiver_ready_for_result    ( i_receiver_ready_for_result   ), // input to the accumulator
    .i_accumulator_waiting_for_data ( i_accumulator_waiting_for_data), // output from accumulator
    .o_ready_to_accept_matrix       ( o_ready_to_accept_matrix      ),
    .o_ready_to_accept_vector       ( o_ready_to_accept_vector      ),
    .o_result_is_valid              ( o_result_is_valid             ),
    .o_this_is_the_last_result      ( o_this_is_the_last_result     ),
    .i_matrix                       ( i_matrix                      ),
    .i_vector                       ( i_vector                      ),
    .o_result                       ( o_vector                      )
    );
    
endmodule
