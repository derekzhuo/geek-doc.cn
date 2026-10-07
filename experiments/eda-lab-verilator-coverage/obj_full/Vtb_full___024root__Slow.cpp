// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See Vtb_full.h for the primary calling header

#include "Vtb_full__pch.h"
#include "Vtb_full__Syms.h"
#include "Vtb_full___024root.h"

void Vtb_full___024root___ctor_var_reset(Vtb_full___024root* vlSelf);

Vtb_full___024root::Vtb_full___024root(Vtb_full__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , __VdlySched{*symsp->_vm_contextp__}
    , vlSymsp{symsp}
 {
    // Reset structure values
    Vtb_full___024root___ctor_var_reset(this);
}

void Vtb_full___024root___configure_coverage(Vtb_full___024root* vlSelf, bool first);

void Vtb_full___024root::__Vconfigure(bool first) {
    if (false && first) {}  // Prevent unused
    Vtb_full___024root___configure_coverage(this, first);
}

Vtb_full___024root::~Vtb_full___024root() {
}

// Coverage
void Vtb_full___024root::__vlCoverInsert(uint32_t* countp, bool enable, const char* filenamep, int lineno, int column,
    const char* hierp, const char* pagep, const char* commentp, const char* linescovp) {
    uint32_t* count32p = countp;
    static uint32_t fake_zero_count = 0;
    if (!enable) count32p = &fake_zero_count;
    *count32p = 0;
    VL_COVER_INSERT(vlSymsp->_vm_contextp__->coveragep(), count32p,  "filename",filenamep,  "lineno",lineno,  "column",column,
        "hier",std::string{name()} + hierp,  "page",pagep,  "comment",commentp,  (linescovp[0] ? "linescov" : ""), linescovp);
}
