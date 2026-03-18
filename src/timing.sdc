# Timing constraints for tt_um_Xelef2000 (Ring Oscillator TRNG)

# Ring oscillators are asynchronous entropy sources - not clocked by system clock
# Mark paths from ring oscillators to synchronizers as false paths
set_false_path -from [get_pins -hierarchical *ring_bit*]
set_false_path -from [get_pins -hierarchical *u_ring*]

# Ring oscillator outputs going directly to pads are also async
set_false_path -to [get_ports {uo_out[1] uo_out[2] uo_out[3] uo_out[4]}]
