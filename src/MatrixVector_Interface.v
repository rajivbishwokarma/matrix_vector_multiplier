`timescale 1ns / 1ps

`include "preprocessors.v"

module MatrixVector_Interface #(parameter D_WIDTH=32, M_SIZE=10) (
    input  aclk,
    input  aresetn,
    output reset_done,
    
    // AXIS SLAVE CONTROL -- RECEIVING THE MATRIX AND VECTOR
    input               s_axis_matrix_valid,
    input [D_WIDTH-1:0] s_axis_matrix,
    output reg          s_axis_matrix_ready,
    
    input               s_axis_vector_valid,
    input [D_WIDTH-1:0] s_axis_vector,
    output reg          s_axis_vector_ready,
    
    // AXIS MASTER CONTROL -- SENDING THE RESULT
    output reg                 m_axis_result_valid,
    output reg [D_WIDTH-1:0]    m_axis_result,
    input                   m_axis_result_ready
    );
    
    
    
    wire  [(D_WIDTH) * (M_SIZE) * (M_SIZE) - 1:0] w_matrix_packed;
    reg  [(D_WIDTH) * (M_SIZE) * (M_SIZE) - 1:0]  r_matrix_packed;
    reg  [(D_WIDTH) * (M_SIZE)            - 1:0]  r_vector_packed;
    wire [(D_WIDTH) * (M_SIZE)            - 1:0]  w_result_packed;
    
    reg  [D_WIDTH - 1:0]  r_matrix_memory [M_SIZE - 1:0][M_SIZE - 1:0];
    
    
    wire received_matrix_is_valid;
    wire received_vector_is_valid;
    
    
    reg tensor_matrix_is_valid;
    reg tensor_vector_is_valid;
    
    /* The interface will have a logic to take the 32-bit elements as a stream
     * and then store that stream in the matrix and vector, so that I/Os are not
     * overutilized.
     */
    
    /* RECEIVE THE DATA */
    reg [31:0] matrix_row_idx = 0, matrix_col_idx = 0, vector_idx;
    
    
    reg [31:0] matrix_x_loop, matrix_y_loop;
    
    reg r_reset_done;
    assign reset_done = r_reset_done;
    integer temp;
    always @ (posedge aclk) begin
        if (!aresetn) begin
            r_vector_packed <= {(D_WIDTH * M_SIZE){1'b0}};
            r_matrix_packed <= {(D_WIDTH * M_SIZE * M_SIZE){1'b0}};
            matrix_row_idx  <= 0;
            matrix_col_idx  <= 0;
            
            for (matrix_x_loop = 0; matrix_x_loop < M_SIZE; matrix_x_loop = matrix_x_loop + 1)
                for (matrix_y_loop = 0; matrix_y_loop < M_SIZE; matrix_y_loop = matrix_y_loop + 1) begin
                    r_matrix_memory[matrix_x_loop][matrix_y_loop] <= 0;
                    
                end
            r_reset_done        <= 1'b0;
            s_axis_matrix_ready <= 1'b0;
            s_axis_vector_ready <= 1'b0;
        end else begin
        
            begin : connection_initiate
            // initiate the connection from the inside
                r_reset_done        <= 1'b1;
                s_axis_matrix_ready <= 1'b1;
                s_axis_vector_ready <= 1'b1;
            end
            
            
            if (s_axis_matrix_valid) begin
 
                /* TODO: Remove the following three lines */
                r_matrix_memory[matrix_row_idx][matrix_col_idx] <= {s_axis_matrix};
                temp =  (matrix_row_idx * D_WIDTH * M_SIZE) + (matrix_col_idx * D_WIDTH);
                $display("index = %d, matrix_row_idx = %d, matrix_col_idx = %d", (matrix_row_idx * D_WIDTH * M_SIZE) + (matrix_col_idx * D_WIDTH), matrix_row_idx, matrix_col_idx); 
                
                r_matrix_packed[(matrix_row_idx * D_WIDTH * M_SIZE) + (matrix_col_idx * D_WIDTH) +: D_WIDTH] <= s_axis_matrix;
                
                
                matrix_col_idx <= ((matrix_col_idx != M_SIZE - 1)) ? matrix_col_idx + 1 : 0;
                
                if (matrix_col_idx == M_SIZE - 1) matrix_row_idx <= (matrix_row_idx != M_SIZE - 1) ? matrix_row_idx + 1 : 0;
            end else begin
                matrix_col_idx <= 0;
                matrix_row_idx <= 0;
            end
            
            
            // this block latches the vector_packed value
            if (s_axis_vector_valid)
                if (matrix_row_idx == 0)
                    r_vector_packed[matrix_col_idx * D_WIDTH +: D_WIDTH] <= s_axis_vector;
        end
    end
    
    
    
    // when data reception is done (last index of row, column), then we can send the data to the core multilier
    assign received_matrix_is_valid = ((s_axis_matrix_valid) & (matrix_row_idx == (M_SIZE - 1)) & (matrix_col_idx == (M_SIZE - 1))) ? 1'b1 : 1'b0;
    assign received_vector_is_valid = ((s_axis_vector_valid) & (matrix_row_idx == 0) & (matrix_col_idx == (M_SIZE - 1))) ? 1'b1 : 1'b0;
    
    // Send the valid signal to the TensorUnit module one clock cycle after the matrix is received.
    always @ (posedge aclk) begin
        tensor_matrix_is_valid <= (received_matrix_is_valid & o_ready_to_accept_matrix) ? 1'b1 : 1'b0;
        tensor_vector_is_valid <= (received_vector_is_valid & o_ready_to_accept_vector) ? 1'b1 : 1'b0;
    end
    
    // One clock cycle after sent_matrix_is_valid and sent_vector_is_valid, assert that we are readdy to receive the result
    reg receive_result;

    
    /* PROCESS THE DATA */
    wire tensor_result_valid;
    TensorUnit #(.D_WIDTH(D_WIDTH), .M_SIZE(M_SIZE)) TensorUnit_Inst (
    .aclk                           ( aclk                          ),
    .aresetn                        ( aresetn                       ), 
    .i_matrix_is_valid              ( tensor_matrix_is_valid        ),
    .i_vector_is_valid              ( tensor_vector_is_valid        ),
    .i_receiver_ready_for_result    ( m_axis_result_ready           ), // input to the accumulator
    .o_ready_to_accept_matrix       ( o_ready_to_accept_matrix      ),
    .o_ready_to_accept_vector       ( o_ready_to_accept_vector      ),
    .o_result_is_valid              ( tensor_result_valid           ),
    .o_this_is_the_last_result      ( o_this_is_the_last_result     ),
    .i_matrix                       ( r_matrix_packed               ),
    .i_vector                       ( r_vector_packed               ),
    .o_result                       ( w_result_packed               )
    );
    
    /* SENING THE DATA */
    
    /* Process:
     * We start receiving the data from the TensorUnit after both of the following signals are high.
     * tensor_result_valid, o_this_is_the_last_result
     * recieve the data in the next clock cycle
     */
    
    wire [D_WIDTH-1:0] w_result_unpacked [M_SIZE-1:0];
    integer result_idx = 0;
    
    // unroll the result vector, for easier data shifting the the always block below
    `UNPACK_VECTOR(D_WIDTH, M_SIZE, w_result_unpacked, w_result_packed)
    

    /* Sending process is simple: 
     * 1. Recieve all the data in the wire: w_result_unpacked
     * 2. Start sending the data in each clock cylce until all the data is sent
     */
    always @ (posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            m_axis_result_valid <= 1'b0;
            m_axis_result       <= 0;
        end else begin
            if (o_this_is_the_last_result & tensor_result_valid)  
                m_axis_result_valid <= 1'b1;
                
            if (m_axis_result_valid) begin
                m_axis_result <= w_result_unpacked[result_idx];
                
                // we will keep the data valid only until all the indexes are valid
                result_idx <= (result_idx < M_SIZE) ? result_idx + 1 : 0;  
                m_axis_result_valid <= (result_idx < M_SIZE) ? m_axis_result_valid : 0;
            end else begin
                m_axis_result <= 0;
            end
        end     
    end         
    
endmodule
