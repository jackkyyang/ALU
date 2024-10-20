/*
   Copyright 2024 jackkyyang

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.

 ***************************************************************************
 * File Name: onehot_mux.sv
 * Creation Date: 2024/10/20
 * Author: jackkyyang
 * Description:
 *   the one-hot multiplexer with the parameterized data type and select width.
 *
 * Parameter List:
 *   - T: data type of the input and output ports
 *   - SEL_WIDTH: width of the select signal and the number of input data
 * Input Ports:
 *   - data: input data array in a user-defined type T
 *   - sel_oh: select signal in a one-hot encoding
 * Output Ports:
 *   - data_o: output data in the user-defined type T
 *
 * Instance Example:
 *   onehot_mux #(
 *      .T(logic [7:0]),
 *      .SEL_WIDTH(8)
 *   ) mux (
 *       .data_i(data_i),
 *       .sel_oh(sel_oh),
 *       .data_o(data_o)
 *   );
 ***************************************************************************
*/



module onehot_mux #(
    parameter type T = logic,
    parameter integer SEL_WIDTH = 4
)(
    input  T                     data_i [SEL_WIDTH-1:0],
    input  logic [SEL_WIDTH-1:0] sel_oh,
    output T                     data_o
);

    localparam integer DATA_WIDTH = $bits(T);

    logic [DATA_WIDTH-1:0] data [SEL_WIDTH-1:0];
    logic [DATA_WIDTH-1:0] data_mux [SEL_WIDTH-1:0];
    logic [DATA_WIDTH-1:0] data_sel [SEL_WIDTH-1:0];

    generate
        for (genvar i = 0; i < SEL_WIDTH; i+=1)  begin:gen_data_in
            assign data[i] = DATA_WIDTH'(data_i[i]);
            assign data_sel[i] = (data[i] & {DATA_WIDTH{sel_oh[i]}});
        end
    endgenerate

    assign data_mux[0] = data_sel[0];
    generate
        for (genvar i = 1; i < SEL_WIDTH; i+=1)  begin:gen_mux
            assign data_mux[i] = data_mux[i-1] | data_sel[i];
        end
    endgenerate

    assign data_o = T'(data_mux[SEL_WIDTH-1]);

`ifdef COMM_ASSERT
    // SVA assertion to check if sel_oh is one-hot encoded
    always @(sel_oh)) begin
        assert ($onehot0(sel_oh)) else $fatal("sel_oh is not one-hot encoded");
    end
`endif // COMM_ASSERT


endmodule
