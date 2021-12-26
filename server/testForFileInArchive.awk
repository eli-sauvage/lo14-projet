BEGIN{
    flag=0 #wether we are between the directory "path" and its "@"
    res=1
};
{
    if($1=="@")flag=0
    if(flag==1) #inside dir
        if(substr($2, 1, 1) == "-") #current line is file
            if($1 == file) #names matching
                res=0
    if($2==path)flag=1
};
END{
    print res
}