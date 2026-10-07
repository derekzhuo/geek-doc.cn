// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See Vtb_full.h for the primary calling header

#ifndef VERILATED_VTB_FULL___024ROOT_H_
#define VERILATED_VTB_FULL___024ROOT_H_  // guard

#include "verilated.h"
#include "verilated_cov.h"
#include "verilated_timing.h"


class Vtb_full__Syms;

class alignas(VL_CACHE_LINE_BYTES) Vtb_full___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    CData/*0:0*/ tb_full__DOT__clk;
    CData/*0:0*/ tb_full__DOT__rst_n;
    CData/*0:0*/ tb_full__DOT__en;
    CData/*0:0*/ tb_full__DOT__clr;
    CData/*7:0*/ tb_full__DOT__count;
    CData/*0:0*/ tb_full__DOT__ovf;
    CData/*0:0*/ tb_full__DOT____Vtogcov__clk;
    CData/*0:0*/ tb_full__DOT____Vtogcov__rst_n;
    CData/*0:0*/ tb_full__DOT____Vtogcov__en;
    CData/*0:0*/ tb_full__DOT____Vtogcov__clr;
    CData/*7:0*/ tb_full__DOT____Vtogcov__count;
    CData/*0:0*/ tb_full__DOT____Vtogcov__ovf;
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_full__DOT__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__tb_full__DOT__rst_n__0;
    CData/*0:0*/ __VactContinue;
    IData/*31:0*/ __VactIterCount;
    VlDelayScheduler __VdlySched;
    VlTriggerScheduler __VtrigSched_h1a0094f0__0;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<3> __VactTriggered;
    VlTriggerVec<3> __VnbaTriggered;

    // INTERNAL VARIABLES
    Vtb_full__Syms* const vlSymsp;

    // CONSTRUCTORS
    Vtb_full___024root(Vtb_full__Syms* symsp, const char* v__name);
    ~Vtb_full___024root();
    VL_UNCOPYABLE(Vtb_full___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
    void __vlCoverInsert(uint32_t* countp, bool enable, const char* filenamep, int lineno, int column,
        const char* hierp, const char* pagep, const char* commentp, const char* linescovp);
};


#endif  // guard
