// Copyright 2019 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

// Author: Luca Colagrande <colluca@ethz.ch>

/// Address Decoder: Maps the input address combinatorially to an index.
/// The address map `addr_map_i` is a packed array of rule_t structs.
/// The ranges of any two rules may overlap. If so, the rule at the higher (more significant)
/// position in `addr_map_i` prevails.
///
/// There can be an arbitrary number of address rules. There can be multiple
/// ranges defined for the same index. The start address has to be less than the end address.
///
module multiaddr_decode #(
  /// Highest index which can happen in a rule.
  parameter int unsigned NoIndices = 32'd0,
  /// Total number of rules.
  parameter int unsigned NoRules   = 32'd0,
  /// Address type inside the rules and to decode.
  parameter type         addr_t    = logic,
  /// Rule packed struct type.
  /// The address decoder expects three fields in `rule_t`:
  ///
  /// typedef struct packed {
  ///   int unsigned idx;
  ///   addr_t       start_addr;
  ///   addr_t       end_addr;
  /// } rule_t;
  ///
  ///  - `idx`:        index of the rule, has to be < `NoIndices`
  ///  - `start_addr`: start address of the range the rule describes, value is included in range
  ///  - `end_addr`:   end address of the range the rule describes, value is NOT included in range
  parameter type         rule_t    = logic
) (
  /// Address to decode.
  input  addr_t                addr_i,
  /// Address map.
  input  rule_t [NoRules-1:0]  addr_map_i,
  /// Decoded indices.
  output logic [NoIndices-1:0] mask_o,
  /// Decode is valid.
  output logic                 dec_valid_o,
  /// Decode is not valid, no matching rule found.
  output logic                 dec_error_o
);

  logic [NoRules-1:0] matched_rules; // purely for address map debugging

  always_comb begin
    // default assignments
    matched_rules = '0;
    dec_valid_o   = 1'b0;
    dec_error_o   = 1'b1;
    mask_o        = '0;

    // match the rules
    for (int unsigned i = 0; i < NoRules; i++) begin
      if ((addr_i >= addr_map_i[i].start_addr) && (addr_i < addr_map_i[i].end_addr)) begin
        matched_rules[i]          = 1'b1;
        dec_valid_o               = 1'b1;
        dec_error_o               = 1'b0;
        mask_o[addr_map_i[i].idx] = 1'b1;
      end
    end
  end

  // Assumptions and assertions
  `ifndef VERILATOR
  `ifndef XSIM
  // pragma translate_off
  initial begin : proc_check_parameters
    assume (NoRules > 0) else
      $fatal(1, $sformatf("At least one rule needed"));
  end
  // pragma translate_on
  `endif
  `endif

endmodule
