// Reference: https://www.edaboard.com/threads/how-to-declare-two-dimensional-input-ports-in-verilog.80929/

// Verilog-2005 does not allow two dimensional arrays in the input/output ports
// Therefore, the macros for doing that within the module are defined here.

//`define PACK_ARRAY(PK_WIDTH,PK_LEN,PK_SRC,PK_DEST)    genvar pk_idx; generate for (pk_idx=0; pk_idx<(PK_LEN); pk_idx=pk_idx+1) begin; assign PK_DEST[((PK_WIDTH)*pk_idx+((PK_WIDTH)-1)):((PK_WIDTH)*pk_idx)] = PK_SRC[pk_idx][((PK_WIDTH)-1):0]; end; endgenerate

//`define UNPACK_ARRAY(PK_WIDTH,PK_LEN,PK_DEST,PK_SRC)  genvar unpk_idx; generate for (unpk_idx=0; unpk_idx<(PK_LEN); unpk_idx=unpk_idx+1) begin; assign PK_DEST[unpk_idx][((PK_WIDTH)-1):0] = PK_SRC[((PK_WIDTH)*unpk_idx+(PK_WIDTH-1)):((PK_WIDTH)*unpk_idx)]; end; endgenerate

 /* Usage and Example */
/*
module example (
    input  [63:0] pack_4_16_in,
    output [31:0] pack_16_2_out
);

wire [3:0] in [0:15];
`UNPACK_ARRAY(4,16,in,pack_4_16_in)

wire [15:0] out [0:1];
`PACK_ARRAY(16,2,in,pack_16_2_out)


// useful code goes here

endmodule // example
*/
// ////////////////////////////////////////////////////////////////////////////

/* Vector Unpacking */
//`define UNPACK_MATRIX(D_WIDTH, M_SIZE, W_DEST, I_SRC) \
//  genvar upk_mat; \
//  generate \
//    for (upk_mat = 0; upk_mat < (M_SIZE); upk_mat = upk_mat + 1) begin \
//      assign W_DEST[upk_mat] = I_SRC[upk_mat * D_WIDTH +: D_WIDTH]; \
//    end \
//  endgenerate


/* Vector Unpacking */
`define UNPACK_VECTOR(D_WIDTH, M_SIZE, W_DEST, I_SRC) \
  genvar upk_idx; \
  generate \
    for (upk_idx = 0; upk_idx < (M_SIZE); upk_idx = upk_idx + 1) begin : upk_loop \
      assign W_DEST[upk_idx] = I_SRC[upk_idx * D_WIDTH +: D_WIDTH]; \
    end \
  endgenerate

/* Vector Unpacking Usage Template */
/* 
 * module my_module (
 *    input [(D_WIDTH) * (M_SIZE) - 1:0]  i_vector
 * );
 * 
 * parameter D_WIDTH = 8; // Define your data width
 * parameter M_SIZE = 4;  // Define your vector size
 * 
 * wire [D_WIDTH-1:0] wi_vector [M_SIZE-1:0];
 * 
 * `UNPACK_VECTOR(D_WIDTH, M_SIZE, wi_vector, i_vector)
 * 
 * // Rest of the module
 * endmodule
*/

/* Vector Packing */
`define PACK_VECTOR(D_WIDTH, M_SIZE, O_DEST, W_SRC) \
  genvar pk_idx; \
  generate \
    for (pk_idx = 0; pk_idx < (M_SIZE); pk_idx = pk_idx + 1) begin : pk_loop \
      assign O_DEST[pk_idx * D_WIDTH +: D_WIDTH] = W_SRC[pk_idx]; \
    end \
  endgenerate

/* Vector Packing Usage Template
 * module my_module (
 *   // Other input/output ports
 *   output reg [(D_WIDTH) * (M_SIZE) - 1:0]  o_vector
 * );
 *
 * parameter D_WIDTH = 8; // Define your data width
 * parameter M_SIZE = 4;  // Define your vector size
 *
 * wire [D_WIDTH-1:0] wo_vector [M_SIZE-1:0];
 *
 * // Populate wo_vector with data, e.g., from internal calculations
 *
 * `PACK_VECTOR(D_WIDTH, M_SIZE, o_vector, wo_vector)
 * 
 * // Rest of the 
 * endmodule
 */


/* Matrix Unpacking */
`define UNPACK_MATRIX(D_WIDTH, M_SIZE, W_DEST, I_SRC) \
  genvar upk_i, upk_j; \
  generate \
    for (upk_i = 0; upk_i < (M_SIZE); upk_i = upk_i + 1) begin : upk_i_loop \
      for (upk_j = 0; upk_j < (M_SIZE); upk_j = upk_j + 1) begin : upk_j_loop \
        assign W_DEST[upk_i][upk_j] = I_SRC[upk_i * M_SIZE * D_WIDTH + upk_j * D_WIDTH +: D_WIDTH]; \
      end \
    end \
  endgenerate
  
///* Matrix Unpacking Usage Template */
///*
// * module my_module (
// *  input [(D_WIDTH) * (M_SIZE) * (M_SIZE) - 1:0]  i_matrix
// * );
// * 
// * parameter D_WIDTH = 8; // Define your data width
// * parameter M_SIZE = 4;  // Define your matrix size
// * 
// * wire [D_WIDTH-1:0] wi_matrix [M_SIZE-1:0][M_SIZE-1:0];
// * 
// * `UNPACK_MATRIX(D_WIDTH, M_SIZE, wi_matrix, i_matrix)
// * 
// * // Rest of the module
// * endmodule
//*/

`define PACK_MATRIX(D_WIDTH, M_SIZE, W_DEST, I_SRC) \
  genvar pk_i, pk_j; \
  generate \
    for (pk_i = 0; pk_i < (M_SIZE); pk_i = pk_i + 1) begin : pk_i_loop \
      for (pk_j = 0; pk_j < (M_SIZE); pk_j = pk_j + 1) begin : pk_j_loop \
        assign W_DEST[pk_i * M_SIZE * D_WIDTH + pk_j * D_WIDTH +: D_WIDTH] = I_SRC[pk_i][pk_j][D_WIDTH-1:0]; \
      end \
    end \
  endgenerate
  
  
  /* PACK_MATRIX Example USAGE*/
  /*
  
  `include "pack_matrix_macro.v" // Assuming the PACK_MATRIX macro is defined in this file

module matrix_packer (
    input wire clk,
    input wire reset,
    output reg [(8 * 2 * 2) - 1 : 0] packed_matrix
);

    // Define the 2D array with dimensions [M_SIZE-1:0][M_SIZE-1:0] and 8-bit wide elements
    reg [7:0] matrix[1:0][1:0];

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            matrix[0][0] <= 8'h11;
            matrix[0][1] <= 8'h12;
            matrix[1][0] <= 8'h21;
            matrix[1][1] <= 8'h22;
        end
    end

    // Use the PACK_MATRIX macro to pack the 2D array 'matrix' into the 1D array 'packed_matrix'
    `PACK_MATRIX(8, 2, packed_matrix, matrix)

endmodule
  
  */