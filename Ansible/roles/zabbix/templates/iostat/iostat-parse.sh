{%- raw -%}
#!/bin/bash

ParameterNumber=0
FromFile=${1}
Metric=${2}

if [[ ${#} != 2 ]]
 then echo "FATAL: some parameters not specified"; exit 1
fi

if ([[ ! -r ${FromFile} ]] || [[ ! -s ${FromFile} ]])
 then echo "FATAL: datafile not found or having zero size"; exit 1
fi

case ${Metric} in
 "rrqm/s") ParameterNumber=2; ;;
 "wrqm/s") ParameterNumber=3; ;;
 "r/s") ParameterNumber=4; ;;
 "w/s") ParameterNumber=5; ;;
 "rkb/s") ParameterNumber=6; ;;
 "wkb/s") ParameterNumber=7; ;;
 "avgrq-sz") ParameterNumber=8; ;;
 "avgqu-sz") ParameterNumber=9; ;;
 "await") ParameterNumber=10; ;;
 "r_await") ParameterNumber=11; ;;
 "w_await") ParameterNumber=12; ;;
 "svctm") ParameterNumber=13; ;;
 "util") ParameterNumber=14; ;;
 *) echo ZBX_NOTSUPPORTED; exit 1 ;;
esac

grep -w ALL ${FromFile} | awk -v ParameterNumber=${ParameterNumber} -F' ' 'BEGIN {sum=0.0;count=0;} {sum=sum+$ParameterNumber;count=count+1;} END {printf("%.2f\n", sum/count);}'
{% endraw %}
