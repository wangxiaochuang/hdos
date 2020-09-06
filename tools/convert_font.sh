count=0
echo "systemFont:"
while read line
do
    # empty line is \r\n
    if [ `echo $line |wc -w` -eq 0 ]; then
        count=0
        continue
    fi
    array=(${line})
    if [ ${array[0]} = "char" ]; then
        #echo new char ${array[1]}
        :
    else
        ((count=count+1))
        if [[ $count -ne 1 ]]; then
            echo -n " ,"
        else
            echo -n "db "
        fi
        echo ${array[0]} |sed "s#\x0d##g" |tr '.*' '01' |sed 's#.*#ibase=2;&#g' |bc |xargs printf "%03xH"
        if [[ $count -eq 16 ]]; then
            echo ""
        fi
        
    fi
done < font.txt
echo ""
