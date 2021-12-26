BEGIN{
    flag=0
    fileBegin=-1
    fileEnd=-1
    bodyBegin=-1
};
{
    if ( NR == 1 ){
        bodyBegin=substr($1, 3)
    }
    if ( NR >= bodyBegin && NR >= fileBegin && NR <= fileEnd)
        print $0
    if($1=="@")flag=0
    if(flag==1) #inside dir
        if(substr($2, 1, 1) == "-") #current line is file
            if($1 == file){ #names matching
                fileBegin=$4 + bodyBegin - 1
                fileEnd=$5 + fileBegin - 1
            }
    if($2==path)flag=1
};