#args p=path f=fileName
{
    if($1 == "directory" && $2 == p){
        print $0
        print f " -rw-r--r-- 0"
    }else{
        print $0
    }
}