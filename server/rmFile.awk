# args : p=path f=folderName
BEGIN{
    flag=0
    folder=p"/"f
};
{
    if ( NR == 1 ){
        bodyBegin=substr($1, 3)
    }
    if($1 == "@")flag=0
    if(flag){
        if($1 == f){
            for(i=bodyBegin+$4-1; i<=bodyBegin+$4+$5-2; i++){#?? mais ça marche
                lignesASuppr[i]=1
            }
        }else{
            print $0
        }
    }
    else{
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
