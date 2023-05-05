`timescale 1ns / 1ps

// Verilog-2005 does not allow two dimensional arrays in the input/output ports
// Therefore, we can do it with custom macros.
`include "preprocessors.v"

module TensorUnit #(parameter D_WIDTH=32, M_SIZE=2) (
    // SYSTEM SIGNALS
    input   aclk,
    input   aresetn,
    
    // AXI CONTROLS 
    input   i_matrix_is_valid,
    input   i_vector_is_valid,
    input   i_receiver_ready_for_result, // input to the accumulator
    input   i_accumulator_waiting_for_data, // output from accumulator
    output  o_ready_to_accept_matrix,
    output  o_ready_to_accept_vector,
    output  o_result_is_valid,
    output  o_this_is_the_last_result,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
    // DATA
    input  [(D_WIDTH) * (M_SIZE) * (M_SIZE) - 1:0]  i_matrix,
    input  [(D_WIDTH) * (M_SIZE)            - 1:0]  i_vector,
    //output [(D_WIDTH) * (M_SIZE) * (M_SIZE) - 1:0]  o_partial_matrix
    
    output [(D_WIDTH) * (M_SIZE)            - 1:0]  o_result
);
    
    // Internal data registers and wires
    reg  [D_WIDTH-1:0] r_partial_matrix    [0:M_SIZE-1][0:M_SIZE-1];
    wire [D_WIDTH-1:0] w_partial    [0:M_SIZE-1][0:M_SIZE-1];    
    wire [D_WIDTH-1:0] wi_matrix    [0:M_SIZE-1][0:M_SIZE-1];
    wire [D_WIDTH-1:0] wi_vector    [0:M_SIZE-1];
    wire [D_WIDTH-1:0] wo_vector    [0:M_SIZE-1];
    wire [D_WIDTH-1:0] w_o_result   [0:M_SIZE-1];
    
    // Loop controls
    integer count_x, count_y;
    
    // Unpack the arrays : see the template
    `UNPACK_MATRIX(D_WIDTH, M_SIZE, wi_matrix, i_matrix)
    `UNPACK_VECTOR(D_WIDTH, M_SIZE, wi_vector, i_vector)
    
    
    // Internal interfacing signals for MATRIX_VECTOR_MULTIPLIER
    reg r_s_axis_partial_tready;
    wire w_s_axis_partial_tvalid_all;
    wire w_m_axis_i_matrix_ready [0:M_SIZE-1][0:M_SIZE-1];
    wire w_m_axis_i_vector_ready [0:M_SIZE-1][0:M_SIZE-1];
    wire w_s_axis_partial_tvalid [0:M_SIZE-1][0:M_SIZE-1];
    
    // Internal interfacing signals for ACCUMULATOR
    wire w_s_axis_accumulate_a_tready;
    wire w_s_axis_accumulate_a_tlast;
    wire w_m_axis_accumulate_result_tvalid;
    
    /* Here, the following block multiplies all the matrix elements with the vector and stores the result in partial matrix */
    /* 
     * If M_SIZE = 3, then, by the end of this operation, we will have the following result.
     * NOTE: we still need to add the elements in each row.
     * a[i][j] x b[j] = partial_matrix[a[i][j]*b[i]]
     * 
     * | a[0][0] a[0][1] a[0][2] |     | b[0] |    | a[0][0]*b[0]   a[0][1]*b[1]   a[0][2]*b[2] |
     * | a[1][0] a[1][1] a[1][2] |  x  | b[1] | =  | a[1][0]*b[0]   a[1][1]*b[1]   a[1][2]*b[2] |
     * | a[2][0] a[2][1] a[2][2] |     | b[2] |    | a[2][0]*b[0]   a[2][1]*b[1]   a[2][2]*b[2] |
     */
    genvar row, element;
    generate
        for (row = 0; row < M_SIZE; row = row + 1) begin
            for (element = 0; element < M_SIZE; element = element + 1) begin
                // Instantiate the floating point ip
                fp_multiply_ab MATRIX_VECTOR_MULTIPLIER (
                    .aclk                   ( aclk                                  ),      // input wire aclk
                    .aresetn                ( aresetn                               ),      // input wire aresetn
                    .s_axis_a_tvalid        ( i_matrix_is_valid               ),      // input wire s_axis_a_tvalid
                    .s_axis_a_tready        ( w_m_axis_i_matrix_ready[row][element] ),      // output wire s_axis_a_tready
                    .s_axis_a_tdata         ( wi_matrix[row][element]               ),      // input wire [31 : 0] s_axis_a_tdata
                    .s_axis_b_tvalid        ( i_vector_is_valid               ),      // input wire s_axis_b_tvalid
                    .s_axis_b_tready        ( w_m_axis_i_vector_ready[row][element] ),      // output wire s_axis_b_tready
                    .s_axis_b_tdata         ( wi_vector[element]                    ),      // input wire [31 : 0] s_axis_b_tdata
                    .m_axis_result_tvalid   ( w_s_axis_partial_tvalid[row][element] ),      // output wire m_axis_result_tvalid
                    .m_axis_result_tready   ( i_accumulator_waiting_for_data  ),      // accumulator is ready for input  /// LOOK OUT FOR THIS!
                    .m_axis_result_tdata    ( w_partial[row][element]               )       // output wire [31 : 0] m_axis_result_tdata
                );
                
                
            end
        end
    endgenerate
    
    assign o_ready_to_accept_matrix    = w_m_axis_i_matrix_ready[0][0];
    assign o_ready_to_accept_vector    = w_m_axis_i_vector_ready[0][0];
    assign w_s_axis_partial_tvalid_all = w_s_axis_partial_tvalid[0][0];
    
    reg [(D_WIDTH) * (M_SIZE) * (M_SIZE) - 1:0]  r_output_matrix;
    
    /* If all of the partials are calculated, then assign it to a temporary memory */
    /* This is in case we need to pipeline the whole design. */
    always @(w_s_axis_partial_tvalid_all) begin
        if (w_s_axis_partial_tvalid_all) begin 
            for (count_x = 0; count_x < M_SIZE; count_x = count_x + 1)
                for (count_y = 0; count_y < M_SIZE; count_y = count_y + 1) begin
                    r_partial_matrix[count_x][count_y] = w_partial[count_x][count_y];
                end
        end  else begin
           r_partial_matrix[count_x][count_y] = 0;
        end
    end
    
    
    /* The first part is done, we begin the second stage of the calculation */
    
    
    reg r_external_receiver_ready,
        r_input_data_is_valid,
        r_last_input_to_accumulator;
        
    reg  [D_WIDTH-1:0]  r_matrix_row_element                    [0:M_SIZE-1];
    wire [D_WIDTH-1:0]  w_accumulated_row_sum                   [0:M_SIZE-1];
    
    wire                w_accumulator_waiting_for_data          [0:M_SIZE-1],
                        w_accumulator_result_is_valid           [0:M_SIZE-1],
                        w_last_result_before_accumulator_reset  [0:M_SIZE-1];
    
    
    /* We will need a state machine for shifting the values in to the accumulator */
    localparam  IDLE = 2'b00,
                LOAD = 2'b01,
                NEXT = 2'b10,
                NOP  = 2'b11;
    reg [1:0]   state;                
    reg [4:0]   row_idx, col_idx;
    
    reg [D_WIDTH-1:0] r_state_tracker = 0;
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            // Reset the signals for PartialAdder_Pipeline control
            r_external_receiver_ready   <= 1'b0;
            r_input_data_is_valid       <= 1'b0;
            r_state_tracker             <= 0;
            col_idx                     <= 0;
            state                       <= IDLE;
            
        end else begin
        
            if (w_s_axis_partial_tvalid_all) begin
            
                /* assert data is valid as all partials have been calculated */
                r_input_data_is_valid       <= 1'b1;
                r_external_receiver_ready   <= i_receiver_ready_for_result;
                
                /* control path: we now shift the elements of the partial matrix one by one to the input to the accumulator */
                case (state)
                
                    IDLE:   state <= (r_input_data_is_valid) ? LOAD : IDLE;
                    
                    LOAD:   
                    begin
                        if (r_state_tracker < M_SIZE) state <= LOAD;
                        else                          state <= IDLE;
                        
                        if (o_this_is_the_last_result) state <= IDLE;
                        
                        r_state_tracker <= r_state_tracker + 1;
                        col_idx         <= col_idx + 1;
                    end
                    default:state <= IDLE;
                
                endcase
                
            end else begin
                r_input_data_is_valid       <= 1'b0;
                r_external_receiver_ready   <= 1'b0;
            end
        end
    end
    
    always @* begin
        for (row_idx = 0; row_idx < M_SIZE; row_idx = row_idx + 1) begin
            /* data path: we now shift the elements of the partial matrix one by one to the input to the accumulator */
            case (state)
                IDLE: begin
                    //col_idx = 0;         
                end
                
                LOAD: begin
                        r_matrix_row_element[row_idx]       = r_partial_matrix[row_idx][col_idx];

                        if (col_idx == (M_SIZE - 1))
                            r_last_input_to_accumulator     = 1'b1;
                        else
                            r_last_input_to_accumulator     = 1'b0;
                end
                
                default:begin
                        r_matrix_row_element[row_idx]   = {M_SIZE, {1'b0}};
                end
            endcase
        end
    end
    
    integer sum_idx;
    reg [D_WIDTH-1:0] temp_sum [0:M_SIZE-1];
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            for (sum_idx = 0; sum_idx < M_SIZE; sum_idx = sum_idx + 1)
                temp_sum[sum_idx] <= 0;
        end else begin
            if (o_this_is_the_last_result)
            for (sum_idx = 0; sum_idx < M_SIZE; sum_idx = sum_idx + 1)
                temp_sum[sum_idx] <= w_accumulated_row_sum[sum_idx];
        end
    end
    
    
    genvar adder_row_idx;
    generate
        for (adder_row_idx = 0; adder_row_idx < M_SIZE; adder_row_idx = adder_row_idx + 1) begin
            PartialAdder_Pipeline #(.D_WIDTH(D_WIDTH), .M_SIZE(M_SIZE)) PartialAdder_Pipleline_Inst (
                .aclk                           ( aclk                                          ),
                .aresetn                        ( aresetn                                       ),
                .i_receiver_ready               ( r_external_receiver_ready                     ),
                .i_input_data_is_valid          ( r_input_data_is_valid                         ),
                .i_last_data_to_acumulator      ( r_last_input_to_accumulator                   ),
                .o_accumulator_is_ready_for_data( w_accumulator_waiting_for_data[adder_row_idx] ),
                .o_output_result_valid          ( w_accumulator_result_is_valid[adder_row_idx]  ),
                .o_this_is_last_result          ( w_last_result_before_accumulator_reset[adder_row_idx]),
                .i_matrix_row                   ( r_matrix_row_element[adder_row_idx]           ),  // put this block inside a loop
                .o_sum_row                      ( w_accumulated_row_sum[adder_row_idx]          )
                );
                
        end
        
    endgenerate
    assign o_this_is_the_last_result = w_last_result_before_accumulator_reset[0];
    
    `PACK_VECTOR(D_WIDTH, M_SIZE, o_result, temp_sum)
endmodule

