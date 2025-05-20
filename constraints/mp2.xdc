## CLOCK
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { sys_clock }]; #IO_L12P_T1_MRCC_35 Sch=sysclk
create_clock -add -name sys_clock -period 8.00 -waveform {0 4} [get_ports { sys_clock }];

## RESET
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { reset_rtl }]; #IO_L12N_T1_MRCC_35 Sch=btn[0]

##Pmod Header JE                                                                                                                  
set_property -dict { PACKAGE_PIN W16   IOSTANDARD LVCMOS33 } [get_ports { tx }]; #IO_L18N_T2_34 Sch=je[2]                     
set_property -dict { PACKAGE_PIN J15   IOSTANDARD LVCMOS33 } [get_ports { rx }]; #IO_25_35 Sch=je[3]                          
