#!/bin/bash

#
# erase specific datasets
# test.sh --dry  -r=/xrdpfc/testalja /store/data/Run2016D /store/data/Run2016H
#
# erase all files in the local root
# test.sh --dry  -r=/xrdpfc/testalja
#

for i in "$@"
do
case $i in
    -r=*|--root=*)
    OSSROOT="${i#*=}"
    shift # past argument=value
    echo osslocalroot $OSSROOT
    ;;
    --dry)
    echo "dry run"
    DRY=YES
    shift # past argument with no value
    ;;
    *)
    # take unknown option as dataset
    PATHS="$PATHS $i"
    ;;
esac
done


# erase all files and links from the local root
if [ -z $PATHS ]; then
   PATHS="/"
fi


echo "datasets = [$PATHS]"


for path in $PATHS
do
xpath=$OSSROOT$path
echo "processing [$xpath] .."
if [ -z $xpath ]; then
   echo "empty path"
   exit 1;
fi

if [ ! -e $xpath ]; then
   echo "$xpath does not exists"
   exit 1;
fi

for lf in `find $xpath -type l`
do
  if [ -z $DRY ]; then
     rm `readlink $lf`
     rm $lf
  else
     echo $lf     
     readlink $lf
  fi 
done
done

