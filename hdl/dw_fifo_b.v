`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Dmitry Matyunin (https://github.com/mcjtag)
// Create Date: 13.08.2023 18:17:43
// Module Name: dw_fifo
// Project Name: dw_fifo
// Additional Comments:
// License: MIT
//  Copyright (c) 2024 Dmitry Matyunin
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

module dw_fifo_b #(
	parameter BYTE_SIZE = 8,						/* Byte Size in bits */
	parameter WRITE_SIZE = 4,						/* Write Size in bytes */
	parameter READ_SIZE = 4,						/* Read Size in bytes */
	parameter WRITE_WIDTH = WRITE_SIZE*BYTE_SIZE,	/* Write Width */
	parameter READ_WIDTH = READ_SIZE*BYTE_SIZE,		/* Read Width */
	parameter FIFO_DEPTH = 8,						/* FIFO Depth in bytes (power of 2) */
	parameter WRITE_LENGTH = $clog2(WRITE_SIZE),	/* Do not modify */
	parameter READ_LENGTH = $clog2(READ_SIZE)		/* Do not modify */
)
(
	input wire clk,
	input wire rstn,
	input wire wr_en,								/* Write enable */
	input wire [WRITE_WIDTH-1:0]wr_data,			/* Data to be written */
	input wire [WRITE_LENGTH-1:0]wr_len,			/* Width of bytes from wr_data to be written*/
	input wire [WRITE_LENGTH-1:0]wr_offt,			/* Start byte in wr_data */
	output wire wr_full,							/* FIFO Full flag */
	output wire wr_valid,							/* Valid signal for write operation */
	input wire rd_en,								/* Read enable */
	output wire [READ_WIDTH-1:0]rd_data,			/* Data to be read */
	input wire [READ_LENGTH-1:0]rd_len,				/* Width of bytes from wr_data to be read */
	output wire rd_empty,							/* FIFO Empty flag */
	output wire rd_valid							/* Valid signal for read operation */
);

localparam BPTR_WIDTH = $clog2(FIFO_DEPTH);

reg [FIFO_DEPTH*BYTE_SIZE-1:0]barray, barray_next = {(FIFO_DEPTH*BYTE_SIZE){1'b0}};
reg [BPTR_WIDTH-1:0]bptr, bptr_wr, bptr_next = {BPTR_WIDTH{1'b0}};

reg [READ_WIDTH-1:0]rd_data_r;

integer i;

assign rd_empty = rd_len >= bptr;
assign rd_valid = rd_en & ~rd_empty & rstn;
assign rd_data = rd_data_r;

assign wr_full = (FIFO_DEPTH - 1 - bptr_wr) <= wr_len;
assign wr_valid = wr_en & ~wr_full & rstn;

always @(*) begin
	for (i = 0; i < READ_SIZE; i = i + 1) begin
		if (i <= rd_len) begin
			rd_data_r[(i+1)*BYTE_SIZE-1-:BYTE_SIZE] = barray[(i+1)*BYTE_SIZE-1-:BYTE_SIZE];
		end else begin
			rd_data_r[(i+1)*BYTE_SIZE-1-:BYTE_SIZE] = 'd0;
		end
	end
end

always @(*) begin
	if (rd_valid == 1'b1) begin
		bptr_wr = bptr - rd_len - 1;
	end else begin
		bptr_wr = bptr;
	end
	
	if (wr_valid == 1'b1) begin
		bptr_next = bptr_wr + wr_len + 1;
	end else begin
		bptr_next = bptr_wr;
	end
end

always @(*) begin
	barray_next = barray;
	
	if (rd_valid == 1'b1) begin
		for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
			if ((i + rd_len + 1) < FIFO_DEPTH) begin
				barray_next[(i+1)*BYTE_SIZE-1-:BYTE_SIZE] = barray[(i+1+rd_len+1)*BYTE_SIZE-1-:BYTE_SIZE];
			end
		end
	end
	
	if (wr_valid == 1'b1) begin
		for (i = 0; i < FIFO_DEPTH; i = i + 1) begin
			if ((i >= bptr_wr) && (i < (bptr_wr + wr_len + 1))) begin
				barray_next[(i+1)*BYTE_SIZE-1-:BYTE_SIZE] = wr_data[(wr_offt+i-bptr_wr+1)*BYTE_SIZE-1-:BYTE_SIZE]; 
			end
		end
	end
end

always @(posedge clk or negedge rstn) begin
	if (rstn == 1'b0) begin
		bptr <= {BPTR_WIDTH{1'b0}};
		barray <= {(FIFO_DEPTH*BYTE_SIZE){1'b0}};
	end else begin
		bptr <= bptr_next;
		barray <= barray_next;
	end
end

endmodule
