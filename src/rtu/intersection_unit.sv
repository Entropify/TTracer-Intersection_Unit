`default_nettype wire
/* verilator lint_off IMPORTSTAR */
import tinytracer_pkg::*;
/* verilator lint_on IMPORTSTAR */

// Debug export intermediate for FSM
/* verilator lint_off DECLFILENAME */ // debug build only: package sits beside the module
package iu_types_pkg;
    typedef enum logic [1:0] {
        S_IDLE       = 2'd0,
        S_RTU_LOAD   = 2'd1,
        S_PROCESS_BV = 2'd2,
        S_CHECKOUT   = 2'd3
    } state_t;

    typedef enum logic [1:0] {
        S_SRAM_IDLE = 2'd0,
        S_SRAM_SEND = 2'd1,
        S_SRAM_WAIT = 2'd2,
        S_SRAM_NEXT = 2'd3
    } sram_state_t;

    typedef enum logic [1:0] {
        S_DEC_IDLE = 2'd0,
        S_DEC_SEND = 2'd1,
        S_DEC_WAIT = 2'd2,
        S_DEC_DONE = 2'd3
    } dec_state_t;
    
    // wip not implemented
    // p = ray * t
    // outward_normal = (p - bv_origin) / bv_r
    // front_face = (dot(ray_dir, normal) < 0)
    // normal = front_face ? outward_normal : -outward_normal;
    // hit_flip =
    //
    // The old stages (CALC_A .. CALC_T) found the distance with the quadratic
    // t = (h + sqrt(h*h - a*c)) / a. A bounding-volume test needs no distance at
    // all and the sphere test only needs the half chord, so the sequence now
    // follows the spec's along/offset form, which the sphere test reuses as is:
    typedef enum logic [6:0] {
        CALC_R2     = 7'd0,   // r_s^2 = r_s x r_s                 M_MUL fmt 0       3
        CALC_TC     = 7'd1,   // to_centre = C - O                 M_VSUB            7
        CALC_ALONG  = 7'd2,   // along = to_centre . D             M_DOT fmt 1      11
        CALC_TCSQ   = 7'd3,   // |to_centre_s|^2                   M_DOT fmt 0      11  (u,v by K)
        CALC_INSIDE = 7'd4,   // |to_centre_s|^2 < r_s^2 ?         M_LT              3  yes: reach
        CALC_BEHIND = 7'd5,   // along < 0 ?                       M_LT              3  yes: skip
        CALC_M      = 7'd6,   // along x D                         M_SCAL_VEC fmt 1  7
        CALC_OFF    = 7'd7,   // offset = along x D - to_centre    M_VSUB            7
        CALC_OFFSQ  = 7'd8,   // |offset_s|^2                      M_DOT fmt 0      11  (u,v by K)
        CALC_REACH  = 7'd9,   // |offset_s|^2 < r_s^2 ?            M_LT              3  yes: reach
        // Sphere test (spec 5d). The first six steps are the same walk as the
        // BV test, so they reuse the same slots; only the radius and centre
        // come from the object record instead of the BV record.
        SP_R2       = 7'd10,  // r_s^2 = r_s x r_s                 M_MUL fmt 0       3
        SP_TC       = 7'd11,  // to_centre = C - O                 M_VSUB            7
        SP_ALONG    = 7'd12,  // along = to_centre . D             M_DOT fmt 1      11
        SP_M        = 7'd13,  // along x D                         M_SCAL_VEC fmt 1  7
        SP_OFF      = 7'd14,  // offset = along x D - to_centre    M_VSUB            7
        SP_OFFSQ    = 7'd15,  // |offset_s|^2                      M_DOT fmt 0      11  (u,v by K)
        SP_MISS     = 7'd16,  // |offset_s|^2 < r_s^2 ?            M_LT              3  no: miss
        SP_HALF2    = 7'd17,  // r_s^2 - |offset_s|^2              M_SUB             3
        SP_SQRT     = 7'd18,  // half_s = sqrt(r_s^2 - off_s^2)    M_SQRT fmt 0     25
        SP_T        = 7'd19,  // t = along - half                  M_SUB             3  entry point
        SP_TGATE    = 7'd20,  // 0.0156 < t ?                      M_LT              3  yes: candidate
        SP_T2       = 7'd21,  // t = along + half                  M_ADD             3  exit point, flip 1
        SP_TGATE2   = 7'd22,  // 0.0156 < t ?                      M_LT              3  no: miss
        SP_BEST     = 7'd23,  // t < best t ?                      M_LT              3  yes: keep
        // Ground test (spec 5f). Runs only when no object was hit, and only
        // when the ray points down. A clamped divide means the floor is too
        // far away, which counts as sky.
        GR_UP       = 7'd25,  // D_z < 0 ?                         M_LT              3  no: sky
        GR_T        = 7'd26,  // t = O_z / -D_z                    M_DIV            19
        // Winner steps (spec 5g). The hit point for every hit, then n for the
        // winner only: the ground n and the checker bit need no macro-op.
        H1          = 7'd27,  // best t x D                        M_SCAL_VEC fmt 1  7
        H2          = 7'd28,  // H = O + (best t x D)              M_VADD            7
        S2          = 7'd29,  // H - C, or C - H when flip = 1     M_VSUB            7
        S4          = 7'd30,  // n = that / r                      M_SPHERE_NORM    57
        CALC_DONE   = 7'd127, // this BV, object, triangle or winner is finished

        // Triangle test (spec 5e). Stage 1 asks whether the triangle is worth
        // testing, stage 2 builds det and the top of alpha, stage 3 does the
        // same for beta, and stage 4 turns the two fractions into a distance.
        // The two edges stay in registers across stages 1 and 2, then each
        // stage re-reads the one it needs at the size it needs.
        TRI_TC      = 7'd31,  // to_corner = v0 - O                M_VSUB            7
        TRI_ALONG   = 7'd32,  // along = to_corner . D             M_DOT fmt 1      11
        TRI_M       = 7'd33,  // along x D                         M_SCAL_VEC fmt 1  7
        TRI_SLID    = 7'd34,  // slid = along x D - to_corner      M_VSUB            7
        TRI_SLIDSQ  = 7'd35,  // |slid_s|^2                        M_DOT fmt 0      11  (u,v by K)
        TRI_FAR     = 7'd36,  // 225 < that ?                      M_LT              3  yes: miss
        TRI_P       = 7'd37,  // P = D x e2s                       M_CROSS fmt 1    14
        TRI_DET     = 7'd38,  // det = e1s . P                     M_DOT fmt 0      11
        TRI_ATOP    = 7'd39,  // alpha_top = slid_s . P            M_DOT fmt 0      11
        TRI_BACK    = 7'd40,  // det < 0 ?                         M_LT              3  yes: back side
        TRI_NEGD    = 7'd41,  // 0 - det                           M_SUB             3  back only
        TRI_NEGA    = 7'd42,  // 0 - alpha_top                     M_SUB             3  back only
        TRI_DETP    = 7'd43,  // 0 < det ?                         M_LT              3  no: parallel
        TRI_ATOPN   = 7'd44,  // alpha_top < 0 ?                   M_LT              3  yes: miss
        TRI_DETLO   = 7'd45,  // det < alpha_top ?                 M_LT              3  yes: miss
        TRI_Q       = 7'd46,  // Q = slid_s x e1s                  M_CROSS fmt 0    14
        TRI_BETA    = 7'd47,  // beta_top = D . Q                  M_DOT fmt 1      11
        TRI_NEGB    = 7'd48,  // 0 - beta_top                      M_SUB             3  back only
        TRI_BETAN   = 7'd49,  // beta_top < 0 ?                    M_LT              3  yes: miss
        TRI_SUM     = 7'd50,  // alpha_top + beta_top              M_ADD             3
        TRI_SUMD    = 7'd51,  // det < that ?                      M_LT              3  yes: miss
        TRI_ALPHA   = 7'd52,  // alpha = alpha_top / det           M_DIV            19
        TRI_BETAD   = 7'd53,  // beta = beta_top / det             M_DIV            19
        TRI_E1D     = 7'd54,  // e1 . D, true size                 M_DOT fmt 1      11
        TRI_A1      = 7'd55,  // alpha x that                      M_MUL fmt 1       3
        TRI_SUM1    = 7'd56,  // along + that                      M_ADD             3
        TRI_E2D     = 7'd57,  // e2 . D, true size                 M_DOT fmt 1      11
        TRI_B2      = 7'd58,  // beta x that                       M_MUL fmt 1       3
        TRI_T       = 7'd59,  // t = step 56 + step 58             M_ADD             3
        TRI_GATE    = 7'd60,  // 0.0156 < t ?                      M_LT              3  no: miss
        TRI_BEST    = 7'd61,  // t < best t ?                      M_LT              3  yes: keep
        // Triangle normal (spec 5g). u and v are the two edges, entered either
        // way round so that a back side hit gets the arrow turned around.
        N1_CROSS    = 7'd62,  // u x v                             M_CROSS fmt 0    14
        N2_NORM     = 7'd63   // resize pre-shift, then length 1   M_NORM fmt 1     65
        // WiP for hit_flip

    } calc_stage_t;

    // Phase: which memory read or step sequence is running. PH_READ is BV
    // w1-w4, PH_W0 is BV w0 (reach only), PH_OBJ is an object's w0 (type bit),
    // PH_HEAD its w3-w6, PH_SPHERE the sphere steps, the rest advance.
    typedef enum logic [4:0] {
        PH_READ     = 5'd0,
        PH_CALC     = 5'd1,
        PH_W0       = 5'd2,
        PH_NEXT     = 5'd3,
        PH_OBJ      = 5'd4,
        PH_HEAD     = 5'd5,
        PH_SPHERE   = 5'd6,
        PH_OBJ_NEXT = 5'd7,
        PH_GROUND   = 5'd8,   // the ground test, only when nothing was hit
        PH_WIN      = 5'd9,   // the winner steps: H, then n
        PH_WIN_C    = 5'd10,  // winner burst: the sphere centre w4-w6
        PH_WIN_R    = 5'd11,  // winner burst: the sphere radius w3, unshifted
        PH_CHECK    = 5'd12,  // nothing left to do: report
        PH_TRI_E    = 5'd13,  // triangle: both edges w3-w8, which is where K comes from
        PH_TRI_V    = 5'd14,  // triangle: the corner w9-w11
        PH_TRI      = 5'd15,  // triangle: walk the step chain
        PH_TRI_E1B  = 5'd16,  // triangle stage 3: edge 1 again
        PH_TRI_E1C  = 5'd17,  // triangle stage 4: edge 1 at its true size
        PH_TRI_E2C  = 5'd18,  // triangle stage 4: edge 2 at its true size
        PH_NORM_U   = 5'd19,  // triangle normal: both edges again
        PH_NORM     = 5'd20   // triangle normal: cross, then resize
    } bv_phase_t;
endpackage
/* verilator lint_on DECLFILENAME */

/* verilator lint_off IMPORTSTAR */
import iu_types_pkg::*;
/* verilator lint_on IMPORTSTAR */

// Intersection Unit: finds the closest thing that one ray segment hits.
module intersection_unit #(
    /* verilator lint_off VARHIDDEN */ // names come from the package, redeclared per module
    parameter ADDR_WIDTH = 9,
    parameter WLEN       = 16,
    parameter DATA_WIDTH = 16
    /* verilator lint_on VARHIDDEN */
) (
    input  logic                   clk,
    input  logic                   rst_n,       // global reset, active low

    // RTU FSM <-> Intersection Unit
    input  logic                   start,       // 1-cycle pulse: search one segment
    output logic                   done,        // 1-cycle pulse: the hit outputs are valid
    output logic                   hit,         // 1 = object or ground hit, 0 = sky
    output logic                   hit_ground,  // 1 = the hit is the ground (only with hit = 1)
    output logic [ADDR_WIDTH-1:0]  hit_addr,    // SRAM address of the hit object's w0
    output logic                   hit_flip,    // sphere: ray started inside; triangle: back side
    output logic [47:0]            hit_point,   // H, POS: z [47:32], y [31:16], x [15:0]
    output logic [47:0]            n,           // out-arrow, DIR, faces the ray, same field order
    output logic                   checker_bit, // hit_point[9] XOR hit_point[25], ground only
                                                       // (the spec calls it `checker`, which is a
                                                       //  SystemVerilog keyword)

    // Ray and scene, from RTU registers (must not change from start to done)
    input  logic [47:0]            ray_origin,  // O, POS (Q9.7): z [47:32], y [31:16], x [15:0]
    input  logic [47:0]            ray_dir,     // D, DIR (Q2.14), length 1: z [47:32], y [31:16], x [15:0]
    input  logic [4:0]             bv_count,    // number of BVs, 0 to 16 (header w15[7:3])

    // Macro-ops to the Decode Unit. macro_if carries req_valid, req_op,
    // req_ready, resp_valid, resp_result and resp_ready, and this module is the
    // client.
    macro_if.client                macro,

    // Reads from the SRAM controller, as the client of sram_rd_if
    sram_rd_if.client              sram,

    // Debug
    output state_t                 state_q,
    output state_t                 state_d,
    output sram_state_t            sram_state_q,
    output sram_state_t            sram_state_d,
    output dec_state_t             dec_state_q,
    output dec_state_t             dec_state_d,
    output calc_stage_t            calc_stage_q,
    output calc_stage_t            calc_stage_d,
    output [ADDR_WIDTH-1:0]        dbg_obj_addr,   // w0[15:7] of the reached BV
    output [6:0]                   dbg_obj_cnt     // w0[6:0]  of the reached BV
);

    // ------------------------------------------------------------------
    // Interface aliases. The body below reads these names; the interface
    // members carry them in and out.
    // ------------------------------------------------------------------
    logic [ADDR_WIDTH-1:0] sram_addr_q;   // address of the word to read
    logic                  sram_req;      // 1-cycle pulse: read that word
    logic [DATA_WIDTH-1:0] sram_rdata;    // the word that came back
    logic                  sram_rvalid;   // 1 = that word is valid
    logic                  macro_reqvalid;
    logic [101:0]          req_sel;       // fmt + u + v + opcode, before the cast
    logic                  macro_reqready;
    logic                  macro_rvalid;
    logic [3*WLEN-1:0]     macro_result;
    logic                  macro_rready;

    assign sram_rdata      = sram.resp_rdata;
    assign sram_rvalid     = sram.resp_valid;
    assign sram.req_raddr  = sram_addr_q;
    assign sram.req_valid  = sram_req;
    assign sram.resp_ready = 1'b1;

    assign macro_rvalid     = macro.resp_valid;
    assign macro_reqready   = macro.req_ready;
    assign macro_result     = macro.resp_result;
    assign macro.req_valid  = macro_reqvalid;
    assign macro.resp_ready = macro_rready;
    // macro_word_t is {fmt, u, v, op} = 102 bits, the same order as req_sel
    assign macro.req_op     = macro_word_t'(req_sel);

    // Assumption:
    // input ray_origin, ray_dir, bv_count stay same in between start 1-cycle pulse
    // input macro_rvalid, res stay same until macro_rready and macro_reqvalid(?)

    // ------------------------------------------------------------------
    // Free compares (Rec 2). Ten checks in the step lists only read the sign,
    // or a threshold, of a number this module already holds. Doing them through
    // the Decode costs a three cycle round trip; as gates they cost one cycle.
    // ------------------------------------------------------------------
    logic cmp_free;   // the current step is one of those checks
    logic free_res;   // its answer, valid the cycle the step is current
    logic [47:0] res; // the step's result, from the gates or from the Decode

    always_comb begin
        cmp_free = 1'b0;
        free_res = 1'b0;
        case (calc_stage_q)
            // along < 0: is the bubble's centre behind the start?
            CALC_BEHIND: begin cmp_free = 1'b1; free_res = slot_a[15]; end
            // 0.0156 < t: is anything actually in front of the start?
            SP_TGATE,
            SP_TGATE2,
            TRI_GATE:    begin cmp_free = 1'b1;
                               free_res = !slot_k[15] && (|slot_k[14:2] || &slot_k[1:0]); end
            // D_z < 0: does the ray point down?
            GR_UP:       begin cmp_free = 1'b1; free_res = ray_dir[47]; end
            // 225 < |slid_s|^2: further than 15 from the corner? 225 is 28,800 raw
            TRI_FAR:     begin cmp_free = 1'b1; free_res = (result_q[15:0] > 16'd28800); end
            // det < 0: back side hit
            TRI_BACK:    begin cmp_free = 1'b1; free_res = slot_i[15]; end
            // 0 < det: not parallel to the plane
            TRI_DETP:    begin cmp_free = 1'b1; free_res = !slot_i[15] && (|slot_i); end
            // alpha_top < 0 and beta_top < 0
            TRI_ATOPN:   begin cmp_free = 1'b1; free_res = slot_b[15]; end
            TRI_BETAN:   begin cmp_free = 1'b1; free_res = slot_j[15]; end
            default: ;
        endcase
    end

    // A free compare has no answer to wait for, so it completes on its own cycle
    assign res = cmp_free ? {47'd0, free_res} : macro_result;

    // ------------------------------------------------------------------
    // K shift and the highest-set-bit finder (spec 5d). The finder picks K so
    // that a radius lands in 8..16 before it is squared; the shifter applies K
    // on the way into a request, so it costs no cycles.
    //
    // The finder is written as gates, not as a loop: a priority chain leaves
    // exactly one bit set, then an OR tree turns that bit into its index. The
    // input is the raw radius word as it lands, so no extra register is needed.
    // ------------------------------------------------------------------
    // Bits 14..1 of the one-hot. Bit 0 is not built: if the highest set bit is
    // position 0 then every index bit is 0 anyway, so it feeds nothing.
    logic [14:1] lof_prio;   // one-hot: the highest set bit of the value below
    logic [3:0]  lof_index;  // that bit's position

    // Two things ask for a size: the radius word as it lands, and, for a
    // triangle, the largest of its six edge parts. The second rule is one off
    // because K = msb(largest edge) - 9 instead of the radius - 10.
    logic [14:1] lof_in;   // bit 0 feeds no index bit, so it is not carried
    logic        tri_edge_rd;               // the six-word edge burst is running
    logic [14:0] tri_mag_next;

    logic        norm_rd;                   // the triangle normal is being scaled
    /* verilator lint_off UNUSEDSIGNAL */   // bit 0 feeds no index bit, as above
    logic [14:0] norm_mag;                  // largest part of the cross product
    /* verilator lint_on UNUSEDSIGNAL */

    assign norm_rd      = (calc_stage_q == N2_NORM);
    assign norm_mag     = max15(max15(abs15(slot_c), abs15(slot_d)), abs15(slot_e));
    assign tri_edge_rd  = (bv_phase == PH_TRI_E);
    assign tri_mag_next = max15(tri_mag, abs15(sram_rdata));
    assign lof_in       = norm_rd    ? norm_mag[14:1] :
                          (tri_edge_rd ? tri_mag_next[14:1] : sram_rdata[14:1]);

    // spec 6.4: k = highest bit of the largest part - 13, so the arrow reads as
    // DIR and its largest part lands between 0.5 and 1
    logic signed [4:0] pre_k;
    assign pre_k        = $signed({1'b0, lof_index}) - 5'sd13;

    // Priority: a bit survives only when nothing above it is set
    assign lof_prio[14] = lof_in[14];
    assign lof_prio[13] = lof_in[13] & ~(|lof_in[14:14]);
    assign lof_prio[12] = lof_in[12] & ~(|lof_in[14:13]);
    assign lof_prio[11] = lof_in[11] & ~(|lof_in[14:12]);
    assign lof_prio[10] = lof_in[10] & ~(|lof_in[14:11]);
    assign lof_prio[9]  = lof_in[9]  & ~(|lof_in[14:10]);
    assign lof_prio[8]  = lof_in[8]  & ~(|lof_in[14:9]);
    assign lof_prio[7]  = lof_in[7]  & ~(|lof_in[14:8]);
    assign lof_prio[6]  = lof_in[6]  & ~(|lof_in[14:7]);
    assign lof_prio[5]  = lof_in[5]  & ~(|lof_in[14:6]);
    assign lof_prio[4]  = lof_in[4]  & ~(|lof_in[14:5]);
    assign lof_prio[3]  = lof_in[3]  & ~(|lof_in[14:4]);
    assign lof_prio[2]  = lof_in[2]  & ~(|lof_in[14:3]);
    assign lof_prio[1]  = lof_in[1]  & ~(|lof_in[14:2]);

    // One-hot to index: one OR per index bit
    assign lof_index[0] = lof_prio[1]  | lof_prio[3]  | lof_prio[5]  | lof_prio[7]  |
                          lof_prio[9]  | lof_prio[11] | lof_prio[13];
    assign lof_index[1] = lof_prio[2]  | lof_prio[3]  | lof_prio[6]  | lof_prio[7]  |
                          lof_prio[10] | lof_prio[11] | lof_prio[14];
    assign lof_index[2] = lof_prio[4]  | lof_prio[5]  | lof_prio[6]  | lof_prio[7]  |
                          lof_prio[12] | lof_prio[13] | lof_prio[14];
    assign lof_index[3] = lof_prio[8]  | lof_prio[9]  | lof_prio[10] | lof_prio[11] |
                          lof_prio[12] | lof_prio[13] | lof_prio[14];

    // K = that index - 10, so r_s is 8 to 16 and r_s^2 is 64 to 256 and
    // never clamps. K > 0 shifts right and rounds, K < 0 shifts left and clamps
    // to 0x7FFF or 0x8000 (spec: "The leading-one finder", "Clamp").
    function automatic logic [15:0] kshift(input logic signed [15:0] v,
                                          input logic signed [4:0]  k);
        logic signed [31:0] w;
        begin
            if (k > 0) begin
                w = {{16{v[15]}}, v} + (32'sd1 <<< (k - 1));
                w = w >>> k;
            end else if (k < 0) begin
                w = {{16{v[15]}}, v} <<< (-k);
            end else begin
                w = {{16{v[15]}}, v};
            end

            if (w > 32'sd32767)       kshift = 16'h7FFF;
            else if (w < -32'sd32768) kshift = 16'h8000;
            else                      kshift = w[15:0];
        end
    endfunction

    // True magnitude of an edge word, for the triangle's K rule
    function automatic logic [14:0] abs15(input logic [15:0] v);
        logic signed [16:0] w;
        begin
            w = v[15] ? -$signed({v[15], v}) : $signed({1'b0, v});
            if (w > 17'sd32767) abs15 = 15'h7FFF;
            else                abs15 = w[14:0];
        end
    endfunction

    function automatic logic [14:0] max15(input logic [14:0] a, input logic [14:0] b);
        max15 = (a > b) ? a : b;
    endfunction

    // Two's complement with the POS clamp, used for the negated ground divisor
    function automatic logic [15:0] neg16(input logic [15:0] v);
        logic signed [16:0] w;
        begin
            w = -$signed({v[15], v});
            if (w > 17'sd32767) neg16 = 16'h7FFF;
            else                neg16 = w[15:0];
        end
    endfunction

    // Operand sources for the request fields (spec: "Operand select")
    typedef enum logic [4:0] {
        SRC_TC,     // to_centre, then offset (same slots)
        SRC_C,      // centre: BV w2-w4, then the object's w4-w6
        SRC_D,      // ray direction
        SRC_O,      // ray origin
        SRC_ALONG,  // along
        SRC_RS,     // r_s
        SRC_RS2,    // r_s^2
        SRC_OFFSQ,  // |offset_s|^2, kept while the miss compare runs
        SRC_HALF,   // half_s, still at the shifted size
        SRC_T,      // candidate t
        SRC_BESTT,  // best t so far
        SRC_C0156,  // constant 0.0156 (0x0002)
        SRC_PRV,    // the previous macro-op result
        SRC_ZERO,   // constant 0
        SRC_DZ,     // only the z part of the ray direction
        SRC_OZ,     // only the z part of the ray origin
        SRC_RADIUS, // the raw radius of the winner, unshifted
        SRC_WA,     // winner: H, or C when the ray started inside
        SRC_WB,     // winner: C, or H when the ray started inside
        SRC_C225,   // constant 225 (0x7080), the 15-unit triangle gate
        SRC_DET,    // det, then the partial distance in stage 4
        SRC_ATOP,   // alpha_top, then alpha
        SRC_BTOP,   // beta_top, then beta
        SRC_E1,     // edge 1 while det is being built
        SRC_NA,     // normal: u, which is edge 1 for a front side hit
        SRC_NB,     // normal: v, which is edge 2 for a front side hit
        SRC_ONE     // constant 1.0 in DIR, 0x4000, for M_NORM
    } src_t;

    // How a request field goes through the size shifter: untouched, by +K
    // (into a squared compare) or by -K (shifting a result back)
    typedef enum logic [2:0] {
        SH_NONE = 3'd0,
        SH_K    = 3'd1,
        SH_NK   = 3'd2,
        SH_PRE  = 3'd3,  // the resize pre-shift before M_NORM, which also
                         // turns a POS arrow into a DIR arrow
        SH_BK   = 3'd4   // the winner's K, for re-reading its edges
    } shift_t;


    // FSM States
    // Disable for the debug build
    //typedef enum logic [1:0] {
    //    S_IDLE       = 2'd0,
    //    S_RTU_LOAD   = 2'd1,
    //    S_PROCESS_BV = 2'd2,
    //    S_CHECKOUT   = 2'd3
    //} state_t;

    //typedef enum logic [1:0] {
    //    S_SRAM_IDLE = 2'd0,
    //    S_SRAM_SEND = 2'd1,
    //    S_SRAM_WAIT = 2'd2,
    //    S_SRAM_NEXT = 2'd3
    //} sram_state_t;

    //typedef enum logic [1:0] {
    //    S_DEC_IDLE = 2'd0,
    //    S_DEC_SEND = 2'd1,
    //    S_DEC_WAIT = 2'd2,
    //    S_DEC_DONE = 2'd3
    //} dec_state_t;
    
    // WiP not implemented
    // p = ray * t
    // outward_normal = (p - bv_origin) / bv_r
    // front_face = (dot(ray_dir, normal) < 0)
    // normal = front_face ? outward_normal : -outward_normal;
    // hit_flip =
    //typedef enum logic [3:0] {
    //    CALC_A            = 4'd0,
    //    CALC_OC           = 4'd1,
    //    CALC_OC_DOT       = 4'd2,
    //    CALC_H            = 4'd3,
    //    CALC_R2           = 4'd4,
    //    CALC_C            = 4'd5,
    //    CALC_AC           = 4'd6,
    //    CALC_H2           = 4'd7,
    //    CALC_DISCRIMINANT = 4'd8,
    //    CALC_HIT          = 4'd9,
    //    CALC_SQRTD        = 4'd10,
    //    CALC_NUMERATOR    = 4'd11,
    //    CALC_T            = 4'd12
    // WiP for hit_flip

    //} calc_stage_t;

    //state_t state_q, state_d;
    //sram_state_t sram_state_q, sram_state_d;
    //dec_state_t dec_state_q, dec_state_d;
    //calc_stage_t calc_stage_q;

    // Next-State Combinational Logic
    // Main State Machine
    always_comb begin
        state_d = state_q;
        case (state_q)
            S_IDLE: begin
                // Boot system after start signal
                if (start) state_d = S_RTU_LOAD;
            end
            S_RTU_LOAD: begin
                // A scene with no BVs still needs the ground test, so there is
                // no short cut to CHECKOUT here
                state_d = S_PROCESS_BV;
            end
            S_PROCESS_BV: begin
                // Report once the BV walk, the ground test and the winner
                // steps are all finished
                if (bv_phase == PH_CHECK) state_d = S_CHECKOUT;
            end
            S_CHECKOUT: begin
                // Return to IDLE state after reporting (done is pulsed for one
                // cycle by the sequential block)
                state_d = S_IDLE;
            end

            default: state_d = S_IDLE;
        endcase
    end

    // SRAM State Machine
    always_comb begin
        sram_state_d = sram_state_q;
        case (sram_state_q)
            S_SRAM_IDLE: begin
                // Load 1st Address and send only if bv_count is valid
                if (sram_start) sram_state_d = S_SRAM_SEND;
            end
            S_SRAM_SEND: begin
                // Move to WAIT state after setting sram_req
                sram_state_d = S_SRAM_WAIT;
            end
            S_SRAM_WAIT: begin
                // Capture the word; sram_req is combinational, so the next word
                // is requested in this cycle and a word costs 2 cycles
                if (sram_rvalid) begin
                    if (sram_w_index == sram_w_last) sram_state_d = S_SRAM_NEXT;
                end
                
                // Scrapped Version
                // Move to next word after latch and hold until all calculation to move to next SRAM BV object (i increment)
                // Radius: w0 -> w1 condition: Latched and Decoder available
                //if (!bv_r_ready)
                //    if (sram_latch && dec_state_q == S_DEC_IDLE) sram_state_d = S_SRAM_NEXT;
                // Origin: w1 -> w2 condition: Latched and Decoder available (Noted: Removed wait for bv_r2 latching as the calculation sequence optimized to local register reduction)
                //else if (calc_stage_q == CALC_OC)
                    // w2 -> w4 condition: Latched 
                //    if (sram_latch && dec_state_q == S_DEC_IDLE) sram_state_d = S_SRAM_NEXT; // Removed (&& bv_r_ready &&) as the calculation sequence optimized to local register reduction
                    // Move to next SRAM BV object (i increment) condition: after all calculation
                //    else if (bv_origin_ready)
                //        if (dec_state_q == S_DEC_DONE) sram_state_d = S_SRAM_NEXT;

            end
            S_SRAM_NEXT: begin
                // Finished this SRAM burst
                sram_state_d = S_SRAM_IDLE;
            end

            default: sram_state_d = S_SRAM_IDLE;
        endcase
    end
    
    // Decoder State Machine
    always_comb begin
        dec_state_d = dec_state_q;

        case (dec_state_q)
            S_DEC_IDLE: begin
            
                // Move to SEND state when operand of corresponding steps ready for req_sel construction and Decoder available
                if (calc_active) begin
                    // A Decode that is ready takes the macro-op in this cycle
                    if (macro_reqready) dec_state_d = S_DEC_WAIT;
                    else           dec_state_d = S_DEC_SEND;
                end
            end
            S_DEC_SEND: begin
                // Move to WAIT state for holding req_sel and processing latched response after setting macro_reqvalid
                if (macro_reqready) dec_state_d = S_DEC_WAIT;
            end
            S_DEC_WAIT: begin
                // Response queue: latched response
                if (macro_rvalid) begin
                    // Last step of this BV
                    if (calc_stage_q == CALC_REACH || calc_stage_q == SP_BEST) dec_state_d = S_DEC_DONE;
                    // Iterate next Decoder request
                    else dec_state_d = S_DEC_IDLE;
                end
            end
            S_DEC_DONE: begin
                // Reset after resetting calc_stage_q
                dec_state_d = S_DEC_IDLE;
            end

            default: dec_state_d = S_DEC_IDLE;
        endcase
    end

    // Next step. The BV walk is straight through; the three compares leave it
    // early. The sphere walk adds the half chord and two t gates.
    always_comb begin
        calc_stage_d = calc_stage_q;
        case (calc_stage_q)
            CALC_R2:     calc_stage_d = CALC_TC;
            CALC_TC:     calc_stage_d = CALC_ALONG;
            CALC_ALONG:  calc_stage_d = CALC_BEHIND;
            // Rec 1: ask about the centre first, and then only one square is
            // ever needed. Behind: only a start inside can still reach, so look
            // at that. Ahead: the closest-approach check covers both cases.
            CALC_BEHIND: calc_stage_d = CALC_M;        // overridden when behind
            CALC_TCSQ:   calc_stage_d = CALC_INSIDE;
            CALC_INSIDE: calc_stage_d = CALC_DONE;
            CALC_M:      calc_stage_d = CALC_OFF;
            CALC_OFF:    calc_stage_d = CALC_OFFSQ;
            CALC_OFFSQ:  calc_stage_d = CALC_REACH;
            CALC_REACH:  calc_stage_d = CALC_DONE;
            SP_R2:       calc_stage_d = SP_TC;
            SP_TC:       calc_stage_d = SP_ALONG;
            SP_ALONG:    calc_stage_d = SP_M;
            SP_M:        calc_stage_d = SP_OFF;
            SP_OFF:      calc_stage_d = SP_OFFSQ;
            SP_OFFSQ:    calc_stage_d = SP_MISS;
            SP_MISS:     calc_stage_d = SP_HALF2;      // overridden on a miss
            SP_HALF2:    calc_stage_d = SP_SQRT;
            SP_SQRT:     calc_stage_d = SP_T;
            SP_T:        calc_stage_d = SP_TGATE;
            SP_TGATE:    calc_stage_d = SP_T2;         // overridden when it passes
            SP_T2:       calc_stage_d = SP_TGATE2;
            SP_TGATE2:   calc_stage_d = SP_BEST;       // overridden when it fails
            SP_BEST:     calc_stage_d = CALC_DONE;
            GR_UP:       calc_stage_d = GR_T;          // overridden when the ray points up
            GR_T:        calc_stage_d = CALC_DONE;
            H1:          calc_stage_d = H2;
            H2:          calc_stage_d = CALC_DONE;
            S2:          calc_stage_d = CALC_DONE;
            S4:          calc_stage_d = CALC_DONE;
            TRI_TC:      calc_stage_d = TRI_ALONG;
            TRI_ALONG:   calc_stage_d = TRI_M;
            TRI_M:       calc_stage_d = TRI_SLID;
            TRI_SLID:    calc_stage_d = TRI_SLIDSQ;
            TRI_SLIDSQ:  calc_stage_d = TRI_FAR;
            TRI_FAR:     calc_stage_d = TRI_P;          // overridden by the 225 gate
            TRI_P:       calc_stage_d = TRI_DET;
            TRI_DET:     calc_stage_d = TRI_ATOP;
            TRI_ATOP:    calc_stage_d = TRI_BACK;
            TRI_BACK:    calc_stage_d = TRI_NEGD;       // the front side skips the negates
            TRI_NEGD:    calc_stage_d = TRI_NEGA;
            TRI_NEGA:    calc_stage_d = TRI_DETP;
            TRI_DETP:    calc_stage_d = TRI_ATOPN;
            TRI_ATOPN:   calc_stage_d = TRI_DETLO;
            TRI_DETLO:   calc_stage_d = CALC_DONE;      // the phase block fetches edge 1
            TRI_Q:       calc_stage_d = TRI_BETA;
            TRI_BETA:    calc_stage_d = TRI_NEGB;       // the front side skips the negate
            TRI_NEGB:    calc_stage_d = TRI_BETAN;
            TRI_BETAN:   calc_stage_d = TRI_SUM;
            TRI_SUM:     calc_stage_d = TRI_SUMD;
            TRI_SUMD:    calc_stage_d = TRI_ALPHA;      // stage 3 passed: on to the distance
            TRI_ALPHA:   calc_stage_d = TRI_BETAD;
            TRI_BETAD:   calc_stage_d = CALC_DONE;      // the phase block fetches edge 1
            TRI_E1D:     calc_stage_d = TRI_A1;
            TRI_A1:      calc_stage_d = TRI_SUM1;
            TRI_SUM1:    calc_stage_d = CALC_DONE;      // the phase block fetches edge 2
            TRI_E2D:     calc_stage_d = TRI_B2;
            TRI_B2:      calc_stage_d = TRI_T;
            TRI_T:       calc_stage_d = TRI_GATE;
            TRI_GATE:    calc_stage_d = TRI_BEST;
            TRI_BEST:    calc_stage_d = CALC_DONE;
            N1_CROSS:    calc_stage_d = N2_NORM;
            N2_NORM:     calc_stage_d = CALC_DONE;
            default:     calc_stage_d = CALC_DONE;
        endcase

        if (step_done) begin
            if (calc_stage_q == CALC_BEHIND && res[0]) calc_stage_d = CALC_TCSQ;
            if (calc_stage_q == SP_MISS    && !res[0]) calc_stage_d = CALC_DONE;
            if (calc_stage_q == SP_TGATE   && res[0])  calc_stage_d = SP_BEST;
            if (calc_stage_q == SP_TGATE2  && !res[0]) calc_stage_d = CALC_DONE;
            if (calc_stage_q == GR_UP      && !res[0]) calc_stage_d = CALC_DONE;
            if (calc_stage_q == TRI_BACK   && !res[0]) calc_stage_d = TRI_DETP;
            if (calc_stage_q == TRI_BETA   && !tri_back)       calc_stage_d = TRI_BETAN;
        end
    end

    // Step table: one row per step (spec 5c for the BV walk, 5d for the sphere
    // walk). Scalar macro-ops only use u.x and v.x, and a row that does not
    // fill the other fields leaves them at the values below.
    always_comb begin
        opcode = M_DOT;
        fmt    = 1'b0;
        src_u  = SRC_TC;
        src_v  = SRC_D;
        sh_u   = SH_NONE;
        sh_v   = SH_NONE;
        neg_u  = 1'b0;
        neg_v  = 1'b0;

        case (calc_stage_q)
            // --- bounding volume test (spec 5c) ---
            // 1. r_s^2 = r_s x r_s
            CALC_R2:     begin opcode = M_MUL;      fmt = 1'b0; src_u = SRC_RS;    src_v = SRC_RS;    end
            // 2. to_centre = C - O
            CALC_TC:     begin opcode = M_VSUB;     fmt = 1'b0; src_u = SRC_C;     src_v = SRC_O;     end
            // 3. along = to_centre . D
            CALC_ALONG:  begin opcode = M_DOT;      fmt = 1'b1; src_u = SRC_TC;    src_v = SRC_D;     end
            // 4. |to_centre_s|^2
            CALC_TCSQ:   begin opcode = M_DOT;      fmt = 1'b0; src_u = SRC_TC;    src_v = SRC_TC;    sh_u = SH_K;  sh_v = SH_K;  end
            // 5. does the ray start inside the BV?
            CALC_INSIDE: begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_PRV;   src_v = SRC_RS2;   end
            // 6. is the centre behind the start?
            CALC_BEHIND: begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_ALONG; src_v = SRC_ZERO;  end
            // 7. along x D
            CALC_M:      begin opcode = M_SCAL_VEC; fmt = 1'b1; src_u = SRC_ALONG; src_v = SRC_D;     end
            // 8. offset = along x D - to_centre
            CALC_OFF:    begin opcode = M_VSUB;     fmt = 1'b0; src_u = SRC_PRV;   src_v = SRC_TC;    end
            // 9. |offset_s|^2
            CALC_OFFSQ:  begin opcode = M_DOT;      fmt = 1'b0; src_u = SRC_TC;    src_v = SRC_TC;    sh_u = SH_K;  sh_v = SH_K;  end
            // 10. is the ray closer to the centre than the radius?
            CALC_REACH:  begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_PRV;   src_v = SRC_RS2;   end

            // --- sphere test (spec 5d) ---
            // 1. r_s^2 = r_s x r_s
            SP_R2:       begin opcode = M_MUL;      fmt = 1'b0; src_u = SRC_RS;    src_v = SRC_RS;    end
            // 2. to_centre = C - O
            SP_TC:       begin opcode = M_VSUB;     fmt = 1'b0; src_u = SRC_C;     src_v = SRC_O;     end
            // 3. along = to_centre . D
            SP_ALONG:    begin opcode = M_DOT;      fmt = 1'b1; src_u = SRC_TC;    src_v = SRC_D;     end
            // 4. along x D
            SP_M:        begin opcode = M_SCAL_VEC; fmt = 1'b1; src_u = SRC_ALONG; src_v = SRC_D;     end
            // 5. offset = along x D - to_centre
            SP_OFF:      begin opcode = M_VSUB;     fmt = 1'b0; src_u = SRC_PRV;   src_v = SRC_TC;    end
            // 6. |offset_s|^2
            SP_OFFSQ:    begin opcode = M_DOT;      fmt = 1'b0; src_u = SRC_TC;    src_v = SRC_TC;    sh_u = SH_K;  sh_v = SH_K;  end
            // 7. does the ray pass outside the sphere?
            SP_MISS:     begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_OFFSQ; src_v = SRC_RS2;   end
            // 8. r_s^2 - |offset_s|^2, the squared half chord
            SP_HALF2:    begin opcode = M_SUB;      fmt = 1'b0; src_u = SRC_RS2;   src_v = SRC_OFFSQ; end
            // 9. half_s = sqrt(that)
            SP_SQRT:     begin opcode = M_SQRT;     fmt = 1'b0; src_u = SRC_PRV;   src_v = SRC_ZERO;  end
            // 10. entry point: t = along - half (half shifted back by K)
            SP_T:        begin opcode = M_SUB;      fmt = 1'b0; src_u = SRC_ALONG; src_v = SRC_HALF;  sh_v = SH_NK; end
            // 11. is the entry point in front of the start?
            SP_TGATE:    begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_C0156; src_v = SRC_T;     end
            // 12. exit point: t = along + half, the ray started inside
            SP_T2:       begin opcode = M_ADD;      fmt = 1'b0; src_u = SRC_ALONG; src_v = SRC_HALF;  sh_v = SH_NK; end
            // 13. is the exit point in front of the start?
            SP_TGATE2:   begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_C0156; src_v = SRC_T;     end
            // 14. is this hit closer than the best one so far?
            SP_BEST:     begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_T;     src_v = SRC_BESTT; end

            // --- ground test (spec 5f) ---
            // 1. does the ray point down?
            GR_UP:       begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_DZ;    src_v = SRC_ZERO;  end
            // 2. t = O_z / -D_z, the negated divisor made on the way in so the
            //    divide sees a positive number as the CORDIC requires
            GR_T:        begin opcode = M_DIV;      fmt = 1'b0; src_u = SRC_OZ;    src_v = SRC_DZ;   neg_v = 1'b1; end

            // --- winner steps (spec 5g) ---
            // 1. best t x D
            H1:          begin opcode = M_SCAL_VEC; fmt = 1'b1; src_u = SRC_BESTT; src_v = SRC_D;     end
            // 2. H = O + (best t x D)
            H2:          begin opcode = M_VADD;     fmt = 1'b0; src_u = SRC_O;     src_v = SRC_PRV;   end
            // 3. H - C, or C - H when the ray started inside, so n faces the ray
            S2:          begin opcode = M_VSUB;     fmt = 1'b0; src_u = SRC_WA;    src_v = SRC_WB;    end
            // 4. n = that / r. Field u.x holds the raw radius, no K shift
            S4:          begin opcode = M_SPHERE_NORM; fmt = 1'b0; src_u = SRC_RADIUS; src_v = SRC_PRV; end

            // --- triangle test (spec 5e) ---
            // stage 1: is this triangle even worth testing?
            TRI_TC:      begin opcode = M_VSUB;     fmt = 1'b0; src_u = SRC_TC;    src_v = SRC_O;     end
            TRI_ALONG:   begin opcode = M_DOT;      fmt = 1'b1; src_u = SRC_TC;    src_v = SRC_D;     end
            TRI_M:       begin opcode = M_SCAL_VEC; fmt = 1'b1; src_u = SRC_ALONG; src_v = SRC_D;     end
            TRI_SLID:    begin opcode = M_VSUB;     fmt = 1'b0; src_u = SRC_PRV;   src_v = SRC_TC;    end
            TRI_SLIDSQ:  begin opcode = M_DOT;      fmt = 1'b0; src_u = SRC_TC;    src_v = SRC_TC;    sh_u = SH_K; sh_v = SH_K; end
            TRI_FAR:     begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_C225;  src_v = SRC_PRV;   end
            // stage 2: P, det and the top of alpha, all from the two edges that
            // are still sitting in registers since the first burst
            TRI_P:       begin opcode = M_CROSS;    fmt = 1'b1; src_u = SRC_D;     src_v = SRC_C;     sh_v = SH_K; end
            TRI_DET:     begin opcode = M_DOT;      fmt = 1'b0; src_u = SRC_E1;    src_v = SRC_C;     sh_u = SH_K; end
            TRI_ATOP:    begin opcode = M_DOT;      fmt = 1'b0; src_u = SRC_TC;    src_v = SRC_C;     sh_u = SH_K; end
            TRI_BACK:    begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_DET;   src_v = SRC_ZERO;  end
            TRI_NEGD:    begin opcode = M_SUB;      fmt = 1'b0; src_u = SRC_ZERO;  src_v = SRC_DET;   end
            TRI_NEGA:    begin opcode = M_SUB;      fmt = 1'b0; src_u = SRC_ZERO;  src_v = SRC_ATOP;  end
            TRI_DETP:    begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_ZERO;  src_v = SRC_DET;   end
            TRI_ATOPN:   begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_ATOP;  src_v = SRC_ZERO;  end
            TRI_DETLO:   begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_DET;   src_v = SRC_ATOP;  end
            // stage 3: the same for beta, with edge 1 fetched again
            TRI_Q:       begin opcode = M_CROSS;    fmt = 1'b0; src_u = SRC_TC;    src_v = SRC_C;     sh_u = SH_K; sh_v = SH_K; end
            TRI_BETA:    begin opcode = M_DOT;      fmt = 1'b1; src_u = SRC_D;     src_v = SRC_PRV;   end
            TRI_NEGB:    begin opcode = M_SUB;      fmt = 1'b0; src_u = SRC_ZERO;  src_v = SRC_BTOP;  end
            TRI_BETAN:   begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_BTOP;  src_v = SRC_ZERO;  end
            TRI_SUM:     begin opcode = M_ADD;      fmt = 1'b0; src_u = SRC_ATOP;  src_v = SRC_BTOP;  end
            TRI_SUMD:    begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_DET;   src_v = SRC_PRV;   end
            // stage 4: the two fractions become a distance
            TRI_ALPHA:   begin opcode = M_DIV;      fmt = 1'b0; src_u = SRC_ATOP;  src_v = SRC_DET;   end
            TRI_BETAD:   begin opcode = M_DIV;      fmt = 1'b0; src_u = SRC_BTOP;  src_v = SRC_DET;   end
            TRI_E1D:     begin opcode = M_DOT;      fmt = 1'b1; src_u = SRC_TC;    src_v = SRC_D;     end
            TRI_A1:      begin opcode = M_MUL;      fmt = 1'b1; src_u = SRC_ATOP;  src_v = SRC_PRV;   end
            TRI_SUM1:    begin opcode = M_ADD;      fmt = 1'b0; src_u = SRC_ALONG; src_v = SRC_PRV;   end
            TRI_E2D:     begin opcode = M_DOT;      fmt = 1'b1; src_u = SRC_C;     src_v = SRC_D;     end
            TRI_B2:      begin opcode = M_MUL;      fmt = 1'b1; src_u = SRC_BTOP;  src_v = SRC_PRV;   end
            TRI_T:       begin opcode = M_ADD;      fmt = 1'b0; src_u = SRC_DET;   src_v = SRC_PRV;   end
            TRI_GATE:    begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_C0156; src_v = SRC_T;     end
            TRI_BEST:    begin opcode = M_LT;       fmt = 1'b0; src_u = SRC_T;     src_v = SRC_BESTT; end

            // --- triangle normal (spec 5g) ---
            N1_CROSS:    begin opcode = M_CROSS;    fmt = 1'b0; src_u = SRC_NA;    src_v = SRC_NB;    sh_u = SH_BK; sh_v = SH_BK; end
            N2_NORM:     begin opcode = M_NORM;     fmt = 1'b1; src_u = SRC_C;     src_v = SRC_ONE;   sh_u = SH_PRE; end
            default:     ;
        endcase
    end

    // One selector shared by both operands
    function automatic logic [47:0] src_sel(input src_t s);
        case (s)
            SRC_TC:    src_sel = {slot_f, slot_g, slot_h};  // to_centre, then offset
            SRC_C:     src_sel = {slot_c, slot_d, slot_e};  // z, y, x
            SRC_D:     src_sel = ray_dir;
            SRC_O:     src_sel = ray_origin;
            SRC_ALONG: src_sel = {16'd0, 16'd0, slot_a};
            SRC_RS:    src_sel = {16'd0, 16'd0, slot_b};
            SRC_RS2:   src_sel = {16'd0, 16'd0, slot_i};
            SRC_OFFSQ: src_sel = {16'd0, 16'd0, slot_j};
            SRC_HALF:  src_sel = {16'd0, 16'd0, slot_j};
            SRC_T:     src_sel = {16'd0, 16'd0, slot_k};
            SRC_BESTT: src_sel = {16'd0, 16'd0, best_t_q};
            SRC_C0156: src_sel = {16'd0, 16'd0, 16'h0002};
            SRC_PRV:   src_sel = result_q;
            SRC_DZ:    src_sel = {16'd0, 16'd0, ray_dir[47:32]};
            SRC_OZ:    src_sel = {16'd0, 16'd0, ray_origin[47:32]};
            SRC_RADIUS:src_sel = {16'd0, 16'd0, slot_j};
            // Winner: with the flip bit the two slide past each other, so one
            // subtract gives H - C outside the surface and C - H inside it
            SRC_WA:    src_sel = best_flip_q ? {slot_c, slot_d, slot_e} : hit_point_q;
            SRC_WB:    src_sel = best_flip_q ? hit_point_q : {slot_c, slot_d, slot_e};
            SRC_C225:  src_sel = {16'd0, 16'd0, 16'h7080};
            SRC_DET:   src_sel = {16'd0, 16'd0, slot_i};
            SRC_ATOP:  src_sel = {16'd0, 16'd0, slot_b};
            SRC_BTOP:  src_sel = {16'd0, 16'd0, slot_j};
            // e1 lives with alpha and beta because it dies the moment det is
            // built, and alpha_top takes its place
            SRC_E1:    src_sel = {slot_b, slot_j, slot_k};
            // The two edges enter the cross product either way round: swapping
            // the operands of a cross product turns the result around, which is
            // exactly what a back side hit needs
            SRC_NA:    src_sel = best_flip_q ? {slot_c, slot_d, slot_e} : {slot_f, slot_g, slot_h};
            SRC_NB:    src_sel = best_flip_q ? {slot_f, slot_g, slot_h} : {slot_c, slot_d, slot_e};
            SRC_ONE:   src_sel = {16'd0, 16'd0, 16'h4000};
            default:   src_sel = 48'd0;
        endcase
    endfunction

    assign u_raw = src_sel(src_u);
    assign v_raw = src_sel(src_v);

    // How far a field shifts: K for a squared compare, -K to undo it, and the
    // resize pre-shift for the triangle normal
    function automatic logic signed [4:0] sh_amt(input shift_t s);
        begin
            case (s)
                SH_K:   sh_amt = k_q;
                SH_NK:  sh_amt = -k_q;
                SH_PRE: sh_amt = pre_k;
                SH_BK:  sh_amt = best_k_q;
                default: sh_amt = 5'sd0;
            endcase
        end
    endfunction

    // The size shifter sits between the scratch registers and the request, so
    // the K shift costs no cycles. SH_NK shifts a result back by -K, which is
    // how half_s becomes a real distance again.
    always_comb begin
        u_vec = u_raw;
        v_vec = v_raw;

        if (sh_u != SH_NONE) begin
            u_vec[47:32] = kshift($signed(u_raw[47:32]), sh_amt(sh_u));
            u_vec[31:16] = kshift($signed(u_raw[31:16]), sh_amt(sh_u));
            u_vec[15:0]  = kshift($signed(u_raw[15:0]),  sh_amt(sh_u));
        end
        if (sh_v != SH_NONE) begin
            v_vec[47:32] = kshift($signed(v_raw[47:32]), sh_amt(sh_v));
            v_vec[31:16] = kshift($signed(v_raw[31:16]), sh_amt(sh_v));
            v_vec[15:0]  = kshift($signed(v_raw[15:0]),  sh_amt(sh_v));
        end

        // Negate on the way in, which is where the ground test makes its
        // divisor positive without spending a macro-op on it
        if (neg_u) begin
            u_vec[47:32] = neg16(u_vec[47:32]);
            u_vec[31:16] = neg16(u_vec[31:16]);
            u_vec[15:0]  = neg16(u_vec[15:0]);
        end
        if (neg_v) begin
            v_vec[47:32] = neg16(v_vec[47:32]);
            v_vec[31:16] = neg16(v_vec[31:16]);
            v_vec[15:0]  = neg16(v_vec[15:0]);
        end
    end

    assign req_field = {fmt, u_vec, v_vec, opcode};

    // Winner outputs: driven straight from their registers so they stay put
    // from done until the next start
    assign hit_point = hit_point_q;
    assign n         = n_q;
    assign checker_bit = hit_ground_q & (hit_point_q[9] ^ hit_point_q[25]);

    // Internal tracking
    // SRAM read progress
    logic [4:0]  bv_index;
    logic [8:0]  bv_base;       // record address: 17 + 5 * i
    logic [2:0]  sram_w_index;  // word number inside the burst
    logic [2:0]  sram_w_last;   // last word number of this burst
    logic        sram_read;     // 1-cycle pulse: burst complete
    logic        sram_start;    // start a burst
    logic [15:0] sram_word_q;   // last burst word, held one cycle for the phase block
    // Decoder status
    logic        calc_active;   // a step sequence may run
    logic        step_done;     // 1-cycle: the current step's result landed
    bv_phase_t   bv_phase;      // which part of the search is running
    // Local register storage for intermediates (144 bit)
    logic [15:0] slot_a; // one-time local register for each ray processes
    logic [15:0] slot_b, slot_c, slot_d, slot_e, slot_f, slot_g, slot_h, slot_i; // local register for intermediate refresh irregularly throughout the local sram bv item cycle
    // Sphere test scratch: half_s (still at the shifted size) and the candidate
    // distance t, which both t gates and the best-hit compare read
    logic [15:0] slot_j, slot_k;
    // Consumed by the step right after they are produced, so they ride in one
    // register instead of a named slot each: |to_centre_s|^2, along x D,
    // |offset_s|^2 and r_s^2 - |offset_s|^2 are never live at the same time
    logic [47:0] result_q;
    logic signed [4:0] k_q;     // K of the object under test
    // Object loop
    logic [8:0]  obj_addr_q;    // running object address
    logic [6:0]  obj_cnt_q;     // objects left in this BV
    logic        obj_tri;       // current object is a triangle (test still WiP)
    // Best hit of this segment
    logic [15:0] best_t_q;
    logic        best_flip_q;
    logic        hit_any_q;
    logic        cand_flip;     // the candidate t came from the exit point
    logic        best_type_q;   // winner: 0 sphere, 1 triangle (triangle test still WiP)
    // Winner outputs, held from done until the next start (decisions 4, 5, 6)
    logic [47:0] hit_point_q;   // H, POS
    logic [47:0] n_q;           // the out-arrow, DIR
    logic        hit_ground_q;  // the winner is the ground
    logic        tri_back;      // the triangle under test is back-facing
    logic        obj_dead;      // Q10: this object has zero size, so skip it
    logic [4:0]  best_k_q;      // the winner's K, to re-read a triangle's edges
    logic [14:0] tri_mag;       // largest edge part seen in this triangle's burst
    // Request construction
    src_t         src_u, src_v;
    shift_t       sh_u, sh_v;
    logic         neg_u, neg_v;
    logic [4:0]   opcode;
    logic         fmt;
    logic [47:0]  u_raw, v_raw, u_vec, v_vec;
    logic [101:0] req_field;
    logic [101:0] req_op_q;

    // Handshakes are combinational, so a partner that is already ready answers
    // in the same cycle and no step pays a bubble
    assign macro_reqvalid  = (dec_state_q == S_DEC_SEND) ||
                        ((dec_state_q == S_DEC_IDLE) && calc_active);
    assign req_sel     = (dec_state_q == S_DEC_SEND) ? req_op_q : req_field;
    assign macro_rready = 1'b1;   // spec 5.5: tied high, the Decode leaves on it
    assign step_done  = cmp_free || ((dec_state_q == S_DEC_WAIT) && macro_rvalid);
    assign calc_active = ((bv_phase == PH_CALC) || (bv_phase == PH_SPHERE) ||
                          (bv_phase == PH_GROUND) || (bv_phase == PH_WIN) ||
                          (bv_phase == PH_TRI)    || (bv_phase == PH_NORM)) &&
                         !cmp_free;   // a free compare asks the Decode for nothing

    // 2 cycles per word: the pulse travels with the capture of the word before
    assign sram_req = (sram_state_q == S_SRAM_SEND) ||
                     ((sram_state_q == S_SRAM_WAIT) && sram_rvalid &&
                      (sram_w_index != sram_w_last));

    // one burst per phase; the phase block decides which record it reads
    assign sram_start = (state_q == S_PROCESS_BV) &&
                        (sram_state_q == S_SRAM_IDLE) &&
                        ((bv_phase == PH_READ)   || (bv_phase == PH_W0) ||
                         (bv_phase == PH_OBJ)    || (bv_phase == PH_HEAD) ||
                         (bv_phase == PH_WIN_C)  || (bv_phase == PH_WIN_R)  ||
                         (bv_phase == PH_TRI_E)  || (bv_phase == PH_TRI_V)   ||
                         (bv_phase == PH_TRI_E1B)|| (bv_phase == PH_TRI_E1C) ||
                         (bv_phase == PH_TRI_E2C) || (bv_phase == PH_NORM_U));

    // K and r_s for the BV under test, taken from the radius word as it lands
    // (spec 5d: K = highest 1 bit of the raw radius - 10, so r_s is 8 to 16)
    logic signed [4:0] k_next;
    logic [15:0]       rs_next;

    assign k_next  = $signed({1'b0, lof_index}) - (tri_edge_rd ? 5'sd9 : 5'sd10);
    assign rs_next = kshift($signed(sram_rdata), k_next);


    // FSM Sequential Iteration
    // Main State Machine
    // WiP
    // PROCESS_BV Handle all of the decision for determining hit and its hittable address, and its shortest t and flipped
    // It should do the reporting at CHECKOUT state after looping all SRAM BV items
    // handshake with SRAM and Decoder module to retrieve the correct hit_addr and hit_t
    // hit_flip, hit_ground should be computed in CHECKOUT state
    // p = ray_origin + ray_dir * hit_t
    // outward_normal = (p - center) / radius
    // front_face = (dot(ray_dir, normal) < 0)
    // normal = front_face ? outward_normal : -outward_normal;
    // hit_flip =
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q    <= S_IDLE;
            done       <= 1'b0;
            hit        <= 1'b0;
            hit_ground <= 1'b0;
            hit_flip   <= 1'b0;
        end else if (start) begin
            // A new segment starts with no hit; the object and ground tests
            // set these, the BV search alone cannot
            state_q    <= state_d;
            done       <= 1'b0;
            hit        <= 1'b0;
            hit_ground <= 1'b0;
            hit_flip   <= 1'b0;
        end else begin
            state_q <= state_d;
            
            case (state_q)
                S_IDLE: begin
                end

                S_RTU_LOAD: begin
                end

                S_PROCESS_BV: begin
                end

                S_CHECKOUT: begin
                    // 1-cycle pulse: the hit outputs are valid. hit_point and n
                    // are already correct and stay put until the next start.
                    done       <= 1'b1;
                    hit        <= hit_any_q;
                    hit_ground <= hit_ground_q;
                    hit_flip   <= best_flip_q;
                end

                default: ;
            endcase
        end
    end

    // SRAM State Machine
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sram_state_q  <= S_SRAM_IDLE;
            sram_addr_q     <= 9'd17; // BV Address = 17 + 5 * i + word
            sram_w_index  <= 3'd0;  // BV word: w0-w4
            sram_w_last   <= 3'd0;  // last word of this burst
            sram_read     <= 1'b0;
            sram_word_q   <= 16'd0;
            k_q           <= 5'sd0;
            slot_b        <= 16'd0;
            slot_c        <= 16'd0;
            slot_d        <= 16'd0;
            slot_e        <= 16'd0;

        end else if (start) begin
            sram_state_q  <= S_SRAM_IDLE;
            sram_addr_q     <= 9'd17; // BV Address = 17 + 5 * i + word
            sram_w_index  <= 3'd0;  // BV word: w0-w4
            sram_w_last   <= 3'd0;
            sram_read     <= 1'b0;
            sram_word_q   <= 16'd0;

        end else begin
            sram_state_q <= sram_state_d;

            // 1-cycle pulse
            sram_read <= 1'b0;

            case (sram_state_q)
                // Start at Address 17
                S_SRAM_IDLE: begin
                    if (sram_start) begin
                        // one burst per phase: BV w1-w4, BV w0, object w0, or the
                        // object's w3-w6 (radius first, then the centre)
                        case (bv_phase)
                            PH_W0: begin
                                sram_addr_q    <= bv_base;
                                sram_w_index <= 3'd0;
                                sram_w_last  <= 3'd0;
                            end
                            PH_OBJ: begin
                                sram_addr_q    <= obj_addr_q;
                                sram_w_index <= 3'd0;
                                sram_w_last  <= 3'd0;
                            end
                            PH_HEAD: begin
                                sram_addr_q    <= obj_addr_q + 9'd3;
                                sram_w_index <= 3'd1;
                                sram_w_last  <= 3'd4;
                            end
                            // winner: the centre of the best sphere, w4-w6
                            PH_WIN_C: begin
                                sram_addr_q    <= hit_addr + 9'd4;
                                sram_w_index <= 3'd2;
                                sram_w_last  <= 3'd4;
                            end
                            // winner: the radius at its true size, w3
                            PH_WIN_R: begin
                                sram_addr_q    <= hit_addr + 9'd3;
                                sram_w_index <= 3'd0;
                                sram_w_last  <= 3'd0;
                            end
                            // triangle: both edges w3-w8. This is the burst that
                            // decides K, so it finishes before anything is shifted
                            PH_TRI_E: begin
                                sram_addr_q    <= obj_addr_q + 9'd3;
                                sram_w_index <= 3'd1;
                                sram_w_last  <= 3'd6;
                                tri_mag      <= 15'd0;
                            end
                            // triangle: the corner w9-w11
                            PH_TRI_V: begin
                                sram_addr_q    <= obj_addr_q + 9'd9;
                                sram_w_index <= 3'd1;
                                sram_w_last  <= 3'd3;
                            end
                            // triangle stages 3 and 4: edge 1, then edge 2,
                            // each fetched at the size that stage needs
                            PH_TRI_E1B: begin
                                sram_addr_q    <= obj_addr_q + 9'd6;
                                sram_w_index <= 3'd1;
                                sram_w_last  <= 3'd3;
                            end
                            PH_TRI_E1C: begin
                                sram_addr_q    <= obj_addr_q + 9'd6;
                                sram_w_index <= 3'd1;
                                sram_w_last  <= 3'd3;
                            end
                            PH_TRI_E2C: begin
                                sram_addr_q    <= obj_addr_q + 9'd3;
                                sram_w_index <= 3'd1;
                                sram_w_last  <= 3'd3;
                            end
                            // triangle normal: both edges of the winner, read
                            // again because the test did not keep them
                            PH_NORM_U: begin
                                sram_addr_q    <= hit_addr + 9'd3;
                                sram_w_index <= 3'd1;
                                sram_w_last  <= 3'd6;
                            end
                            default: begin
                                sram_addr_q    <= bv_base + 9'd1;
                                sram_w_index <= 3'd1;
                                sram_w_last  <= 3'd4;
                            end
                        endcase
                    end
                end

                // Read SRAM: sram_req is high this cycle, so load the next address
                S_SRAM_SEND: begin
                    sram_addr_q <= sram_addr_q + 9'd1;
                end

                // Process SRAM data. sram_req is combinational, so the next word
                // is requested in this same cycle and a word costs 2 cycles.
                S_SRAM_WAIT: begin
                    if (sram_rvalid) begin
                        // held for the phase block, which latches w0 a cycle later
                        sram_word_q <= sram_rdata;

                        // Triangle bursts land by phase: the same words are read
                        // into different registers at different stages, so the
                        // index alone does not say where they go
                        if (bv_phase == PH_TRI_E) begin
                            tri_mag <= tri_mag_next;
                            case (sram_w_index)
                                3'd1: slot_c <= sram_rdata;  // edge 2 z
                                3'd2: slot_d <= sram_rdata;  // edge 2 y
                                3'd3: slot_e <= sram_rdata;  // edge 2 x
                                3'd4: slot_b <= sram_rdata;  // edge 1 z
                                3'd5: slot_j <= sram_rdata;  // edge 1 y
                                3'd6: slot_k <= sram_rdata;  // edge 1 x
                                default: ;
                            endcase
                        end else if (bv_phase == PH_TRI_V) begin
                            case (sram_w_index)
                                3'd1: slot_f <= sram_rdata;  // corner z
                                3'd2: slot_g <= sram_rdata;  // corner y
                                3'd3: slot_h <= sram_rdata;  // corner x
                                default: ;
                            endcase
                        end else if (bv_phase == PH_TRI_E1C) begin
                            case (sram_w_index)
                                3'd1: slot_f <= sram_rdata;  // edge 1 z
                                3'd2: slot_g <= sram_rdata;  // edge 1 y
                                3'd3: slot_h <= sram_rdata;  // edge 1 x
                                default: ;
                            endcase
                        end else if (bv_phase == PH_NORM_U) begin
                            case (sram_w_index)
                                3'd1: slot_c <= sram_rdata;  // edge 2 z
                                3'd2: slot_d <= sram_rdata;  // edge 2 y
                                3'd3: slot_e <= sram_rdata;  // edge 2 x
                                3'd4: slot_f <= sram_rdata;  // edge 1 z
                                3'd5: slot_g <= sram_rdata;  // edge 1 y
                                3'd6: slot_h <= sram_rdata;  // edge 1 x
                                default: ;
                            endcase
                        end else if (bv_phase == PH_TRI_E1B || bv_phase == PH_TRI_E2C) begin
                            case (sram_w_index)
                                3'd1: slot_c <= sram_rdata;  // edge 1, then edge 2: z
                                3'd2: slot_d <= sram_rdata;  // y
                                3'd3: slot_e <= sram_rdata;  // x
                                default: ;
                            endcase
                        end else begin
                        // BV dimensional property for calculation latch on S_DEC_IDLE
                        case (sram_w_index)
                            3'd0: begin
                                // w0: BV object list or object type, see the phase block
                                if (bv_phase == PH_WIN_R) slot_j <= sram_rdata; // raw winner radius
                            end
                            3'd1: begin
                                slot_b     <= rs_next; // radius, already shifted by K
                                k_q        <= k_next;
                                // Q10: a zero radius means no volume, so the test
                                // could never pass and the normal step would divide
                                // by zero. Skip the object at the cheapest point.
                                if (bv_phase == PH_HEAD && sram_rdata == 16'd0)
                                    obj_dead <= 1'b1;
                            end
                            3'd2: begin
                                slot_c     <= sram_rdata; // z
                            end
                            3'd3: begin
                                slot_d     <= sram_rdata; // y
                            end
                            3'd4: begin
                                slot_e     <= sram_rdata; // x
                            end
                            default: ;
                        endcase
                        end

                        if (sram_w_index == sram_w_last) begin
                            sram_read <= 1'b1;
                        end else begin
                            sram_addr_q <= sram_addr_q + 9'd1;
                            sram_w_index <= sram_w_index + 3'd1;
                        end
                    end
                end

                S_SRAM_NEXT: begin
                    // Finished this SRAM burst, back to IDLE
                end

                default: ;
            endcase
        end
    end

    // Decoder State Machine
    // Decoder Math
    // hit == (h*h - a*c !< 0)
    // oc = bv_origin - ray_origin
    // a = dot(ray_dir, ray_dir)
    // b = -2.0 * dot(ray_dir, oc)
    // c = dot(oc, oc) - bv_r * bv_r
    // h = dot(ray_dir, oc)
    // t = (h + sqrt(h*h - a*c) ) / a
    // WiP not implemented
    // p = ray * t
    // outward_normal = (p - bv_origin) / bv_r
    // front_face = (dot(ray_dir, normal) < 0)
    // normal = front_face ? outward_normal : -outward_normal;
    // hit_flip =
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_state_q  <= S_DEC_IDLE;
            bv_index     <= 5'd0;
            bv_base      <= 9'd17;
            req_op_q     <= 102'd0;
            result_q     <= 48'd0;
            slot_a       <= 16'd0;
            slot_f       <= 16'd0;
            slot_g       <= 16'd0;
            slot_h       <= 16'd0;
            slot_i       <= 16'd0;
            slot_j       <= 16'd0;
            slot_k       <= 16'd0;
            obj_addr_q   <= 9'd0;
            obj_cnt_q    <= 7'd0;
            obj_tri      <= 1'b0;
            best_t_q     <= 16'h7FFF;
            best_flip_q  <= 1'b0;
            hit_any_q    <= 1'b0;
            cand_flip    <= 1'b0;
            best_type_q  <= 1'b0;
            hit_point_q  <= 48'd0;
            n_q          <= 48'd0;
            hit_ground_q <= 1'b0;
            hit_addr     <= 9'd0;
            bv_phase     <= PH_READ;
            calc_stage_q <= CALC_R2;
            tri_back     <= 1'b0;
            tri_mag      <= 15'd0;
            best_k_q     <= 5'sd0;
            obj_dead     <= 1'b0;

        end else if (start) begin
            // Reset the BV loop for a new ray
            dec_state_q  <= S_DEC_IDLE;
            bv_index     <= 5'd0;
            bv_base      <= 9'd17;
            result_q     <= 48'd0;
            obj_tri      <= 1'b0;
            best_t_q     <= 16'h7FFF;
            best_flip_q  <= 1'b0;
            hit_any_q    <= 1'b0;
            cand_flip    <= 1'b0;
            best_type_q  <= 1'b0;
            hit_point_q  <= 48'd0;
            n_q          <= 48'd0;
            hit_ground_q <= 1'b0;
            hit_addr     <= 9'd0;
            tri_back     <= 1'b0;
            tri_mag      <= 15'd0;
            best_k_q     <= 5'sd0;
            obj_dead     <= 1'b0;
            // a scene with no BVs goes straight to the ground test
            bv_phase     <= (bv_count == 5'd0) ? PH_GROUND : PH_READ;
            calc_stage_q <= (bv_count == 5'd0) ? GR_UP     : CALC_R2;

        end else begin
            dec_state_q <= dec_state_d;

            // Every BV starts the step sequence again at CALC_R2
            // Every object starts at SP_R2; a step advances only when its
            // macro-op result lands
            if (bv_phase == PH_CALC || bv_phase == PH_SPHERE ||
                bv_phase == PH_GROUND || bv_phase == PH_WIN ||
                bv_phase == PH_TRI    || bv_phase == PH_NORM) begin
                if (step_done) calc_stage_q <= calc_stage_d;
            end else if (bv_phase == PH_HEAD) begin
                calc_stage_q <= SP_R2;
            end else if (bv_phase == PH_READ) begin
                calc_stage_q <= CALC_R2;
            end

            // WiP for hit_flip
            // if (state_q == S_CHECKOUT) begin
            //    calc_stage_q       <= CALC_;
            //end

            case (dec_state_q)
                S_DEC_IDLE: begin
                    // Nothing to latch here: the burst words land in the SRAM
                    // block and the step table reads them the cycle after
                end

                S_DEC_SEND: begin
                    // Hold the macro-op until the Decode Unit takes it
                    req_op_q <= req_field;
                end

                S_DEC_WAIT: begin
                    // Accept Decoder response
                    if (macro_rvalid) begin
                        // Latch res
                        // Note: not sure how to deal with 2 root, in the document at
                        // https://uw-asic.github.io/TinyTracer/encoding/instruction/
                        // it is said that in Functional Units
                        // DIV, SQRT, COS, MAG map to CORDIC. RS1 is the CORDIC operand and RS2 is (see CORDIC)
                        // However, it also noted that in Micro-Op Semantics
                        // U_SQRT	RD <- SQRT(RS1), POS or DIR (FMT); RS2 not used	CORDIC	23
                        // The two-root question does not arise any more: the entry
                        // point is along - half and the exit point along + half, so
                        // a BV test needs no square root and no divide at all.
                        result_q <= res;

                        // local registers held across the BV test
                        // slot_a: along
                        // slot_b: bv_r  (r_s, radius after the K shift)
                        // slot_c: bv_z
                        // slot_d: bv_y
                        // slot_e: bv_x
                        // slot_f: to_centre_z, reused for offset_z
                        // slot_g: to_centre_y, reused for offset_y
                        // slot_h: to_centre_x, reused for offset_x
                        // slot_i: r_s^2
                        case (calc_stage_q)
                            CALC_R2: begin
                                // Latch result (Scalar)
                                slot_i       <= res [15:0];

                                // Internal tracking
                            end

                            CALC_TC: begin
                                // Latch result (Vector 3)
                                {slot_f, slot_g, slot_h} <= res;

                                // Internal tracking
                            end

                            CALC_ALONG: begin
                                // Latch result (Scalar)
                                slot_a       <= res [15:0];

                                // Internal tracking
                            end

                            CALC_TCSQ: begin
                                // Nothing to keep: the next step reads result_q

                                // Internal tracking
                            end

                            CALC_INSIDE: begin
                                // Latch result (Compare)
                                if (res[0]) begin
                                    // The ray starts inside the BV: objects
                                    // inside can still be hit, so reach
                                end else begin
                                end
                            end

                            CALC_BEHIND: begin
                                // Latch result (Compare)
                                if (res[0]) begin
                                    // Centre behind the start: moving along the
                                    // ray only takes it farther away
                                end else begin
                                end
                            end

                            CALC_M: begin
                                // Nothing to keep: CALC_OFF reads result_q

                                // Internal tracking
                            end

                            CALC_OFF: begin
                                // Latch result (Vector 3)
                                {slot_f, slot_g, slot_h} <= res;

                                // Internal tracking
                            end

                            CALC_OFFSQ: begin
                                // Nothing to keep: CALC_REACH reads result_q

                                // Internal tracking
                            end

                            CALC_REACH: begin
                                // Latch result (Compare): reach reads w0, skip
                                // moves straight to the next BV
                                bv_phase     <= res[0] ? PH_W0 : PH_NEXT;
                            end

                            // sphere test (spec 5d)
                            SP_R2: begin
                                // Latch result (Scalar)
                                slot_i       <= res [15:0];
                            end

                            SP_TC: begin
                                // Latch result (Vector 3)
                                {slot_f, slot_g, slot_h} <= res;
                            end

                            SP_ALONG: begin
                                // Latch result (Scalar)
                                slot_a       <= res [15:0];
                            end

                            SP_M: begin
                                // Nothing to keep: SP_OFF reads result_q
                            end

                            SP_OFF: begin
                                // Latch result (Vector 3): offset replaces to_centre
                                {slot_f, slot_g, slot_h} <= res;
                            end

                            SP_OFFSQ: begin
                                // Latch result (Scalar): the miss compare and the
                                // half chord both read it, so it cannot ride in
                                // result_q across the compare
                                slot_j       <= res [15:0];
                            end

                            SP_MISS: begin
                                // Latch result (Compare): a miss ends this object
                            end

                            SP_HALF2: begin
                                // Nothing to keep: SP_SQRT reads result_q
                            end

                            SP_SQRT: begin
                                // Latch result (Scalar): half_s, still at the shifted size
                                slot_j       <= res [15:0];
                            end

                            SP_T: begin
                                // Latch result (Scalar): entry point
                                slot_k    <= res [15:0];
                                cand_flip <= 1'b0;
                            end

                            SP_T2: begin
                                // Latch result (Scalar): exit point, ray started inside
                                slot_k    <= res [15:0];
                                cand_flip <= 1'b1;
                            end

                            SP_BEST: begin
                                // Latch result (Compare): closer than the best so far
                                if (res[0]) begin
                                    best_t_q    <= slot_k;
                                    hit_addr    <= obj_addr_q;   // the port holds it from here
                                    best_flip_q <= cand_flip;
                                    best_type_q <= obj_tri;
                                    hit_any_q   <= 1'b1;
                                end
                            end

                            // ground test (spec 5f)
                            GR_UP: begin
                                // Latch result (Compare): the phase block reads it
                            end

                            GR_T: begin
                                // The phase block stores it as best t; a clamp of
                                // 0x7FFF tells it the floor is too far away
                            end

                            // winner steps (spec 5g)
                            H1: begin
                                // Nothing to keep: H2 reads result_q
                            end

                            H2: begin
                                // Latch result (Vector 3): the hit point, held
                                // until the next start
                                hit_point_q  <= res;
                            end

                            S2: begin
                                // Nothing to keep: S4 reads result_q
                            end

                            S4: begin
                                // Latch result (Vector 3): the out-arrow, held
                                // until the next start
                                n_q          <= res;
                            end

                            // triangle test (spec 5e). Edge 1 shares its three
                            // registers with alpha and beta, because it dies the
                            // moment det is built and they take its place.
                            TRI_TC: begin
                                // Latch result (Vector 3): the corner arrow
                                {slot_f, slot_g, slot_h} <= res;
                            end

                            TRI_ALONG: begin
                                // Latch result (Scalar)
                                slot_a       <= res [15:0];
                            end

                            TRI_M: begin
                                // Nothing to keep: TRI_SLID reads result_q
                            end

                            TRI_SLID: begin
                                // Latch result (Vector 3): slid replaces to_corner
                                {slot_f, slot_g, slot_h} <= res;
                            end

                            TRI_SLIDSQ: begin
                                // Nothing to keep: TRI_FAR reads result_q
                            end

                            TRI_FAR: begin
                                // Latch result (Compare): the phase block reads it
                            end

                            TRI_P: begin
                                // Latch result (Vector 3): P replaces edge 2
                                {slot_c, slot_d, slot_e} <= res;
                            end

                            TRI_DET: begin
                                // Latch result (Scalar): the bottom of both fractions
                                slot_i       <= res [15:0];
                            end

                            TRI_ATOP: begin
                                // Latch result (Scalar): edge 1 is dead here
                                slot_b       <= res [15:0];
                            end

                            TRI_BACK: begin
                                // Latch result (Compare): a negative det is a back side hit
                                if (res[0]) begin
                                    tri_back  <= 1'b1;
                                    cand_flip <= 1'b1;
                                end
                            end

                            TRI_NEGD: begin
                                // Latch result (Scalar): det made positive
                                slot_i       <= res [15:0];
                            end

                            TRI_NEGA: begin
                                // Latch result (Scalar): alpha_top made positive
                                slot_b       <= res [15:0];
                            end

                            TRI_DETP: begin
                                // Latch result (Compare): a zero det means parallel
                            end

                            TRI_ATOPN: begin
                                // Latch result (Compare)
                            end

                            TRI_DETLO: begin
                                // Latch result (Compare)
                            end

                            TRI_Q: begin
                                // Nothing to keep: TRI_BETA reads result_q
                            end

                            TRI_BETA: begin
                                // Latch result (Scalar)
                                slot_j       <= res [15:0];
                            end

                            TRI_NEGB: begin
                                // Latch result (Scalar): beta_top made positive
                                slot_j       <= res [15:0];
                            end

                            TRI_BETAN: begin
                                // Latch result (Compare)
                            end

                            TRI_SUM: begin
                                // Nothing to keep: TRI_SUMD reads result_q
                            end

                            TRI_SUMD: begin
                                // Latch result (Compare)
                            end

                            TRI_ALPHA: begin
                                // Latch result (Direct): alpha, 0 to 1
                                slot_b       <= res [15:0];
                            end

                            TRI_BETAD: begin
                                // Latch result (Direct): beta, 0 to 1
                                slot_j       <= res [15:0];
                            end

                            TRI_E1D: begin
                                // Nothing to keep: TRI_A1 reads result_q
                            end

                            TRI_A1: begin
                                // Nothing to keep: TRI_SUM1 reads result_q
                            end

                            TRI_SUM1: begin
                                // Latch result (Scalar): det is dead, the partial sum takes it
                                slot_i       <= res [15:0];
                            end

                            TRI_E2D: begin
                                // Nothing to keep: TRI_B2 reads result_q
                            end

                            TRI_B2: begin
                                // Nothing to keep: TRI_T reads result_q
                            end

                            TRI_T: begin
                                // Latch result (Scalar): the candidate distance
                                slot_k       <= res [15:0];
                            end

                            TRI_GATE: begin
                                // Latch result (Compare)
                            end

                            TRI_BEST: begin
                                // Latch result (Compare): closer than the best so far
                                if (res[0]) begin
                                    best_t_q    <= slot_k;
                                    hit_addr    <= obj_addr_q;
                                    best_flip_q <= cand_flip;
                                    best_type_q <= 1'b1;
                                    best_k_q    <= k_q;
                                    hit_any_q   <= 1'b1;
                                end
                            end

                            // triangle normal (spec 5g)
                            N1_CROSS: begin
                                // Latch result (Vector 3): the arrow out of the face
                                {slot_c, slot_d, slot_e} <= res;
                            end

                            N2_NORM: begin
                                // Latch result (Vector 3): length 1, held until
                                // the next start
                                n_q          <= res;
                            end

                            // WiP for hit_flip

                            default: ;
                        endcase
                    end
                end

                S_DEC_DONE: begin
                    // Reset for next BV object
                end

                default: ;
            endcase

            // Per-BV phase: read the record, walk the steps, read w0, then one
            // object at a time, then advance
            case (bv_phase)
                PH_READ: if (sram_read) bv_phase <= PH_CALC;
                // the three compares end the BV: inside -> reach, behind ->
                // skip, and the last one decides reach or skip
                PH_CALC: if (step_done) begin
                             // behind: inside decides. ahead: closest approach decides
                             if (calc_stage_q == CALC_INSIDE)     bv_phase <= res[0] ? PH_W0 : PH_NEXT;
                             else if (calc_stage_q == CALC_REACH) bv_phase <= res[0] ? PH_W0 : PH_NEXT;
                         end
                // w0 of the BV: where its objects start and how many there are
                PH_W0:   if (sram_read) begin
                             obj_addr_q <= sram_word_q[15:7];
                             obj_cnt_q  <= sram_word_q[6:0];
                             bv_phase   <= (sram_word_q[6:0] != 7'd0) ? PH_OBJ : PH_NEXT;
                         end
                // w0 of one object: bit 0 picks sphere or triangle
                PH_OBJ:  if (sram_read) begin
                             obj_tri  <= ~sram_word_q[0];
                             tri_back <= 1'b0;
                             obj_dead <= 1'b0;
                             bv_phase <= sram_word_q[0] ? PH_HEAD : PH_TRI_E;
                         end
                // w3-w6 of the object: radius first, then the centre. A sphere of
                // zero radius is skipped rather than tested.
                PH_HEAD: if (sram_read) bv_phase <= obj_dead ? PH_OBJ_NEXT : PH_SPHERE;
                // the sphere sequence ends on a miss, on a failed exit gate, or
                // after the best-hit compare
                PH_SPHERE: if (step_done) begin
                             if (calc_stage_q == SP_MISS && !res[0])        bv_phase <= PH_OBJ_NEXT;
                             else if (calc_stage_q == SP_TGATE2 && !res[0]) bv_phase <= PH_OBJ_NEXT;
                             else if (calc_stage_q == SP_BEST)                      bv_phase <= PH_OBJ_NEXT;
                         end
                // +7 words for a sphere, +12 for a triangle, one object less
                PH_OBJ_NEXT: begin
                    bv_phase   <= (obj_cnt_q > 7'd1) ? PH_OBJ : PH_NEXT;
                    obj_cnt_q  <= obj_cnt_q - 7'd1;
                    obj_addr_q <= obj_addr_q + (obj_tri ? 9'd12 : 9'd7);
                end
                PH_NEXT: begin
                    if (bv_index + 5'd1 < bv_count) begin
                        bv_phase <= PH_READ;
                        bv_index <= bv_index + 5'd1;
                        bv_base  <= bv_base + 9'd5;
                    end else if (hit_any_q) begin
                        // an object was hit: build H and n for the winner
                        bv_phase     <= PH_WIN;
                        calc_stage_q <= H1;
                    end else begin
                        // nothing was hit, so the floor gets its turn
                        bv_phase     <= PH_GROUND;
                        calc_stage_q <= GR_UP;
                    end
                end
                // the ground test (spec 5f): only a downward ray can reach it
                PH_GROUND: if (step_done) begin
                               if (calc_stage_q == GR_UP && !res[0]) begin
                                   bv_phase <= PH_CHECK;   // the ray points up: sky
                               end else if (calc_stage_q == GR_T) begin
                                   // the clamp means too far, and a negative
                                   // quotient means the floor is behind the beam
                                   if (res[15:0] != 16'h7FFF && !res[15]) begin
                                       // floor at this distance, and it wins because
                                       // no object was found
                                       best_t_q     <= res[15:0];
                                       hit_ground_q <= 1'b1;
                                       hit_any_q    <= 1'b1;
                                       n_q          <= {16'h4000, 16'd0, 16'd0};
                                       bv_phase     <= PH_WIN;
                                       calc_stage_q <= H1;
                                   end else begin
                                       bv_phase <= PH_CHECK;   // clamped: too far, sky
                                   end
                               end
                           end
                // winner steps (spec 5g): the hit point first, then n
                PH_WIN: if (step_done) begin
                            if (calc_stage_q == H2) begin
                                // the ground n is a constant; a sphere rebuilds
                                // from its centre, a triangle from its edges
                                if (hit_ground_q)     bv_phase <= PH_CHECK;
                                else if (best_type_q) bv_phase <= PH_NORM_U;
                                else                  bv_phase <= PH_WIN_C;
                            end else if (calc_stage_q == S2) begin
                                bv_phase <= PH_WIN_R;
                            end else if (calc_stage_q == S4) begin
                                bv_phase <= PH_CHECK;
                            end
                        end
                PH_WIN_C: if (sram_read) begin
                              bv_phase     <= PH_WIN;
                              calc_stage_q <= S2;
                          end
                PH_WIN_R: if (sram_read) begin
                              bv_phase     <= PH_WIN;
                              calc_stage_q <= S4;
                          end
                // triangle: both edges first, because K comes from them and
                // nothing may be shifted before it is known
                // all six edge words zero means no area, so nothing to test; a
                // triangle with parallel edges still falls out at the det check
                PH_TRI_E:   if (sram_read) bv_phase <= (tri_mag_next == 15'd0) ? PH_OBJ_NEXT
                                                                               : PH_TRI_V;
                PH_TRI_V:   if (sram_read) begin
                                bv_phase     <= PH_TRI;
                                calc_stage_q <= TRI_TC;
                            end
                PH_TRI_E1B: if (sram_read) begin
                                bv_phase     <= PH_TRI;
                                calc_stage_q <= TRI_Q;
                            end
                PH_TRI_E1C: if (sram_read) begin
                                bv_phase     <= PH_TRI;
                                calc_stage_q <= TRI_E1D;
                            end
                PH_TRI_E2C: if (sram_read) begin
                                bv_phase     <= PH_TRI;
                                calc_stage_q <= TRI_E2D;
                            end
                PH_NORM_U: if (sram_read) begin
                               bv_phase     <= PH_NORM;
                               calc_stage_q <= N1_CROSS;
                           end
                PH_NORM: if (step_done && calc_stage_q == N2_NORM) bv_phase <= PH_CHECK;
                // the triangle chain: every failed check drops to the next object
                PH_TRI: if (step_done) begin
                            case (calc_stage_q)
                                TRI_FAR:   if (res[0])  bv_phase <= PH_OBJ_NEXT; // over 15 from the corner
                                TRI_DETP:  if (!res[0]) bv_phase <= PH_OBJ_NEXT; // parallel to the plane
                                TRI_ATOPN: if (res[0])  bv_phase <= PH_OBJ_NEXT;
                                TRI_DETLO: if (res[0])  bv_phase <= PH_OBJ_NEXT;
                                           else                bv_phase <= PH_TRI_E1B;
                                TRI_BETAN: if (res[0])  bv_phase <= PH_OBJ_NEXT;
                                TRI_SUMD:  if (res[0])  bv_phase <= PH_OBJ_NEXT;
                                TRI_BETAD: bv_phase <= PH_TRI_E1C;
                                TRI_SUM1:  bv_phase <= PH_TRI_E2C;
                                TRI_GATE:  if (!res[0]) bv_phase <= PH_OBJ_NEXT; // behind the start
                                TRI_BEST:  bv_phase <= PH_OBJ_NEXT;
                                default: ;
                            endcase
                        end
                default: ;
            endcase
        end
    end

    // Debug bundle: the first object address and count of the last reached BV
    assign dbg_obj_addr = obj_addr_q;
    assign dbg_obj_cnt  = obj_cnt_q;

endmodule
