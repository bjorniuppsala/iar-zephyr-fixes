Details on zephyr build process
------------------------------------


Refer to https://docs.zephyrproject.org/latest/build/cmake/index.html for a 
good starting point. This do will provide some more details and comments 
regarding how things relate to IAR.

# Configuration Phase
Building starts with west providing some extra paths and options to cmake to form a copmlete cmake system. 

During the cmake config phase device-tree files and KConfig files are processed to select what to build and generate header files that provide #defines reflecting what should be built.

This is also when the first half of the linker script generation runs. The CMake machinery defines memory regions, sections, symbols etc and stores them into command line options for commands to generate the actual linker scripts when information required is available later in the build process. At later stages there are scripts that inspect the generated binaries to dig up information, which is used to fill in missing pieces  for the following stages.

# Build Phase
(what happens when ninja runs)

## Pre-build
see https://docs.zephyrproject.org/latest/build/cmake/index.html#pre-build

## Intermediate binaries
see https://docs.zephyrproject.org/latest/build/cmake/index.html#intermediate-binaries

When building with CONFIG_USERSPACE we get two intermediate builds (pre0 and pre1) and the final.

### pre0 
This is the unfixed size binary build. 
Here three different things are done: 
* Partition alignment - This is to ensure order and alingment between memory sections, to keep the separation between kernel-space global variables and user-space ones. This is so far uncharted territory for us as far as I know, and a bit cary since the gen_app_partitions.py generates ld scripts. We can probably fix this by making it use the same linker script generation machinery as the make config setup does.
* Device dependencies - When using devicetree to describe the system, we need to setup dependencies between devices. So that the UART driver gets the correct I/O pins without having to do explicit lookup. This is also largely untested for us, but the script generates a single .c file.

### pre1
* Generate ISR tables - scans the binary and populates .c file with ISR vector tables (hello (const void*)0xd8df). It is unclear to me why this isnt done with symbols. 
* Kernel object hashing - this is the real magic. This step builds a perfect hash-function to provide (space and time) efficient validation for kernel objects. Pointers to struct k_object are used by user-mode code to access kernel services, and the pointer needs to be validated and associated with its device/driver/function specific data. For kobjects with static lifetime this is handled by a hash table indexed by the pointer value. The debuginfo  from pre0 is used to find static lifetime struct k_object instances, and their address values are passed as keys into gperf to generate a perfect hash function.

## Final binary
This is where all the parts come together, filling in the small blanks from pre1. 




##Improvements for IAR

in kobject_prebuilt_hash iccarm does not see that asso_values is constant. so it ends up in kobject_data.data rather than .rodata. This consumes 0x100 bytes extra ram compared to gcc, *2 due to the size-calulcations in gen_kobject_placeholder.p (--datapct 100)


## Linker script generator:

### application partitions, app_smem, gen_app_partitions.py
Getting the alignment right both APP_SHARED_ALIGN so that both _app_smem_start  and _app_smem_end and ensuring that each partition's part_start and _part_end are aligned to SMEM_PARTITION_ALIGN requires some more tinkering. 
Both of these macros are #defined into . = ALIGN(something) or even two consequtive ones. This is ofcourse not possible to use with ilink, so we need some other variable that either gen_app_partitions.py or the generator itself can handle. 
With the £variables£ it is easy enough to give access to the values, but the logic from each ld-skeleton/toolchain must be modified to generate those definitions into e.g. autoconf.h

How do we get the choice of LINKER_APP_SMEM_UNALIGNED done? It seems to be -D defined by the cmake scripts just when generating pass 0.