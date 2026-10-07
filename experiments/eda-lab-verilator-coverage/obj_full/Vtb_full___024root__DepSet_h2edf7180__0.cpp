// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_full.h for the primary calling header

#include "Vtb_full__pch.h"
#include "Vtb_full___024root.h"

VlCoroutine Vtb_full___024root___eval_initial__TOP__Vtiming__0(Vtb_full___024root* vlSelf);
VlCoroutine Vtb_full___024root___eval_initial__TOP__Vtiming__1(Vtb_full___024root* vlSelf);

void Vtb_full___024root___eval_initial(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_initial\n"); );
    // Body
    Vtb_full___024root___eval_initial__TOP__Vtiming__0(vlSelf);
    Vtb_full___024root___eval_initial__TOP__Vtiming__1(vlSelf);
    vlSelf->__Vtrigprevexpr___TOP__tb_full__DOT__clk__0 
        = vlSelf->tb_full__DOT__clk;
    vlSelf->__Vtrigprevexpr___TOP__tb_full__DOT__rst_n__0 
        = vlSelf->tb_full__DOT__rst_n;
}

void Vtb_full___024root___act_sequent__TOP__0(Vtb_full___024root* vlSelf);
void Vtb_full___024root___act_sequent__TOP__1(Vtb_full___024root* vlSelf);

void Vtb_full___024root___eval_act(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_act\n"); );
    // Body
    if ((4ULL & vlSelf->__VactTriggered.word(0U))) {
        Vtb_full___024root___act_sequent__TOP__0(vlSelf);
    }
    if ((2ULL & vlSelf->__VactTriggered.word(0U))) {
        Vtb_full___024root___act_sequent__TOP__1(vlSelf);
    }
}

void Vtb_full___024root___nba_sequent__TOP__0(Vtb_full___024root* vlSelf);

void Vtb_full___024root___eval_nba(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_nba\n"); );
    // Body
    if ((1ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vtb_full___024root___nba_sequent__TOP__0(vlSelf);
    }
    if ((4ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vtb_full___024root___act_sequent__TOP__0(vlSelf);
    }
    if ((2ULL & vlSelf->__VnbaTriggered.word(0U))) {
        Vtb_full___024root___act_sequent__TOP__1(vlSelf);
    }
}

void Vtb_full___024root___timing_resume(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___timing_resume\n"); );
    // Body
    if ((2ULL & vlSelf->__VactTriggered.word(0U))) {
        vlSelf->__VtrigSched_h1a0094f0__0.resume("@(posedge tb_full.clk)");
    }
    if ((4ULL & vlSelf->__VactTriggered.word(0U))) {
        vlSelf->__VdlySched.resume();
    }
}

void Vtb_full___024root___timing_commit(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___timing_commit\n"); );
    // Body
    if ((! (2ULL & vlSelf->__VactTriggered.word(0U)))) {
        vlSelf->__VtrigSched_h1a0094f0__0.commit("@(posedge tb_full.clk)");
    }
}

void Vtb_full___024root___eval_triggers__act(Vtb_full___024root* vlSelf);

bool Vtb_full___024root___eval_phase__act(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_phase__act\n"); );
    // Init
    VlTriggerVec<3> __VpreTriggered;
    CData/*0:0*/ __VactExecute;
    // Body
    Vtb_full___024root___eval_triggers__act(vlSelf);
    Vtb_full___024root___timing_commit(vlSelf);
    __VactExecute = vlSelf->__VactTriggered.any();
    if (__VactExecute) {
        __VpreTriggered.andNot(vlSelf->__VactTriggered, vlSelf->__VnbaTriggered);
        vlSelf->__VnbaTriggered.thisOr(vlSelf->__VactTriggered);
        Vtb_full___024root___timing_resume(vlSelf);
        Vtb_full___024root___eval_act(vlSelf);
    }
    return (__VactExecute);
}

bool Vtb_full___024root___eval_phase__nba(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_phase__nba\n"); );
    // Init
    CData/*0:0*/ __VnbaExecute;
    // Body
    __VnbaExecute = vlSelf->__VnbaTriggered.any();
    if (__VnbaExecute) {
        Vtb_full___024root___eval_nba(vlSelf);
        vlSelf->__VnbaTriggered.clear();
    }
    return (__VnbaExecute);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_full___024root___dump_triggers__nba(Vtb_full___024root* vlSelf);
#endif  // VL_DEBUG
#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_full___024root___dump_triggers__act(Vtb_full___024root* vlSelf);
#endif  // VL_DEBUG

void Vtb_full___024root___eval(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval\n"); );
    // Init
    IData/*31:0*/ __VnbaIterCount;
    CData/*0:0*/ __VnbaContinue;
    // Body
    __VnbaIterCount = 0U;
    __VnbaContinue = 1U;
    while (__VnbaContinue) {
        if (VL_UNLIKELY((0x64U < __VnbaIterCount))) {
#ifdef VL_DEBUG
            Vtb_full___024root___dump_triggers__nba(vlSelf);
#endif
            VL_FATAL_MT("tb_full.v", 3, "", "NBA region did not converge.");
        }
        __VnbaIterCount = ((IData)(1U) + __VnbaIterCount);
        __VnbaContinue = 0U;
        vlSelf->__VactIterCount = 0U;
        vlSelf->__VactContinue = 1U;
        while (vlSelf->__VactContinue) {
            if (VL_UNLIKELY((0x64U < vlSelf->__VactIterCount))) {
#ifdef VL_DEBUG
                Vtb_full___024root___dump_triggers__act(vlSelf);
#endif
                VL_FATAL_MT("tb_full.v", 3, "", "Active region did not converge.");
            }
            vlSelf->__VactIterCount = ((IData)(1U) 
                                       + vlSelf->__VactIterCount);
            vlSelf->__VactContinue = 0U;
            if (Vtb_full___024root___eval_phase__act(vlSelf)) {
                vlSelf->__VactContinue = 1U;
            }
        }
        if (Vtb_full___024root___eval_phase__nba(vlSelf)) {
            __VnbaContinue = 1U;
        }
    }
}

#ifdef VL_DEBUG
void Vtb_full___024root___eval_debug_assertions(Vtb_full___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_full__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_full___024root___eval_debug_assertions\n"); );
}
#endif  // VL_DEBUG
