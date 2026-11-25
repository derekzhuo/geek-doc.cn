proc connectivity_snapshot {block} {
    set snapshot {}
    foreach net [$block getNets] {
        set inst_terms {}
        foreach iterm [$net getITerms] {
            set inst_name [[$iterm getInst] getName]
            set pin_name [[$iterm getMTerm] getName]
            lappend inst_terms "${inst_name}:${pin_name}"
        }
        set top_ports {}
        foreach bterm [$net getBTerms] {
            lappend top_ports [$bterm getName]
        }
        lappend snapshot [list [$net getName] [lsort $inst_terms] [lsort $top_ports]]
    }
    return [lsort -index 0 $snapshot]
}

proc print_connectivity {label snapshot} {
    foreach row $snapshot {
        lassign $row net_name inst_terms top_ports
        puts "$label net=$net_name inst_terms={$inst_terms} top_ports={$top_ports}"
    }
}
