#args p=path f=fileName
BEGIN{
    flag=0
};
{
    print $0
    if($1 == "@" && flag){
        flag=0
        print "directory "p"/"f
        print "@"
    }

    if($1 == "directory" && $2 == p){
        flag=1
        print f" drw-r--r-- 0"
    }
}