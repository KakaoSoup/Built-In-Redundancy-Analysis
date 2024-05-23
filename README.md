[Abstract]

As chip integration continues to increase, memory dice are being stacked like HBM to reduce size and increase memory capacity.
In addition, as with automotive chips, stability issues are so important that the number of devices that require internal testing continues to increase.
In this situation, BIRA (Built-In Redundancy Analysis) has gained greater importance.
In the case of the previous BIRA, faults are stored using CAM (Content Addressable Memory),
and the fault is analyzed by several modules to determine whether repair is possible and to output a repair solution.
Herein, we refer to this previous BIRA and design an improved BIRA structure that can handle 3 spare structures with 2 banks.
This proposed BIRA allows the repair rate to be increased by adding a reanalyze process rather than the previous BIRA.
Additionally, it is expected that the RA time may be reduced for signals that can process results quickly by adding early termination signals, etc.


[Introduction]

Recently, as the importance of memory increases, the importance of repairing memory is also increasing. Due to the development of semiconductor process technology, attempts to stack memory in 3D increased. 3D memory has advantages in terms of integration and capacity. However, when a fault occurs in a layer, it affects the entire memory. So, the importance of a fault repair method is greater in 3D memory.

The memory repair methods include BIST (Built-In Self-Test) and BIRA (Built-In Redundancy Analysis). First, BIST which detects the faults and transmits its information, is internal testing in memory unlike the existing testing methods using external test equipment such as ATE (Automatic Test Equipment). Therefore, BIST can be tested without the connection of external equipment. This means that tests can be done at startup or during operation, and therefore BIST is mainly used in fields such as automotive and military where product reliability is important.
BIRA exists on the base layer of 3D memory, and it stores and analyzes the fault addresses from BIST and finds the repair solutions that cover all faults by given spares. Memory has some extra capacity (spare), which is used for repairing faults. BIRA checks whether the spares can cover all faults in memory. If spares cover all faults, it is repairable. Otherwise, it is not repairable.


![image](https://github.com/KakaoSoup/Built-In-Redundancy-Analysis/assets/96875348/30b98b00-1015-4e70-9b44-022965882f13)

Figure. Memory Repair Process with BIST and BIRA.


To improve the performance of BIRA, H/W overhead and RA (Redundancy Analysis) time must be reduced, and the repair rate of BIRA must be increased. These factors are important because they determine the cost and performance of a semiconductor. However, there is a trade-off because these factors cannot be improved at the same. Even if all factors are important, the most important factor in current semiconductors is yield. Therefore, the repair rate, which is related to yield, is the most important feature in memory.


![image](https://github.com/KakaoSoup/Built-In-Redundancy-Analysis/assets/96875348/f1949e10-0b40-494b-a7c4-d6fd90f7fe94)

Figure. Given Spare Structure of Project

So, the objective of this project is to design an effective BIRA with a 100% normalized repair rate in the memory with multiple banks. The repair rate is different when using various spare structures [1]. Therefore, proposed BIRA was designed to operate on these three spare structures (Fig.) and checked how the repair rate and analysis time are changed with these structures.
