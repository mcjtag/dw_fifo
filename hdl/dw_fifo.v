`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// 
// Create Date: 13.08.2023 18:17:43
// Design Name: 
// Module Name: dw_fifo
// Project Name: dw_fifo
// Target Devices:
// Tool Versions:
// Description:
// Dependencies:
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// License: MIT
//  Copyright (c) 2023 Dmitry Matyunin
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
// 
//////////////////////////////////////////////////////////////////////////////////

module dw_fifo #(
	parameter WRITE_WIDTH = 32,						/* must be power of 2 */
	parameter READ_WIDTH = 32,						/* must be power of 2 */
	parameter DEPTH_BITS = 128,						/* must be power of 2 */
	parameter WR_LEN_WIDTH = $clog2(WRITE_WIDTH)+1,	/* do not modify */
	parameter RD_LEN_WIDTH = $clog2(READ_WIDTH)+1,	/* do not modify */
	parameter WR_OFFSET = 0							/* write offset flag */
)
(
	input wire clk,
	input wire rst,
	input wire wr_en,								/* write enable */
	input wire [WRITE_WIDTH-1:0]wr_data,			/* data to be written */
	input wire [WR_LEN_WIDTH-1:0]wr_len,			/* width of bits from wr_data to be written*/
	input wire [WR_LEN_WIDTH-1:0]wr_offt,			/* start bit in wr_data */
	output wire wr_full,							/* fifo full flag */
	output wire wr_valid,							/* valid signal for write operation */
	input wire rd_en,								/* read enable */
	output wire [READ_WIDTH-1:0]rd_data,			/* data to be read */
	input wire [RD_LEN_WIDTH-1:0]rd_len,			/* width of bits from wr_data to be read */
	output wire rd_empty,							/* fifo empty flag */
	output wire rd_valid							/* valid signal for read operation */
);

localparam BPTR_WIDTH = $clog2(DEPTH_BITS);

reg [DEPTH_BITS-1:0]barray, barray_next = {DEPTH_BITS{1'b0}};
reg [BPTR_WIDTH-1:0]bptr, bptr_wr, bptr_next = {BPTR_WIDTH{1'b0}};

reg [READ_WIDTH-1:0]rd_data_r;

integer i;

assign rd_empty = rd_len > bptr;
assign rd_valid = rd_en & ~rd_empty & ~rst;
assign rd_data = rd_data_r;

assign wr_full = (DEPTH_BITS - 1 - bptr_wr) < wr_len;
assign wr_valid = wr_en & ~wr_full & ~rst;

always @(*) begin
	for (i = 0; i < READ_WIDTH; i = i + 1) begin
		if (i < rd_len) begin
			rd_data_r[i] = barray[i];
		end else begin
			rd_data_r[i] = 1'b0;
		end
	end
end

always @(*) begin
	if (rd_valid == 1'b1) begin
		bptr_wr = bptr - rd_len;
	end else begin
		bptr_wr = bptr;
	end
	
	if (wr_valid == 1'b1) begin
		bptr_next = bptr_wr + wr_len;
	end else begin
		bptr_next = bptr_wr;
	end
end

always @(*) begin
	barray_next = barray;
	
	if (rd_valid == 1'b1) begin
		for (i = 0; i < DEPTH_BITS; i = i + 1) begin
			if (i+rd_len < DEPTH_BITS) begin
				barray_next[i] = barray[i+rd_len];
			end
		end
	end
	
	if (wr_valid == 1'b1) begin
		for (i = 0; i < DEPTH_BITS; i = i + 1) begin
			if ((i >= bptr_wr) && (i < bptr_wr + wr_len)) begin
				if (WR_OFFSET) begin
					barray_next[i] = wr_data[wr_offt+i-bptr_wr];
				end else begin
					barray_next[i] = wr_data[i-bptr_wr];
				end
			end
		end
	end
end

always @(posedge clk) begin
	if (rst == 1'b1) begin
		bptr <= {BPTR_WIDTH{1'b0}};
		barray <= {DEPTH_BITS{1'b0}};
	end else begin
		bptr <= bptr_next;
		barray <= barray_next;
	end
end

endmodule 
