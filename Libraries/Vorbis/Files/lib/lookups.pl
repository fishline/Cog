#!/usr/bin/perl
print <<'EOD';
/********************************************************************
 *                                                                  *
 * THIS FILE IS PART OF THE OggVorbis SOFTWARE CODEC SOURCE CODE.   *
 * USE, DISTRIBUTION AND REPRODUCTION OF THIS LIBRARY SOURCE IS     *
 * GOVERNED BY A BSD-STYLE SOURCE LICENSE INCLUDED WITH THIS SOURCE *
 * IN 'COPYING'. PLEASE READ THESE TERMS BEFORE DISTRIBUTING.       *
 *                                                                  *
 * THE OggVorbis SOURCE CODE IS (C) COPYRIGHT 1994-2002             *
 * by the XIPHOPHORUS Company http://www.xiph.org/                  *
 *                                                                  *
 ********************************************************************

  function: lookup data; generated by lookups.pl; edit there
  last mod: $Id$

 ********************************************************************/

#ifndef _V_LOOKUP_DATA_H_

#ifdef FLOAT_LOOKUP
EOD

$cos_sz=128;
$invsq_sz=32;
$invsq2exp_min=-32;
$invsq2exp_max=32;

$fromdB_sz=35;
$fromdB_shift=5;
$fromdB2_shift=3;

$invsq_i_shift=10;
$cos_i_shift=9;
$delta_shift=6;

print "#define COS_LOOKUP_SZ $cos_sz\n";
print "static float COS_LOOKUP[COS_LOOKUP_SZ+1]={\n";

for($i=0;$i<=$cos_sz;){
    print "\t";
    for($j=0;$j<4 && $i<=$cos_sz;$j++){
	printf "%+.13f,", cos(3.14159265358979323846*($i++)/$cos_sz) ;
    }
    print "\n";
}
print "};\n\n";

print "#define INVSQ_LOOKUP_SZ $invsq_sz\n";
print "static float INVSQ_LOOKUP[INVSQ_LOOKUP_SZ+1]={\n";

for($i=0;$i<=$invsq_sz;){
    print "\t";
    for($j=0;$j<4 && $i<=$invsq_sz;$j++){
	my$indexmap=$i++/$invsq_sz*.5+.5;
	printf "%.12f,", 1./sqrt($indexmap);
    }
    print "\n";
}
print "};\n\n";

print "#define INVSQ2EXP_LOOKUP_MIN $invsq2exp_min\n";
print "#define INVSQ2EXP_LOOKUP_MAX $invsq2exp_max\n";
print "static float INVSQ2EXP_LOOKUP[INVSQ2EXP_LOOKUP_MAX-\\\n".
      "                              INVSQ2EXP_LOOKUP_MIN+1]={\n";

for($i=$invsq2exp_min;$i<=$invsq2exp_max;){
    print "\t";
    for($j=0;$j<4 && $i<=$invsq2exp_max;$j++){
	printf "%15.10g,", 2**($i++*-.5);
    }
    print "\n";
}
print "};\n\n#endif\n\n";


# 0 to -140 dB
$fromdB2_sz=1<<$fromdB_shift;
$fromdB_gran=1<<($fromdB_shift-$fromdB2_shift);
print "#define FROMdB_LOOKUP_SZ $fromdB_sz\n";
print "#define FROMdB2_LOOKUP_SZ $fromdB2_sz\n";
print "#define FROMdB_SHIFT $fromdB_shift\n";
print "#define FROMdB2_SHIFT $fromdB2_shift\n";
print "#define FROMdB2_MASK ".((1<<$fromdB_shift)-1)."\n";

print "static float FROMdB_LOOKUP[FROMdB_LOOKUP_SZ]={\n";

for($i=0;$i<$fromdB_sz;){
    print "\t";
    for($j=0;$j<4 && $i<$fromdB_sz;$j++){
	printf "%15.10g,", 10**(.05*(-$fromdB_gran*$i++));
    }
    print "\n";
}
print "};\n\n";

print "static float FROMdB2_LOOKUP[FROMdB2_LOOKUP_SZ]={\n";

for($i=0;$i<$fromdB2_sz;){
    print "\t";
    for($j=0;$j<4 && $i<$fromdB_sz;$j++){
	printf "%15.10g,", 10**(.05*(-$fromdB_gran/$fromdB2_sz*(.5+$i++)));
    }
    print "\n";
}
print "};\n\n#ifdef INT_LOOKUP\n\n";


$iisz=0x10000>>$invsq_i_shift;
print "#define INVSQ_LOOKUP_I_SHIFT $invsq_i_shift\n";
print "#define INVSQ_LOOKUP_I_MASK ".(0x0ffff>>(16-$invsq_i_shift))."\n";
print "static long INVSQ_LOOKUP_I[$iisz+1]={\n";
for($i=0;$i<=$iisz;){
    print "\t";
    for($j=0;$j<4 && $i<=$iisz;$j++){
	my$indexmap=$i++/$iisz*.5+.5;
	printf "%8d,", int(1./sqrt($indexmap)*65536.+.5);
    }
    print "\n";
}
print "};\n\n";

$cisz=0x10000>>$cos_i_shift;
print "#define COS_LOOKUP_I_SHIFT $cos_i_shift\n";
print "#define COS_LOOKUP_I_MASK ".(0x0ffff>>(16-$cos_i_shift))."\n";
print "#define COS_LOOKUP_I_SZ $cisz\n";
print "static long COS_LOOKUP_I[COS_LOOKUP_I_SZ+1]={\n";

for($i=0;$i<=$cisz;){
    print "\t";
    for($j=0;$j<4 && $i<=$cisz;$j++){
	printf "%8d,", int(cos(3.14159265358979323846*($i++)/$cos_sz)*16384.+.5) ;
    }
    print "\n";
}
print "};\n\n";


print "#endif\n\n#endif\n";


