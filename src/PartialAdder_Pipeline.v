`timescale 1ns / 1ps

//`include "preprocessors.v"

module PartialAdder_Pipeline #(parameter D_WIDTH=32, M_SIZE=4) (
    input aclk,
    input aresetn,
    
    input i_receiver_ready,
    input i_input_data_is_valid,
    input i_last_data_to_acumulator,
    
    
    output o_accumulator_is_ready_for_data,
    output o_output_result_valid,
    output o_this_is_last_result,
    
    input  [D_WIDTH-1:0] i_matrix_row,
    output [D_WIDTH-1:0] o_sum_row
    );
    reg [D_WIDTH-1:0] index;
    
    // Just a normal counter
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) index <= 0;
        else          index <= (index != M_SIZE) ? index + 1 : 0;    
    end
    
//    // synthesis translate_off
//        always @ (i_matrix_row, o_sum_row) begin
//            $display("==============================================================================================");
//            $display("====================   PartialAdder_Pipeline  =========================================");
//            $display("==============================================================================================");
//            $display("[DISPLAY] index                     = %b", index);
//            $display("[DISPLAY] r_matrix_row_element[%d]  = %b", index, i_matrix_row);
//            $display("[DISPLAY] w_accumulated_row_sum[%d] = %b", index, o_sum_row);
//            $display("==============================================================================================");
//        end
//    // synthesis translate_on
    
    fp_accumulator_ai ACCUMULATE_PARTIAL_ROW_0 (
      .aclk                 ( aclk                              ),
      .aresetn              ( aresetn                           ),
      .s_axis_a_tvalid      ( i_input_data_is_valid             ),  // input wire : incoming data valid?
      .s_axis_a_tready      ( o_accumulator_is_ready_for_data   ),  // output wire s_axis_a_tready
      .s_axis_a_tdata       ( i_matrix_row                      ),  // input wire [31 : 0] : elements from partial matrix
      .s_axis_a_tlast       ( i_last_data_to_acumulator         ),  // input wire s_axis_a_tlast
      .m_axis_result_tvalid ( o_output_result_valid             ),  // output wire : is the output data valid?
      .m_axis_result_tready ( i_receiver_ready                  ),  // input wire : this is master, slave is ready for accepting data
      .m_axis_result_tdata  ( o_sum_row                         ),  // output wire [31 : 0] : row-wise sum available here
      .m_axis_result_tlast  ( o_this_is_last_result             )   // output wire, last calculated data
    );
    
    
endmodule
