// Author: Jaehyun Lim
// Date: 1/19/23
//
// RangeFinder is a hardware thread that takes a series of inputs when go is
// asserted, keeps track of the minimum and maximum inputs, and when 
// finish is asserted, has a valid range output that is the difference b/w
// maximum and minimum input values.

`default_nettype none

module RangeFinder
#(parameter WIDTH=16)
  (input  logic [WIDTH-1:0] data_in,
   input  logic clock, reset,
   input  logic go, finish,
   output logic [WIDTH-1:0] range,
   output logic debug_error);

  logic on;
  logic wait_go, initial_go;
  logic [WIDTH-1:0] min_out, max_out;
  logic switch_min, switch_max;

  // Unused outputs of MagComp
  logic datagtmin, dataeqmin, dataltmax, dataeqmax;

  RangeFinder_fsm fsm (.*);

  Register #(WIDTH) min_reg  (.D(data_in), .Q(min_out), 
                              .en(initial_go | switch_min), 
                              .clear(wait_go | reset), .clock);
  Register #(WIDTH) max_reg  (.D(data_in), .Q(max_out), 
                              .en(initial_go | switch_max), 
                              .clear(wait_go | reset), .clock);

  MagComp  #(WIDTH) min_comp (.A(data_in), .B(min_out), .AltB(switch_min),
                              .AeqB(dataeqmin), .AgtB(datagtmin));
  MagComp  #(WIDTH) max_comp (.A(data_in), .B(max_out), .AgtB(switch_max),
                              .AeqB(dataeqmax), .AltB(dataltmax));

  assign range = max_out - min_out;

endmodule: RangeFinder

module RangeFinder_fsm
  (input  logic go, finish, clock, reset,
   output logic on, initial_go, debug_error, wait_go);

  enum logic [1:0] {WAIT = 2'b00, 
                    GO = 2'b01,
                    ERROR_WAIT = 2'b10} state, n_state;

  // Next state logic 
  always_comb begin
    initial_go = 1'b0;
    case(state) 
      WAIT:
        if (finish & go) 
          n_state = ERROR_WAIT;
        else if (finish) 
          n_state = ERROR_WAIT;
        else if (go) begin
          n_state = GO;
          initial_go = 1'b1;
        end else 
          n_state = WAIT;
      GO:
        if (finish)
          n_state = WAIT;
        else
          n_state = GO;
      ERROR_WAIT:
        if (go) begin
          n_state = GO;
          initial_go = 1'b1;
        end else
          n_state = ERROR_WAIT;
      default: n_state = WAIT;
    endcase
  end

  // Output logic
  always_comb begin
    wait_go = 1'b0;
    debug_error = 1'b0;
    on = 1'b0;

    case(state)
      WAIT:       wait_go = 1'b1;
      GO:         on = 1'b1;
      ERROR_WAIT: debug_error = 1'b1;
    endcase

  end

  always_ff @(posedge clock, posedge reset) 
    if (reset)
      state = WAIT;
    else
      state = n_state;

endmodule: RangeFinder_fsm

module MagComp
    #(parameter WIDTH = 1)
    (output logic AltB, AeqB, AgtB,
     input  logic [WIDTH-1:0] A, B);

    assign AltB = (A < B);
    assign AeqB = (A == B);
    assign AgtB = (A > B);

endmodule: MagComp

module Register
    #(parameter WIDTH = 1)
    (output logic [WIDTH-1:0] Q,
     input  logic [WIDTH-1:0] D,
     input  logic             en, clear, clock);

    always_ff @(posedge clock) begin
        if (en)
            Q <= D;
        else if (clear)
            Q <= '0;
        else 
            Q <= Q;
    end

endmodule: Register
