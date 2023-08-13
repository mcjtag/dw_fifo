# dw_fifo
Asymmetrical FIFO with dynamic width

## Description
`dw_fifo` is based on a combinatorial queue, that allows to implement a dynamic width mechanism and rational ratio.
If N is width of input data and K is width of output data, then K/N ratio can be a rational number (1/2, 3/4, 7/3 and so on).
Such a FIFO can be useful in implementing serdes.

## Parameters:
* `WRITE_WIDTH`  - Width of input data bus, must be power of 2
* `READ_WIDTH`   - Width of output data bus, must be power of 2
* `DEPTH_BITS` 	 - Depth of FIFO (in bits), must be power of 2
* `WR_LEN_WIDTH` - Width of length of bits to be written (Width of "width"), must be log2(WRITE_WIDTH)+1
* `RD_LEN_WIDTH` - Width of length of bits to be read (Width of "width"), must be log2(READ_WIDTH)+1
* `WR_OFFSET`    - Write offset flag

## Ports
* `clk`      - Input clock
* `rst`      - Reset
* `wr_en`    - Write enable
* `wr_data`  - Input data to be written
* `wr_len`   - Width of bits from wr_data to be written
* `wr_offt`  - Start bit in wr_data
* `wr_full`  - FIFO full flag
* `wr_valid` - Valid signal for write operation
* `rd_en`    - Read enable
* `rd_data`  - Data to be read
* `rd_len`   - Width of bits from wr_data to be read
* `rd_empty` - FIFO empty flag
* `rd_valid` - Valid signal for read operation

## Requirements
* `DEPTH_BITS` parameter must be at least 2 times larger than  `WRITE_WIDTH` and `READ_WIDTH`

## Example

If it is necessary to implement a FIFO with N = 7 and K = 4, where N is input width and K is output width, then the following scheme is possible:

Parameters:
`WRITE_WIDTH` -> 8 (must be power of 2 and not less than N)
`READ_WIDTH`  -> 4
`DEPTH_BITS`  -> 16 (minimum value)

Ports:
`wr_data` -> {1'bx, SOME_WR_DATA[6:0]}
`wr_len`  -> 7
and
`rd_data` -> {SOME_RD_DATA[3:0]} 
`rd_len`  -> 4