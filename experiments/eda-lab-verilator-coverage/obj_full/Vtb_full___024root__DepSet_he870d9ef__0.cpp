// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_full.h for the primary calling header

#include "Vtb_full__pch.h"
#include "Vtb_full__Syms.h"
#include "Vtb_full___024root.h"

VL_INLINE_OPT VlCoroutine Vtb_full___024root___eval_initial__TOP__Vtiming__0(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_initial__TOP__Vtiming__0\n"); );
    // Init
    IData/*31:0*/ tb_full__DOT____Vrepeat2;
    tb_full__DOT____Vrepeat2 = 0;
    // Body
    vlSelf->tb_full__DOT__rst_n = 0U;
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       21);
    ++(vlSymsp->__Vcoverage[18]);
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       21);
    ++(vlSymsp->__Vcoverage[18]);
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       21);
    ++(vlSymsp->__Vcoverage[18]);
    vlSelf->tb_full__DOT__rst_n = 1U;
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       23);
    ++(vlSymsp->__Vcoverage[19]);
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       23);
    ++(vlSymsp->__Vcoverage[19]);
    vlSelf->tb_full__DOT__en = 1U;
    tb_full__DOT____Vrepeat2 = 0x12cU;
    while (VL_LTS_III(32, 0U, tb_full__DOT____Vrepeat2)) {
        co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                           nullptr, 
                                                           "@(posedge tb_full.clk)", 
                                                           "tb_full.v", 
                                                           27);
        ++(vlSymsp->__Vcoverage[20]);
        tb_full__DOT____Vrepeat2 = (tb_full__DOT____Vrepeat2 
                                    - (IData)(1U));
    }
    vlSelf->tb_full__DOT__clr = 1U;
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       31);
    ++(vlSymsp->__Vcoverage[21]);
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       31);
    ++(vlSymsp->__Vcoverage[21]);
    vlSelf->tb_full__DOT__clr = 0U;
    vlSelf->tb_full__DOT__en = 0U;
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       36);
    ++(vlSymsp->__Vcoverage[22]);
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       36);
    ++(vlSymsp->__Vcoverage[22]);
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       36);
    ++(vlSymsp->__Vcoverage[22]);
    co_await vlSelf->__VtrigSched_h1a0094f0__0.trigger(0U, 
                                                       nullptr, 
                                                       "@(posedge tb_full.clk)", 
                                                       "tb_full.v", 
                                                       36);
    ++(vlSymsp->__Vcoverage[22]);
    VL_WRITEF("FULL done, count=%0# ovf=%b\n",8,vlSelf->tb_full__DOT__count,
              1,(IData)(vlSelf->tb_full__DOT__ovf));
    VL_FINISH_MT("tb_full.v", 39, "");
    ++(vlSymsp->__Vcoverage[23]);
}

VL_INLINE_OPT VlCoroutine Vtb_full___024root___eval_initial__TOP__Vtiming__1(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_initial__TOP__Vtiming__1\n"); );
    // Body
    while (1U) {
        co_await vlSelf->__VdlySched.delay(0x1388ULL, 
                                           nullptr, 
                                           "tb_full.v", 
                                           16);
        vlSelf->tb_full__DOT__clk = (1U & (~ (IData)(vlSelf->tb_full__DOT__clk)));
        ++(vlSymsp->__Vcoverage[17]);
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_full___024root___dump_triggers__act(Vtb_full___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_full___024root___eval_triggers__act(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_triggers__act\n"); );
    // Body
    vlSelf->__VactTriggered.set(0U, (((IData)(vlSelf->tb_full__DOT__clk) 
                                      & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__tb_full__DOT__clk__0))) 
                                     | ((~ (IData)(vlSelf->tb_full__DOT__rst_n)) 
                                        & (IData)(vlSelf->__Vtrigprevexpr___TOP__tb_full__DOT__rst_n__0))));
    vlSelf->__VactTriggered.set(1U, ((IData)(vlSelf->tb_full__DOT__clk) 
                                     & (~ (IData)(vlSelf->__Vtrigprevexpr___TOP__tb_full__DOT__clk__0))));
    vlSelf->__VactTriggered.set(2U, vlSelf->__VdlySched.awaitingCurrentTime());
    vlSelf->__Vtrigprevexpr___TOP__tb_full__DOT__clk__0 
        = vlSelf->tb_full__DOT__clk;
    vlSelf->__Vtrigprevexpr___TOP__tb_full__DOT__rst_n__0 
        = vlSelf->tb_full__DOT__rst_n;
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_full___024root___dump_triggers__act(vlSelf);
    }
#endif
}

VL_INLINE_OPT void Vtb_full___024root___act_sequent__TOP__0(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___act_sequent__TOP__0\n"); );
    // Body
    if (((IData)(vlSelf->tb_full__DOT__clk) ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__clk))) {
        ++(vlSymsp->__Vcoverage[0]);
        vlSelf->tb_full__DOT____Vtogcov__clk = vlSelf->tb_full__DOT__clk;
    }
}

VL_INLINE_OPT void Vtb_full___024root___act_sequent__TOP__1(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___act_sequent__TOP__1\n"); );
    // Body
    if (((IData)(vlSelf->tb_full__DOT__rst_n) ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__rst_n))) {
        ++(vlSymsp->__Vcoverage[2]);
        vlSelf->tb_full__DOT____Vtogcov__rst_n = vlSelf->tb_full__DOT__rst_n;
    }
    if (((IData)(vlSelf->tb_full__DOT__en) ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__en))) {
        ++(vlSymsp->__Vcoverage[4]);
        vlSelf->tb_full__DOT____Vtogcov__en = vlSelf->tb_full__DOT__en;
    }
    if (((IData)(vlSelf->tb_full__DOT__clr) ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__clr))) {
        ++(vlSymsp->__Vcoverage[6]);
        vlSelf->tb_full__DOT____Vtogcov__clr = vlSelf->tb_full__DOT__clr;
    }
}

VL_INLINE_OPT void Vtb_full___024root___nba_sequent__TOP__0(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___nba_sequent__TOP__0\n"); );
    // Init
    CData/*7:0*/ __Vdly__tb_full__DOT__count;
    __Vdly__tb_full__DOT__count = 0;
    // Body
    ++(vlSymsp->__Vcoverage[30]);
    if ((1U & (~ (IData)(vlSelf->tb_full__DOT__rst_n)))) {
        ++(vlSymsp->__Vcoverage[29]);
    }
    __Vdly__tb_full__DOT__count = vlSelf->tb_full__DOT__count;
    if (vlSelf->tb_full__DOT__rst_n) {
        if (vlSelf->tb_full__DOT__clr) {
            ++(vlSymsp->__Vcoverage[28]);
            __Vdly__tb_full__DOT__count = 0U;
            vlSelf->tb_full__DOT__ovf = 0U;
        } else if (vlSelf->tb_full__DOT__en) {
            __Vdly__tb_full__DOT__count = (0xffU & 
                                           ((IData)(1U) 
                                            + (IData)(vlSelf->tb_full__DOT__count)));
            if ((0xffU == (IData)(vlSelf->tb_full__DOT__count))) {
                vlSelf->tb_full__DOT__ovf = 1U;
            }
        }
        if ((1U & (~ (IData)(vlSelf->tb_full__DOT__clr)))) {
            if (vlSelf->tb_full__DOT__en) {
                ++(vlSymsp->__Vcoverage[26]);
                if ((0xffU != (IData)(vlSelf->tb_full__DOT__count))) {
                    ++(vlSymsp->__Vcoverage[25]);
                }
                if ((0xffU == (IData)(vlSelf->tb_full__DOT__count))) {
                    ++(vlSymsp->__Vcoverage[24]);
                }
            }
            if ((1U & (~ (IData)(vlSelf->tb_full__DOT__en)))) {
                ++(vlSymsp->__Vcoverage[27]);
            }
        }
    } else {
        __Vdly__tb_full__DOT__count = 0U;
        vlSelf->tb_full__DOT__ovf = 0U;
    }
    vlSelf->tb_full__DOT__count = __Vdly__tb_full__DOT__count;
    if (((IData)(vlSelf->tb_full__DOT__ovf) ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__ovf))) {
        ++(vlSymsp->__Vcoverage[16]);
        vlSelf->tb_full__DOT____Vtogcov__ovf = vlSelf->tb_full__DOT__ovf;
    }
    if ((1U & ((IData)(vlSelf->tb_full__DOT__count) 
               ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[8]);
        vlSelf->tb_full__DOT____Vtogcov__count = ((0xfeU 
                                                   & (IData)(vlSelf->tb_full__DOT____Vtogcov__count)) 
                                                  | (1U 
                                                     & (IData)(vlSelf->tb_full__DOT__count)));
    }
    if ((2U & ((IData)(vlSelf->tb_full__DOT__count) 
               ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[9]);
        vlSelf->tb_full__DOT____Vtogcov__count = ((0xfdU 
                                                   & (IData)(vlSelf->tb_full__DOT____Vtogcov__count)) 
                                                  | (2U 
                                                     & (IData)(vlSelf->tb_full__DOT__count)));
    }
    if ((4U & ((IData)(vlSelf->tb_full__DOT__count) 
               ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[10]);
        vlSelf->tb_full__DOT____Vtogcov__count = ((0xfbU 
                                                   & (IData)(vlSelf->tb_full__DOT____Vtogcov__count)) 
                                                  | (4U 
                                                     & (IData)(vlSelf->tb_full__DOT__count)));
    }
    if ((8U & ((IData)(vlSelf->tb_full__DOT__count) 
               ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[11]);
        vlSelf->tb_full__DOT____Vtogcov__count = ((0xf7U 
                                                   & (IData)(vlSelf->tb_full__DOT____Vtogcov__count)) 
                                                  | (8U 
                                                     & (IData)(vlSelf->tb_full__DOT__count)));
    }
    if ((0x10U & ((IData)(vlSelf->tb_full__DOT__count) 
                  ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[12]);
        vlSelf->tb_full__DOT____Vtogcov__count = ((0xefU 
                                                   & (IData)(vlSelf->tb_full__DOT____Vtogcov__count)) 
                                                  | (0x10U 
                                                     & (IData)(vlSelf->tb_full__DOT__count)));
    }
    if ((0x20U & ((IData)(vlSelf->tb_full__DOT__count) 
                  ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[13]);
        vlSelf->tb_full__DOT____Vtogcov__count = ((0xdfU 
                                                   & (IData)(vlSelf->tb_full__DOT____Vtogcov__count)) 
                                                  | (0x20U 
                                                     & (IData)(vlSelf->tb_full__DOT__count)));
    }
    if ((0x40U & ((IData)(vlSelf->tb_full__DOT__count) 
                  ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[14]);
        vlSelf->tb_full__DOT____Vtogcov__count = ((0xbfU 
                                                   & (IData)(vlSelf->tb_full__DOT____Vtogcov__count)) 
                                                  | (0x40U 
                                                     & (IData)(vlSelf->tb_full__DOT__count)));
    }
    if ((0x80U & ((IData)(vlSelf->tb_full__DOT__count) 
                  ^ (IData)(vlSelf->tb_full__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[15]);
        vlSelf->tb_full__DOT____Vtogcov__count = ((0x7fU 
                                                   & (IData)(vlSelf->tb_full__DOT____Vtogcov__count)) 
                                                  | (0x80U 
                                                     & (IData)(vlSelf->tb_full__DOT__count)));
    }
}
