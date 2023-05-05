`timescale 1ns / 1ps

module MatrixVector_Pipelined #(parameter D_WIDTH=32, M_SIZE=10) (
    input                   aclk,
    input                   aresetn,
    
    input  [D_WIDTH-1:0]    i_matrix,
    input  [D_WIDTH-1:0]    i_vector,
    
    output [D_WIDTH-1:0]    o_result
    );
    
    
    
endmodule
