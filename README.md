[Introduction]
As chip integration continues to increase, memory dice are being stacked like HBM to reduce size and increase memory capacity.
In addition, as with automotive chips, stability issues are so important that the number of devices that require internal testing continues to increase.
In this situation, BIRA (Built-In Redundancy Analysis) has gained greater importance.
In the case of the previous BIRA, faults are stored using CAM (Content Addressable Memory),
and the fault is analyzed by several modules to determine whether repair is possible and to output a repair solution.
Herein, we refer to this previous BIRA and design an improved BIRA structure that can handle 3 spare structures with 2 banks.
This proposed BIRA allows the repair rate to be increased by adding a reanalyze process rather than the previous BIRA.
Additionally, it is expected that the RA time may be reduced for signals that can process results quickly by adding early termination signals, etc.
