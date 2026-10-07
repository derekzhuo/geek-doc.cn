// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_naive.h for the primary calling header

#include "Vtb_naive__pch.h"
#include "Vtb_naive__Syms.h"
#include "Vtb_naive___024root.h"

VL_ATTR_COLD void Vtb_naive___024root___eval_static__TOP(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___eval_static__TOP\n"); );
    // Body
    vlSelf->tb_naive__DOT__clk = 0U;
    ++(vlSymsp->__Vcoverage[1]);
    vlSelf->tb_naive__DOT__rst_n = 1U;
    ++(vlSymsp->__Vcoverage[3]);
    vlSelf->tb_naive__DOT__en = 0U;
    ++(vlSymsp->__Vcoverage[5]);
    vlSelf->tb_naive__DOT__clr = 0U;
    ++(vlSymsp->__Vcoverage[7]);
}

#ifdef VL_DEBUG
VL_ATTR_COLD void Vtb_naive___024root___dump_triggers__stl(Vtb_naive___024root* vlSelf);
#endif  // VL_DEBUG

VL_ATTR_COLD void Vtb_naive___024root___eval_triggers__stl(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___eval_triggers__stl\n"); );
    // Body
    vlSelf->__VstlTriggered.set(0U, (IData)(vlSelf->__VstlFirstIteration));
#ifdef VL_DEBUG
    if (VL_UNLIKELY(vlSymsp->_vm_contextp__->debug())) {
        Vtb_naive___024root___dump_triggers__stl(vlSelf);
    }
#endif
}

VL_ATTR_COLD void Vtb_naive___024root___stl_sequent__TOP__0(Vtb_naive___024root* vlSelf) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___stl_sequent__TOP__0\n"); );
    // Body
    if (((IData)(vlSelf->tb_naive__DOT__clk) ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__clk))) {
        ++(vlSymsp->__Vcoverage[0]);
        vlSelf->tb_naive__DOT____Vtogcov__clk = vlSelf->tb_naive__DOT__clk;
    }
    if (((IData)(vlSelf->tb_naive__DOT__rst_n) ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__rst_n))) {
        ++(vlSymsp->__Vcoverage[2]);
        vlSelf->tb_naive__DOT____Vtogcov__rst_n = vlSelf->tb_naive__DOT__rst_n;
    }
    if (((IData)(vlSelf->tb_naive__DOT__en) ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__en))) {
        ++(vlSymsp->__Vcoverage[4]);
        vlSelf->tb_naive__DOT____Vtogcov__en = vlSelf->tb_naive__DOT__en;
    }
    if (((IData)(vlSelf->tb_naive__DOT__clr) ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__clr))) {
        ++(vlSymsp->__Vcoverage[6]);
        vlSelf->tb_naive__DOT____Vtogcov__clr = vlSelf->tb_naive__DOT__clr;
    }
    if (((IData)(vlSelf->tb_naive__DOT__ovf) ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__ovf))) {
        ++(vlSymsp->__Vcoverage[16]);
        vlSelf->tb_naive__DOT____Vtogcov__ovf = vlSelf->tb_naive__DOT__ovf;
    }
    if ((1U & ((IData)(vlSelf->tb_naive__DOT__count) 
               ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[8]);
        vlSelf->tb_naive__DOT____Vtogcov__count = (
                                                   (0xfeU 
                                                    & (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)) 
                                                   | (1U 
                                                      & (IData)(vlSelf->tb_naive__DOT__count)));
    }
    if ((2U & ((IData)(vlSelf->tb_naive__DOT__count) 
               ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[9]);
        vlSelf->tb_naive__DOT____Vtogcov__count = (
                                                   (0xfdU 
                                                    & (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)) 
                                                   | (2U 
                                                      & (IData)(vlSelf->tb_naive__DOT__count)));
    }
    if ((4U & ((IData)(vlSelf->tb_naive__DOT__count) 
               ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[10]);
        vlSelf->tb_naive__DOT____Vtogcov__count = (
                                                   (0xfbU 
                                                    & (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)) 
                                                   | (4U 
                                                      & (IData)(vlSelf->tb_naive__DOT__count)));
    }
    if ((8U & ((IData)(vlSelf->tb_naive__DOT__count) 
               ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[11]);
        vlSelf->tb_naive__DOT____Vtogcov__count = (
                                                   (0xf7U 
                                                    & (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)) 
                                                   | (8U 
                                                      & (IData)(vlSelf->tb_naive__DOT__count)));
    }
    if ((0x10U & ((IData)(vlSelf->tb_naive__DOT__count) 
                  ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[12]);
        vlSelf->tb_naive__DOT____Vtogcov__count = (
                                                   (0xefU 
                                                    & (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)) 
                                                   | (0x10U 
                                                      & (IData)(vlSelf->tb_naive__DOT__count)));
    }
    if ((0x20U & ((IData)(vlSelf->tb_naive__DOT__count) 
                  ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[13]);
        vlSelf->tb_naive__DOT____Vtogcov__count = (
                                                   (0xdfU 
                                                    & (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)) 
                                                   | (0x20U 
                                                      & (IData)(vlSelf->tb_naive__DOT__count)));
    }
    if ((0x40U & ((IData)(vlSelf->tb_naive__DOT__count) 
                  ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[14]);
        vlSelf->tb_naive__DOT____Vtogcov__count = (
                                                   (0xbfU 
                                                    & (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)) 
                                                   | (0x40U 
                                                      & (IData)(vlSelf->tb_naive__DOT__count)));
    }
    if ((0x80U & ((IData)(vlSelf->tb_naive__DOT__count) 
                  ^ (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)))) {
        ++(vlSymsp->__Vcoverage[15]);
        vlSelf->tb_naive__DOT____Vtogcov__count = (
                                                   (0x7fU 
                                                    & (IData)(vlSelf->tb_naive__DOT____Vtogcov__count)) 
                                                   | (0x80U 
                                                      & (IData)(vlSelf->tb_naive__DOT__count)));
    }
}

VL_ATTR_COLD void Vtb_naive___024root___configure_coverage(Vtb_naive___024root* vlSelf, bool first) {
    if (false && vlSelf) {}  // Prevent unused
    Vtb_naive__Syms* const __restrict vlSymsp VL_ATTR_UNUSED = vlSelf->vlSymsp;
    VL_DEBUG_IF(VL_DBG_MSGF("+    Vtb_naive___024root___configure_coverage\n"); );
    // Body
    if (false && first) {}  // Prevent unused
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[0]), first, "tb_naive.v", 4, 16, ".tb_naive", "v_toggle/tb_naive", "clk", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[1]), first, "tb_naive.v", 4, 22, ".tb_naive", "v_line/tb_naive", "block", "4");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[2]), first, "tb_naive.v", 5, 16, ".tb_naive", "v_toggle/tb_naive", "rst_n", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[3]), first, "tb_naive.v", 5, 24, ".tb_naive", "v_line/tb_naive", "block", "5");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[4]), first, "tb_naive.v", 6, 16, ".tb_naive", "v_toggle/tb_naive", "en", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[5]), first, "tb_naive.v", 6, 21, ".tb_naive", "v_line/tb_naive", "block", "6");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[6]), first, "tb_naive.v", 7, 16, ".tb_naive", "v_toggle/tb_naive", "clr", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[7]), first, "tb_naive.v", 7, 22, ".tb_naive", "v_line/tb_naive", "block", "7");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[8]), first, "tb_naive.v", 8, 16, ".tb_naive", "v_toggle/tb_naive", "count[0]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[9]), first, "tb_naive.v", 8, 16, ".tb_naive", "v_toggle/tb_naive", "count[1]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[10]), first, "tb_naive.v", 8, 16, ".tb_naive", "v_toggle/tb_naive", "count[2]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[11]), first, "tb_naive.v", 8, 16, ".tb_naive", "v_toggle/tb_naive", "count[3]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[12]), first, "tb_naive.v", 8, 16, ".tb_naive", "v_toggle/tb_naive", "count[4]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[13]), first, "tb_naive.v", 8, 16, ".tb_naive", "v_toggle/tb_naive", "count[5]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[14]), first, "tb_naive.v", 8, 16, ".tb_naive", "v_toggle/tb_naive", "count[6]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[15]), first, "tb_naive.v", 8, 16, ".tb_naive", "v_toggle/tb_naive", "count[7]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[16]), first, "tb_naive.v", 9, 16, ".tb_naive", "v_toggle/tb_naive", "ovf", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[17]), first, "tb_naive.v", 16, 5, ".tb_naive", "v_line/tb_naive", "block", "16");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[18]), first, "tb_naive.v", 20, 9, ".tb_naive", "v_line/tb_naive", "block", "20");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[19]), first, "tb_naive.v", 18, 5, ".tb_naive", "v_line/tb_naive", "block", "18-22");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[0]), first, "counter.v", 5, 23, ".tb_naive.dut", "v_toggle/counter", "clk", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[2]), first, "counter.v", 6, 23, ".tb_naive.dut", "v_toggle/counter", "rst_n", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[4]), first, "counter.v", 7, 23, ".tb_naive.dut", "v_toggle/counter", "en", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[6]), first, "counter.v", 8, 23, ".tb_naive.dut", "v_toggle/counter", "clr", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[8]), first, "counter.v", 9, 23, ".tb_naive.dut", "v_toggle/counter", "count[0]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[9]), first, "counter.v", 9, 23, ".tb_naive.dut", "v_toggle/counter", "count[1]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[10]), first, "counter.v", 9, 23, ".tb_naive.dut", "v_toggle/counter", "count[2]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[11]), first, "counter.v", 9, 23, ".tb_naive.dut", "v_toggle/counter", "count[3]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[12]), first, "counter.v", 9, 23, ".tb_naive.dut", "v_toggle/counter", "count[4]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[13]), first, "counter.v", 9, 23, ".tb_naive.dut", "v_toggle/counter", "count[5]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[14]), first, "counter.v", 9, 23, ".tb_naive.dut", "v_toggle/counter", "count[6]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[15]), first, "counter.v", 9, 23, ".tb_naive.dut", "v_toggle/counter", "count[7]", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[16]), first, "counter.v", 10, 23, ".tb_naive.dut", "v_toggle/counter", "ovf", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[20]), first, "counter.v", 21, 13, ".tb_naive.dut", "v_branch/counter", "if", "21-22");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[21]), first, "counter.v", 21, 14, ".tb_naive.dut", "v_branch/counter", "else", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[22]), first, "counter.v", 19, 18, ".tb_naive.dut", "v_branch/counter", "if", "19-20");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[23]), first, "counter.v", 19, 19, ".tb_naive.dut", "v_branch/counter", "else", "");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[24]), first, "counter.v", 16, 18, ".tb_naive.dut", "v_line/counter", "elsif", "16-18");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[25]), first, "counter.v", 13, 9, ".tb_naive.dut", "v_line/counter", "elsif", "13-15");
    vlSelf->__vlCoverInsert(&(vlSymsp->__Vcoverage[26]), first, "counter.v", 12, 5, ".tb_naive.dut", "v_line/counter", "block", "12");
}
