{%- raw -%} 
#!/bin/bash

if [[ -n $(pgrep ${0} 2>/dev/null | grep -v $$) ]]
 then echo "Script is already running"; exit 1
fi

if [[ ${#} != 3 ]]
 then echo 'Args not found'; exit 1
fi

OutFile=${1}
TmpFile="${OutFile}.tmp"
Times=${2}
Interval=${3}
unset Result

Result=$(/usr/bin/iostat -xm -g ALL -T ${Interval} ${Times} 2>/dev/null | sed -rn 's/^\s+(ALL\s+.*)$/\1/p' | tail -n +2)
printf "${Result}\n" > ${TmpFile} && mv -f ${TmpFile} ${OutFile}

unset OutFile
unset TmpFile
unset Times
unset Result
unset Interval

exit 0
{% endraw %}
