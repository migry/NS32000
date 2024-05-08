
This folder contains the composite source code for the TDS (Tiny Development System) firmware
which runs on a National Semiconductor DB16000 or DB32000 multubus format development card.

The composite source code was created from source code modules found on the web.

The sources were originally created by National Semiconductor.

The source code is written in standard National Semiconductor NS32000 series assembly code format,
and should assemble with some of the assemblers which can still be found for this CPU.

However the assembly code does assemble using the MigryTech NS32000 series assembler
called "gas32k" which is written in Perl (and therefore requires Perl to be installed in
order to execute the code). Using thed supplied "do.sh" and running under some flavour of
Linux, the code will be assembled to produce two 27128 EPROM image binaries for installation
into the development board.

NOTE: in order to support altternative architectures, such as use of a different UART, the source
      code contains C preprocessor like #define, #ifdef and #endif directives which are supported
      by the MigryTech assembler. If used with a different assembler, then the source file should
      be pre-processed using the C preprocessor "cpp".

