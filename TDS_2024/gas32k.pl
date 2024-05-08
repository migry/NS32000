#!/usr/bin/perl

use strict;

my $DEBUG =0;
my $DEBUGL=1;

##########################################################################################
# TODO or TOCHECK
##########################################################################################

##########################################################################################
#
# Migrys assembler for the NS32016 written in Perl.
#
# Rev 1.00 (19-Mar-2015)
# - Use an old disassembler for the framework
# - Read in the assembly code into an array
# Rev 1.01 (23-Mar-2015)
# - Parse the first command -> .org
# Rev 1.02 (25-Mar-2015)
# Rev 1.03 (26-Mar-2015)
# - Finish off LPRx instruction.
# - Try MOVx gen.gen -> works for simple cases!
# Rev 1.04 (27-Mar-2015)
# - Re-code operands as twi fields
# - Add more instructions (just to make first pass through the test.32k example code)
# Rev 1.05 (28-Mar-2015)
# Rev 1.06 (29-Mar-2015)
# - Much code added to grab and process operands.
# -Test out on a small snippet of code (with expected binary) found on the web.
# Rev 1.06 (30-Mar-2015)
# - Try to add scaled indexing.
# - Improve identifier and label handling
# - Add 0th pass to find out identifiers and labels
# Rev 1.07 (31-Mar-2015)
# - Add code to cope with the 3rd operand of ACBi instruction.
# Rev 1.08 (01-Apr-2015)
# - Now that using the {dest} flag branches are no longer working -> fixed?
# Rev 1.09 (26-Apr-2015)
# - Add support for .word
# Rev 1.10 (30-Jul-2015)
# - Pick up again. Used cputest.32k to fix a few broken opcodes. ADDR to be fixed next.
# Rev 1.11 (01-Aug-2015)
# - Update directives to process byte,word and double constants (still a bug in word and double)
# Rev 1.12 (03-Aug-2015)
# - Work on log file output format of byte and double (to be completed).
# Rev 1.13 (05-Aug-2015)
# - Sort out final problems with double,word and bytes dumps - now all fixed.
# - Try to get format same as Udos software in order to do a tkdiff on the list file.
# Rev 1.14 (07-Aug-2015)
# - Need to work on LSH,BICPSR,BISPSR,MOVZB,MOVXB,ADDR,MOVMB,MOVMW,CMPMB,CMPMW,CVTP
# Rev 1.15 (10-Aug-2015)
# - Sorted out immediate shift value which must have only length of 1 byte
# - Sorted out problem with BICPSR and BISPSR
# Rev 1.16 (11-Aug-2015)
# - Sorted out problem with INSS and EXTS (needed offset and length operands to be parsed)
# Rev 1.17 (12-Aug-2015)
# - Sorted out ADDR problem (needed to convert instruction opcode and size fields to lower case).
# - Note: RET is broken.
# Rev 1.18 (13-Aug-2015)
# - Fix RET. Fix displacement calculation.
# Rev 1.19 (15-Aug-2015)
# - Scaled indexing now is working.
# Rev 1.20 (17-Aug-2015)
# - Work on MOVZBW etc. Problem understood but not quite fixed.
# Rev 1.21 (18-Aug-2015)
# - Fixed more instructions EXT and INS with the 4th register operand.
# Rev 1.22 (19-Aug-2015)
# - Fix CVTP, INDEX ,CHECK and CASE. Need to add scaled index code to all opcodes. Not sure of the best place to put the code
# - Still need to fix MOVS and CMPS
# Rev 1.23 (20-Aug-2015)
# - Fix ENTER,EXIT,SAVE and RESTORE register coding. Fix MOVS and CMPS.
# - Move 2 labels and all code is matching. Need to fix label difference which was hard coded.
# Rev 1.24 (20-Oct-2015)
# - Start to work on the output files.
# Rev 1.25 (28-Oct-2015)
# - Tidy up output files.
# Rev 1.26 (28-Oct-2015)
# - Continue tidy up.
# Rev 1.27 (04-Feb-2016)
# - Found a bug in the second stage loader, jmp @0x8100 does not assemble the destination
#   correctly (and instead jumps to 0x0!).
# Rev 1.28 (03-May-2019)
# - Fix the label diff expression.
# Rev 1.29 (20-Jun-2020)
# - Try to support National Semiconductor GENIX assembler format and directives.
# Rev 1.30 (21-Jun-2020)
# - Continue. Add .BLKB , .DSECT , .ENDSEG
# Rev 1.31 (22-Jun-2020)  
# - Continue.
# Rev 1.32 (24-Jun-2020)  
# - Continue. Add SMR and LMR instructions with format 14 to opcode table.
# - Finally runs all the way through the initial aint.a32 code. Much code does not match. Good start! Need to implement IMPORT.
# Rev 1.33 (25-Jun-2020)  
# Rev 1.34 (26-Jun-2020)  
# - Add IMPORTP to correct CXP instruction.
# Rev 1.35 (27-Jun-2020)  
# - Various fixes (some were bugs). Diff of output assembly and Definicon LIS file now 80% matching.
# - Need to implement floating point instructions.
# Rev 1.36 (28-Jun-2020)  
# - Start to add float instructions.
# - Assembly output almost nearly matches the Definicon assembler. Only 3 lines are genuinely different.
# Rev 1.37 (29-Jun-2020)  
# - More additions and directives added, but further support code needed.
# Rev 1.38 (30-Jun-2020)  
# - Add more operators to expr and term.
# Rev 1.39 (01-Jul-2020)  
# - Unary operator tilde added. Assembly list nearly 100% matching (except for added sizes for branches)
# - More expression tweaks, making sure PCrel minus PCrel is seen as a constant.
# Rev 1.40 (02-Jul-2020)  
# - Fix output list for ENDPROC.
# Rev 1.41 (03-Jul-2020)  
# Rev 1.42 (04-Jul-2020)  
# Rev 1.43 (05-Jul-2020)  
# - Implement the correct offset for parameters passed to PROCs.
# Rev 1.44 (06-Jul-2020)  
# Rev 1.45 (07-Jul-2020)  
# Rev 1.46 (08-Jul-2020)  
# Rev 1.47 (09-Jul-2020)  
# - Add more miscellanous sanity checks, while working on tds.32k
# Rev 1.48 (10-Jul-2020)  
# Rev 1.49 (14-Jul-2020)  
# - Write new code to create either single or split ROM binaries.
# Rev 1.50 (15-Jul-2020)  
# - Change ROM file names.
# Rev 1.51 (16-Jul-2020)  
# - Fix broken expression evaluator (got the expression type wrong in some cases).
# Rev 1.52 (17-Jul-2020)  
# Rev 1.53 (08-May-2024)  
#
##########################################################################################
#
# The general form of any line is...
#
# {label:} {mnemonic {operands}} {;comments}
#
# label is optional, but must start in column one and be terminated with a colon
# 
# numbers are by default decimal
# hex numbers start 0x (like in the C language) or 'x
#
# identifier equ expression
#
##########################################################################################

my $Arg;
my $i;
my $o;
my @rom;
my $split;
my $eprom;

my $asm_file="";
my $file_in_type;
my $outfmt="default";
my $outlisfile="out.lis";
my $outhexfile="out.hex";
my $outtab=35;

my @gasm_text; # expansion of all text read in

my @gasm_filelist; # list of all source files
my @gasm_fileindex; # needed for error messages
my @gasm_filelineno; 

my @gout_text;
my $gasm_text_cnt;
my $gline;
my $gpass=0;
my $gpc;
my $gpc_min=0xffffffff;
my $gpc_max=0;
my $gdsectpc; # DSECT/ENDSEG
my $gfppc; # FP
my $gsbpc;  # SB/ENDSEG

my $gcode_section;
my $gdata_section;
my $gstatic_section;
my $gframe_section;
my $gparam_section;
my $greturn_section;
my $glocal_section;


my $gstart_dsectpc;
my $goffset_dsectpc;

my %gidentifier;
my %gidentifier_defined;
my %gidentifier_defline;

my @gcode;
my %gcode_label;
my %gcode_label_defline;
my %gsb_label;
my %gsb_label_defline;
my %gdsect_label;
my %gdsect_label_defline;
my %gimport_label;
my %gimport_label_defline;
my $gimport_count;
my %gimportp_label;
my %gimportp_label_defline;
# frame pointer
my %gfp_label;
my %gfp_label_defline;

my $glocallength;

my $gparamlength;
my $gparamcount;
my $gparamreturn;
my @gparamname;
my @gparamoffset;

my $greturnlength;

my $gendproc;
my %gmodule_exports;

my $glabel_updates;
my $glabeltype; # ":" = external proc

my $gdisptype;
my $gexprtype;
my $gopnoflag;
my $gopcode;
my $gundefined_symbol;

my @instruction_set=(
#format=0
{ ins=>"(BEQ)", op=>0x0, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BNE)", op=>0x1, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BCS)", op=>0x2, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BCC)", op=>0x3, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BHI)", op=>0x4, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BLS)", op=>0x5, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BGT)", op=>0x6, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BLE)", op=>0x7, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BFS)", op=>0x8, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BFC)", op=>0x9, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BLO)", op=>0xA, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BHS)", op=>0xB, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BLT)", op=>0xC, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BGE)", op=>0xD, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
{ ins=>"(BR)",  op=>0xE, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
# ins=>"(B??)", op=>0xF, operand1=>"none", operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>0 },
#format=1
{ ins=>"(BSR)",         op=>0x0,   operand1=>"none",    operand2=>"none", operand3=>"none", dest=>1, cycles=>0, format=>104 },
{ ins=>"(RET)",         op=>0x1,   operand1=>"disp",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>101 },
{ ins=>"(CXP)",         op=>0x2,   operand1=>"cxpdisp", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>105 },
{ ins=>"(RXP)",         op=>0x3,   operand1=>"disp",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>101 },
{ ins=>"(RETT)",        op=>0x4,   operand1=>"disp",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>101 },
{ ins=>"(RETI)",        op=>0x5,   operand1=>"none",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>100 },
{ ins=>"(SAVE)",        op=>0x6,   operand1=>"reglist", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>102 },
{ ins=>"(RESTORE)",     op=>0x7,   operand1=>"reglistx",operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>102 },
{ ins=>"(ENTER)",       op=>0x8,   operand1=>"reglist", operand2=>"disp", operand3=>"none", dest=>0, cycles=>0, format=>103 },
{ ins=>"(EXIT)",        op=>0x9,   operand1=>"reglistx",operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>109 },
{ ins=>"(NOP)",         op=>0xA,   operand1=>"none",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>100 },
{ ins=>"(WAIT)",        op=>0xB,   operand1=>"none",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>100 },
{ ins=>"(DIA)",         op=>0xC,   operand1=>"none",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>100 },
{ ins=>"(FLAG)",        op=>0xD,   operand1=>"none",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>100 },
{ ins=>"(SVC)",         op=>0xE,   operand1=>"none",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>100 },
{ ins=>"(BPT)",         op=>0xF,   operand1=>"none",    operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>100 },
#format=2
{ ins=>"(ADDQ)([BWD])", op=>0x0,   operand1=>"short",   operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>200 },
{ ins=>"(CMPQ)([BWD])", op=>0x1,   operand1=>"short",   operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>200 },
{ ins=>"(SPR)([BWD])",  op=>0x2,   operand1=>"procreg", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>200 },
{ ins=>"(ACB)([BWD])",  op=>0x4,   operand1=>"short",   operand2=>"genwr", operand3=>"none", dest=>1, cycles=>0, format=>201 },
{ ins=>"(MOVQ)([BWD])", op=>0x5,   operand1=>"short",   operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>200 },
{ ins=>"(LPR)([BWD])",  op=>0x6,   operand1=>"procreg", operand2=>"genrd", operand3=>"none", dest=>0, cycles=>0, format=>200 },
#Scond...
#format=22
{ ins=>"(SEQ)([BWD])", op=>0x0, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SNE)([BWD])", op=>0x1, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SCS)([BWD])", op=>0x2, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SCC)([BWD])", op=>0x3, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SHI)([BWD])", op=>0x4, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SLS)([BWD])", op=>0x5, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SGT)([BWD])", op=>0x6, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SLE)([BWD])", op=>0x7, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SFS)([BWD])", op=>0x8, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SFC)([BWD])", op=>0x9, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SLO)([BWD])", op=>0xa, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SHS)([BWD])", op=>0xb, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SLT)([BWD])", op=>0xc, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
{ ins=>"(SGE)([BWD])", op=>0xd, operand1=>"genwr", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>22 },
#format=3
{ ins=>"(CXPD)",         op=>0x0,  operand1=>"genrd", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>3 }, # special case (see later)
{ ins=>"(BICPSR)([BW])", op=>0x2,  operand1=>"genrd", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>3 }, # no D option
{ ins=>"(JUMP)",         op=>0x4,  operand1=>"genrd", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>3 }, # special case (see later)
{ ins=>"(BISPSR)([BW])", op=>0x6,  operand1=>"genrd", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>3 }, # no D option
# ins=>"(???)",          op=>0x8,  operand1=>"genrd", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>3 }, #TRAP#
{ ins=>"(ADJSP)([BWD])", op=>0xA,  operand1=>"genrd", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>3 },
{ ins=>"(JSR)",          op=>0xC,  operand1=>"genrd", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>3 }, # special case (see later)
{ ins=>"(CASE)([BWD])",  op=>0xE,  operand1=>"genrd", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>3 },
#format=4
{ ins=>"(ADD)([BWD])",  op=>0x0, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(CMP)([BWD])",  op=>0x1, operand1=>"genrd", operand2=>"genrd", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(BIC)([BWD])",  op=>0x2, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
# ins=>"(???)([BWD])",  op=>0x3, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(ADDC)([BWD])", op=>0x4, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(MOV)([BWD])",  op=>0x5, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(OR)([BWD])",   op=>0x6, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
# ins=>"(???)([BWD])",  op=>0x7, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(SUB)([BWD])",  op=>0x8, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(ADDR)",        op=>0x9, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(AND)([BWD])",  op=>0xA, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
# ins=>"(???)([BWD])",  op=>0xB, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(SUBC)([BWD])", op=>0xC, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(TBIT)([BWD])", op=>0xD, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
{ ins=>"(XOR)([BWD])",  op=>0xE, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
# ins=>"(???)([BWD])",  op=>0xF, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>4 },
#format=5
{ ins=>"(MOVS)([BWD])", op=>0x0, operand1=>"options", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>5 },
{ ins=>"(MOVST)",       op=>0x0, operand1=>"options", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>5 },
{ ins=>"(CMPS)([BWD])", op=>0x1, operand1=>"options", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>5 },
{ ins=>"(CMPST)",       op=>0x1, operand1=>"options", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>5 },
{ ins=>"(SETCFG)",      op=>0x2, operand1=>"cfglist", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>5 }, #TODO
{ ins=>"(SKPS)([BWD])", op=>0x3, operand1=>"options", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>5 },
{ ins=>"(SKPST)",       op=>0x3, operand1=>"options", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>5 },
#format=6
{ ins=>"(ROT)([BWD])",   op=>0x0, operand1=>"count", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(ASH)([BWD])",   op=>0x1, operand1=>"count", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(CBIT)([BWD])",  op=>0x2, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(CBITI)([BWD])", op=>0x3, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
# ins=>"(ROT)([BWD])",   op=>0x4, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 }, #TRAP#
{ ins=>"(LSH)([BWD])",   op=>0x5, operand1=>"count", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(SBIT)([BWD])",  op=>0x6, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(SBITI)([BWD])", op=>0x7, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(NEG)([BWD])",   op=>0x8, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(NOT)([BWD])",   op=>0x9, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 }, 
# ins=>"(???)([BWD])",   op=>0xA, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 }, #TRAP#
{ ins=>"(SUBP)([BWD])",  op=>0xB, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(ABS)([BWD])",   op=>0xC, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(COM)([BWD])",   op=>0xD, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(IBIT)([BWD])",  op=>0xE, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
{ ins=>"(ADDP)([BWD])",  op=>0xF, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>6 },
#format=7
{ ins=>"(MOVM)([BWD])",  op=>0x0, operand1=>"genrd", operand2=>"genwr", operand3=>"length", dest=>0, cycles=>0, format=>7 },
{ ins=>"(CMPM)([BWD])",  op=>0x1, operand1=>"genrd", operand2=>"genwr", operand3=>"length", dest=>0, cycles=>0, format=>7 },
{ ins=>"(INSS)([BWD])",  op=>0x2, operand1=>"genrd", operand2=>"genwr", operand3=>"offset", dest=>0, cycles=>0, format=>7 },
{ ins=>"(EXTS)([BWD])",  op=>0x3, operand1=>"genrd", operand2=>"genwr", operand3=>"offset", dest=>0, cycles=>0, format=>7 },
{ ins=>"(MOVX)(B)(W)",   op=>0x4, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(MOVZ)(B)(W)",   op=>0x5, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(MOVZ)([BW])(D)",op=>0x6, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(MOVX)([BW])(D)",op=>0x7, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(MUL)([BWD])",   op=>0x8, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(MEI)([BWD])",   op=>0x9, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
# ins=>"(???)([BWD])",   op=>0xA, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 }, #TRAP#
{ ins=>"(DEI)([BWD])",   op=>0xB, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(QUO)([BWD])",   op=>0xC, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(REM)([BWD])",   op=>0xD, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(MOD)([BWD])",   op=>0xE, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
{ ins=>"(DIV)([BWD])",   op=>0xF, operand1=>"genrd", operand2=>"genwr", operand3=>"none", dest=>0, cycles=>0, format=>7 },
#format=8
{ ins=>"(EXT)([BWD])",   op=>0x0, operand1=>"genrd", operand2=>"genwr", operand3=>"length",dest=>0, cycles=>0, format=>8 },
{ ins=>"(CVTP)",         op=>0x1, operand1=>"genrd", operand2=>"genwr", operand3=>"reg",   dest=>0, cycles=>0, format=>8 }, #operands defined out of order
{ ins=>"(INS)([BWD])",   op=>0x2, operand1=>"genrd", operand2=>"genwr", operand3=>"length",dest=>0, cycles=>0, format=>8 },
{ ins=>"(CHECK)([BWD])", op=>0x3, operand1=>"genrd", operand2=>"genwr", operand3=>"reg",   dest=>0, cycles=>0, format=>8 }, #TODO
{ ins=>"(INDEX)([BWD])", op=>0x4, operand1=>"genrd", operand2=>"genrd", operand3=>"reg",   dest=>0, cycles=>0, format=>8 },
{ ins=>"(FFS)([BWD])",   op=>0x5, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>8 },
#format=12 FPU
{ ins=>"(MOV)([BWD])L",  op=>0x0, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>90 },
{ ins=>"(MOV)([BWD])F",  op=>0x1, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>91 },
{ ins=>"(LFSR)",         op=>0x3, operand1=>"genrd", operand2=>"none",  operand3=>"none",  dest=>0, cycles=>0, format=>93 },
{ ins=>"(MOVLF)",        op=>0x5, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>95 },
{ ins=>"(MOVFL)",        op=>0x6, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>96 },
{ ins=>"(ROUNDL)([BWD])",op=>0x8, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>980 },
{ ins=>"(ROUNDF)([BWD])",op=>0x9, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>981 },
{ ins=>"(TRUNCL)([BWD])",op=>0xA, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>980 },
{ ins=>"(TRUNCF)([BWD])",op=>0xB, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>981 },
{ ins=>"(SFSR)",         op=>0xD, operand1=>"genwr", operand2=>"none",  operand3=>"none",  dest=>0, cycles=>0, format=>92 },
{ ins=>"(FLOORL)([BWD])",op=>0xE, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>980 },
{ ins=>"(FLOORF)([BWD])",op=>0xF, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>981 },
#format=11 FPU
{ ins=>"(ADDF)",         op=>0x0, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>111 },
{ ins=>"(ADDL)",         op=>0x0, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>110 },
{ ins=>"(MOVF)",         op=>0x1, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>111 },
{ ins=>"(MOVL)",         op=>0x1, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>110 },
{ ins=>"(CMPF)",         op=>0x2, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>111 },
{ ins=>"(CMPL)",         op=>0x2, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>110 },
{ ins=>"(SUBF)",         op=>0x4, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>111 },
{ ins=>"(SUBL)",         op=>0x4, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>110 },
{ ins=>"(NEGF)",         op=>0x5, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>111 },
{ ins=>"(NEGL)",         op=>0x5, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>110 },
{ ins=>"(DIVF)",         op=>0x8, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>111 },
{ ins=>"(DIVL)",         op=>0x8, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>110 },
{ ins=>"(MULF)",         op=>0xC, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>111 },
{ ins=>"(MULL)",         op=>0xC, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>110 },
{ ins=>"(ABSF)",         op=>0xD, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>111 },
{ ins=>"(ABSL)",         op=>0xD, operand1=>"genrd", operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>110 },
#format=14 MMU
{ ins=>"(LMR)",          op=>0x2, operand1=>"mmureg",operand2=>"genrd", operand3=>"none",  dest=>0, cycles=>0, format=>14 },
{ ins=>"(SMR)",          op=>0x3, operand1=>"mmureg",operand2=>"genwr", operand3=>"none",  dest=>0, cycles=>0, format=>14 },
##############
{ ins=>"END", op=>0x00, operand1=>"none", operand2=>"none", operand3=>"none", dest=>0, cycles=>0, format=>0 },
);

######################################################################################

use constant ADDRESS_MODE_REGISTER_0 => 0x00;
use constant ADDRESS_MODE_REGISTER_1 => 0x01;
use constant ADDRESS_MODE_REGISTER_2 => 0x02;
use constant ADDRESS_MODE_REGISTER_3 => 0x03;
use constant ADDRESS_MODE_REGISTER_4 => 0x04;
use constant ADDRESS_MODE_REGISTER_5 => 0x05;
use constant ADDRESS_MODE_REGISTER_6 => 0x06;
use constant ADDRESS_MODE_REGISTER_7 => 0x07;

use constant ADDRESS_MODE_REGISTER_0_RELATIVE => 0x08;
use constant ADDRESS_MODE_REGISTER_1_RELATIVE => 0x09;
use constant ADDRESS_MODE_REGISTER_2_RELATIVE => 0x0A;
use constant ADDRESS_MODE_REGISTER_3_RELATIVE => 0x0B;
use constant ADDRESS_MODE_REGISTER_4_RELATIVE => 0x0C;
use constant ADDRESS_MODE_REGISTER_5_RELATIVE => 0x0D;
use constant ADDRESS_MODE_REGISTER_6_RELATIVE => 0x0E;
use constant ADDRESS_MODE_REGISTER_7_RELATIVE => 0x0F;

use constant ADDRESS_MODE_FRAME_MEMORY_RELATIVE => 0x10;
use constant ADDRESS_MODE_STACK_MEMORY_RELATIVE => 0x11;
use constant ADDRESS_MODE_STATIC_MEMORY_RELATIVE=> 0x12;

use constant ADDRESS_MODE_IMMEDIATE      => 0x14;
use constant ADDRESS_MODE_ABSOLUTE       => 0x15;
use constant ADDRESS_MODE_EXTERNAL       => 0x16;
use constant ADDRESS_MODE_TOP_OF_STACK   => 0x17;

use constant ADDRESS_MODE_FRAME_MEMORY   => 0x18;
use constant ADDRESS_MODE_STACK_MEMORY   => 0x19;
use constant ADDRESS_MODE_STATIC_MEMORY  => 0x1A;
use constant ADDRESS_MODE_PROGRAM_MEMORY => 0x1B;

use constant ADDRESS_MODE_BYTE_SCALED_INDEX   => 0x1C;
use constant ADDRESS_MODE_WORD_SCALED_INDEX   => 0x1D;
use constant ADDRESS_MODE_DWORD_SCALED_INDEX  => 0x1E;
use constant ADDRESS_MODE_QWORD_SCALED_INDEX  => 0x1F;

use constant OKUNDEF  => 2;
use constant OK       => 1;
use constant NOTOK    => 0;

use constant SYMBOL_CODE    => 1;
use constant SYMBOL_DSECT   => 2;
use constant SYMBOL_SB      => 3;
use constant SYMBOL_FP      => 4;
use constant SYMBOL_EQU     => 5;
use constant SYMBOL_IMPORTP => 6;
use constant SYMBOL_IMPORT  => 7;

######################################################################################

print ";;;##########################################\n";
print ";;; NS32016 assembler v1.53 (08-May-2024)\n";
print ";;;##########################################\n";
print ";;; written by migry (migrytech\@gmail.com) \n";
print ";;;##########################################\n";
if ($ARGV[0] =~ /-version/) {
  return 0;
}

parse_command_line();

read_all_asms($asm_file);

unless(open(LIST,">".$outlisfile)) { die("Could not open output list file $outlisfile\n"); }

print "PASS 0\n";
$gpass=0; find_label(); # on the pre-pass through find all the labels and give them default values as a starting point
dump_labels(1);
dump_sb_labels(1);
dump_dsect_labels(1);
dump_identifiers(1);

print "########################\nPASS 1\n";
$gpass=1; assemble();
print "########################\nPASS 2\n";
$gpass=2; assemble();
print "########################\nPASS 3\n";
$gpass=3; assemble();
print "########################\nPASS 4\n";
$gpass=4; assemble();


# use pass 99 to indicate that the logfile should be printed
print "########################\nPASS 99\n";
$gpass=99; assemble();

dump_labels(2);
dump_sb_labels(2);
dump_dsect_labels(2);
dump_identifiers(2);
close(LIST);

write_bin();

exit;

######################################################################################
my %define;
my $define_level;
my @define_flag;
my $gfileindex;
######################################################################################
sub read_all_asms {
  my ($filename) = @_;

  $gfileindex=0;
  $gasm_text_cnt=1;
  $define_level=0;
  $define_flag[$define_level]=1;

  read_asmfile($filename);
}

######################################################################################
# just suck the source into an array of text strings
sub read_asmfile {
  my ($filename) = @_;
  my $txt;
  my $lineno=1;
  my $IN;

  $gfileindex++;

  # record filename and assign index
  push @gasm_filelist ,$filename; 

  unless(open($IN,"<".$filename)) { die("Could not open input assembly file $filename\n"); }
if ($DEBUG>50) { print "***** OPENED $filename *****\n"; }
  while (<$IN>) {
    chomp($txt=$_);
    if ($txt =~ /^\s*#\s*define\b(.*)/) {
      if ($1 =~ /\s*(\w+)\s*$/) {
        $define{$1}=0;
      } else {
        errorfile(); print(" problem with #define\n"); exit;
      }
    } elsif ($txt =~ /^\s*#\s*ifdef\b\s*(.*)\s*$/) {
      $define_level++;
      if (defined($define{$1})) { $define_flag[$define_level]=1; }
      else                      { $define_flag[$define_level]=0; }
    } elsif ($txt =~ /^\s*#\s*ifndef\b\s*(.*)\s*$/) {
      if (defined($define{$1})) { $define_flag[$define_level]=0; }
      else                      { $define_flag[$define_level]=1; }
      $define_level++;
    } elsif ($txt =~ /^\s*#\s*endif\b(.*)/) {
      $define_level--;
    } elsif ($define_flag[$define_level]==1) {
      $gasm_text[$gasm_text_cnt]=$txt;
      $gasm_fileindex[$gasm_text_cnt]=$gfileindex;
      $gasm_filelineno[$gasm_text_cnt] = $lineno;
      $gasm_text_cnt++;
      if ($txt =~ /^\s*\.include\s+"(.*)"\s*(;.*)?$/) {
          $gasm_text_cnt--;
          read_asmfile($1); # recurse
      }
    } else {
    }
    $lineno++;
  }
  close($IN);
if ($DEBUG>50) { print "***** CLOSED $filename *****\n"; }
}

######################################################################################
sub exists_import {
  my ($label) = @_ ;

  my $import=defined($gimport_label{$label});
  if ($import) { return 1;} else { return 0; }
}

######################################################################################
sub read_import {
  my ($label) = @_ ;

  return ($gimport_label{$label});
}

######################################################################################
sub exists_importp {
  my ($label) = @_ ;

  my $importp=defined($gimportp_label{$label});
  if ($importp) { return 1;} else { return 0; }
}

######################################################################################
sub exists_label {
  my ($label) = @_ ;

  my $code =defined($gcode_label   {$label});
  my $sb   =defined($gsb_label     {$label});
  my $dsect=defined($gdsect_label  {$label});
  my $fp   =defined($gfp_label     {$label});
  my $id   =defined($gidentifier   {$label});
  my $imp  =defined($gimportp_label{$label});
  my $im   =defined($gimport_label {$label});
  if    ($code==1)  { return SYMBOL_CODE; }
  elsif ($dsect==1) { return SYMBOL_DSECT; }
  elsif ($sb==1)    { return SYMBOL_SB; }
  elsif ($fp==1)    { return SYMBOL_FP; }
  elsif ($id==1)    { return SYMBOL_EQU; }
  elsif ($imp==1)   { return SYMBOL_IMPORTP; }
  elsif ($im==1)    { return SYMBOL_IMPORT; }
  else              { return 0; }
}

######################################################################################
sub defined_label {
  my ($label) = @_ ;

  my $code =defined($gcode_label   {$label});
  my $sb   =defined($gsb_label     {$label});
  my $dsect=defined($gdsect_label  {$label});
  my $fp   =defined($gfp_label     {$label});
  my $id   =defined($gidentifier   {$label});
  my $imp  =defined($gimportp_label{$label});
  my $im   =defined($gimport_label {$label});
  if    ($code==1)  { return 1; }
  elsif ($dsect==1) { return 1; }
  elsif ($sb==1)    { return 1; }
  elsif ($fp==1)    { return 1; }
  elsif ($id==1)    { return $gidentifier_defined{$label}; }
  elsif ($imp==1)   { return 1; }
  elsif ($im==1)    { return 1; }
  else              { return NOTOK; }
}

######################################################################################
sub defined_at_line {
  my ($label) = @_ ;

  my $code =defined($gcode_label   {$label});
  my $dsect=defined($gdsect_label  {$label});
  my $sb   =defined($gsb_label     {$label});
  my $fp   =defined($gfp_label     {$label});
  my $id   =defined($gidentifier   {$label});
  my $imp  =defined($gimportp_label{$label});
  my $im   =defined($gimport_label {$label});
  if    ($code==1)  { return $gcode_label_defline{$label};    }
  elsif ($dsect==1) { return $gdsect_label_defline{$label};   }
  elsif ($sb==1)    { return $gsb_label_defline{$label};      }
  elsif ($fp==1)    { return $gfp_label_defline{$label};      }
  elsif ($id==1)    { return $gidentifier_defline{$label};    }
  elsif ($imp==1)   { return $gimportp_label_defline{$label}; }
  elsif ($im==1)    { return $gimport_label_defline{$label};  }
  else              { return NOTOK; }
}

######################################################################################
sub read_label {
  my ($label) = @_ ;

  my $code =defined($gcode_label  {$label});
  my $sb   =defined($gsb_label    {$label});
  my $dsect=defined($gdsect_label {$label});
  my $fp   =defined($gfp_label    {$label});
  my $imp  =defined($gimport_label{$label});
  my $val;

  if ($fp==1) {
    $val=$gfp_label{$label};
    $gexprtype="FP"; 
    if ($DEBUG>30) { printf("read_label(): FRAME LABEL <$label> = <$val>\n"); }
    return ($val);
  }
  elsif ($code==1) {
    $val=$gcode_label{$label};
    $gexprtype="CODE"; 
    if ($DEBUG>30) { printf("DEBUG:: code label <$label> = <$val>\n"); }
    return ($val);
  }
  elsif ($sb==1) {
    $val=$gsb_label{$label};
    $gexprtype="SB";
    if ($DEBUG>30) { printf("DEBUG:: SB label <$label> = <$val>\n"); }
    return ($val);
  }
  elsif ($imp==1) {
    $val=$gimport_label{$label};
    $gexprtype="IMPORT";
    if ($DEBUG>30) { printf("DEBUG:: IMPORT label <$label> = <$val>\n"); }
    return ($val);
  }
  elsif ($dsect==1) {
    $val=$gdsect_label{$label};
    $gexprtype="DATA";
    if ($DEBUG>30) { printf("DEBUG:: data label <$label> = <$val>\n"); }
    return ($val);
  } else {
    errorfile(); print(" read_label(): internal error - no label found ($label)\n"); exit;
  }
  return 0;
}

######################################################################################
sub remove_label {
  my ($label) = @_ ;

  # check if already exists...
  if (defined($gcode_label{$label})) {
      delete($gcode_label{$label});
  } else {
      errorfile(); print("remove_label(): tried to remove non-existant label ($label)\n"); exit;
  }
}

######################################################################################
#sub update_label {
#  my ($label,$labpc) = @_ ;
#
#  # check if already exists...
#  if (defined($gcode_label{$label})) {
#      $gcode_label{$label}=$labpc;
#  } else {
#      errorfile();
#      print(" update_label(): tried to remove non-existant label ($label)\n"); exit;
#  }
#}
#
######################################################################################
#
# In the 0th pass we just want to build up a list of valid labels
# We can do basic checks to confirm that any label hasn't been defined twice
#
sub store_pc_label {
  my ($label,$labpc) = @_ ;

  # check if already exists...
  if (defined($gcode_label{$label})) {
    # yes...
    if ($gpass==0) {
      my $line=$gcode_label_defline{$label};
      errorfile(); print(" store_pc_label(): label ($label) already defined \n"); exit;
    } else {
      # update value...
      my $oldpc=$gcode_label{$label};
      if ($labpc != $oldpc) {
if ($DEBUG>10) { printf("UPDATING LABEL: new PC=%08X old PC=%08X  LABEL=%s\n",$labpc,$oldpc,$label); }
        $glabel_updates++;
      }
      $gcode_label{$label}=$labpc; # update the label with the current value of PC
    }
  } else {
    # on the 0th pass store an estimated value
    $gcode_label{$label}=$labpc; # save the label and current value of PC
    $gcode_label_defline{$label}=$gasm_filelineno[$gline]; # save the line number found on
if ($DEBUG>30) { printf("ESTIMATED LABEL: PC=%08X LABEL=%s\n",$labpc,$label); }
  }
}

######################################################################################
#
# In the 0th pass we just want to build up a list of valid DSECT labels/offsets
# We can do basic checks to confirm that any label hasn't been defined twice
#
sub store_dsect_label {
  my ($label,$labdsect) = @_ ;

  # check if already exists...
  if (defined($gdsect_label{$label})) {
    # yes...
    if ($gpass==0) {
      my $line=$gdsect_label_defline{$label};
      errorfile(); print(" store_dsect_label(): data section label ($label) already defined \n"); exit;
    } else {
      # update value...
      my $olddsect=$gdsect_label{$label};
      if ($labdsect != $olddsect) {
if ($DEBUG>10) { printf("STORING DSECT LABEL: new PC=%08X old PC=%08X  LABEL=%s\n",$labdsect,$olddsect,$label); }
        $glabel_updates++;
      }
      $gdsect_label{$label}=$labdsect; # update the label with the current value of PC
    }
  } else {
    # on the 0th pass store an estimated value
    $gdsect_label{$label}=$labdsect; # save the label and current value of PC
    my $ln=$gasm_filelineno[$gline];
    $gdsect_label_defline{$label}=$ln; # save the line number found on
if ($DEBUG>30) { printf("ESTIMATED DSECT LABEL: PC=%08X LABEL=%s\n",$labdsect,$label); }
  }
}

######################################################################################
#
# In the 0th pass we just want to build up a list of valid SB labels/offsets
# We can do basic checks to confirm that any label hasn't been defined twice
#
sub store_sb_label {
  my ($label,$labsb) = @_ ;

  # check if already exists...
  my $exists=exists_label($label);

  if ($exists==0) {
    # on the 0th pass store an estimated value
    $gsb_label{$label}=$labsb; # save the label and current value of PC
    my $ln=$gasm_filelineno[$gline];
    $gsb_label_defline{$label}=$ln; # save the line number found on
    if ($DEBUG>30) { printf("\nESTIMATED SB LABEL: PC=%08X LABEL=%s\n",$labsb,$label); }
    return;
  } elsif ($exists==SYMBOL_SB) {
    # yes...
    if ($gpass==0) {
      my $line=$gsb_label_defline{$label};
      errorfile(); printf(" static base symbol <$label> previously defined in line $line\n"); exit;
    } else {
      # update value...
      my $oldsb=$gsb_label{$label};
      if ($labsb != $oldsb) {
        if ($DEBUG>10) { printf("STORING SB LABEL: new PC=%08X old PC=%08X  LABEL=%s\n",$labsb,$oldsb,$label); }
        $glabel_updates++;
      }
      $gsb_label{$label}=$labsb; # update the label with the current value of PC
      return;
    }
  } else {
    redefined($label);
  }

}

######################################################################################
#
# In the 0th pass we just want to build up a list of valid FP labels/offsets
# We can do basic checks to confirm that any label hasn't been defined twice
#
sub store_fp_label {
  my ($label,$labfp) = @_ ;

  # check if already exists...
  if (defined($gfp_label{$label})) {
    # yes...
    if ($gpass==0) {
      my $line=$gfp_label_defline{$label};
      errorfile(); print(" store_fp_label(): frame pointer label ($label) already defined \n"); exit;
    } else {
      # update value...
      my $oldfp=$gfp_label{$label};
      if ($labfp != $oldfp) {
if ($DEBUG>10) { printf("STORING FP LABEL: new PC=%08X old PC=%08X  LABEL=%s\n",$labfp,$oldfp,$label); }
        $glabel_updates++;
      }
      $gfp_label{$label}=$labfp; # update the label with the current value of PC
    }
  } else {
    # on the 0th pass store an estimated value
    $gfp_label{$label}=$labfp; # save the label and current value of PC
    my $ln=$gasm_filelineno[$gline];
    $gfp_label_defline{$label}=$ln; # save the line number found on
if ($DEBUG>30) { printf("\nESTIMATED FP LABEL: PC=%08X LABEL=%s\n",$labfp,$label); }
  }
}

######################################################################################
sub dump_identifiers {
  my ($dest)=@_;

  if ($dest==1) { print("\nIDENTIFIER DUMP\n"); print("\n***************\n"); }
  if ($dest==2) { print(LIST "\nIDENTIFIER DUMP\n"); print(LIST "\n***************\n"); }
  foreach my $t (sort {$gidentifier{$a} <=> $gidentifier{$b} } keys %gidentifier) {
  #foreach my $t (keys %gidentifier) {
    my $x=(0+$gidentifier{$t})&0xffffffff;
    if ($dest==1) { printf("%08X %s\n",$x,$t); }
    if ($dest==2) { printf(LIST "%08X %s\n",$x,$t); }
  }
}

######################################################################################
#
sub dump_labels {
  my ($dest)=@_;

  if ($dest==1) { print("\nLABEL DUMP\n"); print  ("**********\n"); }
  if ($dest==2) { print(LIST "\nLABEL DUMP\n"); print  (LIST "**********\n"); }
  foreach my $t (sort {$gcode_label{$a} <=> $gcode_label{$b} } keys %gcode_label) {
    my $x=(0+$gcode_label{$t})&0xffffffff;
    if ($dest==1) { printf("%08X %s\n",$x,$t); }
    if ($dest==2) { printf(LIST "%08X %s\n",$x,$t); }
  }
}

######################################################################################
#
sub dump_fp_labels {
  my ($dest)=@_;

  if ($dest==1) { print("\nFP OFFSET DUMP\n"); print  ("**************\n"); }
  if ($dest==2) { print(LIST "\nFP OFFSET DUMP\n"); print  (LIST "**************\n"); }
  foreach my $t (sort {$gfp_label{$a} <=> $gfp_label{$b} } keys %gfp_label) {
    my $x=(0+$gfp_label{$t})&0xffffffff;
    if ($dest==1) { printf("%08X %s\n",$x,$t); }
    if ($dest==2) { printf(LIST "%08X %s\n",$x,$t); }
  }
}

######################################################################################
#
sub dump_sb_labels {
  my ($dest)=@_;

  if ($dest==1) { print("\nSB OFFSET DUMP\n"); print  ("**************\n"); }
  if ($dest==2) { print(LIST "\nSB OFFSET DUMP\n"); print  (LIST "**************\n"); }
  foreach my $t (sort {$gsb_label{$a} <=> $gsb_label{$b} } keys %gsb_label) {
    my $x=(0+$gsb_label{$t})&0xffffffff;
    if ($dest==1) { printf("%08X %s\n",$x,$t); }
    if ($dest==2) { printf(LIST "%08X %s\n",$x,$t); }
  }
}

######################################################################################
#
sub dump_dsect_labels {
  my ($dest)=@_;

  if ($dest==1) { print("\nDSECT OFFSET DUMP\n"); print  ("*****************\n"); }
  if ($dest==2) { print(LIST "\nDSECT OFFSET DUMP\n"); print  (LIST "*****************\n"); } 
  foreach my $t (sort {$gdsect_label{$a} <=> $gdsect_label{$b} } keys %gdsect_label) {
    my $x=(0+$gdsect_label{$t})&0xffffffff;
    if ($dest==1) { printf("%08X %s\n",$x,$t); }
    if ($dest==2) { printf(LIST "%08X %s\n",$x,$t); }
  }
}

######################################################################################
sub store_identifier {
  my ($id,$v,$ok) = @_;

  my $exists=exists_label($id);

if ($DEBUG>75) { print ">>>store_identifier($id,$v,$ok) exists=$exists // "; }

  if ($exists==0) {
    # no... so add it to the global indentifier structure...
    $gidentifier{$id}=(0+$v)&0xffffffff;
    $gidentifier_defined{$id}=$ok;
    my $ln=$gasm_filelineno[$gline];
    $gidentifier_defline{$id}=$ln;
    return;
  }

  if ($exists==SYMBOL_EQU) {
    if ($gpass==0) {
      my $line=$gidentifier_defline{$id};
      errorfile(); printf(" identifier <$id> previously defined in line $line\n"); exit;
    } else {
      if (defined_label($id)==OKUNDEF) {
        # update now that the value is known
        $gidentifier{$id}=(0+$v)&0xffffffff;
        $gidentifier_defined{$id}=$ok;
      }
      return;
    }
  } 

  redefined($id);
}

######################################################################################
sub redefined {
  my ($symbol) = @_;

  my $exists=exists_label($symbol);

  my $t;
  my $line;
  if ($exists==1) { $t="code label";       $line=$gcode_label_defline   {$symbol}; }
  if ($exists==2) { $t="data section";     $line=$gdsect_label_defline  {$symbol}; }
  if ($exists==3) { $t="static base";      $line=$gsb_label_defline     {$symbol}; }
  if ($exists==4) { $t="frame pointer";    $line=$gfp_label_defline     {$symbol}; }
  if ($exists==5) { $t="equate";           $line=$gidentifier_defline   {$symbol}; }
  if ($exists==6) { $t="import procedure"; $line=$gimportp_label_defline{$symbol}; }
  if ($exists==7) { $t="import variable";  $line=$gimport_label_defline {$symbol}; }
  errorfile(); printf(" symbol <$symbol> previously defined as type $t in line $line\n"); exit;
}

######################################################################################
sub store_double {
  my ($double)=@_;
  my ($msb,$xsb,$ysb,$lsb);
  
  if ($DEBUG>21) { printf("STORE DOUBLE @%08X %02X %02X %02X %02X\n",$gpc,$msb,$xsb,$ysb,$lsb); } 
  my $lsb=(($double&0x000000ff)>>0 )&0xff; $gcode[$gpc]=$lsb; inc_gpc();
  my $ysb=(($double&0x0000ff00)>>8 )&0xff; $gcode[$gpc]=$ysb; inc_gpc();
  my $xsb=(($double&0x00ff0000)>>16)&0xff; $gcode[$gpc]=$xsb; inc_gpc();
  my $msb=(($double&0xff000000)>>24)&0xff; $gcode[$gpc]=$msb; inc_gpc();
  #$gdouble_data[$gdouble_data_count++]=(256*256*256*$lsb)+(256*256*$ysb)+(256*$xsb)+$msb; # reverse for log file as word is stored little endian
}

######################################################################################
sub store_word {
  my ($word)=@_;
  my ($msb,$lsb);
  
  if ($DEBUG>21) { printf("STORE WORD @%08X %02X %02X\n",$gpc,$msb,$lsb); } 
  my $lsb=(($word&0x00ff)>>0 )&0xff; $gcode[$gpc]=$lsb; inc_gpc();
  my $msb=(($word&0xff00)>>8 )&0xff; $gcode[$gpc]=$msb; inc_gpc();
  #$gword_data[$gword_data_count++]=(256*$lsb)+$msb; # reverse for log file as word is stored little endian
}

######################################################################################
sub store_byte {
  my ($byte)=@_;
  
  if ($DEBUG>21) { printf("STORE BYTE @0x%08X 0x%02X\n",$gpc,$byte); } 
  $gcode[$gpc]=$byte; inc_gpc();
}

######################################################################################
sub process_double_data {
  my ($whitespace,$text)=@_;
  my $ocnt=0;
  my $outtext;

  if ($whitespace eq "") {
    errorfile(); print " invalid expression after .double assembler directive\n"; exit;
  }

  my $double_data_count=0;
  my $pc=$gpc; #remember the current PC position
  my $rem=$text;
  my $going=1;
  while ($going) {
    my ($ok,$double,$zz)=expr($text);
    if ($ok>0) {
      $double=($double+0)&0xffffffff;
      store_double($double);
      $double_data_count++;
    } else {
      errorfile(); print " invalid expression after .double assembler directive\n"; exit;
    }
    $text=$zz;
    $text =~ s/^\s+//; # strip leading whitespace
    if ($text eq "") { $going=0; next; }
    #check for comma
    if ($text =~ /(,?)\s*(.*)/) {
      if ($1 eq ",") {
        $text=$2;
        if ($text eq "") { $going=0; next; }
        next;
      }
    }
    if ($text =~ /^;/) { 
      $going=0; next;
    } else {
      errorfile(); print " invalid expression after .double assembler directive\n"; exit;
    }
  }
  if ($gpass!=99) { return; }

  $ocnt += print_word_byte_data($pc,$double_data_count,4);

}

######################################################################################
sub process_word_data {
  my ($whitespace,$text)=@_;

  my $ocnt=0;
  my $outtext;

  if ($whitespace eq "") {
    errorfile(); print " invalid expression after .word assembler directive\n"; exit;
  }

  my $word_data_count=0;
  my $pc=$gpc; #remember the current PC position
  my $rem=$text;
  my $going=1;
  while ($going) {
    my ($ok,$word,$zz)=expr($text);
    if ($ok>0) {
      $word=($word+0)&0xffff;
      store_word($word);
      $word_data_count++;
    } else {
      errorfile(); print " invalid expression after .word assembler directive\n"; exit;
    }
    $text=$zz;
    $text =~ s/^\s+//; # strip leading whitespace
    if ($text eq "") { $going=0; next; }
    #check for comma
    if ($text =~ /(,?)\s*(.*)/) {
      if ($1 eq ",") {
        $text=$2;
        if ($text eq "") { $going=0; next; }
        next;
      }
    }
    if ($text =~ /^;/) { 
      $going=0; next;
    } else {
      errorfile(); print " invalid expression after .word assembler directive\n"; exit;
    }
  }
  if ($gpass!=99) { return; }

  $ocnt += print_word_byte_data($pc,$word_data_count,2);

}

######################################################################################
sub process_byte_data {
  my ($text)=@_;
  my $ocnt=0;
  my $outtext;

#if ($DEBUGL>0) { print LIST "[process_byte_data]($text)\n"; }

  my $byte_data_count=0;
  my $pc=$gpc; #remember the current PC position
  my $rem=$text;

  my $going=1;
  while ($going) {

    # check for string (enclosed in double quotes)
    # need to prevent regexp being greedy
    if ($text =~ /^\s*"(.*?)"(\s*)(,?)(.*)/) {
      my $string=$1;
      my $separator=$3;
      $rem=$4; 
      for my $ch (split //,$string) { 
        store_byte(ord($ch)); 
        $byte_data_count++;
      }
      $text=$rem;
      $text =~ s/^\s+//; # strip leading whitespace
      if ($text eq "")   { $going=0; next; }
      if ($text =~ /^;/) { $going=0; next; }
      next; 
    }
    # single quotes for NS compatibility
    if ($text =~ /^\s*'(.*?)'(\s*)(,?)(.*)/) {
      my $string=$1;
      my $separator=$3;
      $rem=$4; 
      for my $ch (split //,$string) { 
        store_byte(ord($ch)); 
        $byte_data_count++;
      }
      $text=$rem;
      $text =~ s/^\s+//; # strip leading whitespace
      if ($text eq "")   { $going=0; next; }
      if ($text =~ /^;/) { $going=0; next; }
      next; 
    }

    # if not a string then we expect an expression...
    my ($ok,$byte,$zz)=expr($text);
    if ($ok>0) {
      store_byte(($byte+0)&0xff);
      $byte_data_count++;
    } else {
      errorfile(); print " invalid expression after .byte assembler directive\n"; exit;
    }
    $text=$zz;
#if ($DEBUG>0) { print "[process_byte_data]text=($text)\n"; }
    $text =~ s/^\s+//; # strip leading whitespace
    if ($text eq "") { $going=0; next; }
    #check for comma
#if ($DEBUG>0) { print "[process_byte_data]text=($text)\n"; }
    if ($text =~ /(,?)\s*(.*)/) {
      if ($1 eq ",") {
        $text=$2;
        if ($text eq "") { $going=0; next; }
        next;
      }
    }
    if ($text =~ /^;/) { 
      $going=0; next;
    } else {
      errorfile(); print " invalid expression after .byte assembler directive (...$text)\n"; exit;
    }
  }
  if ($gpass!=99) { return; }

  ###############
  # GPASS == 99 #
  ###############
  
  $ocnt += print_word_byte_data($pc,$byte_data_count,1);

}

######################################################################################
sub process_field_data {
  my ($text)=@_;

  my $ocnt=0;
  my $outtext;
  my $rem;

if ($DEBUG>25) { print "process_field_data(): ($text)\n\n"; }

  my $byte_data_count=0;
  my $pc=$gpc; #remember the current PC position

  my $bitcount=0;
  my $fieldvalue=0;

  my $going=1;
  while ($going==1) {

    # check for string (enclosed in double quotes)
    # need to prevent regexp being greedy
    if ($text =~ /^\s*\[\s*([^\]]*)\s*\]\s*([^,]*)\s*(,?)\s*(.*)$/) {
      my $repeat=$1;
      my $value=$2;
      my $separator=$3;
      $rem=$4; 


      if ($separator ne ',') {
        $going=0;
      }
      $text=$rem;

      # get repeat value 
      my ($ok,$repeatcnt,$rem)=expr($repeat);
      if ($ok>0) {
        #store_byte(($byte+0)&0xff);
        #$byte_data_count++;
      } else {
        errorfile(); print " invalid expression after .field assembler directive\n"; exit;
      }
      # get bit field value 
      my ($ok,$bitfield,$rem)=expr($value);
      if ($ok>0) {
        $fieldvalue=$fieldvalue+($bitfield<<$bitcount);
        $bitcount+=$repeatcnt;
        #store_byte(($byte+0)&0xff);
        #$byte_data_count++;
      } else {
        errorfile(); print " invalid expression after .field assembler directive\n"; exit;
      }

if ($DEBUG>50) { printf("\nFIELD: %X ($repeat)($value)($separator)($rem)\n",$fieldvalue); }

    }
    else { 
      errorfile(); print " invalid expression after .field assembler directive\n"; exit;
    }
  }

  $bitcount=$bitcount+8;
  while ($bitcount>8) {
    my $byte=($fieldvalue+0)&0xff;
    store_byte($byte); 
#if ($DEBUG>0) { printf("BYTE=%02X\n",$byte); }
    $byte_data_count++;
    $fieldvalue=($fieldvalue+0)>>8;
    $bitcount=$bitcount-8;
  }
  if ($gpass!=99) { return; }

  ###############
  # GPASS == 99 #
  ###############
  
  $ocnt += print_word_byte_data($pc,$byte_data_count,1);

}

######################################################################################
sub find_label {
   
  my $asm;
  my $rawasm;
  my $Label="";
  my $Comment="";
  my $valid_label;

  $gpc=0; # if no org assume code assembled at 0
  $gdsectpc=0; # if no org assume code assembled at 0
  $gsbpc=0;

  $gimport_count=0;

  $gcode_section=1;
  $gdata_section=0;
  $gstatic_section=0;
  $gframe_section=0;
  $gparam_section=0;
  $greturn_section=0;
  $glocal_section=0;

  undef %gmodule_exports;

  for ($gline=1;$gline<=$gasm_text_cnt;$gline++) {

    $asm = $gasm_text[$gline];
    $rawasm=$asm;
    my $flfi=$gasm_fileindex[$gline];
    my $flln=$gasm_filelineno[$gline];
    my $flfn= $gasm_filelist[$flfi-1];

    #######################################
if ($DEBUG>1) { 
  print "\n]]]]]find_label():file=$flfn,line=$flln,code=$rawasm\n"; 
}
    $Label="";
    $valid_label=0;
    $Comment="";
    # skip blank lines
    if ($asm =~ /^\s*$/) { 
      next; 
    }
    # comment only...
    if ($asm =~ /^\s*;(.*)/) { 
      $gout_text[$gline]=$1;
      next; 
    }

    #######################################
    # split a line into optional label, optional mnemonic and optional comment
    #######################################

    # allow spaces in front of labels...(to be reviewed)
    if ($asm =~ /^\s*([A-Z]\w*)::?\s*(.*)/i) {
      $Label=$1;
      $asm=$2;             # assembly text minus label part
      $valid_label=1;

      if ( ($asm !~ /^\s*\.blk[bdw]\b/i) && ($asm !~ /^\s*\.equ\b/i) ) {
        store($Label);
      }
      # need better check that label is valid
    } 


    $asm =~ s/^\s+//; # strip leading whitespace
    if ($asm eq "") { next; } # label only on this line
    if ($asm =~  /^\s*;/) { next; } # label plus comment on this line

    ###############
    # .import <list>
    ################
    if ($asm =~ /^\.import\b\s*(.*)$/i) {
      my $import_list=$1." ;";
      if ($import_list =~ /^\s*;.*$/) {
        errorfile(); print " expected list of import objects\n"; exit;
      }
      while ($import_list !~ /^\s*;.*$/) {
        my $import;
        if ($import_list =~ /^(\w+)(\s*,\s*)?(.*)?$/) {
          $import=$1;
          store_import($import);
          my $import_comma=$2;
          my $import_rem=$3;
          if (defined($import_comma)) {
             $import_list=$import_rem;
             next;
          } else {
            ###if ($import_rem =~ /^\s*$/) { last; }
            if ($import_rem =~ /^\s*;.*$/) { last; }
            errorfile(); print " expected import identifier separator but found ($import_rem)\n"; exit;
          }
        } else {
          errorfile(); print " expected import identifier but found ($import_list)\n"; exit;
        }
      }
      next;
    }

    ###################
    # .importp <list>
    ###################
    if ($asm =~ /^\.importp\b\s*(.*)$/i) {
      my $import_list=$1." ;";
      if ($import_list =~ /^\s*;.*$/) {
        errorfile(); print " expected list of import objects\n"; exit;
      }
      while ($import_list !~ /^\s*;.*$/) {
        my $import;
        if ($import_list =~ /^(\w+)(\s*,\s*)?(.*)?$/) {
          $import=$1;
          store_importp($import);
          my $import_comma=$2;
          my $import_rem=$3;
          if (defined($import_comma)) {
             $import_list=$import_rem;
             next;
          } else {
            ###if ($import_rem =~ /^\s*$/) { last; }
            if ($import_rem =~ /^\s*;.*$/) { last; }
            errorfile(); print " expected import identifier separator but found ($import_rem)\n"; exit;
          }
        } else {
          errorfile(); print " expected import identifier but found ($import_list)\n"; exit;
        }
      }
      next;
    }

    #########
    # .export
    #########
    if ($asm =~ /^\.export\b/i) {
      next;
    }

    ##########
    # .exportp
    ##########
    if ($asm =~ /^\.exportp\b(.*)(;.*)?/i) {
      my $module_name=$1;
      $module_name =~ s/^\s*//;    # strip leading whitespace
      $module_name =~ s/\s*$//;    # strip trailing whitespace
      if (defined($gmodule_exports{$module_name})) {
        errorfile(); print(" module already defined\n"); exit;
      }
      $gmodule_exports{$module_name}=0;
      next;
    }

    ###################
    # .module 
    ###################
    if ($asm =~ /^\.module\b/i) {
      next;
    }

    ###################
    # .proc 
    ###################
    if ($asm =~ /^\.proc\b/i) {
      $gfppc=0;
      undef %gfp_label_defline;
      undef %gfp_label;

      $gcode_section=0;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=1;
      $gparam_section=1;
      $greturn_section=0;
      $glocal_section=0;

      # paramters to the proc
      $greturnlength=0;
      $glocallength=0;
      $gparamlength=0;
      $gparamcount=0;
      undef @gparamname;
      undef @gparamoffset;
      next;
    }

    ###################
    # .returns 
    ###################
    if ($asm =~ /^\.returns\b/i) {

      $gcode_section=0;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=1;
      $gparam_section=0;
      $greturn_section=1;
      $glocal_section=0;

      if ($glabeltype eq "INT") { $gfppc=$gparamlength+8; } else { $gfppc=$gparamlength+12; }
      next;
    }

    ###################
    # .endproc 
    ###################
    if ($asm =~ /^\.endproc\b/i) {
      next;
    }

    ###################
    # .var 
    ###################
    if ($asm =~ /^\.var\b/i) {

      $gcode_section=0;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=1;
      $gparam_section=0;
      $greturn_section=0;
      $glocal_section=1;

      next;
    }

    ###################
    # .begin 
    ###################
    if ($asm =~ /^\.begin\b/i) {

      $gcode_section=1;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=0;
      $gparam_section=0;
      $greturn_section=0;
      $glocal_section=0;
if ($DEBUG>25) { print("@@@@@ BEGIN: ret=$greturnlength, local=$glocallength, param=$gparamlength, paramcnt=$gparamcount, \n"); }
       if ($DEBUG>25) { dump_fp_labels(1); }
      next;
    }

    ###################
    # .subtitle <string>
    ###################
    if ($asm =~ /^\.subtitle\b/i) {
      next;
    }

    ###################
    # .width <integer>
    ###################
    if ($asm =~ /^\.width\b/i) {
      next;
    }

    ##################
    # .list
    ##################
    if ($asm =~ /^\.list\b/i) {
      next;
    }

    ########
    # .eject
    ########
    if ($asm =~ /^\.eject\b/i) {
      next;
    }

    ########
    # .align 
    ########
    if ($asm =~ /^\s*\.align\b\s*(.*)$/i) {
      my $expr1; my $expr2;
      my $match=$1;
      my $str1; my $str2;
      my $ok1; my $ok2;
      my $rem1; my $rem2;
      if ($match =~ /^\s*(.*)\s*,\s*(.*)\s*$/) {
        $str1=$1;$str2=$2;
        ($ok1,$expr1,$rem1)=expr($str1);
        ($ok2,$expr2,$rem2)=expr($str2);
      } elsif ($match =~ /^\s*$/) {
        errorfile(); print(" expected expression(s) in ALIGN pseudo-op\n"); exit;
      } elsif ($match =~ /^\s*;.*$/) {
        errorfile(); print(" expected expression(s) in ALIGN pseudo-op\n"); exit;
      } elsif ($match =~ /^\s*(.*)\s*$/) {
        $str1=$1;
        ($ok1,$expr1,$rem1)=expr($str1); $expr2=0;
      } else {
        errorfile(); print(" expected expression(s) in ALIGN pseudo-op\n"); exit;
      }
if ($DEBUG>25) { print "ALIGN ($expr1) ($expr2) \n"; }
      if ($gdata_section==1)   { $gdsectpc=doalign($gdsectpc,$expr1,$expr2); }
      if ($gstatic_section==1) { $gsbpc=doalign($gsbpc,$expr1,$expr2); }
      if ($gcode_section==1)   { $gpc=doalign($gpc,$expr1,$expr2); }
      if ($gframe_section==1)  { $gfppc=doalign($gfppc,$expr1,$expr2); }
      next;
    }

    ##########
    # .program
    ##########
    if ($asm =~ /^\.program\b/i) {

      $gcode_section=1;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=0;
      $gparam_section=0;
      $greturn_section=0;
      $glocal_section=0;

      next;
    }

    #########
    # .static
    #########
    if ($asm =~ /^\.static\b/i) {

      $gcode_section=0;
      $gdata_section=0;
      $gstatic_section=1;
      $gframe_section=0;
      $gparam_section=0;
      $greturn_section=0;
      $glocal_section=0;

      next;
    }

    ###################
    # .dsect expression
    ###################
    if ($asm =~ /^\.dsect\b\s*(.*)/i) {
      my $remainder=$1;
      if (($remainder =~ /^\s*$/)||($remainder =~ /i^\s*;(.*)$/)) {
        $asm="";
        $gstart_dsectpc=$gdsectpc; # remember address of start of this section (needed for $)

        $gcode_section=0;
        $gdata_section=1;
        $gstatic_section=0;
        $gframe_section=0;
        $gparam_section=0;
        $greturn_section=0;
        $glocal_section=0;

        next;
      } else {
        errorfile(); print " unexpected text after .dsect assembler directive\n"; exit;
      }
    }

    ###################
    # .endseg expression
    ###################
    if ($asm =~ /^\.endseg\s*(.*)/i) {
      my $remainder=$1;
      if (($remainder =~ /^\s*$/)||($remainder =~ /i^\s*;(.*)$/)) {
        $asm="";

        $gcode_section=1;
        $gdata_section=0;
        $gstatic_section=0;
        $gframe_section=0;
        $gparam_section=0;
        $greturn_section=0;
        $glocal_section=0;

        next;
      } else {
        errorfile(); print " unexpected text after .endseg assembler directive\n"; exit;
      }
    }

    #################
    # .org expression
    #################
    if ($asm =~ /^\.org\b(.*)/i) {
      my $remainder=$1;
      $remainder =~ s/^\s*//; # remove leading whitespace
      if (($remainder =~ /^\s*$/)||($remainder =~ /^\s*;(.*)$/)) {
        errorfile(); print(" expected integer expression after .org \n"); exit;
      }
      my ($ok,$org,$remainder2)=expr($remainder);
      if ($ok==0) {
        errorfile(); print " invalid expression after .org assembler directive\n"; exit;
      }
      if (($remainder2 =~ /^\s*$/)||($remainder2 =~ /^\s*;(.*)$/)) {
if ($DEBUG>1) { print ">>>>>ORG=$org\n"; }  
        $gpc=$org;
        next;
      } else {
        errorfile();
        printf(" unexpected text at end of .org line\n"); #ERROR#
      }
    }

    ####################
    # .ramorg expression
    ####################
    if ($asm =~ /^\.ramorg\b(.*)/i) {
      my $remainder=$1;
      $remainder =~ s/^\s*//; # remove leading whitespace
      if (($remainder =~ /^\s*$/)||($remainder =~ /^\s*;(.*)$/)) {
        errorfile(); printf(" expected integer expression after .ramorg \n"); exit;
      }
      my ($ok,$ramorg,$remainder2)=expr($remainder);
      if ($ok==0) {
        errorfile(); print " invalid expression after .ramorg assembler directive\n"; exit;
      }
      if (($remainder2 =~ /^\s*$/)||($remainder2 =~ /^\s*;(.*)$/)) {
if ($DEBUG>1) { print ">>>>>RAMORG=$ramorg\n"; }  
        $gdsectpc=$ramorg;
        next;
      } else {
        errorfile();
        printf(" unexpected text at end of .ramorg line\n"); #ERROR#
      }
    }

    ####################
    # .sborg expression
    ####################
    if ($asm =~ /^\.sborg\b(.*)/i) {
      my $remainder=$1;
      $remainder =~ s/^\s*//; # remove leading whitespace
      if (($remainder =~ /^\s*$/)||($remainder =~ /^\s*;(.*)$/)) {
        errorfile(); printf(" expected integer expression after .sborg \n"); exit;
      }
      my ($ok,$sborg,$remainder2)=expr($remainder);
      if ($ok==0) {
        errorfile(); print " invalid expression after .sborg assembler directive\n"; exit;
      }
      if (($remainder2 =~ /^\s*$/)||($remainder2 =~ /^\s*;(.*)$/)) {
if ($DEBUG>1) { print ">>>>>SBORG=$sborg\n"; }  
        #$gsbpc=$sborg;
        next;
      } else {
        errorfile();
        printf(" unexpected text at end of .sborg line\n"); #ERROR#
      }
    }

    #########
    # .field 
    #########
    if ($asm =~ /^\.field\b(.*)/i) {
if ($DEBUG>25) { print ".FIELD\n"; }
      process_field_data($1);
      next;
    }

    ####################
    # .blkb expression
    ####################
    if ($asm =~ /^\.blkb\s*(.*)/i) {
      my $remainder=$1;
      if (($remainder =~ /^\s*$/) || ($remainder =~ /^\s*;/)) {

        if ($valid_label==1) { # check for  associated label - if no value default value is 1
          store_and_inc($Label,1,1);
          next;
        }
        inc_pc(1);
        next;
      }
      my ($ok,$blkb,$remainder)=expr($1);
      if ($ok==0) {
        errorfile(); print " invalid expression after .blkb assembler directive\n"; exit;
      }
      if (($remainder =~ /\s*(.*)$/)||($remainder =~ /\s*;\s*(.*)$/)) {
        if ($valid_label==1) { # check for  associated label
          store_and_inc($Label,$blkb,1);
          next;
        }
        inc_pc($blkb);
        next;
      } else {
        errorfile(); printf(" unexpected text at end of .blkb line\n"); exit;
      }
    }

    ####################
    # .blkw expression
    ####################
    if ($asm =~ /^\.blkw\s*(.*)/i) {
      my $remainder=$1;
      if (($remainder =~ /^\s*$/) || ($remainder =~ /^\s*;/)) {

        if ($valid_label==1) { # check for  associated label - if no value default value is 2
          store_and_inc($Label,1,2);
          next;
        }
        inc_pc(2);
        next;
      }
      my ($ok,$blkw,$remainder)=expr($1);
      if ($ok==0) {
        errorfile(); print " invalid expression after .blkw assembler directive\n"; exit;
      }
      if (($remainder =~ /\s*(.*)$/)||($remainder =~ /\s*;\s*(.*)$/)) {
        if ($valid_label==1) { # check for  associated label
          store_and_inc($Label,$blkw,2);
          next;
        }
        inc_pc(2*$blkw);
        next;
      } else {
        errorfile(); printf(" unexpected text at end of .blkw line\n"); exit;
      }
    }
    ####################
    # .blkd expression
    ####################
    if ($asm =~ /^\.blkd\s*(.*)/i) {
      my $remainder=$1;
      if (($remainder =~ /^\s*$/) || ($remainder =~ /^\s*;/)) {

        if ($valid_label==1) { # check for  associated label - if no value default value is 4
          store_and_inc($Label,1,4);
          next;
        }
        inc_pc(4);
        next;
      }
      my ($ok,$blkd,$remainder)=expr($1);
      if ($ok==0) {
        errorfile(); print " invalid expression after .blkd assembler directive\n"; exit;
      }
      if (($remainder =~ /\s*(.*)$/)||($remainder =~ /\s*;\s*(.*)$/)) {
        if ($valid_label==1) { # check for  associated label
          store_and_inc($Label,$blkd,4);
          next;
        }
        inc_pc(4*$blkd);
        next;
      } else {
        errorfile(); printf(" unexpected text at end of .blkd line\n"); exit;
      }
    }

    ####################
    # .double expression
    ####################
    if ($asm =~ /^\s*\.double(\s*)(.*)/i) {
      process_double_data($1,$2);
      next;
    }
    ####################
    # .word expression
    ####################
    if ($asm =~ /^\s*\.word(\s*)(.*)/i) {
      process_word_data($1,$2);
      next;
    }
    ####################
    # .dc.l expression 
    ####################
    if ($asm =~ /^\s*dc.l(\s*)(.*)/i) {
      process_word_data($1,$2);
      next;
    }
    ##################
    # .byte expression
    ##################
    if ($asm =~ /^\s*\.byte\s+(.*)/i) {
if ($DEBUG>25) { print ".BYTE\n"; }
      process_byte_data($1);
      next;
    }
    ##################
    # dc.b expression 
    ##################
    if ($asm =~ /^\s*dc\.b\s+(.*)/i) {
      process_byte_data($1);
      next;
    }

    ################################
    # identifier: .equ expression
    ################################
    if ($asm =~ /^\s*\.equ\s+(.*)/i) {
      my ($ok,$v,$zz)=expr($1);
      if ($ok==NOTOK) {
        errorfile(); print " invalid expression after .EQU assembler directive\n"; exit;
      }
      if (($zz =~ /^\s*$/)||($zz =~ /^\s*;.*$/)) {
        # store identifier in list
        if ($gexprtype eq "SB") { 
          store_sb_label($Label,$v); 
        } else {
          store_identifier($Label,$v,$ok);
        }
if ($DEBUG>25) { printf("      : %08x equ %s\n",$v,$Label); }
        next;
      } else {
        errorfile(); print " unexpected text <$zz> at end of equ line\n"; exit;
      }
      # can never reach here!
    }
    # quick check to see if this is a valid instruction...
    # use the instruction look up table...
    my $searching=1; # flag to terminate loop early
    my $iset_idx=0;  # index into the instruction set struct
    my $iset_ptr;    # pointer to various fields
    my $iset_regexp; # opcode regexp
    my $found=0;

if ($DEBUG>100) { print("checking instruction ($asm)\n"); }

    while ($searching==1) {
      $iset_ptr=$instruction_set[$iset_idx]; # get pointer first
      $iset_regexp=$iset_ptr->{ins};         # get regexp
      if ($asm =~ /$iset_regexp/i) {     # can we find a match?
        $gpc=$gpc+4; # default number of bytes assumed per instruction
        $found=1;
        last;
      }
      $iset_idx++;
      if ($iset_regexp eq "END") { $searching=0; }
    }
    if ($found==1) { next; }
    errorfile();
    # now check MMU instructions
    if ($asm =~ /RDVAL\s+/i) { next; }
    if ($asm =~ /WRVAL\s+/i) { next; }
    if ($asm =~ /MOVSU\s+/i) { next; }
    if ($asm =~ /MOVUS\s+/i) { next; }
    errorfile (); print(" Unexpected syntax ($asm) in ($rawasm)\n"); exit;

  }
}

######################################################################################
#
# this procedure reads the assembly source text a line at a time from a pre-loaded array
#
# first thing is to check for any label or comment
#
# an early check is for any assembler directive (no label or comment allowed)
#
# the label and comment are stripped off, and then the opcode and operands are extracted
#
# the instruction set structure is designed such that each opcocde is a Perl regexp
# a function searches for any match
# NOTE: I have chosen not to implement all instructions as some are rarely used and
#       I am unlikely to use them myself.
#

sub assemble {

  my $asm;
  my $directive;

  my $Comment;
  my $Label;
  my $Opcode;
  my $Bwdch;
  my $Flch;
  my $Bwd;
  my $Fl;
  my $Operands;
  my $Operand1;
  my $Operand2;
  my $Operand3; # not used for many instructions
  my $Operand4; # not used for many instructions
  my $Short;
  my $Cond;
  my $Gen;
  my $Gen1type; my $Genc1; my $Genv1; my $Genv11; my $Gen1SIReg; my $Gen1SIsz; my $Gen1SIOpcode;
  my $Gen2type; my $Genc2; my $Genv2; my $Genv22; my $Gen2SIReg; my $Gen2SIsz; my $Gen2SIOpcode;
  my $DispPc; my $DispPcSz;
  my $Disp; 
  my $DispSz;
  my $Dest; 
  my $DestSz;
  my $Reglist;
  my $Offset;
  my $Length;
  my $MOV_special;
  my $CVTP_EXT_reg;
  my $MMU_reg;
  my $valid_label;
  my $var_regs;
  

  $gpc=0; # if no org assume code assembled at 0
  $glabel_updates=0;
  undef @gcode; #empty code storage ready for new assembly pass
  $gpc_min=0xffffffff;
  $gpc_max=0;
  $gdsectpc=0;
  $gsbpc=0;

  $gcode_section=1;
  $gdata_section=0;
  $gstatic_section=0;
  $gframe_section=0;
  $gparam_section=0;
  $greturn_section=0;
  $glocal_section=0;

  $gendproc=0;
  $glabeltype="";
   
  for ($gline=1;$gline<$gasm_text_cnt;$gline++) {

    #############################
    $Gen1SIReg=-1; $Gen1SIsz="";
    $Gen2SIReg=-1; $Gen2SIsz="";
    $Gen1type=0; $Gen2type=0;
    $Genc1=0;
    $Genc2=0;
    $Genv1=0;
    $Genv2=0;
    $Genv11=0;
    $Genv22=0;

    $Gen1SIReg=0;$Gen1SIsz="";$Gen1SIOpcode=0;
    $Gen2SIReg=0;$Gen2SIsz="";$Gen2SIOpcode=0;

    $Fl=0;
    $Label="";
    $Comment="";
    #############################
    $asm = $gasm_text[$gline];
    my $rawasm=$asm;
    my $assfi=$gasm_fileindex[$gline];
    my $assln=$gasm_filelineno[$gline];
    my $assfn= $gasm_filelist[$assfi-1];
    #############################

    #############################
    # skip blank lines - quickly filter out
    if ($asm =~ /^\s*$/) { 
      if ($gpass==99) { 
        printf(LIST "				%6d\n",$assln); 
      }
      next; 
    }

    #############################
    # comment only... - quickly filter out
    if ($asm =~ /^\s*(;.*)/) { 
      $asm=$1;
      if ($gpass==99) { 
        printf(LIST "				%6d  %s\n",$assln,$rawasm); 
      }
      next; 
    }

if ($DEBUG>1) { 
    printf("\n###############################\nAssembling %s line %d PC=%08X <%s>\n",$assfn,$assln,$gpc,$asm); 
}

    ######################################################################################
    #
    # split a line into optional label, optional mnemonic and optional comment
    #
    $valid_label=0;
    my $labeltype;
    if ($asm =~ /^\s*([a-zA-Z]\w*):([:-]?)\s*(.*)/) {
      $Label=$1;
      $labeltype=$2;
      $asm=$3;             # assembly text minus label part
      $asm =~ s/^\s*//;    # strip leading whitespace
      $asm =~ s/\s*$//;    # strip trailing whitespace
      $valid_label=1;

      if ( ($asm !~ /^\s*\.blk[bdw]\b/i) && ($asm !~ /^\s*\.equ\b/i) ) {
        store($Label);
      }
      #if ($asm =~ /^\s*\.proc\b/i) {
      #  if ($labeltype eq ":") { $glabeltype="EXT"; } else { $glabeltype="INT"; }
      #}

    }

    # extract code and comment  - could be a problem if code contains ';' for example
    if ($asm =~ /^\s*(\.?\w+)\s+(.*)$/) {
      my $opcode=$1;
      my $operands=$2;
      my $code;
      ($code,$Comment)=parse_comment($operands);
      $code =~ s/\s*$//;    # strip trailing whitespace
if ($DEBUG>25) { print "OPCODECC =($code)($Comment)\n"; }
      $asm=$opcode." ".$code;
    }
    if ($asm =~ /^;/) { $asm=""; }
if ($DEBUG>25) { print "OPCODEASM=($asm)\n"; }

    #if ($asm =~ /^([^;]*)\s*;(.*)/) {
    #  $asm=$1;
    #  $Comment=$2;
    #}

    if ($asm eq "") {
      if ($gpass==99) {
        printf(LIST "				%6d  %s\n",$assln,$rawasm); 
      }
      next;
    }

    #######################################
    #
    # process assembler directives first...
    #
    #######################################

    #
    # .org expression
    #
    $asm =~ s/^\s*//;
    if ($asm =~ /\.org\s+(.*)/i) {
      my ($ok,$org,$zz)=expr($1);
      if ($ok==0) {
        errorfile(); print " invalid expression after .org assembler directive\n"; exit;
      }
      if (($zz =~ /\s*$/)||($zz =~ /\s*;.*$/)) {
if ($DEBUG>8) { print "ORG=$org\n"; } 
        if ($gpass==99) {
          print LIST "\n";
          my $ocnt=9; printf(LIST "%08X ",$org);  
          while ($ocnt<$outtab) { $ocnt++;  print LIST " "; }
          print LIST $asm."\n";
          if ($org==0) { $gpc_min=$org; }
          if (($gpc>0)&&($org>0)) { if ($gpc_min==0xffffffff) { $gpc_min=0; } } # no org statement at the start so 0 would have been assumed
          if ($org<$gpc_min) { $gpc_min=$org; }
        }
        $gpc=$org;
        next;
      } else {
        errorfile(); print " unexpected text at end of .org line\n"; exit;
      }
    }
    
    ####################
    # .ramorg expression
    ####################
    if ($asm =~ /^\.ramorg\b(.*)/i) {
      my $remainder=$1;
      $remainder =~ s/^\s*//; # remove leading whitespace
      if (($remainder =~ /^\s*$/)||($remainder =~ /^\s*;(.*)$/)) {
        errorfile(); printf(" expected integer expression after .ramorg \n"); exit;
      }
      my ($ok,$ramorg,$remainder2)=expr($remainder);
      if ($ok==0) {
        errorfile(); print " invalid expression after .ramorg assembler directive\n"; exit;
      }
      if (($remainder2 =~ /^\s*$/)||($remainder2 =~ /^\s*;(.*)$/)) {
        $gdsectpc=$ramorg;
        if ($gpass==99) {
          print LIST "\n";
          my $ocnt=9; printf(LIST "%08X ",$ramorg);  
          while ($ocnt<$outtab) { $ocnt++;  print LIST " "; }
          print LIST $asm."\n";
        }
        next;
      } else {
        errorfile(); printf(" unexpected text at end of .ramorg line\n"); exit;
      }
    }

    ####################
    # .sborg expression
    ####################
    if ($asm =~ /^\.sborg\b(.*)/i) {
      my $remainder=$1;
      $remainder =~ s/^\s*//; # remove leading whitespace
      if (($remainder =~ /^\s*$/)||($remainder =~ /^\s*;(.*)$/)) {
        errorfile(); printf(" expected integer expression after .sborg \n"); exit;
      }
      my ($ok,$sborg,$remainder2)=expr($remainder);
      if ($ok==0) {
        errorfile(); print " invalid expression after .sborg assembler directive\n"; exit;
      }
      if (($remainder2 =~ /^\s*$/)||($remainder2 =~ /^\s*;(.*)$/)) {
        $gdsectpc=$sborg;
        if ($gpass==99) {
          print LIST "\n";
          my $ocnt=9; printf(LIST "%08X ",$sborg);  
          while ($ocnt<$outtab) { $ocnt++;  print LIST " "; }
          print LIST $asm."\n";
        }
        next;
      } else {
        errorfile(); printf(" unexpected text at end of sborg line\n"); exit;
      }
    }

    my $raw="";
    #########
    # .module -- not yet implemented
    #########
    if ($asm =~ /^\.module/i) {
      $raw=".MODULE";
      #next;
    }

    ###################
    # .proc 
    ###################
    if ($asm =~ /^\.proc\b/i) {

      $gfppc=0;
      undef %gfp_label_defline;
      undef %gfp_label;

      $gcode_section=0;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=1;
      $gparam_section=1;
      $greturn_section=0;
      $glocal_section=0;

      # proc paramters
      $greturnlength=0;
      $glocallength=0;
      $gparamlength=0;
      $gparamcount=0;
      undef @gparamname;
      undef @gparamoffset;

      if ($valid_label==1) {
        if ( ($labeltype eq ":") || (defined($gmodule_exports{$Label})) ) { $glabeltype="EXT"; } else { $glabeltype="INT"; }
      } else {
        errorfile(); printf(" label not found in proc directive\n"); exit;
      }

      $raw=".PROC";
      #next;
    }

    ###################
    # .returns 
    ###################
    if ($asm =~ /^\.returns\b/i) {

      $gcode_section=0;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=1;
      $gparam_section=0;
      $greturn_section=1;
      $glocal_section=0;

      if ($glabeltype eq "INT") { $gfppc=$gparamlength+8; } else { $gfppc=$gparamlength+12; }

      $raw=".PROC";
      #next;
    }

    ###################
    # .endproc 
    ###################
    if ($asm =~ /^\.endproc\b/i) {
      $asm = "EXIT ".$var_regs;
      $gendproc=1;
      #next;
    }

    ###################
    # .var 
    ###################
    if ($asm =~ /^\.var\b(.*)/i) {
      $var_regs=$1;
      if ($var_regs =~ /^\s*$/) { $var_regs=" []"; }
      $raw=".VAR";
      # compute proc parameter offsets
      $gparam_section=0;
      foreach my $fplabel (sort {$gfp_label{$a} <=> $gfp_label{$b} } keys %gfp_label) {
if ($DEBUG>30) { printf("(.var) FRAME LABEL SEARCH <$fplabel>\n"); }
        for (my $i=0;$i<$gparamcount;$i++) {
          if ($gparamname[$i] eq $fplabel) {
            my $val;
            if ($glabeltype eq "INT") { $val=$gparamoffset[$i]+8; } else { $val=$gparamoffset[$i]+12; }
            $gfp_label{$fplabel}=$val;
if ($DEBUG>30) { printf("(.var) FRAME LABEL FOUND <$fplabel> = <$val>\n"); }
          }
        }
      }

      $gcode_section=0;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=1;
      $gparam_section=0;
      $greturn_section=0;
      $glocal_section=1;

      $gfppc=0;
      #next;
    }

    ###################
    # .begin 
    ###################
    if ($asm =~ /^\.begin\b/i) {
      my $cnt=$glocallength;
if ($DEBUG>25) { print("@@@@@ BEGIN: ret=$greturnlength, local=$glocallength, param=$gparamlength, paramcnt=$gparamcount, $gfppc=$gfppc\n"); }
      $asm = "ENTER ".$var_regs.",$cnt";

      $gcode_section=1;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=0;
      $gparam_section=0;
      $greturn_section=0;
      $glocal_section=0;

    }


    ###################
    # .subtitle <string>
    ###################
    if ($asm =~ /^\.subtitle\b/i) {
      next;
    }

    ##################
    # .width <integer> -- not yet implemented
    ##################
    if ($asm =~ /^\.width\b/i) {
      $raw=".WIDTH";
      next;
    }

    ##################
    # .list
    ##################
    if ($asm =~ /^\.list\b/i) {
      next;
    }

    ##################
    # .eject <integer> -- not yet implemented
    ##################
    if ($asm =~ /^\.eject/i) {
      $raw=".EJECT";
      next;
    }

    #########
    # .import
    #########
    if ($asm =~ /^\.import\s+(\w)+/i) {
      #my $import=$1;
      $raw=".IMPORT";
      #next;
    }

    ##########
    # .importp -- not yet implemented
    ##########
    if ($asm =~ /^\.importp/i) {
      $raw=".IMPORTP";
      #next;
    }

    #########
    # .export
    #########
    if ($asm =~ /^\.export\b/i) {
      $raw=".EXPORT";
    }

    ##########
    # .exportp
    ##########
    if ($asm =~ /^\.exportp\b(.*)(;.*)?/i) {
      #my $module_name=$1;
      #$module_name =~ s/^\s*//;    # strip leading whitespace
      #$module_name =~ s/\s*$//;    # strip trailing whitespace
      #if (define($gmodule_exports{$module_name}=0;
      #  errorfile(); print(" module already defined\n"); exit;
      #}
      #$gmodule_exports{$module_name}=0;
      $raw=".EXPORTP";
    }

    ###################
    # .endseg expression
    ###################
    if ($asm =~ /^\.endseg\s*(.*)/i) {
      my $remainder=$1;
      if (($remainder =~ /^\s*$/)||($remainder =~ /i^\s*;(.*)$/)) {
        $asm="";
        if ($gpass==99) {
          if ($gstatic_section==1) { printf(LIST "%08x %s			%6d  %s\n",$gsbpc,"SB",$assln,$rawasm); }
          elsif ($gdata_section==1) { printf(LIST "%08x %s			%6d  %s\n",$gdsectpc,"IM",$assln,$rawasm); }
          elsif ($gframe_section==1) { printf(LIST "			%6d  %s\n",$gfppc,"IM",$assln,$rawasm); }
          else { printf(LIST "%08x %s			%6d  %s\n",$gpc,"PC",$assln,$rawasm); }
        }

        $gcode_section=1;
        $gdata_section=0;
        $gstatic_section=0;
        $gframe_section=0;
        $gparam_section=0;
        $greturn_section=0;
        $glocal_section=0;

        next;
      } else {
        errorfile(); print " unexpected text after .endseg assembler directive\n"; exit;
      }
    }

    ########
    # .align 
    ########
    if ($asm =~ /^\s*\.align\b\s*(.*)$/i) {
      my $expr1; my $expr2;
      my $match=$1;
      my $str1; my $str2;
      my $ok1; my $ok2;
      my $rem1; my $rem2;
      if ($match =~ /^\s*(.*)\s*,\s*(.*)\s*$/) {
        $str1=$1;$str2=$2;
        ($ok1,$expr1,$rem1)=expr($str1);
        ($ok2,$expr2,$rem2)=expr($str2);
      } elsif ($match =~ /^\s*$/) {
        errorfile(); print(" expected expression(s) in ALIGN pseudo-op\n"); exit;
      } elsif ($match =~ /^\s*;.*$/) {
        errorfile(); print(" expected expression(s) in ALIGN pseudo-op\n"); exit;
      } elsif ($match =~ /^\s*(.*)\s*$/) {
        $str1=$1;
        ($ok1,$expr1,$rem1)=expr($str1); $expr2=0;
      } else {
        errorfile(); print(" expected expression(s) in ALIGN pseudo-op\n"); exit;
      }
if ($DEBUG>25) { print "ALIGN ($expr1) ($expr2) \n"; }
      my $t="??";
      my $ppc="??";
      if ($gdata_section==1)   { $t="DA"; $ppc=$gdsectpc; $gdsectpc=doalign($gdsectpc,$expr1,$expr2); }
      if ($gstatic_section==1) { $t="SB"; $ppc=$gsbpc; $gsbpc=doalign($gsbpc,$expr1,$expr2); }
      if ($gcode_section==1)   { $t="PC"; $ppc=$gpc; $gpc=doalign($gpc,$expr1,$expr2); }
      if ($gframe_section==1)  { $t="FP"; $ppc=$gfppc; $gfppc=doalign($gfppc,$expr1,$expr2); }
      if ($gpass==99) {
        printf(LIST "%08x %s			%6d  %s\n",$ppc,$t,$assln,$rawasm); 
      }
      next;
    }

    ##########
    # .program
    ##########
    if ($asm =~ /^\.program\b/i) {

      $gcode_section=1;
      $gdata_section=0;
      $gstatic_section=0;
      $gframe_section=0;
      $gparam_section=0;
      $greturn_section=0;
      $glocal_section=0;

      if ($gpass==99) {
        printf(LIST "%08x PC				%6d  %s\n",$gpc,$assln,$rawasm); 
      }
      next;
    }

    #########
    # .static
    #########
    if ($asm =~ /^\.static\s*(.*)/i) {
      my $remainder=$1;
      if (($remainder =~ /^\s*$/)||($remainder =~ /i^\s*;(.*)$/)) {
        $asm="";

        $gcode_section=0;
        $gdata_section=0;
        $gstatic_section=1;
        $gframe_section=0;
        $gparam_section=0;
        $greturn_section=0;
        $glocal_section=0;

        if ($gpass==99) {
          printf(LIST "%08x %s			%6d  %s\n",$gsbpc,"SB",$assln,$rawasm); 
        }
        next;
      } else {
        errorfile(); print " unexpected text after .static assembler directive\n"; exit;
      }
    }

    ###################
    # .dsect expression
    ###################
    if ($asm =~ /^\.dsect\b\s*(.*)/i) {
      my $remainder=$1;
      if (($remainder =~ /^\s*$/)||($remainder =~ /i^\s*;(.*)$/)) {
        $asm="";
        $gstart_dsectpc=$gdsectpc; # remember address of start of this section (needed for $)

        $gcode_section=0;
        $gdata_section=1;
        $gstatic_section=0;
        $gframe_section=0;
        $gparam_section=0;
        $greturn_section=0;

        if ($gpass==99) {
          printf(LIST "%08x %s			%6d  %s\n",$gdsectpc,"IM",$assln,$rawasm); 
        }
        #next;
      } else {
        errorfile(); print " unexpected text after .dsect assembler directive\n"; exit;
      }
    }

    # process directives - identified by starting with a dot
    $directive=$asm;
    #
    # .alignd
    #
    if ($directive =~ /^\s*\.alignd\s*$/) {
      while (($gpc&0x3)!=0) { $gpc++; }
if ($DEBUG>8) { printf("ALIGND=%08X\n",$gpc); } 
      if ($gpass==99) {
      }
      next;
    }
    #
    # .alignw expression
    #
    if ($directive =~ /^\s*\.alignw\s*$/) {
      while (($gpc&0x1)!=0) { $gpc++; }
if ($DEBUG>8) { printf("ALIGNW=%08X\n",$gpc); } 
      if ($gpass==99) {
      }
      next;
    }

    ########
    # .align 
    ########
    if ($directive =~ /^\s*\.align\b\s*(.*)$/) {
      my $expr=$1;
      next;
    }

    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    if ($raw ne "") {
      if ($gpass==99) {
        printf(LIST "				%6d  %s\n",$assln,$rawasm); 
      }
      next;
    }
    #~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

    #
    # .double expression
    #
    if ($directive =~ /^\s*\.double(\s*)(.*)/i) {
      process_double_data($1,$2);
      next;
    }
    ##################
    # .word expression
    ##################
    if ($directive =~ /^\s*.word(\s*)(.*)/i) {
      process_word_data($1,$2);
      next;
    }

    #########
    # .field 
    #########
    if ($directive =~ /^\.field\b(.*)/i) {
if ($DEBUG>25) { print ".FIELD\n"; }
      process_field_data($1);
      next;
    }

    ##################
    # .byte expression 
    ##################
    if ($directive =~ /^\s*\.byte\s+(.*)/i) {
if ($DEBUG>25) { print ".BYTE\n"; }
      process_byte_data($1);
      next;
    }
    
    ####################
    # .blkb expression
    ####################
    if ($asm =~ /^\.blkb\b(.*)/i) {
      my $remainder=$1;
      $remainder =~ s/\s*$//; # strip trailing whitespace
      if (($remainder =~ /^\s*$/) || ($remainder =~ /^\s*;/)) {
        # no value specified so default to '1'
        if ($valid_label==1) { 
          print_blkb($rawasm,$Label);
          store_and_inc($Label,1,1);
          next;
        }
        print_blkb($rawasm,""); 
        inc_pc(1);
        next;
      }
      $remainder =~ s/^\s*//; # strip leading whitespace
      my ($ok,$blkb,$remainder)=expr($remainder);
      if ($ok==0) {
        errorfile(); print " invalid expression after .blkb assembler directive\n"; exit;
      }
      if (($remainder =~ /\s*(.*)$/)||($remainder =~ /\s*;\s*(.*)$/)) {
        if ($valid_label==1) { # check for  associated label
          print_blkb($rawasm,$Label);
          store_and_inc($Label,$blkb,1);
          next;
        }
        print_blkb($rawasm,""); 
        inc_pc($blkb);
        next;
      } else {
        errorfile(); printf(" unexpected text at end of .blkb line\n"); exit;
      }
    }

    ####################
    # .blkw expression
    ####################
    if ($asm =~ /^\.blkw\b(.*)/i) {
      my $remainder=$1;
      $remainder =~ s/\s*$//; # strip trailing whitespace
      if (($remainder =~ /^\s*$/) || ($remainder =~ /^\s*;/)) {
        # no value specified so default to '2'
        if ($valid_label==1) { # check for  associated label - if no value default value is 1
          print_blkw($rawasm,$Label);
          store_and_inc($Label,1,2);
          next;
        }
        print_blkw($rawasm,""); 
        inc_pc(2);
        next;
      }
      $remainder =~ s/^\s*//; # strip leading whitespace
      my ($ok,$blkw,$remainder)=expr($remainder);
      if ($ok==0) {
        errorfile(); print " invalid expression after .blkw assembler directive\n"; exit;
      }
      if (($remainder =~ /\s*(.*)$/)||($remainder =~ /\s*;\s*(.*)$/)) {
        if ($valid_label==1) { # check for  associated label
          print_blkw($rawasm,$Label);
          store_and_inc($Label,$blkw,2);
          next;
        }
        print_blkw($rawasm,""); 
        inc_pc(2*$blkw);
        next;
      } else {
        errorfile(); printf(" unexpected text at end of .blkw line\n"); exit;
      }
    }
    ####################
    # .blkd expression
    ####################
    if ($asm =~ /^\.blkd\b(.*)/i) {
      my $remainder=$1;
      $remainder =~ s/\s*$//; # strip trailing whitespace
      if (($remainder =~ /^\s*$/) || ($remainder =~ /^\s*;/)) {
        # no value specified so default to '4'
        if ($valid_label==1) { # check for  associated label - if no value default value is 1
          print_blkd($rawasm,$Label);
          store_and_inc($Label,1,4);
          next;
        }
        print_blkd($rawasm,""); 
        inc_pc(4);
        next;
      }
      $remainder =~ s/^\s*//; # strip leading whitespace
      my ($ok,$blkd,$remainder)=expr($remainder);
      if ($ok==0) {
        errorfile(); print " invalid expression after .blkd assembler directive\n"; exit;
      }
      if (($remainder =~ /\s*(.*)$/)||($remainder =~ /\s*;\s*(.*)$/)) {
        if ($valid_label==1) { # check for  associated label
          print_blkd($rawasm,$Label);
          store_and_inc($Label,$blkd,4);
          next;
        }
        print_blkd($rawasm,""); 
        inc_pc(4*$blkd);
        next;
      } else {
        errorfile(); printf(" unexpected text at end of .blkd line\n"); exit;
      }
    }

    ##################
    # dc.b expression 
    ##################
    if ($directive =~ /^\s*dc\.b\s+(.*)/i) {
      process_byte_data($1);
      next;
    }

    ################################
    # identifier: .equ expression
    ################################
    if ($asm =~ /^\s*\.equ\s+(.*)/i) {
      my $expr=$1;
      $expr =~ s/\s*$//; # strip trailing whitespace
      my ($ok,$v,$remainder)=expr($expr);
      if (($remainder =~ /\s*$/)||($remainder =~ /\s*;.*$/)) {
        if ($ok==OKUNDEF) {
          errorfile(); print " symbol ($gundefined_symbol) not defined by end of pass 0 (possible forward reference?)\n"; exit;
        }
        # store identifier in list
        if ($gexprtype eq "SB") { 
          store_sb_label($Label,$v); 
        } else {
          store_identifier($Label,$v,$ok);
        }
        if ($gpass==99) {
          printf(LIST "				%6d  %s\n",$assln,$rawasm); 
        }
        next;
      } else {
        errorfile(); print " unexpected text at end of .equ line\n"; exit;
      }
      # can never reach here!
    }

    ###########################
    # identifier equ expression
    ###########################
    if ($directive =~ /([A-Za-z]\w*)\s+equ\s+(.*)/i) {
      my $identifier=$1;
      my ($ok,$v,$zz)=expr($2);
      if (($zz =~ /\s*$/)||($zz =~ /\s*;.*$/)) {
        # store identifier in list
        ####$gidentifier{$identifier}=$v;
        if ($gpass==99) { printf(LIST "-------- %08x EQU %s\n",$v,$identifier); }
        next;
      } else {
        errorfile(); print " unexpected text at end of equ line\n"; exit;
      }
      # can never reach here!
    }


    ######################################################################################
    #
    # now just strip leading and trailing whitespace
    $asm =~ s/^\s*//;
    $asm =~ s/\s*$//;

    ######################################################################################
    #
    # must be label and comment
    if ($asm eq "") { 
      if ($gpass==99) { 
        if ($Comment ne "") { 
          print LIST "--------                           ;".$Comment."\n";  
        }
      }
      next; 
    } # no mnemonic on this line

    ######################################################################################
    #
    # separate opcode and operand(s) - whitespace is expected to separate the opcode from the operands
    if ($asm =~ /^([a-zA-Z]+)\s+(.*)/) {
      # this will match only of there are operands
      $Opcode=$1;
      $Operands=$2;
    } elsif ($asm =~ /^([a-zA-Z]+)/) {
      # this will match if there are no operands
      $Opcode=$1;
      $Operands="";
    } else {
      # there is something on this line but the characters are not valid for an opcode
      errorfile(); printf(" illegal characters found when expecting opcode <$asm>\n"); exit;
    }

    ######################################################################################
    #
    # examine source for valid opcodes
    #

    my $searching=1; # flag to terminate loop early
    my $found=0;     # flag used after exit to indicate match success
    my $iset_idx=0;  # index into the instruction set struct
    my $iset_ptr;    # pointer to various fields
    my $iset_regexp; # opcode regexp

    while ($searching==1) {
      $iset_ptr=$instruction_set[$iset_idx]; # get pointer first
      $iset_regexp=$iset_ptr->{ins};         # get regexp
      #####################
      if ($Opcode =~ /^$iset_regexp$/i) {     # can we find a match?
        $found=1;
        $Opcode=lc($1);
        $Bwdch=lc($2); # might not be a second field!
        $MOV_special=lc($3); # this is a special case for only 2 instructions
        $Short=0;
        $Offset=0;
        $Length=0;
        $CVTP_EXT_reg="";
        $MMU_reg="";
        $gopcode=$Opcode;
        # many NS32016 instructions have a size specifier
        # it is also specified in the instruction opcode as a regexp [BWD]
        # where b=byte, w=word, d=double word
        if ($iset_regexp =~ /\[BWD\]/) {
             if ($Bwdch eq "b") { $Bwd=0; }
          elsif ($Bwdch eq "w") { $Bwd=1; }
          elsif ($Bwdch eq "d") { $Bwd=3; }
          else {
            errorfile(); print " bad operand size specifier <$Bwdch> in instruction <$Opcode> unknown\n"; exit;
          }
        } elsif ($iset_regexp =~ /\[BW\]/) {
               if ($Bwdch eq "b") { $Bwd=0; }
            elsif ($Bwdch eq "w") { $Bwd=1; }
            else {
              errorfile(); print " bad operand size specifier <$Bwdch> in instruction <$Opcode> unknown\n"; exit;
            }
        } elsif ($iset_regexp =~ /\(B\)/) {
               if ($Bwdch eq "b") { $Bwd=0; }
            else {
              errorfile(); print " bad operand size specifier <$Bwdch> in instruction <$Opcode> unknown\n"; exit;
            }
        } else {
          $Bwdch="";
          $Bwd=-1;
        }
        # special cases for B/W/D
        if ($Opcode =~ /jsr/)  { $Bwd=3; $Bwdch=""; } # special case for format3
        if ($Opcode =~ /jump/) { $Bwd=3; $Bwdch=""; } # special case for format3
        if ($Opcode =~ /cxpd/) { $Bwd=3; $Bwdch=""; } # special case for format3
        if ($Opcode =~ /movst/) { $Bwd=0; $Bwdch=""; $Short=1; } # special case for format5
        if ($Opcode =~ /cmpst/) { $Bwd=0; $Bwdch=""; $Short=1; } # special case for format5
        if ($Opcode =~ /skpst/) { $Bwd=0; $Bwdch=""; $Short=1; } # special case for format5
        $searching=0;
      }
      #####################
      $iset_idx++;
      if ($iset_regexp eq "END") { $searching=0; }
    }

    ####################################################################
    #my @code;
    #my $code_idx=0; 
    ####################################################################
    #
    # opcode (in the form of a Perl regexp has found a match
    # so now lets figure out if this instruction has any operands...
    #
    if ($found==1) {
      my $OpcodeBinary=$iset_ptr->{op};
if ($DEBUG>5) { print "MATCH($Opcode$Bwdch)[$Operands]<$OpcodeBinary><asm=$asm>\n"; }
      my $expected_operand1=$iset_ptr->{operand1};
      my $expected_operand2=$iset_ptr->{operand2};
      my $expected_operand3=$iset_ptr->{operand3};
      my $expected_dest=$iset_ptr->{dest};
      my $expect_n=0;

      if ($expected_operand1 ne   "none") { $expect_n++; } 
      if ($expected_operand2 ne   "none") { $expect_n++; } 
      if ($expected_operand3 ne   "none") { $expect_n++; } 
      if ($expected_operand3 eq "offset") { $expect_n++; } # makes it 4 expected operands
      if ($expected_dest           ==  1) { $expect_n++; } 
      if ($Opcode              eq "ext" ) { $expect_n++; } # makes it 4 expected operands
      if ($Opcode              eq "ins" ) { $expect_n++; } 

      # no operands expected, so just check for unexpected garbage...
      if ($expect_n==0) { 
        if ($Operands ne "") { 
          errorfile(); printf(" unexpected extra stuff found after an instruction which has no operands\n%s\n",$rawasm); exit;
        }
      } elsif ($expect_n==4) {
        # split operands where more than one is expected
        ($Operand1,$Operand2,$Operand3,$Operand4) = Operands_split4($Operands);
      } elsif ($expect_n==3) {
        # split operands where more than one is expected
        ($Operand1,$Operand2,$Operand3) = Operands_split3($Operands);
        $Operand4="";
      } elsif ($expect_n==2) {
        # split operands where more than one is expected
        ($Operand1,$Operand2) = Operands_split2($Operands);
        $Operand3="";
        $Operand4="";
      } elsif ($expect_n==1) {
        $Operand1=$Operands;
        $Operand2="";
        $Operand3="";
        $Operand4="";
      } else {
        errorfile(); printf(" it should not be possible to reach this error message\n%s\n",$rawasm); exit;
      }
if ($DEBUG>2) {
  print "+++Opcode=====<$Opcode>\n";
  print "+++expect=====<$expect_n>\n";
  print "+++OPERAND1===<$Operand1>\n";
  print "+++OPERAND2===<$Operand2>\n";
  print "+++OPERAND3===<$Operand3>\n";
  print "+++OPERAND4===<$Operand4>\n";
}

      # EXT has 4 operands, so make it a special case and re-order
      if (($Opcode eq "ins")||($Opcode eq "ext")) { 
        my $regstr=$Operand1;
        $Operand1=$Operand2;
        $Operand2=$Operand3;
        $Operand3=$Operand4;
        $Operand4="";
        $expect_n=3; #fudge to process the 3 final parameters
        # the first parameter is a register
        if ($regstr =~ /^r([0-7])$/i) {
          $CVTP_EXT_reg=$1+0;
        } else {
          errorfile(); print " error parsing EXT instruction when expecting a base register R0..R7 ($regstr)\n"; exit;
        }
      }
      # CVTP special case as operands out of normal order
      if (($Opcode eq "cvtp")||($Opcode eq "check")||($Opcode eq "index")) {
        my $regstr=$Operand1;
        $Operand1=$Operand2;
        $Operand2=$Operand3;
        $Operand3="";
        $Operand4="";
        if ($Opcode eq "cvtp") { $Bwdch="d"; $Bwd=3; } #check instruction already has BWD field
        $expect_n=2; #fudge to process the 2 final parameters
        # the first parameter is a register
        if ($regstr =~ /^r([0-7])$/i) {
          $CVTP_EXT_reg=$1+0;
        } else {
          errorfile(); print " error parsing EXT instruction when expecting a base register R0..R7 ($regstr)\n"; exit;
        }
      }

      ####################################################################################

      # if we have got here we are now expecting "at least" one operate, so lets grab it...

      $gopnoflag=1;
      $gexprtype="";
      my $f=$iset_ptr->{format};
      if ($f==90) { $Fl=0; } # ...IL
      if ($f==91) { $Fl=0; } # ...IF
      if ($f==981) { $Fl=1; } # ...FI
      if ($f==980) { $Fl=2; } # ...LI
      if ($f==92) { $Fl=0; } # (I)
      if ($f==93) { $Fl=0; } # (I)
      if ($f==95) { $Fl=2; } # ...LF 
      if ($f==96) { $Fl=1; } # ...FL
      if ($f==110) { $Fl=1; } # ...LL
      if ($f==111) { $Fl=1; } # ...FF

      #############
      #           #
      # OPERAND 1 #
      #           #
      #############

      # cxpdisp
      if ($expected_operand1 eq "cxpdisp") {
        my $Cxp=match_cxpdisp($Operand1);
        if ($Cxp == -1) { 
          errorfile(); print " error parsing CXP expected label in external module <$Operand1>\n"; exit;
        }
        $DispSz=1;
        $Disp=$Cxp;
if ($DEBUG>9) { print "OPERAND1[CXP]=$Cxp\n"; }
      }

      # procreg
      if ($expected_operand1 eq "procreg") {
        $Short=match_procreg($Operand1);
        if ($Short==-1) {
          errorfile(); print " error parsing expected short processor register field <$Operand1>\n"; exit;
        }
if ($DEBUG>9) { print "OPERAND1(procreg)[Short]=$Short\n"; }
      }

      # short
      if ($expected_operand1 eq "short") {
        my $ok;
        ($ok,$Short)=match_short($Operand1);
        if ($ok==0) {
          errorfile(); print " error parsing expected short field <$Operand1>\n"; exit;
        }
if ($DEBUG>9) { print "OPERAND1(short)[Short1]=$Short\n"; }
      }

      # scaled indexing
      if ($Operand1 =~ /(.*)\s*\[\s*+r([0-7])\s*:\s*([bwdq])\s*\]/i) {
        $Operand1=$1;
        $Gen1SIReg=$2;
        $Gen1SIsz=lc($3);
        if ($DEBUG>20) { print "SCALED INDEXED1=[$1]($2){$3}\n"; }
      }
      # genrd
      if ($expected_operand1 eq "genrd") {
        ($Genc1,$Gen1type,$Genv1,$Genv11)=match_gen($Operand1,$Bwd,$Fl);
        if ($Genc1==-1) {
          errorfile(); print " (bad genrd) first operand <$Operand1>\n"; exit;
        }
if ($DEBUG>9) { print "OPERAND1[Genrd]=$Gen1type ($Genv1)\n"; }
      }
      # genwr
      if ($expected_operand1 eq "genwr") {
        ($Genc1,$Gen1type,$Genv1,$Genv11)=match_gen($Operand1,$Bwd,$Fl);
        if ($Genc1==-1) {
          errorfile(); print " (bad genwr) first operand <$Operand1>\n"; exit;
        }
if ($DEBUG>9) { print "OPERAND1[Genwr]=$Gen1type ($Genv1)\n"; }
      }

#      # cond
#      if ($expected_operand1 eq "cond") {
#        ($DispPcSz,$DispPc)=match_cond($Operand1,$pc);
#if ($DEBUG>1) { print "COND DispPcSz=$DispPcSz DispPc=$DispPc \n"; }
#        if ($DispPcSz==-1) {
#          print "ERROR(line=$gline): bad target for conditional branch <$Operand1>\n"; #ERROR#
#          exit;
#        }
#      }

      # disp
      if ($expected_operand1 eq "disp") {
        ($DispSz,$Disp)=match_disp($Operand1);
if ($DEBUG>1) { print "DISP DispSz=$DispSz Disp=$Disp \n"; }
        if ($DispPc==-1) {
          errorfile(); print " bad offset value <$Operand1>\n"; exit;
        }
if ($DEBUG>9) { print "OPERAND1[disp]=$DispSz ($Disp)\n"; }
      }

      # reglist
      if ($expected_operand1 eq "reglist") {
        ($Reglist)=match_reglist($Operand1);
        if ($Reglist==-1) {
          errorfile(); print " bad register list <$Opcode> for <$Opcode> instruction\n"; exit;
        }
      }
      # reglistx
      if ($expected_operand1 eq "reglistx") {
        ($Reglist)=match_reglistx($Operand1);
        if ($Reglist==-1) {
          errorfile(); print " bad register list <$Opcode> for <$Opcode> instruction\n"; exit;
        }
      }

      # count
      if ($expected_operand1 eq "count") {
        ($Genc1,$Gen1type,$Genv1,$Genv11)=match_gen($Operand1,0,0); # force to be 1 byte long
        if ($Genc1==-1) {
          errorfile(); print " (bad genrd) <$Operand1>\n"; exit;
        }
        if ($Genc1>1) {
          errorfile(); print " (bad genrd) <$Operand1> is out of range ($Genc1)\n"; exit;
        }
if ($DEBUG>9) { print "OPERAND1[Count]=$Gen1type ($Genv1)\n"; }
      }

      # options
      if ($expected_operand1 eq "options") {
        $Short=match_option($Operand1)+$Short; # Short already 1 if MOVST
if ($DEBUG>9) { print "OPERAND1[Options]=$Short\n"; }
      }

      # cfglist
      if ($expected_operand1 eq "cfglist") {
        $Short=match_cfglist($Operand1);
        $Bwd=3;
if ($DEBUG>9) { print "OPERAND1[Cfglist]=$Short\n"; }
      }

      # mmureg
      if ($expected_operand1 eq "mmureg") {
        $MMU_reg=match_mmureg($Operand1);
if ($DEBUG>9) { print "OPERAND1[MMUreg]=$MMU_reg\n"; }
      }

      #####################################################################################
      #
      # do we expect a second operand
      #

      if ($expected_operand2 ne "none") {

        $gopnoflag=2;
        $gexprtype="";
        if ($f==90) { $Fl=2; } # ...IL
        if ($f==91) { $Fl=1; } # ...IF
        if ($f==981) { $Fl=0; } # ...FI
        if ($f==980) { $Fl=0; } # ...FI
        if ($f==92) { $Fl=0; } # no 2nd operand
        if ($f==93) { $Fl=0; } # no 2nd operand
        if ($f==95) { $Fl=1; } # ...LF 
        if ($f==96) { $Fl=2; } # ...FL
        if ($f==110) { $Fl=1; } # ...LL
        if ($f==111) { $Fl=1; } # ...FF


        # scaled indexing
        if ($Operand2 =~ /(.*)\s*\[\s*+r([0-7])\s*:\s*([bwdq])\s*\]/i) {
          $Operand2=$1;
          $Gen2SIReg=$2;
          $Gen2SIsz=lc($3);
          if ($DEBUG>20) { print "SCALED INDEXED2=[$1]($2){$3}\n"; }
        }

        # standard addressing modes...

        # genrd
        if ($expected_operand2 eq "genrd") {
          ($Genc2,$Gen2type,$Genv2,$Genv22)=match_gen($Operand2,$Bwd,$Fl);
          if ($Genc2==-1) {
            errorfile(); print " (bad gen rd) <$Operand2>\n"; exit;
          }
if ($DEBUG>9) { printf("Gen2=%02X Val=%X\n",$Gen2type,$Genv2); }
        }
        # genwr
        if ($expected_operand2 eq "genwr") {
          ($Genc2,$Gen2type,$Genv2,$Genv22)=match_gen($Operand2,$Bwd,$Fl);
          if ($Genc2==-1) {
            errorfile(); print " (bad gen wr) <$Operand2>\n"; exit;
          }
if ($DEBUG>9) { printf("Gen2=%02X Val=%X\n",$Gen2type,$Genv2); }
        }
      }

      # special cases for second operand

      # reglist
      if ($expected_operand2 eq "reglist") {
        $gopnoflag=2;
        ($Reglist)=match_reglist($Operand2);
        if ($Reglist==-1) {
          errorfile(); print " bad register list <$Opcode> for <$Opcode> instruction\n"; exit;
        }
      }

      # reglistx
      if ($expected_operand2 eq "reglistx") {
        $gopnoflag=2;
        ($Reglist)=match_reglistx($Operand2);
        if ($Reglist==-1) {
          errorfile(); print " bad register list <$Opcode> for <$Opcode> instruction\n"; exit;
        }
      }

      # disp
      if ($expected_operand2 eq "disp") {
        $gopnoflag=2;
        ($DispSz,$Disp)=match_disp($Operand2);
if ($DEBUG>1) { print "DISP DispSz=$DispSz Disp=$Disp \n"; }
        if ($DispPc==-1) {
          errorfile(); print " bad offset value <$Operand2>\n"; exit;
        }
      }

      #####################################################################################
      #
      # do we expect a destination operand
      #

      # dest
      if ($expected_dest==1) {
        my $dest;
        if ($expect_n==1) { $dest=$Operand1; }
        if ($expect_n==2) { $dest=$Operand2; }
        if ($expect_n==3) { $dest=$Operand3; }
        ($DestSz,$Dest)=match_dest($dest,$gpc);
if ($DEBUG>1) { print "OPERAND3/DEST DestSz=$DestSz Disp=$Dest \n"; }
        if ($DestSz==-1) {
          errorfile(); print " bad destination address\n"; exit;
        }
      }

      #####################################################################################
      #
      # do we have a length for MOVM/CMPM
      #
      if ($expected_operand3 eq "length") { 
        my ($ok,$v,$zz)=expr($Operand3);
        if (($ok>0)&&($zz eq "")) { 
          $Length=$v; 
          if (!(($Length>=0)&&($Length<0x4000))) { 
            print "WARNING: offset out of range 0..0x3fff ($Length)\n"; #ERROR#
            $Length=0;
          }
        } else {
          errorfile(); print " problem with length operand ($Operand3)\n"; exit;
        }
      }
      $Offset=-1;

      #####################################################################################
      #
      # do we have an offset and length INSS/EXTS
      #
      if ($expected_operand3 eq "offset") { 
        my ($ok,$v,$zz)=expr($Operand3);
        if (($ok>0)&&($zz eq "")) { 
          $Offset=$v; 
          if (!(($Offset>=0)&&($Offset<=7))) { 
            print "WARNING: offset out of range 0..7 ($Offset)\n"; #ERROR#
            $Offset=0;
          }
        } else {
          errorfile(); print "ERROR: problem with offset operand ($Operand3)\n"; exit;
        }
        my ($ok,$v,$zz)=expr($Operand4);
        if (($ok>0)&&($zz eq "")) { 
          $Length=$v; 
          if (!(($Length>=1)&&($Length<=32))) { 
            print "WARNING: length out of range 1..32 ($Length)\n"; #ERROR#
            $Length=1;
          }
        } else {
          errorfile(); print " problem with length operand ($Operand4)\n"; exit;
        }
      }

      #######################################################
      #
      # determine instruction format and create opcode binary..
      #
      #my $f=$iset_ptr->{format};
      $f=$iset_ptr->{format};

      #######################
      # FORMAT = 0 (Bcondi) #
      #######################
      if ($f==0) {
        # Bcond (branch)...
        my $DispType=32;
        my $op8=($OpcodeBinary<<4)+0xA;
        $gpc=$gpc+addcode($gpc,$op8,1,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $DestSz,$Dest,0,$DispType, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT = 1 #
      ##############
      if ($f==100) {
        # RETI,NOP,WAIT,DIA,FLAG,SVC,BPT
        my $Disp=0;
        my $DispSz=0;
        my $DispType=0;
        my $op8=($OpcodeBinary<<4)+0x2;
        $gpc=$gpc+addcode($gpc,$op8,1,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          0,0,0,0,
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS(%x)\n",$op8); }
        log_gpc(); 
        next; 
      }
      if ($f==101) {
        # RET,RXP,RETT
        my $DispType=32;
        my $op8=($OpcodeBinary<<4)+0x2;
        $gpc=$gpc+addcode($gpc,$op8,1,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $DispSz,$Disp,0,$DispType, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS(%x)\n",$op8); }
        log_gpc(); 
        next; 
      }
      if ($f==105) {
        # CXP
        my $DispType=32;
        my $op8=($OpcodeBinary<<4)+0x2;
        $gpc=$gpc+addcode($gpc,$op8,1,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $DispSz,$Disp,0,$DispType, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS(%x)\n",$op8); }
        log_gpc(); 
        next; 
      }
      if ($f==102) {
        # SAVE (constant coded as R7..R0) & RESTORE (constant coded as R0..R7)
        my $op8=($OpcodeBinary<<4)+0x2;
        $gpc=$gpc+addcode($gpc,$op8,1,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          1,$Reglist,0,102, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS(%x)\n",$op8); }
        log_gpc(); 
        next; 
      }
      if ($f==109) {
        # EXIT
        my $op8=($OpcodeBinary<<4)+0x2;
        $gpc=$gpc+addcode($gpc,$op8,1,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          1,$Reglist,0,102, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS EXIT(%x)\n",$op8); }
        log_gpc(); 
        next; 
      }
      if ($f==103) {
        # ENTER (constant coded as R7..R0)
        my $op8=($OpcodeBinary<<4)+0x2;
        $gpc=$gpc+addcode($gpc,$op8,1,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          1,$Reglist,0,102, 
                          $DispSz,$Disp,0,32,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS(%x)\n",$op8); }
        log_gpc(); 
        next; 
      }
      if ($f==104) {
        # BSR
        my $op8=($OpcodeBinary<<4)+0x2;
        $gpc=$gpc+addcode($gpc,$op8,1,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $DestSz,$Dest,0,32, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS(%x)\n",$op8); }
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT = 2 #
      ##############
      if ($f==200) {
        # ADDQ,CMPQ,SPR,Scond,MOVQ,LPR
        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        my $op16=($Gen2type<<11)+($Short<<7)+($OpcodeBinary<<4)+0xc+$Bwd;
        my $sz=0;
           if ($Bwd==0) { $sz=1; }
        elsif ($Bwd==1) { $sz=2; }
        elsif ($Bwd==3) { $sz=4; }
        $gpc=$gpc+addcode($gpc,$op16,2,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          0,0,0,0,
                          $Genc2,$Genv2,$Genv22,$Gen2type, 
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("ZZZ>>>SUCCESS(%x)\n",$op16); }
        log_gpc(); 
        next; 
      }
      if ($f==201) {
        # ACB
        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        my $op16=($Gen2type<<11)+($Short<<7)+($OpcodeBinary<<4)+0xc+$Bwd;
        my $sz=0;
           if ($Bwd==0) { $sz=1; }
        elsif ($Bwd==1) { $sz=2; }
        elsif ($Bwd==3) { $sz=4; }
        $gpc=$gpc+addcode($gpc,$op16,2,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc2,$Genv2,$Genv22,$Gen2type, 
                          $DestSz,$Dest,0,32,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("ZZZ>>>SUCCESS(%x)\n",$op16); }
        log_gpc(); 
        next; 
      }
      #######################
      # FORMAT = 2 (Scondi) #
      #######################
      if ($f==22) {
        # Scondi
        my $op16=($Gen1type<<11)+($OpcodeBinary<<7)+0x3c+$Bwd;
        my $sz=0;
           if ($Bwd==0) { $sz=1; }
        elsif ($Bwd==1) { $sz=2; }
        elsif ($Bwd==3) { $sz=4; }
        $gpc=$gpc+addcode($gpc,$op16,2,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc1,$Genv1,$Genv11,$Gen1type, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS SCOND(%x)\n",$op16); }
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT = 3 #
      ##############
      if ($f==3) {
        # CXPD,BICPSR,JUMP,BISPSR,ADJSP,JSR,CASE
        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        my $op16=($Gen1type<<11)+($OpcodeBinary<<7)+0x7C+$Bwd;
        $gpc=$gpc+addcode($gpc,$op16,2,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc1,$Genv1,$Genv11,$Gen1type, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS(%x)(%d)\n",$op16,$Bwd); }
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT = 4 #
      ##############
      if ($f==4) {
        # ADD,CMP,BIC,ADDC,MOV,OR,SUB,ADDR,AND,SUBC,TBIT,XOR
        if ($Opcode eq "addr") { $Bwd=3; }
        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        my $op16=($Gen1type<<11)+($Gen2type<<6)+($OpcodeBinary<<2)+$Bwd;
        my $sz=0;
           if ($Bwd==0) { $sz=1; }
        elsif ($Bwd==1) { $sz=2; }
        elsif ($Bwd==3) { $sz=4; }
        $gpc=$gpc+addcode($gpc,$op16,2,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc1,$Genv1,$Genv11,$Gen1type, 
                          $Genc2,$Genv2,$Genv22,$Gen2type,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
if ($DEBUG>11) { printf("SUCCESS[gen,gen](%x)\n",$op16); }
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT = 5 #
      ##############
      if ($f==5) {
        # MOVS,CMPS,SETCFG,SKPS
        my $op24=($Short<<15)+($OpcodeBinary<<10)+($Bwd<<8)+0x0E;
if ($DEBUG>11) { printf("SUCCESS[short](%x) (%X) (%X) (%X)\n",$op24,$Short,$OpcodeBinary,$Bwd); }
        $gpc=$gpc+addcode($gpc,$op24,3,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          0,0,0,0, 
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT = 6 #
      ##############
      if ($f==6) {
        # ROT,ASH,CBIT,CBITI,LSH,SBIT,SBITI,NEG,SUBP,ABS,COM,IBIT,ADDP
        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        my $op24=($Gen1type<<19)+($Gen2type<<14)+($OpcodeBinary<<10)+($Bwd<<8)+0x4E;
if ($DEBUG>11) { printf("SUCCESS[gen,gen](%x)\n",$op24); }
        $gpc=$gpc+addcode($gpc,$op24,3,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc1,$Genv1,$Genv11,$Gen1type, 
                          $Genc2,$Genv2,$Genv22,$Gen2type,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT = 7 #
      ##############
      if ($f==7) {
        # MOVM, CMPM, INSS, EXTS, MOVXBW, MOVZBW, MOVZiD, MOVXiD, MUL, MEI, DEI, QUO, REM, MOD, DIV
        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        my $op24=($Gen1type<<19)+($Gen2type<<14)+($OpcodeBinary<<10)+($Bwd<<8)+0xCE;
        my $sz=0;
           if ($Bwd==0) { $sz=1; }
        elsif ($Bwd==1) { $sz=2; }
        elsif ($Bwd==3) { $sz=4; }
        $gpc=$gpc+addcode($gpc,$op24,3,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc1,$Genv1,$Genv11,$Gen1type, 
                          $Genc2,$Genv2,$Genv22,$Gen2type,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT = 8 #
      ##############
      if ($f==8) {
        # EXT, CVTP, INS, CHECK, INDEX, FFS
        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        my $op24=($Gen1type<<19)+($Gen2type<<14)+($CVTP_EXT_reg<<11)+(($OpcodeBinary&4)<<8)+(($OpcodeBinary&3)<<6)+($Bwd<<8)+0x2E;
        my $sz=0;
           if ($Bwd==0) { $sz=1; }
        elsif ($Bwd==1) { $sz=2; }
        elsif ($Bwd==3) { $sz=4; }
        $gpc=$gpc+addcode($gpc,$op24,3,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc1,$Genv1,$Genv11,$Gen1type, 
                          $Genc2,$Genv2,$Genv22,$Gen2type,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
        log_gpc(); 
        next; 
      }

      #############
      # FORMAT =9 #
      #############
      if ($f==90)  { $f=9; } # ...IF
      if ($f==91)  { $f=9; } # ...IL
      if ($f==981) { $f=9; } # ...FI
      if ($f==980) { $f=9; } # ...LI
      # LFSR 
      if ($f==93) { $Flch=1; $Bwd=3; $f=9; }
      if ($f==92) {
        # SFSR
        $Flch=1; $Bwd=3; $f=9;
        $Genc2=$Genc1; $Genc1=0;
        $Genv2=$Genv1; $Genv1=0;
        $Gen2type=$Gen1type; $Gen1type=0;
      }
      # MOVLF
      if ($f==95) { $Flch=1; $Bwd=2; $f=9; }
      # MOVFL
      if ($f==96) { $Flch=0; $Bwd=3; $f=9; }

      if ($f==9) {
        # MOVif, ROUND, TRUNC, FLOOR
        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        my $op24=($Gen1type<<19)+($Gen2type<<14)+(($OpcodeBinary)<<10)+($Bwd<<8)+0x3E;
        $gpc=$gpc+addcode($gpc,$op24,3,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc1,$Genv1,$Genv11,$Gen1type, 
                          $Genc2,$Genv2,$Genv22,$Gen2type,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
        log_gpc(); 
        next; 
      }

      ##############
      # FORMAT =11 # - floating point instructions for NS82081
      ##############
      if ($f==110) {
        # MOVL, ADDL, etc.
        $Flch=0;
        $f=11;
      }
      if ($f==111) {
        # MOVF, ADDF, etc.
        $Flch=1;
        $f=11;
      }
      if ($f==11) {
        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        $Bwd=0; # not used
        my $op24=($Gen1type<<19)+($Gen2type<<14)+(($OpcodeBinary)<<10)+($Flch<<8)+0xBE;
        $gpc=$gpc+addcode($gpc,$op24,3,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
                          $Genc1,$Genv1,$Genv11,$Gen1type, 
                          $Genc2,$Genv2,$Genv22,$Gen2type,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
                          $Offset,$Length);
        log_gpc(); 
        next; 
      }

#      ##############
#      # FORMAT =12 # - floating point conversion instructions for NS82081
#      ##############
#      if ($f==12) {
#        # TRUNCF,TRUNCL
#        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
#        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
#        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
#        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
#        if (lc($Gen2SIsz) eq "b") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
#        if (lc($Gen2SIsz) eq "w") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
#        if (lc($Gen2SIsz) eq "d") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
#        if (lc($Gen2SIsz) eq "q") { $Gen2SIOpcode=$Gen2type; $Gen2type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
#        my $op24=($Gen1type<<19)+($Gen2type<<14)+(($OpcodeBinary)<<10)+($Bwd<<8)+0x3E;
#        $gpc=$gpc+addcode($gpc,$op24,3,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment, 
#                          $Genc1,$Genv1,$Gen1type, 
#                          $Genc2,$Genv2,$Gen2type,
#                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,$Gen2SIReg,$Gen2SIsz,$Gen2SIOpcode,
#                          $Offset,$Length);
#        log_gpc(); 
#        next; 
#      }

      ##############
      # FORMAT =14 #
      ##############
      if ($f==14) {
        # SMR, LMR - need to swap over operands
        $Gen1SIOpcode=$Gen2SIOpcode;
        $Gen1SIReg=$Gen2SIReg; 
        $Gen1SIsz=$Gen2SIsz;
        $Gen1type=$Gen2type;
        $Genc1=$Genc2;
        $Genv1=$Genv2;
        $Genv11=$Genv22;

        if (lc($Gen1SIsz) eq "b") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_BYTE_SCALED_INDEX; } # basemode[Rn:B]
        if (lc($Gen1SIsz) eq "w") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_WORD_SCALED_INDEX; } # basemode[Rn:W]
        if (lc($Gen1SIsz) eq "d") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_DWORD_SCALED_INDEX; } # basemode[Rn:D]
        if (lc($Gen1SIsz) eq "q") { $Gen1SIOpcode=$Gen1type; $Gen1type=ADDRESS_MODE_QWORD_SCALED_INDEX; } # basemode[Rn:Q]
        $Bwd=3; # double word MMU register write

        my $op24=($Gen1type<<19)+($MMU_reg<<15)+($OpcodeBinary<<10)+($Bwd<<8)+0x1E; # bit14=0
        $gpc=$gpc+addcode($gpc,$op24,3,$Opcode,$Bwdch,$MOV_special,$Operands,$Comment,
                          $Genc1,$Genv1,$Genv11,$Gen1type,
                          0,0,0,0,
                          $Gen1SIReg,$Gen1SIsz,$Gen1SIOpcode,-1,"",0,
                          $Offset,$Length);
        log_gpc();
        next;
      }

      #
      errorfile(); print " format <$f> not yet coded <asm=$asm>\n"; exit;
      #######################################################

    } #if(found)

    # no matching instruction to the users opcode was found
    # NOTE: not all valid instructions have been coded

if ($DEBUG>25) { printf("CODE=<%s> OPERANDS=<%s> LABEL=<%s> COMMENT=<%s>\n",$Opcode,$Operands,$Label,$Comment); }
    errorfile(); print " could not parse ($asm)\n"; exit;
  } #for
  print "LABEL UPDATES = $glabel_updates\n";

  if ($gpass==99) {
    printf(LIST "%d Assembly error(s) detected.\n");
  }
}

######################################################################################
sub Operands_split2 {
  my ($ops) = @_;

  my @fields = parse_operands($ops);
  my $totfields=@fields;
  if ($totfields != 2) { 
    errorfile(); print " unable to split the line based on commas - remove from comments?\n"; 
    my $s=$gasm_text[$gline];
    print ">>>>>$s\n";
  }
  for (my $i = 0; $i < @fields; $i++) {
    $fields[$i] =~ s/\s*$//;    # strip trailing whitespace
  }
  return $fields[0],$fields[1];
}

######################################################################################
sub Operands_split3 {
  my ($ops) = @_;

  my @fields = parse_operands($ops);
  my $totfields=@fields;
  if ($totfields != 3) { 
    errorfile(); print " unable to split the line based on commas - remove from comments?\n"; 
    my $s=$gasm_text[$gline];
    print ">>>>>$s\n";
  }
  for (my $i = 0; $i < @fields; $i++) {
    $fields[$i] =~ s/\s*$//;    # strip trailing whitespace
  }
  return $fields[0],$fields[1],$fields[2];
}

######################################################################################
sub Operands_split4 {
  my ($ops) = @_;

  my @fields = parse_operands($ops);
  my $totfields=@fields;
  if ($totfields != 4) { 
    errorfile(); print " unable to split the line based on commas - remove from comments?\n"; 
    my $s=$gasm_text[$gline];
    print ">>>>>$s\n";
  }
  for (my $i = 0; $i < @fields; $i++) {
    $fields[$i] =~ s/\s*$//;    # strip trailing whitespace
  }
  return $fields[0],$fields[1],$fields[2],$fields[3];
}

######################################################################################
# TODO
sub compute_offset_size {
  my ($disp) = @_;

     if (($disp<      64)&&($disp>=      -64)) { return(1); }
  elsif (($disp<    8192)&&($disp>=    -8192)) { return(2); }
  elsif (($disp<16277216)&&($disp>=-16277216)) { return(4); }
  return (0);
}

######################################################################################
sub size_offset {
  my ($v) = @_;

  if (($v<      64)&&($v>=      -64)) { return (1); }
  if (($v<    8192)&&($v>=    -8192)) { return (2); }
  if (($v<16277216)&&($v>=-16277216)) { return (4); }
  return(0);
}

######################################################################################
sub get_offset {
  my ($e,$errs,$fixed) = @_;

if ($DEBUG>50) { print("DEBUG: get_offset ($e)\n"); }

  my ($ok,$v,$zz)=expr($e);
  if ($ok>0) {
    if ( ($fixed=~/:B/i)&&(($v<      64)&&($v>=      -64)) ) { return (1,$v); }
    if ( ($fixed=~/:W/i)&&(($v<    8192)&&($v>=    -8192)) ) { return (2,$v); }
    if ( ($fixed=~/:D/i)&&(($v<16277216)&&($v>=-16277216)) ) { return (4,$v); }
    if ($fixed ne "") {
      errorfile();
      print " offset ($v) out of range of offset type ($fixed)\n"; #ERROR#
    }
    if (($v<      64)&&($v>=      -64)) { return (1,$v); }
    if (($v<    8192)&&($v>=    -8192)) { return (2,$v); }
    if (($v<16277216)&&($v>=-16277216)) { return (4,$v); }
    errorfile();
    print " offset out of range (+/- 16M)\n"; #ERROR#
  } else {
    errorfile(); printf(" %s\n",$errs); exit;
  }
}

######################################################################################
sub get_absolute {
  my ($e,$errs) = @_;

  my ($ok,$v,$zz)=expr($1);
  if ($ok>0) {
    return $v;
  } else {
    errorfile(); printf(" %s\n%s\n",$errs,$gasm_text[$gline]); exit;
  }
}

######################################################################################
#
# returns 3 values
# 1st = size of extra stuff in bytes or -1 for an error, normally 0,1,2 or 4
# 2nd = mode of addressing (R0=00000, etc.) to fill into field in the instruction binary opcode
# 3rd = value of extra stuff
#
sub match_gen {
  my ($gen,$bwd,$float) = @_;

  my $rrerrs="bad offset processing register relative operand";
  my $abserrs="problem parsing absolute value after @ symbol";
  my $mrerrs="bad offset processing memory relative operand";

  my $si_reg="";
  my $si_sz=0;
  my $si_bin=0;

  $gdisptype="";

if ($DEBUG>25) { print("match_gen(): gen=($gen) bwd=($bwd) float=($float)\n"); }

  # MEMORY (FP,SP,SB) RELATIVE
  if ($gen =~  /^(.*)\s*\(\s*(.*)\s*\(\s*((fp|sp|sb))\s*\)\s*\)\s*$/i) {
    my ($disp2sz,$disp2)=get_offset($1,$mrerrs,"");
    my ($disp1sz,$disp1)=get_offset($2,$mrerrs,"");
if ($DEBUG>25) { print "MEMORY RELATIVE <$1> ( <$2> ( $3 ) ) $disp2 $disp1\n"; }
    if (lc($3) eq "fp") { return ($disp1sz,ADDRESS_MODE_FRAME_MEMORY_RELATIVE,$disp1,$disp2); } 
    if (lc($3) eq "sp") { return ($disp1sz,ADDRESS_MODE_STACK_MEMORY_RELATIVE,$disp1,$disp2); } 
    if (lc($3) eq "sb") { return ($disp1sz,ADDRESS_MODE_STATIC_MEMORY_RELATIVE,$disp1,$disp2); } 
    errorfile(); print " match_gen(): memory relative - expected FP, SP or SB\n"; exit;
  }
  # MEMORY (PC) RELATIVE
  elsif ($gen =~ /^%(.*)$/i) { 
    my ($DestSz,$Offset)=match_dest($1,$gpc,0);
    return ($DestSz,ADDRESS_MODE_PROGRAM_MEMORY,$Offset,0); #NOTE fixed size offset (TODO)
  }
  # REGISTER...
  elsif (($float==0)&&($gen =~ /^R0$/i)) { return (0,ADDRESS_MODE_REGISTER_0,0,0); }
  elsif (($float==0)&&($gen =~ /^R1$/i)) { return (0,ADDRESS_MODE_REGISTER_1,0,0); }
  elsif (($float==0)&&($gen =~ /^R2$/i)) { return (0,ADDRESS_MODE_REGISTER_2,0,0); }
  elsif (($float==0)&&($gen =~ /^R3$/i)) { return (0,ADDRESS_MODE_REGISTER_3,0,0); }
  elsif (($float==0)&&($gen =~ /^R4$/i)) { return (0,ADDRESS_MODE_REGISTER_4,0,0); }
  elsif (($float==0)&&($gen =~ /^R5$/i)) { return (0,ADDRESS_MODE_REGISTER_5,0,0); }
  elsif (($float==0)&&($gen =~ /^R6$/i)) { return (0,ADDRESS_MODE_REGISTER_6,0,0); }
  elsif (($float==0)&&($gen =~ /^R7$/i)) { return (0,ADDRESS_MODE_REGISTER_7,0,0); }
  # FLOATING POINT REGISTER...
  elsif (($float!=0)&&($gen =~ /^F0$/i)) { return (0,ADDRESS_MODE_REGISTER_0,0,0); }
  elsif (($float!=0)&&($gen =~ /^F1$/i)) { return (0,ADDRESS_MODE_REGISTER_1,0,0); }
  elsif (($float!=0)&&($gen =~ /^F2$/i)) { return (0,ADDRESS_MODE_REGISTER_2,0,0); }
  elsif (($float!=0)&&($gen =~ /^F3$/i)) { return (0,ADDRESS_MODE_REGISTER_3,0,0); }
  elsif (($float!=0)&&($gen =~ /^F4$/i)) { return (0,ADDRESS_MODE_REGISTER_4,0,0); }
  elsif (($float!=0)&&($gen =~ /^F5$/i)) { return (0,ADDRESS_MODE_REGISTER_5,0,0); }
  elsif (($float!=0)&&($gen =~ /^F6$/i)) { return (0,ADDRESS_MODE_REGISTER_6,0,0); }
  elsif (($float!=0)&&($gen =~ /^F7$/i)) { return (0,ADDRESS_MODE_REGISTER_7,0,0); }
  # REGISTER RELATIVE..
  elsif ($gen =~ /^(.*?)(:[BWD])?\s*\(\s*R0\s*\)\s*$/i) { my ($sz,$v)=get_offset($1,$rrerrs,$2); return ($sz,ADDRESS_MODE_REGISTER_0_RELATIVE,$v,0); }
  elsif ($gen =~ /^(.*?)(:[BWD])?\s*\(\s*R1\s*\)\s*$/i) { my ($sz,$v)=get_offset($1,$rrerrs,$2); return ($sz,ADDRESS_MODE_REGISTER_1_RELATIVE,$v,0); }
  elsif ($gen =~ /^(.*?)(:[BWD])?\s*\(\s*R2\s*\)\s*$/i) { my ($sz,$v)=get_offset($1,$rrerrs,$2); return ($sz,ADDRESS_MODE_REGISTER_2_RELATIVE,$v,0); }
  elsif ($gen =~ /^(.*?)(:[BWD])?\s*\(\s*R3\s*\)\s*$/i) { my ($sz,$v)=get_offset($1,$rrerrs,$2); return ($sz,ADDRESS_MODE_REGISTER_3_RELATIVE,$v,0); }
  elsif ($gen =~ /^(.*?)(:[BWD])?\s*\(\s*R4\s*\)\s*$/i) { my ($sz,$v)=get_offset($1,$rrerrs,$2); return ($sz,ADDRESS_MODE_REGISTER_4_RELATIVE,$v,0); }
  elsif ($gen =~ /^(.*?)(:[BWD])?\s*\(\s*R5\s*\)\s*$/i) { my ($sz,$v)=get_offset($1,$rrerrs,$2); return ($sz,ADDRESS_MODE_REGISTER_5_RELATIVE,$v,0); }
  elsif ($gen =~ /^(.*?)(:[BWD])?\s*\(\s*R6\s*\)\s*$/i) { my ($sz,$v)=get_offset($1,$rrerrs,$2); return ($sz,ADDRESS_MODE_REGISTER_6_RELATIVE,$v,0); }
  elsif ($gen =~ /^(.*?)(:[BWD])?\s*\(\s*R7\s*\)\s*$/i) { my ($sz,$v)=get_offset($1,$rrerrs,$2); return ($sz,ADDRESS_MODE_REGISTER_7_RELATIVE,$v,0); }
  # ABSOLUTE
  elsif ($gen =~ /^@(.*)$/i) { my ($v)=get_absolute($1,$abserrs); return (4,ADDRESS_MODE_ABSOLUTE,$v,0); }
  # TOS
  elsif ($gen =~ /^TOS$/i) { return (0,ADDRESS_MODE_TOP_OF_STACK,0,0); }
  # FRAME
  elsif ($gen =~ /^(.*)\(FP\)$/i) { my ($sz,$v)=get_offset($1,$rrerrs,""); return ($sz,ADDRESS_MODE_FRAME_MEMORY,$v,0); }
  # STACK
  elsif ($gen =~ /^(.*)\(SP\)$/i) { my ($sz,$v)=get_offset($1,$rrerrs,""); return ($sz,ADDRESS_MODE_STACK_MEMORY,$v,0); }
  # STATIC BASE
  elsif ($gen =~ /^(.*)\(SB\)$/i) { my ($sz,$v)=get_offset($1,$rrerrs,""); return ($sz,ADDRESS_MODE_STATIC_MEMORY,$v,0); }
  # IMMEDIATE...for sure due to leading #
  elsif ($gen =~ /^#(.*)$/) {
    my $imm=$1;
    my ($ok,$v,$remainder)=expr($imm);
    if ($ok>0) {
      if ($DEBUG>25) { print "match_gen(): EXIT remainder=<$remainder> \n"; }
      if ($bwd==0) { return (1,ADDRESS_MODE_IMMEDIATE,$v,0); }
      if ($bwd==1) { return (2,ADDRESS_MODE_IMMEDIATE,$v,0); }
      if ($bwd==3) { return (4,ADDRESS_MODE_IMMEDIATE,$v,0); }
      errorfile(); print " match_gen():  bwd not 0,1 or 3 <$gen>\n"; exit;
    } else {
      errorfile(); print "  match_gen(): found # so expected immediate value expression but found <$gen>\n"; exit;
    }
  }
  # must be some kind of expression, lets evaluate it and find out what type of labels it uses...
  elsif ($gen =~ /^(.*)\s*$/) {
    my $imm=$1;
    if ($DEBUG>25) { print("match_gen(): IMMEDIATE 0 ($imm)\n"); }
    #===================================================================
    my $isfloat=0;
    my $f;
    if ($gen =~ /^([\+-]?)(\d*)\.(\d*)([eE]?)([\+-]?)(\d*)/) {
if ($DEBUG>25) { print "FLOAT found $1,$2,$3,$4,$5,$6,\n"; }
      $f=tofloat($float,$1,$2,$3,$4,$5,$6); 
      $isfloat=1;
    }
    #===================================================================
    if (($isfloat==1)&&($float==1)) {
      return (4,ADDRESS_MODE_IMMEDIATE,($f+0)&0xffffffff,0); 
    }
    #===================================================================
    if (($isfloat==1)&&($float==2)) {
      return (8,ADDRESS_MODE_IMMEDIATE,($f+0)&0xffffffffffffffff,0); 
    }
    #===================================================================
    my ($ok,$v,$remainder)=expr($imm);
    if ($ok>0) {
      if ($DEBUG>25) { print(" match_gen(): IMMEDIATE 1 value=($v) type=($gexprtype) remainder=<$remainder>\n"); }
      if (($gopcode eq "addr")&&($gopnoflag==1)) { 
        if ($gexprtype eq "")    { $gexprtype="CODE"; }
        if ($gexprtype eq "IMM") { $gexprtype="CODE"; }
      }
      if ($DEBUG>25) { print(" match_gen(): IMMEDIATE 2 value=($v) type=($gexprtype)\n"); }
      #===================================================================
      if ($gexprtype eq "IMPORT") {
        my $ext=$v;
        if ($remainder eq "") {
            if ($DEBUG>25) { print("DEBUG: ->EXTERNAL 1 ($remainder) ($ext) (0)\n"); }
            return (2,ADDRESS_MODE_EXTERNAL,$ext,0); 
        } else {
          my ($ok,$offset,$extremainder)=expr($remainder);
          if ($ok>0) {
            if ($DEBUG>25) { print("DEBUG: ->EXTERNAL 2 ($extremainder) ($ext) ($offset)\n"); }
            return (2,ADDRESS_MODE_EXTERNAL,$ext,$offset); 
          } else {
            errorfile(); print(" match_gen(): internal error - processing EXT offset\n"); exit;
          }
        }
      }

      #===================================================================
      if ($gexprtype eq "CODE") {
        if ($DEBUG>25) { print("DEBUG: ->CODE ($imm) rem=($remainder)\n"); }
        $remainder =~ /(:[BWD])?/i;
        if ($gexprtype eq "IMM") {
          $v=$v;
        } else {
          $v=$v-$gpc;
        }
        my $fixed=$1;
        if ( ($fixed=~/:B/i)&&(($v<      64)&&($v>=      -64)) ) { return (1,ADDRESS_MODE_PROGRAM_MEMORY,$v,0); }
        if ( ($fixed=~/:W/i)&&(($v<    8192)&&($v>=    -8192)) ) { return (2,ADDRESS_MODE_PROGRAM_MEMORY,$v,0); }
        if ( ($fixed=~/:D/i)&&(($v<16277216)&&($v>=-16277216)) ) { return (4,ADDRESS_MODE_PROGRAM_MEMORY,$v,0); }
        if (($gpass==99)&&($fixed ne "")) {
          errorfile(); print " offset ($v) out of range of offset type ($fixed)\n"; exit;
        }
        if ( ($v<      64)&&($v>=      -64) ) { return (1,ADDRESS_MODE_PROGRAM_MEMORY,$v,0); }
        if ( ($v<    8192)&&($v>=    -8192) ) { return (2,ADDRESS_MODE_PROGRAM_MEMORY,$v,0); }
        if ( ($v<16277216)&&($v>=-16277216) ) { return (4,ADDRESS_MODE_PROGRAM_MEMORY,$v,0); }
        if ($gpass==99) {
          errorfile(); print " offset ($v) out of range of offset type ($fixed)\n"; exit;
        }
        else { return (4,ADDRESS_MODE_PROGRAM_MEMORY,$v,0); }
        #if ($bwd==0) { return (1,ADDRESS_MODE_PROGRAM_MEMORY,$v); } # TODO
        #if ($bwd==1) { return (2,ADDRESS_MODE_PROGRAM_MEMORY,$v); }
        #if ($bwd==3) { return (4,ADDRESS_MODE_PROGRAM_MEMORY,$v); }
        #errorfile();
        #print "ERROR: found pc relative so expected immediate value expression but found <$gen>\n";
        #exit;
      }

      #===================================================================
      if (($gexprtype eq "FP")||($gexprtype eq "SB")) {
        if ($DEBUG>25) { print("DEBUG: ->$gexprtype ($imm)\n"); }
        my $off=size_offset($v);
        if ($off==0) {
          errorfile(); print " offset for x($gexprtype) out of range\n"; exit;
        }
        if ($gexprtype eq "SB") { return ($off,ADDRESS_MODE_STATIC_MEMORY,$v,0); }
        if ($gexprtype eq "FP") { return ($off,ADDRESS_MODE_FRAME_MEMORY,$v,0); }
        errorfile(); print(" match_gen(): internal error - incorrect data type ($gexprtype)\n"); exit;
      }

      #===================================================================
      # FRAME  POINTER
      #if ($gexprtype eq "FP") {
      #  if ($DEBUG>25) { print("DEBUG: ->FP ($imm)\n"); }
      #  my $offsize=size_offset($v);
      #  if ($offsize==0) {
      #    errorfile();
      #    print " offset for x(FP) out of range\n";
      #    exit;
      #  }
      #  if ($DEBUG>30) { printf("match_gen(): FRAME LABEL size=<$offsize> <$imm> = <$v>] \n"); }
      #  return ($offsize,ADDRESS_MODE_FRAME_MEMORY,$v,0); 
      #}
      #===================================================================
      my $immsize=0;
      if ($remainder ne "") {
        if      ($remainder =~ /^(:B)$/i) {
#####print("=:B=");
          $immsize=1;
        } elsif ($remainder =~ /^(:W)$/i) {
#####print("=:W=");
          $immsize=2;
        } elsif ($remainder =~ /^(:D)$/i) {
#####print("=:D=");
          $immsize=4;
        } else {
          if ($remainder=~/^\(\s*(.*)$/) {
            my ($ok,$expr,$rem)=expr($1);
            if ($rem=~/^\s*\)\s*(.*)/) {
              $rem=$1; # remove trailing bracket
              if ($DEBUG>25) { printf("SPECIAL $gexprtype rem=<%s> %X] ",$rem,$expr); }
              my $sz=compute_offset_size($expr);
              my $disp2=$v;
              # STATIC BASE 
              if ($gexprtype eq "SB") { return ($sz,ADDRESS_MODE_STATIC_MEMORY_RELATIVE,$expr,$disp2); }
              if ($gexprtype eq "FP") { return ($sz,ADDRESS_MODE_FRAME_MEMORY_RELATIVE,$expr,$disp2); }
            } else {
              badexpr($remainder);
            }
            errorfile(); printf("GEN_MATCH: remainder=<$remainder>\n"); exit;
          }
        }
      }
      #===================================================================
      if ($DEBUG>25) { print("match_gen(): IMMEDIATE 3 ($gexprtype)\n"); }
      if (($float==0)&&($immsize==1)) { return (1,ADDRESS_MODE_IMMEDIATE,($v+0)&0x000000ff,0); }
      if (($float==0)&&($immsize==2)) { return (2,ADDRESS_MODE_IMMEDIATE,($v+0)&0x0000ffff,0); }
      if (($float==0)&&($immsize==4)) { return (4,ADDRESS_MODE_IMMEDIATE,($v+0)&0xffffffff,0); }
      if (($float==0)&&($bwd==0))     { return (1,ADDRESS_MODE_IMMEDIATE,($v+0)&0x000000ff,0); }
      if (($float==0)&&($bwd==1))     { return (2,ADDRESS_MODE_IMMEDIATE,($v+0)&0x0000ffff,0); }
      if (($float==0)&&($bwd==3))     { return (4,ADDRESS_MODE_IMMEDIATE,($v+0)&0xffffffff,0); }
      if ($float==1)                  { return (4,ADDRESS_MODE_IMMEDIATE,($v+0)&0xffffffff,0); }
      if ($float==2)                  { return (8,ADDRESS_MODE_IMMEDIATE,$v); }
    } else {
      errorfile(); print " found ($imm) so expected immediate value expression but found <$gen>\n"; exit;
    }
  }
  else  { return (-1,-1,-1,-1); }
}

######################################################################################
sub match_dest {
  my ($strdest,$labpc) = @_;

  my $offset_size=0;
  my $s = $strdest;

if ($DEBUG>1) { print "[DEST($strdest)]\n"; }

  if ($strdest eq '$') { return (1,0); } # offset is zero

  if ($strdest =~ /(.*):B$/i) { $s=$1; $offset_size=1; }
  if ($strdest =~ /(.*):W$/i) { $s=$1; $offset_size=2; }
  if ($strdest =~ /(.*):D$/i) { $s=$1; $offset_size=4; }
  if (exists_label($s)>0) {
    my $val=read_label($s);
    my $dest=-($labpc-$val);
if ($DEBUG>1) { printf("[DEST($strdest)] dest=%X *=%X offset=%d \n",$val,$labpc,$dest); }

    if ($offset_size==1) {
     if (($dest<      64)&&($dest>=      -64)) { return ($offset_size,$dest); }
     else { 
       if ($gpass==99) {
         errorfile(); print(" branch offset ($dest) not in B range\n"); return ($offset_size,0); exit;
       } else {
         warnfile(); print(" branch offset ($dest) not in B range\n"); return ($offset_size,0); 
       }
     }
    }
    if ($offset_size==2) {
      if (($dest<    8192)&&($dest>=    -8192)) { return ($offset_size,$dest); }
      else { errorfile(); print(" branch offset ($dest) not in W range\n"); return ($offset_size,0); }
    }
    if ($offset_size==4) {
      if (($dest<16277216)&&($dest>=-16277216)) { return ($offset_size,$dest); }
      else { errorfile(); print(" branch offset ($dest) not in D range\n"); return ($offset_size,0); }
    }

    # no user defined branch offset size
    if (($dest<      64)&&($dest>=      -64)) { return (1,$dest); }
    if (($dest<    8192)&&($dest>=    -8192)) { return (2,$dest); }
    if (($dest<16277216)&&($dest>=-16277216)) { return (4,$dest); }
    errorfile(); print(" branch offset massive and completely out of range\n"); exit;
  } elsif (($gopcode eq "addr")&&($gopnoflag==1)) { 
    my ($size,$offset)=match_disp($strdest);
    my $dest=-($labpc-$offset);
    return ($size,$dest);
  } else {
      my $errs="branch target label ($strdest) not found";
      errorfile(); printf(" %s\n",$errs); exit;
  }
  return (-1,-1);
}

######################################################################################
sub match_disp {
  my ($strdisp) = @_;

if ($DEBUG>1) { print "[DISP($strdisp)]\n"; }
  my ($ok,$disp,$zz)=expr($strdisp);
  if ($ok>0) {
    if (($disp<      64)&&($disp>=      -64)) { return (1,$disp); }
    if (($disp<    8192)&&($disp>=    -8192)) { return (2,$disp); }
    if (($disp<16277216)&&($disp>=-16277216)) { return (4,$disp); }
    errorfile(); print "[DISP] branch offset massive and completely out of range\n"; exit;
  } else {
      errorfile(); print "ERROR: error parsing displacement\n"; exit;
  }
  return (-1,-1);
}

######################################################################################
sub match_cond {
  my ($cond,$labpc) = @_;

if ($DEBUG>1) { print "match_cond(): ($cond) $labpc\n"; }
  if (exists_label($cond)>0) {
    my $val=read_label($cond);
    my $disp=-($labpc-$val);
if ($DEBUG>1) { print "FOUND COND LABEL <$cond> value <$val> disp <$disp>\n"; }
    if (($disp<      64)&&($disp>=      -64)) { return (1,$disp); }
    if (($disp<    8192)&&($disp>=    -8192)) { return (2,$disp); }
    if (($disp<16277216)&&($disp>=-16277216)) { return (4,$disp); }
    my $errs=" match_cond(): branch offset massive and completely out of range";

    errorfile(); printf(" %s\n%s\n",$errs,$gasm_text[$gline]); exit;
  } else {
    #forwards jump, so assume word offset
    return (2,0xabcd); # this will be corrected on pass 2
  }
  return (-1,-1);
}

######################################################################################
sub match_short {
  my ($short) = @_;

  if ($short =~ /^#(.*)/ ) {
    $short=$1;
  } elsif ($short =~ /^\s*(.*)/ ) {
    $short=$1;
  } else {
    errorfile(); print " short constant of <$short> must start with the # immediate symbol\n"; exit;
  }
  my ($ok,$v,$zz)=expr($1);
  if ($ok>0) {
     if (($v>=-16)&&($v<=16)) {
###printf("SHORT:::(%X)(%d)\n",$v,$v);
       $v=$v&0xf; # mask all but 4 ls bits
       return ($ok,$v); 
     } elsif ((($v+0)&0xfffffff0)==0xfffffff0) {
       $v=$v&0xf; # mask all but 4 ls bits
       return ($ok,$v); 
     } else {
      errorfile(); print " short value of <$short> is not in range (-16..15)\n"; exit;
     }
  } else {
    errorfile(); print " found # so expected immediate value expression but found <$short>\n"; exit;
  }
}

######################################################################################
# fill Short field with U/W/B/0 (4 bits)
sub match_option {
  my ($options) = @_;

  my $optb=0;
  my $optu=0;
  my $optw=0;

  if ($options eq "") { return 0; } # no option list is valid

  if ($options !~ /^\[(.*)\]$/ ) {
    errorfile(); printf(" string option list must be enclosed in square brackets\n"); exit;
  }
  my $option_list=$1;
  if ($option_list =~ /B/i) { $optb=2; }
  if ($option_list =~ /U/i) { $optu=1; }
  if ($option_list =~ /W/i) { $optw=1; }

  if (($optu==1)&&($optw==1)) { print "WARNING: U with W string option is not valid in line $gline\n"; return $optb; }
  if (($optu==1)&&($optw==0)) { return (8+$optb); }
  if (($optu==0)&&($optw==1)) { return (4+$optb); }
  if (($optu==0)&&($optw==0)) { return (0+$optb); }
}

######################################################################################
sub match_mmureg {
  my ($mmu_reg) = @_;

  if ($mmu_reg =~ /BPR0/i) { return(0x0); }
  if ($mmu_reg =~ /BPR1/i) { return(0x1); }
  if ($mmu_reg =~ /PF0/i)  { return(0x4); }
  if ($mmu_reg =~ /PF1/i)  { return(0x5); }
  if ($mmu_reg =~ /SC/i)   { return(0x8); }
  if ($mmu_reg =~ /MSR/i)  { return(0xA); }
  if ($mmu_reg =~ /BCNT/i) { return(0xB); }
  if ($mmu_reg =~ /PTB0/i) { return(0xC); }
  if ($mmu_reg =~ /PTB1/i) { return(0xD); }
  if ($mmu_reg =~ /EIA/i)  { return(0xF); }

  if ($mmu_reg =~ /MCR/i)  { return(0x8); } # to check
  if ($mmu_reg =~ /TEAR/i)  { return(0xB); }
  if ($mmu_reg =~ /IVAR0/i)  { return(0xE); }
  if ($mmu_reg =~ /IVAR1/i)  { return(0xF); }
  errorfile(); printf(" unknown MMU register ($mmu_reg)\n"); exit;
}

######################################################################################
sub match_cfglist {
  my ($options) = @_;

  my $optc=0;
  my $optm=0;
  my $optf=0;
  my $opti=0;

  #if ($options eq "") { return 0; } # no option list is valid

  if ($options !~ /^\[(.*)\]$/ ) {
    errorfile(); printf(" string option list must be enclosed in square brackets\n"); exit;
  }
  my $option_list=$1;
  if ($option_list =~ /C/i) { $optc=8; }
  if ($option_list =~ /M/i) { $optm=4; }
  if ($option_list =~ /F/i) { $optf=2; }
  if ($option_list =~ /I/i) { $opti=1; }

  return $optc+$optm+$optf+$opti;
}

######################################################################################
sub match_reglist {
  my ($reglist) = @_;

  my %r;
  my $regmask=0;

#print "<$reglist>\n";
  if ($reglist !~ /^\[(.*)\]\s*$/ ) {
    errorfile(); printf(" register list must be enclosed in square brackets\n"); exit;
  }
  $reglist=$1;
  $reglist =~ s/ //g;
#print "<$reglist>\n";
  my @list=split(/,/,$reglist);
  my $noregs = scalar @list;
  for ($i=0;$i<$noregs;$i++) {
    my $reg=$list[$i];
    if ($reg !~ /^r[0-7]$/i) {
      errorfile(); printf(" illegal register name\n"); exit;
    }
    if (defined($r{$reg})) {
      errorfile(); printf(" register <$reg> appears more than once in the register list\n"); exit;
    }
    $r{$reg}=1;
#print "$i $list[$i] \n";
    if (lc($reg) eq "r0") { $regmask=$regmask|0x01; }
    if (lc($reg) eq "r1") { $regmask=$regmask|0x02; }
    if (lc($reg) eq "r2") { $regmask=$regmask|0x04; }
    if (lc($reg) eq "r3") { $regmask=$regmask|0x08; }
    if (lc($reg) eq "r4") { $regmask=$regmask|0x10; }
    if (lc($reg) eq "r5") { $regmask=$regmask|0x20; }
    if (lc($reg) eq "r6") { $regmask=$regmask|0x40; }
    if (lc($reg) eq "r7") { $regmask=$regmask|0x80; }
  }
#print "======$regmask======\n";
  return $regmask; 
}

######################################################################################
sub match_reglistx {
  my ($reglist) = @_;

  my %r;
  my $regmask=0;

#print "<$reglist>\n";
  if ($reglist !~ /^\[(.*)\]$/ ) {
    errorfile(); printf(" register list must be enclosed in square brackets\n"); exit;
  }
  $reglist=$1;
  $reglist =~ s/ //g;
#print "<$reglist>\n";
  my @list=split(/,/,$reglist);
  my $noregs = scalar @list;
  for ($i=0;$i<$noregs;$i++) {
    my $reg=$list[$i];
    if ($reg !~ /^r[0-7]$/i) {
      errorfile(); printf(" illegal register name\n"); exit;
    }
    if (defined($r{$reg})) {
      errorfile(); printf(" register <$reg> appears more than once in the register list\n"); exit;
    }
    $r{$reg}=1;
#print "$i $list[$i] \n";
    if (lc($reg) eq "r7") { $regmask=$regmask|0x01; }
    if (lc($reg) eq "r6") { $regmask=$regmask|0x02; }
    if (lc($reg) eq "r5") { $regmask=$regmask|0x04; }
    if (lc($reg) eq "r4") { $regmask=$regmask|0x08; }
    if (lc($reg) eq "r3") { $regmask=$regmask|0x10; }
    if (lc($reg) eq "r2") { $regmask=$regmask|0x20; }
    if (lc($reg) eq "r1") { $regmask=$regmask|0x40; }
    if (lc($reg) eq "r0") { $regmask=$regmask|0x80; }
  }
#print "======$regmask======\n";
  return $regmask; 
}

######################################################################################
sub match_cxpdisp {
  my ($cxp) = @_;

  if (exists_importp($cxp)) {return $gimportp_label{$cxp}; } else { return -1; }
}

######################################################################################
sub match_procreg {
  my ($short) = @_;

     if ($short =~ /^UPSR$/i)    { return 0x0; }
  elsif ($short =~ /^FP$/i)      { return 0x8; }
  elsif ($short =~ /^SP$/i)      { return 0x9; }
  elsif ($short =~ /^SB$/i)      { return 0xA; }
  elsif ($short =~ /^PSR$/i)     { return 0xD; }
  elsif ($short =~ /^INTBASE$/i) { return 0xE; }
  elsif ($short =~ /^MOD$/i)     { return 0xF; }
  else  { return -1; }
}

######################################################################################
sub addcode_scaled_index {
  my ($reg,$mode,$oldpc,$bytecnt)=@_;

  my $byte;

if ($DEBUG>11) { printf("[addcode_scaled_index] reg=%s mode=%x\n",$reg,$mode); }

  $byte=(($mode&0x1f)<<3)|($reg&0x7); $gcode[$oldpc+$bytecnt++]=$byte;

  return $bytecnt;
}

######################################################################################
sub addcode_disp {
  my ($disp,$sz,$pc,$bytecnt)=@_;

  my $byte;

if ($DEBUG>11) { printf("[addcode_disp] disp=%X sz=%d pc=%X \n",$disp,$sz,$pc); }
  if ($sz==1) { 
    $byte=(($disp&0xff)>>0)&0x7f; $gcode[$pc+$bytecnt++]=$byte;
  }
  elsif ($sz==2) { 
    $byte=(($disp&0xff00)>>8)&0x3f; $gcode[$pc+$bytecnt++]=$byte|0x80;
    $byte=(($disp&0x00ff)>>0)&0xff; $gcode[$pc+$bytecnt++]=$byte;
  }
  elsif ($sz==4) { 
    $byte=(($disp&0xff000000)>>24)&0x3f; $gcode[$pc+$bytecnt++]=$byte|0xc0;
    $byte=(($disp&0x00ff0000)>>16)&0xff; $gcode[$pc+$bytecnt++]=$byte;
    $byte=(($disp&0x0000ff00)>>8 )&0xff; $gcode[$pc+$bytecnt++]=$byte;
    $byte=(($disp&0x000000ff)>>0 )&0xff; $gcode[$pc+$bytecnt++]=$byte;
  }
  else {
    errorfile(); print(" addcode_disp(): offset too big\n"); exit;
  }
  return $bytecnt;
}

######################################################################################
sub addcode {
  my ($oldpc,$op,$opno,$opcode,$bwd,$mov_special,$operands,$usercomment,
      $genc1,$genv1,$genv11,$gen1type,
      $genc2,$genv2,$genv22,$gen2type,
      $gen1sireg,$gen1sisz,$gen1siopcode,
      $gen2sireg,$gen2sisz,$gen2siopcode,
      $offset,$length) = @_;

# pc = program counter
# op = 8,16 or 24 bit opcode binary value
# opno = 1,2 or 3 bytes of opcode
# bwd = 0 for byte, 1 for word or 3 for double word
# operands = user text of operands
# usercommen = user text of comment
# genc1 = count of bytes in gen1
# genv1 = value of gen1
# gen1type = type of gen1 (only some generate extra bytes)
# genc2 = count of bytes in gen2
# genv2 = value of gen2
# gen2type = type of gen2 (only some generate extra bytes)

#
# +-------+----------+----------+-------+-------+----------------+----------------+
# | Opcde | Gen Addr | Gen Addr | Index | Index | Displacement 1 | Displacement 2 |
# |       |  Mode 1  |  Mode 2  |   1   |   2   |  Immediate 1   |  Immediate 2   |
# +-------+----------+----------+-------+-------+----------------+----------------+
#

if ($DEBUG>9) { 
printf("[ADDCODE] PC=%X op=%x opno=%x opcode=%s bwd=%s MOV=($mov_special) \n",$oldpc,$op,$opno,$opcode,$bwd,$mov_special);
printf("[ADDCODE] gen1=#%d v1=%8x type1=%02x (si=%x/%d/%s) \n",$genc1,$genv1,$gen1type,$gen1siopcode,$gen1sireg,$gen1sisz);
printf("[ADDCODE] gen2=#%d v2=%8x type2=%02x (si=%x/%d/%s) \n",$genc2,$genv2,$gen2type,$gen2siopcode,$gen2sireg,$gen2sisz);
printf("[ADDCODE] off=%d len=%d \n",$offset,$length);
printf("\n");
}

  my $bytecnt=0;

  ####################################
  # BASIC INSTRUCTION 1,2 or 3 bytes #
  ####################################
  
  # get the instruction byte ordering sorted out - it is reversed as to that shown in the databook (which is for readability)
     if ($opno==1) { $gcode[$oldpc+$bytecnt++]=$op&0xff; }
  elsif ($opno==2) { $gcode[$oldpc+$bytecnt++]=(($op&0x00ff)>>0)&0xff; 
                     $gcode[$oldpc+$bytecnt++]=(($op&0xff00)>>8)&0xff; }
  elsif ($opno==3) { $gcode[$oldpc+$bytecnt++]=(($op&0x0000ff)>>0 )&0xff; 
                     $gcode[$oldpc+$bytecnt++]=(($op&0x00ff00)>>8 )&0xff;
                     $gcode[$oldpc+$bytecnt++]=(($op&0xff0000)>>16)&0xff; }
  else {
    errorfile(); print " opno can only be 1,2 or 3 but found <$opno>\n"; exit;
  }

  ###################
  # Scaled Indexing #
  ###################
  #addcode_scaled_index { my ($reg,$mode,$oldpc,$bytecnt)=@_;

  if ($gen1sisz ne "") {
    my $byte=($gen1siopcode<<3)+$gen1sireg;
    $gcode[$oldpc+$bytecnt++]=$byte;
    $gen1type=$gen1siopcode; #restore type so that the disp gets printed out
  }
  if ($gen2sisz ne "") {
    my $byte=($gen2siopcode<<3)+$gen2sireg;
    $gcode[$oldpc+$bytecnt++]=$byte;
    $gen2type=$gen2siopcode; #restore type so that the disp gets printed out
  }
    
  if ($gen1type==102) {
    # register list byte value
    $gcode[$oldpc+$bytecnt++]=$genv1;
  }

  ############################
  # Addressing Extension A   #
  #   Immediate Value or     #
  # Disp or                  #
  # Disp1 followed by Disp 2 #
  ############################

  # add additional bytes for immediate, displacement, absolute or ...
  if ($gen1type==ADDRESS_MODE_IMMEDIATE) {
    # IMMEDIATE... (big endian)
    if ($genc1==1) { 
      my $x=(($genv1&0xff)>>0)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
    }
    if ($genc1==2) { 
      my $x=(($genv1&0xff00)>>8)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x00ff)>>0)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
    }
    if ($genc1==4) { 
      my $x=(($genv1&0xff000000)>>24)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x00ff0000)>>16)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x0000ff00)>>8 )&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x000000ff)>>0 )&0xff; $gcode[$oldpc+$bytecnt++]=$x;
    }
    if ($genc1==8) { 
      my $x=(($genv1&0xff00000000000000)>>44)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x00ff000000000000)>>40)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x0000ff0000000000)>>36)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x000000ff00000000)>>32)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x00000000ff000000)>>24)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x0000000000ff0000)>>16)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x000000000000ff00)>>8 )&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv1&0x00000000000000ff)>>0 )&0xff; $gcode[$oldpc+$bytecnt++]=$x;
    }
  }
  if ($gen1type==ADDRESS_MODE_ABSOLUTE) {
    # ABSOLUTE... (big endian)
       if (($genv1<      64)&&($genv1>=      -64)) { $genc1=1; }
    elsif (($genv1<    8192)&&($genv1>=    -8192)) { $genc1=2; }
    elsif (($genv1<16277216)&&($genv1>=-16277216)) { $genc1=4; }
    $bytecnt=addcode_disp($genv1,$genc1,$oldpc,$bytecnt);
  }
  if ( ($gen1type==32) || 
       ($gen1type==ADDRESS_MODE_FRAME_MEMORY) || 
       ($gen1type==ADDRESS_MODE_STACK_MEMORY) || 
       ($gen1type==ADDRESS_MODE_STATIC_MEMORY) || 
       (($gen1type>=0x8)&&($gen1type<=0xF)) 
     ) {
    # DISPLACEMENT... (big endian) with encoding
    $bytecnt=addcode_disp($genv1,$genc1,$oldpc,$bytecnt);
  }

  if ($gen1type==ADDRESS_MODE_PROGRAM_MEMORY) {
    # PC relative
   $bytecnt=addcode_disp($genv1,$genc1,$oldpc,$bytecnt);
  }

  if ($gen1type==ADDRESS_MODE_EXTERNAL) {
    # EXTERNAL
    $gcode[$oldpc+$bytecnt++]=$genv1;
    my $disp1=compute_offset_size($genv11);
    $bytecnt=addcode_disp($genv11,$disp1,$oldpc,$bytecnt);
  }

  if ( ($gen1type==ADDRESS_MODE_STATIC_MEMORY_RELATIVE) ||
       ($gen1type==ADDRESS_MODE_FRAME_MEMORY_RELATIVE)   ) {
    my $disp2=compute_offset_size($genv1);
    my $disp1=compute_offset_size($genv11);
    $bytecnt=addcode_disp($genv1, $disp2,$oldpc,$bytecnt);
    $bytecnt=addcode_disp($genv11,$disp1,$oldpc,$bytecnt);
  }

  ############################
  # Addressing Extension A   #
  #   Immediate Value or     #
  # Disp or                  #
  # Disp1 followed by Disp 2 #
  ############################

  # add additional bytes for immediate, displacement, absolute or ...
  if ($gen2type==ADDRESS_MODE_IMMEDIATE) {
    # IMMEDIATE... (big endian)
    if ($genc2==1) { 
      my $x=(($genv2&0xff)>>0)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
    }
    if ($genc2==2) { 
      my $x=(($genv2&0xff00)>>8)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x00ff)>>0)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
    }
    if ($genc2==4) { 
      my $x=(($genv2&0xff000000)>>24)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x00ff0000)>>16)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x0000ff00)>>8 )&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x000000ff)>>0 )&0xff; $gcode[$oldpc+$bytecnt++]=$x;
    }
    if ($genc2==8) { 
      my $x=(($genv2&0xff00000000000000)>>44)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x00ff000000000000)>>40)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x0000ff0000000000)>>36)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x000000ff00000000)>>32)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x00000000ff000000)>>24)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x0000000000ff0000)>>16)&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x000000000000ff00)>>8 )&0xff; $gcode[$oldpc+$bytecnt++]=$x;
      my $x=(($genv2&0x00000000000000ff)>>0 )&0xff; $gcode[$oldpc+$bytecnt++]=$x;
    }
  }
  if ($gen2type==ADDRESS_MODE_ABSOLUTE) {
    # ABSOLUTE... (big endian)
       if (($genv2<      64)&&($genv2>=      -64)) { $genc2=1; }
    elsif (($genv2<    8192)&&($genv2>=    -8192)) { $genc2=2; }
    elsif (($genv2<16277216)&&($genv2>=-16277216)) { $genc2=4; }
    $bytecnt=addcode_disp($genv2,$genc2,$oldpc,$bytecnt);
  }
  if ( ($gen2type==32) ||   # BRANCH
       ($gen2type==ADDRESS_MODE_FRAME_MEMORY) || # FRAME
       ($gen2type==ADDRESS_MODE_STACK_MEMORY) || # STACK POINTER
       ($gen2type==ADDRESS_MODE_STATIC_MEMORY) || # STATIC BASE
       (($gen2type>=0x8)&&($gen2type<=0xF)) # REGISTER
     ) {
    # DISPLACEMENT... (big endian) with encoding
    $bytecnt=addcode_disp($genv2,$genc2,$oldpc,$bytecnt);
  }

  if ($gen2type==ADDRESS_MODE_PROGRAM_MEMORY) {
    # PC relative
    $bytecnt=addcode_disp($genv2,$genc2,$oldpc,$bytecnt);
  }

  if ($gen2type==ADDRESS_MODE_EXTERNAL) {
    # EXTERNAL
    $gcode[$oldpc+$bytecnt++]=$genv2;
    my $disp2=compute_offset_size($genv22);
    $bytecnt=addcode_disp($genv22,$disp2,$oldpc,$bytecnt);
  }

  if ( ($gen2type==ADDRESS_MODE_STATIC_MEMORY_RELATIVE) ||
       ($gen2type==ADDRESS_MODE_FRAME_MEMORY_RELATIVE)   ) {
    my $disp2=compute_offset_size($genv2);
    my $disp1=compute_offset_size($genv22);
    $bytecnt=addcode_disp($genv2, $disp2,$oldpc,$bytecnt);
    $bytecnt=addcode_disp($genv22,$disp1,$oldpc,$bytecnt);
  }

  ##################################
  # Implied Operands (imm or disp) #
  ##################################

  # offset+length byte from INSS and EXTS instructions...
  if (($offset>=0)&&($length>0)) {
    my $byte=($offset<<5)+($length-1);
    $gcode[$oldpc+$bytecnt++]=$byte;
  }
  # length for MOVM and CMPM instructions
  if ((($opcode eq "movm")||($opcode eq "cmpm"))&&($offset==-1)&&($length>0)) {
    my $no_of_bytes;
       if ($bwd eq "b") { $no_of_bytes=1; }
    elsif ($bwd eq "w") { $no_of_bytes=2; }
    elsif ($bwd eq "d") { $no_of_bytes=4; }
    my $disp=($length-1)*$no_of_bytes; # offset is counted in bytes so use opcode operand size to modify the raw length value
    # now calculate the number of bytes treating the length to be coded as a displacement
       if (($disp<      64)&&($disp>=      -64)) { $no_of_bytes=1; }
    elsif (($disp<    8192)&&($disp>=    -8192)) { $no_of_bytes=2; }
    elsif (($disp<16277216)&&($disp>=-16277216)) { $no_of_bytes=4; }
    $bytecnt=addcode_disp($disp,$no_of_bytes,$oldpc,$bytecnt);
  }
  # ext
  if ((($opcode eq "ext")||($opcode eq "ins"))&&($offset==-1)&&($length>0)) {
    my $no_of_bytes;
    my $disp=$length;
    # now calculate the number of bytes treating the length to be coded as a displacement
       if (($disp<      64)&&($disp>=      -64)) { $no_of_bytes=1; }
    elsif (($disp<    8192)&&($disp>=    -8192)) { $no_of_bytes=2; }
    elsif (($disp<16277216)&&($disp>=-16277216)) { $no_of_bytes=4; }
    $bytecnt=addcode_disp($disp,$no_of_bytes,$oldpc,$bytecnt);
  }

  # ENDPROC assembler directive assembles to 2 instruictions: EXIT and RET
  if ($gendproc==1) { 
    if ($glabeltype eq "INT") {
      # add 0x12,0x00 RET 0 code
      $gcode[$oldpc+$bytecnt++]=0x12; # RET
    } else {
      # add RXP <n>
      $gcode[$oldpc+$bytecnt++]=0x32; # RXP
    }
    my $len=($gparamlength-$greturnlength);
    my $sz=size_offset($len);
    $bytecnt=addcode_disp($len,$sz,$oldpc,$bytecnt);
    #####$gcode[$oldpc+$bytecnt++]=($gparamlength-$greturnlength);
    $gendproc=0;
  }

  ###############
  # GPASS == 99 #
  ###############
  
  # WRITE TO LOG

  if ($gpass==99) {
    printf(LIST "%08x PC ",$oldpc);
    my $chcnt=9;
    # print byte of code 8 bytes per line of output for readability
    my $j;
    for ($j=0;$j<$bytecnt;$j++) {
      printf(LIST "%02x",$gcode[$oldpc+$j]);
      $chcnt=$chcnt+2;
    }
    my $ln=$gasm_filelineno[$gline];
    #while ($chcnt<34) { printf(LIST " "); $chcnt++; }
    while ($chcnt<29) { print LIST "	"; $chcnt+=8; }
    printf(LIST "%6d  ",$ln);
  
    my $outtext=$gasm_text[$gline];
    printf(LIST "%s\n",$outtext);

#    $opcode=$opcode.$bwd.$mov_special;
#    my $txtlen=length($opcode);
#    printf(LIST "%s ",$opcode);
#    $chcnt=$chcnt+$txtlen;
#    while ($chcnt<50) { printf(LIST " "); $chcnt++; }
#  
#    $txtlen=length($operands);
#    printf(LIST "%s ",$operands);
#    $chcnt=$chcnt+$txtlen;
#    while ($chcnt<70) { printf(LIST " "); $chcnt++; }
#  
#    if ($usercomment ne "") { $usercomment=";".$usercomment; }
#    printf(LIST "$usercomment\n");
  }
  return $bytecnt;
}

######################################################################################
sub read_intelhex {
  my ($file) = @_;
  my $h = '[0-9A-F]';
  my $txt;

  unless(open(IN,"<".$file)) { die("Could not open file $file\n"); }
  while (<IN>) {
    chomp($txt=$_);
    my $tt=$txt;
    if ($DEBUG==1) { print "$txt\n"; }

    # nob = number of bytes of intelhex data on this line
    $txt =~ /^:($h{2})/; $txt = $';
    my $nob = hex($1);
    my $len = $nob * 2;
    my $lx = hex($1);
    $txt =~ /^($h{2})/; $txt = $';
    my $addrhi = hex($1);
    $txt =~ /^($h{2})/; $txt = $';
    my $addrlo = hex($1);

    # addr = address in the ROM
    my $addr = (256*$addrhi)+$addrlo;

    # type should always be zero
    $txt =~ /^($h{2})/; $txt = $';
    my $type = hex($1);

    # data = 32 bytes of hex data
    my $hh = "$h\{$len\}";
    $txt =~ /^($hh)($h{2})/;
    my $data = $1;

    # sum = checksum
    my $sum = hex($2);

    # extract the data into an array of bytes
    my $data_text = $data;
    my $cksum=0;
    my $ptr=$addr;
    for ($i=0; $i<$len/2; $i++) {
      $data_text =~ /^($h{2})/;
      $data_text = $';
      my $value = hex($1);
      if ($type == 0x00) { $rom[$ptr]{data} = $value; $rom[$ptr]{valid}=1; }
      if ($DEBUG==2) { printf("%02x %04x \n",$value,$ptr); }
      $ptr++;
      $cksum = ($cksum+$value)%0x100;
    }

    # re-calculate the checksum
    $cksum = ($cksum + $lx)%0x100;
    $cksum = ($cksum + $addrhi)%0x100;
    $cksum = ($cksum + $addrlo)%0x100;
    $cksum = ($cksum + $type)%0x100;
    $cksum = ($cksum + $sum)%0x100;

    #print "($nob) ($addr) ($type) $txt [$sum-$cksum]\n";
    if ($DEBUG==3) { printf("%02d %04x %02x %02x %s\n",$nob,$addr,$type,$cksum,$txt); }
  }

  close(IN);

}

######################################################################################
sub is_hex {
  my ($value) = @_;

  if (!defined($value)) { return -1; }
  if ($value =~ /[^0-9a-f]/i) { return -1; }
  if ($value !~ /[0-9a-f][0-9a-f][0-9a-f][0-9a-f]/i) { return -1; }
  my $int = hex($value);
  return $int;
}

######################################################################################
sub badexpr {
  my ($e) = @_;
  errorfile(); print "(BADEXPR): expected expr but found <$e>\n"; exit;
}

######################################################################################
sub badterm {
  my ($t) = @_;
  errorfile(); print "(BADTERM): expected term but found <$t>\n"; exit;
}

######################################################################################

# handle <term> ( + or - or | or ^ <term> ) repeated
# ==     <term> + <expr>
# ==     <term> - <expr>
# ==     <term> | <expr>
# ==     <term> ^ <expr>

# assume leading whitespace already stripped off

sub expr {
  my ($e) = @_;

if ($DEBUG>25) { print "expr():<$e> "; }
  my $rem;
  my $term1;
  my $term2;
  my $ok1;
  my $ok2;
  my $type1;
  my $type2;
  my $singletermflag=1;

  ($ok1,$term1,$rem)=term($e);
  $type1=$gexprtype;
  $type2="";
  if ($ok1==NOTOK) { 
if ($DEBUG>25) { print "*EBAD1($ok1,0,$rem)] ";  }
    return (NOTOK,0,$rem);
  }
  # special case for EXT variables
  if ($gexprtype eq "IMPORT") {
    if ($rem =~ /^\s*$/) {
if ($DEBUG>25) { print " EXT1 ok=$ok1: rem=<$rem> $term1] ";  }
      return ($ok1,$term1,"");
    }
    if ($rem =~ /^\s*\+\s*(.*)$/) {
      my $ext_offset=$1;
      #$gexprtype=""; # reset
if ($DEBUG>25) { print " EXT2 ok=$ok1: rem=<$rem> ($ext_offset) $term1] ";  }
      return ($ok1,$term1,$ext_offset);
    }

  }


  # while the expression is linked by + or - or | or ^ get the next term...
  while ($rem =~ /^\s*[-\+\|\^]/ ) {

    $singletermflag=0;
    if ($rem =~ /^\s*-\s*(.*)/) {
      $rem=$1; 
      ($ok2,$term2,$rem)=term($rem);
      if ($ok2>0) {
        if ($ok1==OKUNDEF) { $ok2=OKUNDEF; }
        $type2=$gexprtype;
if ($DEBUG>25) { print "\nexpr() ($term1 - $term2,$type1,$type2,$rem)]\n"; }
        if (($type1 eq "FP"    )&&($type2 eq "FP"   )) { $gexprtype="IMM"; }
        if (($type1 eq "SB"    )&&($type2 eq "SB"   )) { $gexprtype="IMM"; }
        if (($type1 eq "CODE"  )&&($type2 eq "CODE" )) { $gexprtype="IMM"; }
        $term1=$term1-$term2;
      } else {
        badexpr($e);
      }

    } elsif ($rem =~ /^\s*\+\s*(.*)/) {
      $rem=$1; 
      ($ok2,$term2,$rem)=term($rem);
      if ($ok2>0) {
        if ($ok1==OKUNDEF) { $ok2=OKUNDEF; }
        $type2=$gexprtype;
if ($DEBUG>25) { print "\nexpr() ($term1 + $term2,$type1,$type2,$rem)]\n"; }
        $term1=$term1+$term2;
      } else {
        badexpr($e);
      }

    } elsif ($rem =~ /^\s*\|\s*(.*)/) {
      $rem=$1; 
      ($ok2,$term2,$rem)=term($rem);
      if ($ok2>0) {
        if ($ok1==OKUNDEF) { $ok2=OKUNDEF; }
        $type2=$gexprtype;
if ($DEBUG>25) { print "\nexpr() ($term1 | $term2,$type1,$type2,$rem)]\n"; }
        $term1=$term1|$term2;
      } else {
        badexpr($e);
      }

    } elsif ($rem =~ /^\s*\^\s*(.*)/) {
      $rem=$1; 
      ($ok2,$term2,$rem)=term($rem);
      if ($ok2>0) {
        if ($ok1==OKUNDEF) { $ok2=OKUNDEF; }
        $type2=$gexprtype;
if ($DEBUG>25) { print "\nexpr() ($term1 ^ $term2,$type1,$type2,$rem)]\n"; }
        $term1=$term1^$term2;
      } else {
        badexpr($e);
      }

    } else {
      errorfile(); print(" expr(): internal error - no +,-,|,^ operator found\n"); exit;
      #return ($ok2,$term1,$rem);
    }
    # update type... (TODO)
if ($DEBUG>25) { print "\nexpr():(ok=$ok2:$term1,$rem,$type1,$type2)]\n "; }
    if    (($type1 eq "CODE")&&($type2 eq "CODE")) { $type1="IMM"; }
    elsif (($type1 eq "IMM" )&&($type2 eq "CODE")) { $type1="CODE"; }
    elsif (($type1 eq "CODE")&&($type2 eq "IMM" )) { $type1="CODE"; }
    elsif (($type1 eq "SB"  )&&($type2 eq "SB"  )) { $type1="IMM"; }
    elsif (($type1 eq "IMM" )&&($type2 eq "SB"  )) { $type1="SB"; }
    elsif (($type1 eq "SB"  )&&($type2 eq "IMM" )) { $type1="SB"; }
    else { }
    $ok1=$ok2;
if ($DEBUG>25) { print "\nexpr():(ok=$ok1:$term1,$rem,$type1)]\n "; }
  } # while

if ($DEBUG>25) { print "EOK2:(ok=$ok1,$term1,$type1,$rem)] "; }
  $gexprtype=$type1;
  return ($ok1,$term1,$rem);

}

######################################################################################

# handle <factor> ( + or - <factor> ) ^
# ==     <factor> + or - <term>

sub term {
  my ($t) = @_;

if ($DEBUG>25) { print "TERM=<$t> "; }
  my $rem;
  my $factor1;
  my $factor2;
  my $ok;

  ($ok,$factor1,$rem)=factor($t);
  if ($ok==NOTOK) { 
if ($DEBUG>25) { print "*T!(0,,$rem)] "; }
    return (NOTOK,0,$rem);
  }

  while (($rem =~ /^\s*<</)||($rem =~ /^\s*>>/)||($rem =~ /^\s*[\*\/\&]/)) {

    if ($rem =~ /^\s*\*\s*(.*)/) {
      $rem=$1; 
      ($ok,$factor2,$rem)=term($rem);
      if ($ok>0) {
        $factor1=$factor1*$factor2;
if ($DEBUG>25) { print "T1($ok,$factor1,$rem)] "; }
        #return ($ok,$factor1,$rem);
      } else {
        badterm($t);
      }
    } elsif ($rem =~ /^\s*\/\s*(.*)/) {
      $rem=$1; 
      ($ok,$factor2,$rem)=term($rem);
      if ($ok>0) {
        $factor1=$factor1/$factor2;
if ($DEBUG>25) { print "T2($ok,$factor1,$rem)] "; }
        #return ($ok,$factor1,$rem);
      } else {
        badterm($t);
      }
    } elsif ($rem =~ /^\s*\&\s*(.*)/) {
      $rem=$1; 
      ($ok,$factor2,$rem)=term($rem);
      if ($ok>0) {
        $factor1=$factor1&$factor2;
if ($DEBUG>25) { print "T3($ok,$factor1,$rem)] "; }
        #return ($ok,$factor1,$rem);
      } else {
        badterm($t);
      }
    } elsif ($rem =~ /^\s*<<\s*(.*)/) {
      $rem=$1; 
      ($ok,$factor2,$rem)=term($rem);
      if ($ok>0) {
        $factor1=$factor1<<$factor2;
if ($DEBUG>25) { print "T4($ok,$factor1,$rem)] "; }
        #return ($ok,$factor1,$rem);
      } else {
        badterm($t);
      }
    } elsif ($rem =~ /^\s*>>\s*(.*)/) {
      $rem=$1; 
      ($ok,$factor2,$rem)=term($rem);
      if ($ok>0) {
        $factor1=$factor1>>$factor2;
if ($DEBUG>25) { print "T5($ok,$factor1,$rem)] "; }
        #return ($ok,$factor1,$rem);
      } else {
        badterm($t);
      }
    
    } else {
if ($DEBUG>25) { print "TT:($ok,$factor1,$rem)] "; }
      return ($ok,$factor1,$rem);
    }
  } # while

  # a term can have something remaining
if ($DEBUG>25) { print "Tr($ok,$factor1,$rem)] "; }
  return ($ok,$factor1,$rem);

}

######################################################################################

sub factor {
  my ($f) = @_;

if ($DEBUG>25) { print "\n>>>FACTOR=<$f> "; }
  my $rem;
  #my $OK=1;

  # check for brackets...
  if ($f=~/^\(\s*(.*)/) {
    my ($ok,$expr,$rem)=expr($1);
    if ($rem=~/\s*\)\s*(.*)/) {
      if ($DEBUG>25) { printf("a %X] ",$expr); }
      $rem=$1; # remove trailing bracket
      return ($ok,$expr,$rem); 
    } else {
      badexpr($f);
    }
  } elsif ($f =~ /^([-\+~]{0,1})\s*(0x[0-9A-Fa-f]*)(.*)/) { # hex number found (0x.... format)
    # HEX 0x...
    my $negation=$1;
    my $hexs=$2;
    $rem=$3;
    $gexprtype="IMM";
    my $h=hex($hexs);
    if ($negation eq "" ) { 
      $h=($h+0)&0xffffffff;
      if ($DEBUG>25) { printf("b %X] ",$h); }
      return (OK, $h,$rem); 
    }
    if ($negation eq "+") { 
      $h=($h+0)&0xffffffff;
      if ($DEBUG>25) { printf("c %X] ",$h); }
      return (OK,-$h,$rem); 
    }
    if ($negation eq '-') { 
      $h=(-$h+0); #&0xffffffff;
      if ($DEBUG>25) { printf("d %X] ",$h); }
      return (OK,$h,$rem); 
    }
    if ($negation eq '~') { 
      my $hh= (~($h+0)&0xffffffff);
      if ($DEBUG>25) { printf("%e %X] ",$hh); }
      return (OK,$hh,$rem); 
    }
  } elsif ($f =~ /^([-\+~]{0,1})\s*x'([0-9A-Fa-f]*)(.*)/) { # alternative hex number found (x'.... format)
    # HEX x'...
    my $negation=$1;
    my $hexs="0x".$2;
    $rem=$3;
    $gexprtype="IMM";
    my $h=hex($hexs);
    if ($negation eq "" ) { 
      $h=($h+0)&0xffffffff;
      if ($DEBUG>25) { printf("f %X] ",$h); }
      return (OK, $h,$rem); 
    }
    if ($negation eq '+' ) { 
      $h=($h+0)&0xffffffff;
      if ($DEBUG>25) { printf("g %X] ",$h); }
      return (OK, $h,$rem); 
    }
    if ($negation eq '-') { 
      $h=(-$h+0); #&0xffffffff;
      if ($DEBUG>25) { printf("h %X] ",$h); }
      return (OK,$h,$rem); 
    }
    if ($negation eq '~') { 
      my $hh= (~($h+0)&0xffffffff);
      if ($DEBUG>25) { printf("i %X] ",$hh); }
      return (OK,$hh,$rem); 
    }
  } elsif ($f =~ /^([-\+~]{0,1})\s*[hH]'([0-9A-Fa-f]*)(.*)/) { # alternative hex number found (h'.... format)
    # HEX h'...
    my $negation=$1;
    my $hexs="0x".$2;
    $rem=$3;
    $gexprtype="IMM";
    my $h=hex($hexs);
    if ($negation eq "" ) { 
      $h=($h+0)&0xffffffff;
      if ($DEBUG>25) { printf("j %X] ",$h); }
      return (OK, $h,$rem); 
    }
    if ($negation eq '+' ) { 
      $h=($h+0)&0xffffffff;
      if ($DEBUG>25) { printf("k %X] ",$h); }
      return (OK, $h,$rem); 
    }
    if ($negation eq '-') { 
      $h=(-$h+0); #&0xffffffff;
      if ($DEBUG>25) { printf("l %X] ",$h); }
      return (OK,$h,$rem); 
    }
    if ($negation eq '~') { 
      my $hh= (~($h+0)&0xffffffff);
      if ($DEBUG>25) { printf("m %X] ",$hh); }
      return (OK,$hh,$rem); 
    }
  } elsif ($f =~ /^([-\+~]{0,1})\s*(\d+)(.*)/) { # decimal number found
    # DECIMAL simple
    my $negation=$1;
    my $dec=$2;
    $rem=$3;
    $gexprtype="IMM";
    if ($negation eq "" ) { 
      $dec=($dec+0)&0xffffffff;
      if ($DEBUG>25) { printf("n %X] ",$dec); }
      return (OK, $dec,$rem); 
    }
    if ($negation eq '+') { 
      $dec=($dec+0)&0xffffffff;
      if ($DEBUG>25) { printf("p %X] ",$dec); }
      return (OK,$dec,$rem); 
    }
    if ($negation eq '-') { 
      $dec=(-$dec+0); #&0xffffffff;
      if ($DEBUG>25) { printf("q %X] ",$dec); }
      return (OK,$dec,$rem); 
    }
    if ($negation eq '~') { 
      my $dd= (~($dec+0)&0xffffffff);
      if ($DEBUG>25) { printf("r %d %X] ",$dec,$dd); }
      return (OK,$dd,$rem); 
    }
  } elsif ($f =~ /^([-\+~]{0,1})\s*[dD]'(\d+)(.*)/) { # alternative decimal number found (d'.... format)
    # DECIMAL d'...
    my $negation=$1;
    my $dec=$2;
    $rem=$3;
    $gexprtype="IMM";
    if ($negation eq "" ) { 
      $dec=($dec+0)&0xffffffff;
      if ($DEBUG>25) { printf("s %X] ",$dec); }
      return (OK, $dec,$rem); 
    }
    if ($negation eq '+' ) { 
      $dec=($dec+0)&0xffffffff;
      if ($DEBUG>25) { printf("t %X] ",$dec); }
      return (OK, $dec,$rem); 
    }
    if ($negation eq '-') { 
      $dec=(-$dec+0); #&0xffffffff;
      if ($DEBUG>25) { printf("u %X] ",$dec); }
      return (OK,$dec,$rem); 
    }
    if ($negation eq '~') { 
      my $dd= (~($dec+0)&0xffffffff);
      if ($DEBUG>25) { printf("v %X] ",$dd); }
      return (OK,$dd,$rem); 
    }
  } elsif ($f =~ /^"(.)"(.*)/) { 
    # character constant found
    my $char=$1;
    $rem=$2;
    $gexprtype="IMM";
    my $val=ord($char);
    if ($DEBUG>25) { printf("w %X] ",$val); }
    return (OK,$val,$rem);
  } elsif ($f =~ /^'(.)'(.*)/) { 
    # character constant found
    my $char=$1;
    $rem=$2;
    $gexprtype="IMM";
    my $val=ord($char);
    if ($DEBUG>25) { printf("x %X] ",$val); }
    return (OK,$val,$rem);
  } elsif ($f =~ /^'(.)(.)'(.*)/) { 
    # two character constant found
    my $char1=$1;
    my $char2=$2;
    $rem=$3;
    $gexprtype="IMM";
    my $val=(ord($char1)<<8)+ord($char2);
    if ($DEBUG>25) { printf("y %X] ",$val); }
    return (OK,$val,$rem);
  } elsif ($f =~ /^'(.)(.)(.)'(.*)/) { 
    # two character constant found
    my $char1=$1;
    my $char2=$2;
    my $char3=$3;
    $rem=$4;
    $gexprtype="IMM";
    my $val=(ord($char1)<<16)+(ord($char2)<<8)+ord($char3);
    if ($DEBUG>25) { printf("z %X] ",$val); }
    return (OK,$val,$rem);
  } elsif ($f =~ /^'(.)(.)(.)(.)'(.*)/) { 
    # two character constant found
    my $char1=$1;
    my $char2=$2;
    my $char3=$3;
    my $char4=$4;
    $rem=$5;
    $gexprtype="IMM";
    my $val=(ord($char1)<<24)+(ord($char2)<<16)+(ord($char3)<<8)+ord($char4);
    if ($DEBUG>25) { printf("%X] ",$val); }
    return (OK,$val,$rem);

  #} elsif (($gdata_section==1)&&($f =~ /^\$(.*)/)) { # DSECT counter
  #  $rem=$1;
  #  my $offset_dsectpc=$gdsectpc-$gstart_dsectpc;
  #  if ($DEBUG>25) { printf("%X] ",$offset_dsectpc); }
  #  return ($OK,$offset_dsectpc,$rem); 

  } elsif ($f =~ /^\$(.*)/) { # program counter 
    $rem=$1;
    my $ppc;
    if ($gdata_section  ==1) { $ppc=$gdsectpc; $gexprtype="DATA"; }
    if ($gstatic_section==1) { $ppc=$gsbpc;    $gexprtype="SB";   }
    if ($gcode_section  ==1) { $ppc=$gpc;      $gexprtype="CODE"; }
    if ($gframe_section ==1) { $ppc=$gfppc;    $gexprtype="FP";   }
    if ($DEBUG>25) { printf("\nfactor():%s \$=%X] ",$gexprtype,$ppc); }
    return (OK,$ppc,$rem); 

  } else {
if ($DEBUG>11) { print "factor(): ($f)\n"; }
    if ($f =~ /^([-\+~])?\s*([a-zA-Z]\w*)(.*)/) {
      my $unary=$1;
      my $w=$2;
      $rem=$3;
if ($DEBUG>11) { print "unary=<$unary> "; }
if ($DEBUG>11) { print "factor(): w=<$w> rem=<$rem>\n"; }
      if (defined($gidentifier{$w})) {
        my $val=$gidentifier{$w};
          if (defined_label($w)==OKUNDEF) {
if ($DEBUG>25) { printf("factor(): UNDEFINED IDENTIFIER <$w>] \n"); }
          $gundefined_symbol=$w;
          $gexprtype="IMM"; 
          return (OKUNDEF,0xabcdef,$rem);
        }
        if    ($unary eq '-') { $val=-($val+0); }
        elsif ($unary eq '~') { $val=(~($val+0)&0xffffffff); }
        else { $val=($val+0)&0xffffffff; }
if ($DEBUG>25) { printf("factor(): IDENTIFIER <$w> value %X] \n",$val); }
        $gexprtype="IMM"; 
        return (OK,$val,$rem);

      } elsif (exists_label($w)>0) {
        if (defined_label($w)==OKUNDEF) {
if ($DEBUG>11) { printf("factor(): FOUND UNDEFINED LABEL <$w> type=<$gexprtype> rem=<$rem>] \n"); }
          $gundefined_symbol=$w;
          return (OKUNDEF,0xabcdef,$rem);
        }
        my $val=read_label($w);
        if    ($unary eq '-') { $val=-($val+0); }
        elsif ($unary eq '~') { $val=(~($val+0)&0xffffffff); }
        if ($gexprtype eq "") { $gexprtype="CODE"; } # try to figure out expression type
if ($DEBUG>11) { printf("factor(): FOUND LABEL <$w> value <%X> type=<$gexprtype> rem=<$rem>] \n",$val); }
        return (OK,$val,$rem);

      } elsif (exists_import($w)) {
        my $val=read_import($w);
        if    ($unary eq '-') { $val=-($val+0); }
        elsif ($unary eq '~') { $val=(~($val+0)&0xffffffff); }
        $gexprtype="IMPORT"; 
if ($DEBUG>11) { printf("factor(): FOUND IMPORT <%s> %X] \n",$w,$val); }
        return (OK,$val,$rem);

      } else {
if ($DEBUG>11) { print "factor(): w=<$w> rem=<$rem> gpass=<$gpass>\n"; }
        if ($gpass==0) {
          $gexprtype="PC"; 
if ($DEBUG>25) { printf("FOUND POSSIBLE LABEL <%s> rem=%X] ",$w,$rem); }
          return (OKUNDEF,0xabcdef,$rem);

        } else {
          #if ($DEBUG>25) { dump_fp_labels(1); }
          errorfile(); print " expected identifier but found <$f>\n"; exit;
        }
      }
    } else {
      errorfile(); print " expected term but found <$f>\n"; exit;
    }
  }
}

######################################################################################
sub inc_gpc {
  if ($gpc>$gpc_max) { $gpc_max=$gpc; }
  $gpc++;
}

######################################################################################
sub log_gpc {
  if ($gpc>$gpc_max) { $gpc_max=$gpc; }
}

######################################################################################
sub parse_command_line {

  my $i;
  my $o;
  my $c;

  if(!@ARGV) {
    print "No Arguments supplied\n";
    print "<filename>  (must have an extention of .32k) \n";
    print "-d<level>   (sets the debug level for the developer)\n";
    print "-eprom2764  (determines the size of the output binary - fills with 0x00)\n";
    print "-eprom27128 (determines the size of the output binary - fills with 0x00)\n";
    print "-eprom27256 (determines the size of the output binary - fills with 0x00)\n";
    print "-split2     (create two binary files of alternate bytes, suitable for EPROMS for the 16-bit NS32016)\n";
    print "-split4     (create two binary files of alternate bytes, suitable for EPROMS for the 32-bit NS32032)\n";
    print "-h          (for help)\n";
    print "\n";
    print "e.g.> ./gas32k.pl tds.32k -eprom27128 -split2 \n";
    print "\n";
    exit;
  }
  
  $split=1;
  $eprom=0;

  while($Arg = shift(@ARGV)) {
    if( $Arg !~ /^-/) {
      if ($asm_file eq "") {
        $asm_file=$Arg;
        if ($asm_file !~ /.32k$/) { 
          print "ERROR: file extention should be .32k\n";
          exit;
        }
      } else {
        # We expected a switch
        print "Switch expected instead of $Arg\n";
        exit;
      }
    }
  
    # Remove switch
    $Arg =~ s/^-//g;
  
    if($Arg eq "") {
     print "'-' cannot be used on its own\n";
     exit;
    }
  
    # examine switches
    if($Arg=~ /^h/i || $Arg =~ /\?/) {
      help();
      exit;
    }

    # examine switches
    if($Arg=~ /^eprom2764/i) {
      $eprom=(64*1024)/8;
    }

    if($Arg=~ /^eprom27128/i) {
      $eprom=(128*1024)/8;
    }

    if($Arg=~ /^eprom27256/i) {
      $eprom=(256*1024)/8;
    }

    if($Arg=~ /^split2/i) {
      $split=2;
    }

    #if($Arg=~ /^split4/i) {
    #  $split=4;
    #}

    # examine switches
    if($Arg =~ /^d(\d+)/i) {
      $DEBUG=$1;
      print "Setting debug level to $DEBUG\n";
    }
  
  
  }
  if ($asm_file eq "") { print "bad command line arguments, try -h\n\n"; exit; } 
  
}
######################################################################################
sub write_bin {

  my $pc=0;
  my $x;
  my $bootlength=$gpc_max-$gpc_min+1;
  my $byte;

  my $BIN;
  my $FORCE1;
  my $FORCE2;

  my $outbinfile     ="out.bin";
  my $outbinbootfile1="lo.bin";
  my $outbinbootfile2="hi.bin";
 
  printf("PC min=%08x max=%08x\n",$gpc_min,$gpc_max);

  if ($eprom==0) { return; }

  my $eprom_total=$eprom*$split;
  if ($gpc_max>($eprom*$split)) {
    print "ERROR: Binary is too large for selected EPROM and configurations\n";
    exit;
  }

  if ($split==1) {
    unless(open($BIN,">".$outbinfile))      { die("Could not open file $outbinfile\n"); }
    binmode($BIN);
  } elsif ($split==2) {
    unless(open($FORCE1,">".$outbinbootfile1)) { die("Could not open file $outbinbootfile1\n"); }
    unless(open($FORCE2,">".$outbinbootfile2)) { die("Could not open file $outbinbootfile2\n"); }
    binmode($FORCE1);
    binmode($FORCE2);
  } else {
  }

  while ($pc<$eprom_total) {
    if ($pc>=$gpc_max) {
      $x=0xff;
    } else {
      $x=$gcode[$pc];   
      if (!defined($x)) {
        $x=0;
      }
    }
    ###printf(BIN "%08X %02X\n",$pc,$x);
    if ($split==1) {
      $byte=pack("C",$x);  
      print $BIN $byte;
    } elsif (($split==2)&&(($pc&1)==0)) {
      $byte=pack("C",$x);  
      print $FORCE1 $byte;
    } elsif (($split==2)&&(($pc&1)==1)) {
      $byte=pack("C",$x);  
      print $FORCE2 $byte;
    } else {
    }
    $pc++;
  }

  if ($split==1) {
    close($BIN);
  } elsif ($split==2) {
    close($FORCE1);
    close($FORCE2);
  } else {
  }
  
}

######################################################################################

sub help {
print <<EOF;

***************************************************
* Migry's Assembler for the NS32016 Microprocessor *
***************************************************

Release 1.53

This Perl executable reads in a text file containing NS32016 assembly language and directives and 
outputs both a text list file (out.lis) and a binary file (out.bin).
The assembler is multi-pass and will attempt to code branch offsets into as few bytes as possible.
Currently floating point opcodes are not supported.

A limited number of assembly directives are supported:-
   .org <value> - to set the new assembly code address (0x0000 is assumed if there is no initial .org statement)
   .double <value> [, <value> [ etc.]] - store double word value(s) (4 bytes)
   .word   <value> [, <value> [ etc.]] - store word value(s) (2 bytes)
   .byte   <value> [, <value> [ etc.]] - store byte value(s) (1 byte)
   - the above directives can take a list of values which must be comma separated 
   - decimal numbers are the default
   - hex numbers can be coded either 0x1234 or x'1234 (negative -0x1234 or -x'1234)
   <identifier> equ <expression>
   - currently <expression> can only be a simple number

EOF
}

######################################################################################
sub check_symbol {
  my ($label) = @_;

  my $exists=exists_label($label);
  if ($exists == 0) { return; } # OK

  my $defined_at_ln=$gasm_filelineno[$gline];
  my $ln=defined_at_line($label);
  if ($defined_at_ln == $ln) { return; } # OK

  errorfile(); print(" symbol ($label) previously defined at line $ln\n"); exit;
}

######################################################################################

sub errorfile {
  my $fi=$gasm_fileindex[$gline];
  my $ln=$gasm_filelineno[$gline];
  my $fn= $gasm_filelist[$fi-1];
  printf("\nERROR(%s,line %s):",$fn,$ln); 
}

######################################################################################

sub warnfile {
  my $fi=$gasm_fileindex[$gline];
  my $ln=$gasm_filelineno[$gline];
  my $fn= $gasm_filelist[$fi-1];
  printf("WARNING(%s,line %s):",$fn,$ln); 
}

######################################################################################

sub store_import {
  my ($label) = @_;

#  # check if already exists...
#  if (defined($gimport_label{$label})) {
#    return;
#  }
#if ($DEBUG>10) { printf("STORING IMPORT %s=%x\n",$label,$gimport_count); }
#  $gimport_label{$label}=$gimport_count;
#  $gimport_count++;
#}

  my $exists=exists_label($label);

  if ($exists==0) {
    # no... so add it to the global structure...
    if ($DEBUG>10) { printf("STORING IMPORT %s=%x line=%d\n",$label,$gimport_count,$gline); }
    $gimport_label{$label}=$gimport_count;
    my $ln=$gasm_filelineno[$gline];
    $gimport_label_defline{$label}=$ln;
    $gimport_count++;
    return;
  }

  if ($exists==SYMBOL_IMPORT) {
    if ($gpass==0) {
      my $line=$gimport_label_defline{$label};
      errorfile(); printf(" import <$label> previously defined in line $line\n"); exit;
    } else {
      return;
    }
  } 

  redefined($label);
}

######################################################################################

sub store_importp {
  my ($label) = @_;

#  # check if already exists...
#  if (defined($gimportp_label{$label})) {
#    return;
#  }
#if ($DEBUG>10) { printf("STORING IMPORTP %s=%x\n",$label,$gimport_count); }
#  $gimportp_label{$label}=$gimport_count;
#  $gimport_count++;

  my $exists=exists_label($label);

  if ($exists==0) {
    # no... so add it to the global structure...
    if ($DEBUG>10) { printf("STORING IMPORTP %s=%x line=%d\n",$label,$gimport_count,$gline); }
    $gimportp_label{$label}=$gimport_count;
    my $ln=$gasm_filelineno[$gline];
    $gimportp_label_defline{$label}=$ln;
    $gimport_count++;
    return;
  }

  if ($exists==SYMBOL_IMPORTP) {
    if ($gpass==0) {
      my $line=$gimportp_label_defline{$label};
      errorfile(); printf(" importp <$label> previously defined in line $line\n"); exit;
    } else {
      return;
    }
  } 

  redefined($label);
}

######################################################################################

sub store {
  my ($label) = @_;

  if ($gdata_section==1)   { 
    store_dsect_label($label,$gdsectpc); 
  }
  elsif ($gstatic_section==1) { 
    store_sb_label($label,$gsbpc); 
  }
  elsif ($gcode_section==1) {
    store_pc_label($label,$gpc); 
  }
  elsif ($gframe_section==1) {
    store_fp_label($label,$gfppc); 
  } else {
    errorfile(); print(" store(): internal error - no label found ($label)\n"); exit;
  }
}

######################################################################################
sub inc_pc {
  my ($x) = @_;
  if ($gdata_section==1)   { $gdsectpc=$gdsectpc+$x; }
  if ($gstatic_section==1) { $gsbpc=$gsbpc+$x; }
  if ($gcode_section==1)   { $gpc=$gpc+$x; }
  if ($gframe_section==1)  { 

    if ($gparam_section==1)  {
      $gfppc+=$x;
      $gparamlength+=$x;
      $gparamname[$gparamcount]="0";
      $gparamoffset[$gparamcount]=0;
      if ($gparamcount>0) {
        for (my $i=0;$i<$gparamcount;$i++) {
          $gparamoffset[$i]+=($x);
        }
      }
      $gparamcount++;
if ($DEBUG>25) { printf("inc_pc(): FP PARAM %x \n",$gfppc); }
    }

    if ($greturn_section==1) {
      $gfppc-=$x;
      $greturnlength+=$x;
if ($DEBUG>25) { printf("inc_pc(): FP RETURN %x \n",$gfppc); }
    }

    if ($glocal_section==1) {
      $glocallength+=$x;
if ($DEBUG>25) { printf("inc_pc(): FP LOCAL %x \n",$glocallength); }
    }
  }
}

######################################################################################

sub store_and_inc {
  my ($label,$blkb,$size) = @_;

  if ($gdata_section==1)   { 
if ($DEBUG>25) { printf("store_and_inc():DATA %08X %s\n",$gdsectpc,$label); }
    store_dsect_label($label,$gdsectpc); 
    check_symbol($label);
    $gdsectpc=$gdsectpc+($blkb*$size); 
  }

  elsif ($gstatic_section==1) { 
if ($DEBUG>25) { printf("store_and_inc():SB   %08X %s\n",$gsbpc,$label); }
    store_sb_label($label,$gsbpc); 
    check_symbol($label);
    $gsbpc=$gsbpc+($blkb*$size); 
  }

  elsif ($gcode_section==1) {
if ($DEBUG>25) { printf("store_and_inc():CODE %08X %s\n",$gpc,$label); }
    store_pc_label($label,$gpc); 
    check_symbol($label);
    $gpc=$gpc+($blkb*$size); 
  }

  elsif ($gframe_section==1) {
if ($DEBUG>25) { printf("store_and_inc():FP   %08X %s\n",$gfppc,$label); }
    check_symbol($label);
    store_fp_label($label,$gfppc); 
    
    if ($gparam_section==1) {
      $gfppc+=($blkb*$size); 
      $gparamlength+=($blkb*$size); 
      $gparamname[$gparamcount]=$label;
      $gparamoffset[$gparamcount]=0;
      if ($gparamcount>0) {
        for (my $i=0;$i<$gparamcount;$i++) {
          $gparamoffset[$i]+=($blkb*$size);
if ($DEBUG>25) { printf("store_and_inc(): FP PARAM %s=%x \n",$gparamname[$i],$gparamoffset[$i]); }
        }
      }
      $gparamcount++;
    }
    if ($greturn_section==1) {
      $gfppc-=($blkb*$size); 
      $greturnlength+=($blkb*$size); 
      $gfp_label{$label}=$gfppc;
if ($DEBUG>25) { printf("store_and_inc(): FP RETURN %s=%x \n",$label,$gfppc); }
    }
    if ($glocal_section==1) {
      $gfppc-=($blkb*$size); 
      $glocallength+=($blkb*$size); 
      $gfp_label{$label}=$gfppc;
if ($DEBUG>25) { printf("inc_pc(): FP LOCAL %s=%x \n",$label,$glocallength); }
    }
   
  } else {
    errorfile(); print(" store(): internal error - no label found ($label)\n"); exit;
  }
}

######################################################################################

sub print_label {
  my ($label) = @_;

  if ($gpass==99) {
    printf(LIST "%s:\n",$label); 
  }

}

######################################################################################
sub print_blkb {

  my ($rawasm,$label) = @_;
  my $val;
  my $t;

  if ($gpass==99) {

    my $ln=$gasm_filelineno[$gline];
    if ($gdata_section==1)   { $t="IM"; $val=$gdsect_label{$label}; } 
    if ($gstatic_section==1) { $t="SB"; $val=$gsb_label{$label}; } 
    if ($gcode_section==1)   { $t="PC"; $val=$gcode_label{$label}; }
    if ($gframe_section==1)  { $t="FP"; $val=$gfp_label{$label}; 
      printf(LIST "			%6d  %s\n",$ln,$rawasm); 
      return;
    }

    printf(LIST "%08x %s			%6d  %s\n",$val,$t,$ln,$rawasm); 
  }

}

######################################################################################
sub print_blkw {

  my ($rawasm,$label) = @_;
  my $val;
  my $t;

  if ($gpass==99) {

    my $ln=$gasm_filelineno[$gline];
    if ($gdata_section==1)   { $t="IM"; $val=$gdsect_label{$label}; } 
    if ($gstatic_section==1) { $t="SB"; $val=$gsb_label{$label}; } 
    if ($gcode_section==1)   { $t="PC"; $val=$gcode_label{$label}; }
    if ($gframe_section==1)  { $t="FP"; $val=$gfp_label{$label}; 
      printf(LIST "			%6d  %s\n",$ln,$rawasm); 
      return;
    } 

    printf(LIST "%08x %s			%6d  %s\n",$val,$t,$ln,$rawasm); 
  }

}

######################################################################################
sub print_blkd {

  my ($rawasm,$label) = @_;
  my $val;
  my $t;

  if ($gpass==99) {

    my $ln=$gasm_filelineno[$gline];
    if ($gdata_section==1)   { $t="IM"; if ($label eq "") { $val=$gdsectpc; } else { $val=$gdsect_label{$label}; } }
    if ($gstatic_section==1) { $t="SB"; if ($label eq "") { $val=$gsbpc;    } else { $val=$gsb_label   {$label}; } }
    if ($gcode_section==1)   { $t="PC"; if ($label eq "") { $val=$gpc;      } else { $val=$gcode_label {$label}; } }
    if ($gframe_section==1)  { $t="FP"; if ($label eq "") { $val=$gfppc;    } else { $val=$gfp_label   {$label}; }  
      printf(LIST "			%6d  %s\n",$ln,$rawasm); 
      return;
    }

    printf(LIST "%08x %s			%6d  %s\n",$val,$t,$ln,$rawasm); 
  }

}

######################################################################################
sub print_word_byte_data {

  my ($pc,$count,$size) = @_;

  my $outtext=$gasm_text[$gline];
  my $rawasm=$gasm_text[$gline];

  $outtext =~ s/^\s+//; # strip leading whitespace

  my $byte_idx=0;
  my $ocnt=0;

  my $pctype="??";
  if ($gdata_section==1)   { $pctype="DS"; } 
  if ($gstatic_section==1) { $pctype="SB"; } 
  if ($gcode_section==1)   { $pctype="PC"; }
  if ($gframe_section==1)  { $pctype="FP"; } 

  $ocnt+=12; printf(LIST "%08x %s ",$pc,$pctype); # print address field

  if ($size==1) {
    my $max= ($count>10)?10:$count;
    for (my $j=0;$j<$max;) {
      my $ch=$gcode[$pc+$j++];
      $ocnt+=2; printf(LIST "%02x",$ch); 
    }
    while ($ocnt<31) { print LIST "	"; $ocnt+=8; }
  }

  if ($size==2) {
    $count=$count*2;;
    my $max= ($count>10)?10:$count;
    for (my $j=0;$j<$max;) {
      my $ch1=$gcode[$pc+$j++];
      my $ch2=$gcode[$pc+$j++];
      $ocnt+=4; printf(LIST "%02x%02x",$ch1,$ch2); 
    }
    while ($ocnt<31) { print LIST "	"; $ocnt+=8; }
  }

  if ($size==4) {
    $count=$count*4;;
    my $max= ($count>10)?10:$count;
    for (my $j=0;$j<$max;) {
      my $ch1=$gcode[$pc+$j++];
      my $ch2=$gcode[$pc+$j++];
      my $ch3=$gcode[$pc+$j++];
      my $ch4=$gcode[$pc+$j++];
      $ocnt+=8; printf(LIST "%02x%02x%02x%02x",$ch1,$ch2,$ch3,$ch4); 
    }
    while ($ocnt<31) { print LIST "	"; $ocnt+=8; }
  }

  my $ln=$gasm_filelineno[$gline];
  my $rawasm=$gasm_text[$gline];
  printf(LIST "%6d  %s\n",$ln,$rawasm); 

  return $ocnt;
}

######################################################################################
# size is 1 for float and 2 for long

sub tofloat {
  my($size,$sign,$pre,$post,$echar,$esign,$exp) = @_;

  if (!defined($pre))  { $pre="0"; }
  if (!defined($post)) { $post="0"; }
  if (!defined($exp))  { $exp=0; } else { $exp=$exp+0; }
  if ((defined($esign))&&($esign eq '-'))  { $exp=-$exp; }
#print "FLOAT1 ($pre,$post).($exp)\n";
  my $len=length($post);
  for (my $i=0;$i<$len;$i++) {
   $pre=$pre*10;
   $exp=$exp-1;
  }
#print "FLOAT2 ($pre,$post).($exp)\n";
  my $ff=$pre+$post+0;
  if ((defined($sign))&&($sign eq '-')) { $ff=-$ff; }
  $ff = $ff * (10**$exp);
#print "FLOAT3 $ff = ($pre,$post).($exp)\n";

  if ($size==1) {
    my $z=unpack("b32",pack("f",$ff));
    my $rz=reverse $z;
    my $word=oct("0b".$rz);
    return $word;
  } else {
    my $z=unpack("b64",pack("d",$ff));
    my $rz=reverse $z;
    my $word=oct("0b".$rz);
    return $word;
  }
}

######################################################################################
# $gdsectpc=doalign($gdsectpc,$expr1,$expr2); }
sub doalign {
  my ($pc,$base,$offset) = @_;

  my $rem = $pc % $base;
  $pc = $pc - $rem;
  $pc = $pc + $base + $offset;
  return ($pc);
}

######################################################################################
# return code part and comment part
sub parse_comment {
    my $text = shift;      # record containing comma-separated values
    my @new  = ();
    my $p;
    my $flag=0;

#print "#####COMMENT   : $text\n";
    while ($text =~ m{
          \s*([Hh]'[0-9a-fA-F]+)
        | \s*([Xx]'[0-9a-fA-F]+)
        | \s*(\[.*?\])\s*
        | \s*(".*?")\s*
        | \s*('.*?')\s*
        | ([,;])
    }gx) {
      $p=pos($text);
      my $match=$+;
#print "#####COMMENTXX : ($match)$p\n";
      if ($match eq ";") { $flag=1; last; }
    }

    if ($flag==1) {
      my $str=substr($text,0,$p-1);
      my $com=substr($text,$p,length($text)-$p);
#print "#####COMMENTRET: ($str);($com)\n";
      return ($str,$com);
    } else {
      return ($text,"");
    }
}

######################################################################################
#
# code copied from https://www.oreilly.com/library/view/perl-cookbook/1565922433/ch01s16.html
#
sub parse_operands {
    my $text = shift;      # record containing comma-separated values
    my @new  = ();
    push(@new, $+) while $text =~ m{
        # the first part groups the phrase inside the quotes.
        # see explanation of this pattern in MRE
             \s*(\[\s*[^\]]*\])\s*,? 
           | \s*("\s*[^\"]*")\s*,? 
           | \s*('\s*[^']*')\s*,? 
           | \s*([^,]+)\s*,? 
           | ,
       }gx;
       push(@new, undef) if substr($text, -1,1) eq ',';
       return @new;      # list of values that were comma-separated
}

######################################################################################
# 
# ---------------------------------------------------------------------------
# | Precedence|Operator |      Name      |     Operation                  |
# ---------------------------------------------------------------------------
# | Unary Operators:                                                      |
# ---------------------------------------------------------------------------
# |     1     |    +     |  unary positive|  identity                     |
# |     1     |    -     |  unary minus   |  two's complement             |
# |     1     |    ~     |  complement    |  one's complement             |
# ---------------------------------------------------------------------------
# | Binary Operators:                                                     |
# ---------------------------------------------------------------------------
# |     2     |    *     |  multiply      |  multiply 1st and 2nd terms   |
# |     2     |    /     |  divide        |  divide 1st by 2nd term       |
# |     2     |    %     |  modulus       |  remainder of 1st / 2nd term  |
# |     2     |    &     |  logical AND   |  bit AND of 1st and 2nd terms |
# |     2     |   <<     |  shift left    |  shift 1st by 2nd term;       |
# |           |          |                |  emptied bits are zero-filled |
# |     2     |   >>     |  shift right   |  shift 1st by 2nd term;       |
# |           |          |                |  emptied bits are zero-filled |
# |     3     |    +     |  add           |  add 1st and 2nd terms        |
# |     3     |    -     |  subtract      |  subtract 1st and 2nd terms   |
# |     3     |    |     |  logical or    |  bit OR of 1st and 2nd terms  |
# |     3     |    ^     |  exclusive or  |  bit exclusive OR of 1st and  |
# |           |          |                |  2nd terms                    |
# ---------------------------------------------------------------------------
# .pa
#                    TABLE 2-2  TYPES AND OPERATORS
# 
# ---------------------------------------------------------------------------
# |  Unary operators:                                                     |
# |                                                                       |
# |             Operator        Term1   Operation                         |
# |                                                                       |
# |                +             %1     identity of %1                    |
# |                -             %1     two's complement of %1            |
# |                ~             %1     one's complement of %1            |
# ---------------------------------------------------------------------------
# |  Binary operators:                                                    |
# |                                                                       |
# |     Term1   Operator    Term2       Operation                         |
# |       %1       *          #2        multiply %1 by #2                 |
# |       %1       /          #2        divide %1 by #2                   |
# |       %1       %          #2        modulus of %1 divided by #2       |
# |       %1       &          #2        bit-wise logical AND of %1 and #2 |
# |       %1      <<          #2        shift %1 left by #2 positions     |
# |       %1      >>          #2        shift %1 right by #2 positions    |
# |                                                                       |
# |       %1       +          #2        add %1 and #2                     |
# |       %1       -          #2        subtract #2 from %1               |
# |       %1       -          &2        subtract &2 from %1               |
# |                                                                       |
# |       $1       +          #2        add $1 and #2                     |
# |       $1       -          #2        subtract #2 from $1               |
# |       $1       -          &2        subtract &2 from $1               |
# |                                                                       |
# |       %1       |          #2        bit-wise logical OR of %1 and #2  |
# |       %1       ^          #2        bit wise exclusive OR of %1 and #2|
# ---------------------------------------------------------------------------
# .cw 12
# Notation:
# 
# #2   may be a term which has Immediate type.   It must appear  to
#      the right of the operator.
# 
# %1   may be a term which has either Immediate or Absolute type or
#      one  of the Relative types.   This term must appear  to  the
#      right  of  a   unary operator or to the  left  of  a  binary
#      operator.
# 
# $1   may be a term with External type.   It must appear  to  the
#      left of the operator.
# 
# &2   must  be a term which has the same type as the  first  term.
#      It must appear to the right of a binary operator.
# .pa
#  2.8.1  Rules for Expressions
# 
# Expressions must follow the following rules:
# 
#  a)  Unary  operators precede single terms,  e.g.  the expression
#      ~(-1) is legal, but 7 ~(-1) is not.
# 
#  b)  Binary operators separate two terms, e.g. the expression 7+2
#      is legal, but 7+*2 is not.
# 
#  c)  Expressions  may  be  made  up  of  several  other   smaller
#      expressions.  Unary and binary operators may be used to link
#      up the smaller expressions,  e.g.  the two expressions "2+1"
#      and  "4+2"  may  be combined with a  division  operator  and
#      parentheses   to  obtain  the  single  compound   expression
#      "(2+1)/(4+2)".
# 
#  d)  Expressions are evaluated by three rules:
# 
#    - Parentheses.   Expressions  within  parentheses  are  always
#      evaluated first.  E.g.  the expression "16/8/2" evaluates to
#      "1", while the expression "16/(8/2)" evaluates to "4".
# 
#    - Precedence Groups.  An operator of a higher precedence group
#      will  cause the assembler to evaluate the terms  surrounding
#      that  operator  prior to terms surrounding an operator of  a
#      lower  precedence  whenever  parentheses  do  not  otherwise
#      control  the  evaluation order,  e.g the expression  "8+8/4"
#      evaluates  to "10",  but the expression "8/8+4  evaluates to
#      "5".
# 
#    - Left to Right Evaluation.  Expressions evaluate from left to
#      right  whenever  parentheses  or  precedence  rules  do  not
#      otherwise  determine evaluation order,  e.g.  the expression
#      "4*2/1"  evaluates  as  "8",   but  the  expression  "4/2*1"
#      evaluates to "2".
# 
# 
######################################################################################
