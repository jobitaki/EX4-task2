`default_nettype none

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);

    RangeFinder #(8) rf(
        .data_in(io_in[7:0]),
        .clock(clock),
        .reset(reset),
        .go(io_in[8]),
        .finish(io_in[9]),
        .range(io_out[7:0]),
        .debug_error(io_out[8])
    );

endmodule
