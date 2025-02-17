if [ "$1" = "start" ]
then
    echo "begin script"
    export TERM=dumb
    script $2
fi

if [ "$1" = "reset" ]
then
    echo "reset script"
    export TERM=xterm-256color
fi