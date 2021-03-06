# !/bin/bash

SCRIPT_PATH=~/UiO/rse-tools/contingencytables

rewrite=TRUE
valid_chapter_number='^[0-9]+$'
ch_num=0

if [ $2 = false ] || [ $2 = FALSE ]
then
	rewrite=FALSE
	if [[ $3 =~ $valid_chapter_number ]]; then
		ch_num=$3
	else
		echo "No chapter number provided. I'll try to estimate it from the code"
	fi
elif [[ $2 =~ $valid_chapter_number ]]; then
		ch_num=$2
else
	echo "No chapter number provided. I'll try to estimate it from the code"
fi

if [ $ch_num -eq 0 ]; then
	R -e "source('$SCRIPT_PATH/reformat.R'); reformat('$1', saveOutput=$rewrite)"
else
	R -e "source('$SCRIPT_PATH/reformat.R'); reformat('$1', $ch_num, $rewrite)"
fi
