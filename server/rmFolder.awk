# args : p=path f=folderName
BEGIN{
    flag=0
    blockPrint=0
    folder=p"/"f
    # print folder
    inParentDir=0
    bodyBegin=-1
    blockPrintB=0
    lignesEnMoins=0
    out=""
};
{
    if ( NR == 1 ){
        bodyBegin=substr($1, 3)
    }
    if( linesToDel[NR] == 1){
        blockPrintB=1
    }
    if($1 == "@" && flag == 1)
        blockPrint=1
    if($1 == "@"){
        flag=0
        inParentDir=0
    }
    if(flag && substr($2, 1, 1) == "-" && $3 != 0){
        # print"---------------"$0
        for(i=bodyBegin+$4-1; i<=bodyBegin+$4+$5-2; i++){#?? mais ça marche
            # print "**"i
            linesToDel[i]=1
        }
    }
    if($1 == "directory"){
        if(substr($2, 1, length(folder)) == folder){#in folder or subfolder to delete
            flag=1
        }
        if($2 == p) inParentDir=1
    }
    if(inParentDir && $1 == f)blockPrint=1
    if(!flag && !blockPrint && !blockPrintB && NR != 1){
        out=out$0"\n"
    }else if(!blockPrintB){
        lignesEnMoins++
        # print "-----"NR$0flag blockPrint blockPrintB lignesEnMoins
    }
    if(blockPrint){
        blockPrint=0
    }
    if(blockPrintB){
        out=out" \n"
        blockPrintB=0
    }
};
END{
    print "3:"bodyBegin-lignesEnMoins+1 #+1 for 3:x
    print out
}