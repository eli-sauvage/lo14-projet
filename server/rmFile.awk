# args : p=path f=folderName
BEGIN{
    blockH=0
    blockB=0
    flag=0
    folder=p"/"f
};
{
    if ( NR == 1 ){
        bodyBegin=substr($1, 3)
        print "3:"substr($1, 3)-1
    }
    if($1 == "@")flag=0
    if(flag && NR != 1){
        if($1 == f){
            for(i=bodyBegin+$4-1; i<=bodyBegin+$4+$5-2; i++){#?? mais ça marche
                lignesASuppr[i]=1
            }
        }else{
            print $0
        }
    }
    else if(NR != 1){
        if(lignesASuppr[NR]){
            print " "
        }else{
            print $0
        }
    }
    if($1=="directory" && $2 == p)flag=1
};
END{

}