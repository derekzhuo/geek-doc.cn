// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_naive.h for the primary calling header

#include "Vtb_naive__pch.h"
#include "Vtb_naive___024root.h"

VL_ATTR_COLD void Vtb_naive___024root___eval_static__TOP(Vtb_naive___024root* vlSelf);

VL_ATTR_COLD void Vtb_naive___024root___eval_static(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___eval_static\n"); );
    // Body
    Vtb_naive___024root___eval_static__TOP(vlSelf);
}

VL_ATTR_COLD void Vtb_naive___024root___eval_final(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___eval_final\n"); );
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_naive___024root___dump_triggers__stl(Vtb_naive___024root* vlSelf);
#endif  // VL_DEBUG
VL_ATTR_COLD bool Vtb_naive___024root___eval_phase__stl(Vtb_naive___024root* vlSelf);

VL_ATTR_COLD void Vtb_naive___024root___eval_settle(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___eval_settle\n"); );
    // Init
    IData/*31:0*/ __VstlIterCount;
    CData/*0:0*/ __VstlContinue;
    // Body
    __VstlIterCount = 0U;
    vlSelf->__VstlFirstIteration = 1U;
    __VstlContinue = 1U;
    while (__VstlContinue) {
        if (VL_UNLIKELY((0x64U < __VstlIterCount))) {
#ifdef VL_DEBUG
            Vtb_naive___024root___dump_triggers__stl(vlSelf);
#endif
            VL_FATAL_MT("tb_naive.v", 3, "", "Settle region did not converge.");
        }
        __VstlIterCount = ((IData)(1U) + __VstlIterCount);
        __VstlContinue = 0U;
        if (Vtb_naive___024root___eval_phase__stl(vlSelf)) {
            __VstlContinue = 1U;
        }
        vlSelf->__VstlFirstIteration = 0U;
    }
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_naive___024root___dump_triggers__stl(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___dump_triggers__stl\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VstlTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        VL_DBG_MSGF("         'stl' region trigger index 0 is active: Internal 'stl' trigger - first iteration\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_naive___024root___stl_sequent__TOP__0(Vtb_naive___024root* vlSelf);

VL_ATTR_COLD void Vtb_naive___024root___eval_stl(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___eval_stl\n"); );
    // Body
    if ((1ULL & vlSelf->__VstlTriggered.word(0U))) {
        Vtb_naive___024root___stl_sequent__TOP__0(vlSelf);
    }
}

VL_ATTR_COLD void Vtb_naive___024root___eval_triggers__stl(Vtb_naive___024root* vlSelf);

VL_ATTR_COLD bool Vtb_naive___024root___eval_phase__stl(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___eval_phase__stl\n"); );
    // Init
    CData/*0:0*/ __VstlExecute;
    // Body
    Vtb_naive___024root___eval_triggers__stl(vlSelf);
    __VstlExecute = vlSelf->__VstlTriggered.any();
    if (__VstlExecute) {
        Vtb_naive___024root___eval_stl(vlSelf);
    }
    return (__VstlExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_naive___024root___dump_triggers__act(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___dump_triggers__act\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VactTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 0 is active: @(posedge tb_naive.clk or negedge tb_naive.rst_n)\n");
    }
    if ((2ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 1 is active: @(posedge tb_naive.clk)\n");
    }
    if ((4ULL & vlSelf->__VactTriggered.word(0U))) {
        VL_DBG_MSGF("         'act' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_naive___024root___dump_triggers__nba(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___dump_triggers__nba\n"); );
    // Body
    if ((1U & (~ (IData)(vlSelf->__VnbaTriggered.any())))) {
        VL_DBG_MSGF("         No triggers active\n");
    }
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 0 is active: @(posedge tb_naive.clk or negedge tb_naive.rst_n)\n");
    }
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 1 is active: @(posedge tb_naive.clk)\n");
    }
    if ((4ULL & vlSelf->__VnbaTriggered.word(0U))) {
        VL_DBG_MSGF("         'nba' region trigger index 2 is active: @([true] __VdlySched.awaitingCurrentTime())\n");
    }
}
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_naive___024root___ctor_var_reset(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___ctor_var_reset\n"); );
    // Body
    vlSelf->tb_naive__DOT__clk = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT__rst_n = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT__en = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT__clr = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT__count = VL_RAND_RESET_I(8);
    vlSelf->tb_naive__DOT__ovf = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT____Vtogcov__clk = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT____Vtogcov__rst_n = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT____Vtogcov__en = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT____Vtogcov__clr = VL_RAND_RESET_I(1);
    vlSelf->tb_naive__DOT____Vtogcov__count = VL_RAND_RESET_I(8);
    vlSelf->tb_naive__DOT____Vtogcov__ovf = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__tb_naive__DOT__clk__0 = VL_RAND_RESET_I(1);
    vlSelf->__Vtrigprevexpr___TOP__tb_naive__DOT__rst_n__0 = VL_RAND_RESET_I(1);
}
