#args p=path f=fileName
{
    if(NR==1)print $1":"$2+1
    else if($1 == "directory" && $2 == p){
        print $0
        print f " -rw-r--r-- 0"
    }else{
        print $0
    }
}