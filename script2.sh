#!/usr/bin/env bash
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "mile/mile/Info.plist")

MAJOR="$( cut -d '.' -f 1 <<< "$version" )"
MINOR="$( cut -d '.' -f 2 <<< "$version" )"
PATCH="$( cut -d '.' -f 3 <<< "$version" )"

CURRENT_VERSION=release/${MAJOR}.${MINOR}.0

echo "Creating new milestone version"
BRANCH=${MAJOR}.$(($MINOR+1)).0
MILESTONE="\"$BRANCH\""
CREATE_NEW_MILESTONE=1
counter=1
curl -H "Authorization: token $1" \
"https://api.github.com/repos/tinder-dmytroryshchuk/milestone/milestones" > milestones_json
cat milestones_json | jq '.[].title' > milestones_title
cat milestones_json | jq '.[].number' > milestones_number
while read milestones_title
do
	echo "========================= exists ========================="
	read milestone <<< $(awk 'NR=="'$counter'"' milestones_title)
	echo $milestone
	echo $MILESTONE
	if [ $milestone == $MILESTONE ]; then
		read number <<< $(awk 'NR=="'$counter'"' milestones_number)
		echo "~~Milestone $number is already exist~~"
		NEW_MILESTONE_NUMBER=$number
		CREATE_NEW_MILESTONE=0
	fi
	((counter++))
done < milestones_title
if [ $CREATE_NEW_MILESTONE -eq 1 ]; then
	NEW_MINOR=$(($MINOR+1))
	NEW_VERSION=${MAJOR}.${NEW_MINOR}.0
	due_date=$(date -v +14d '+%Y-%m-%d')"T17:00:00Z"
	echo "~~" $NEW_VERSION "version of milestone was created~~"
	curl -H "Authorization: token $1" --include --request POST \
	--data '{"title":"'${NEW_VERSION}'", "due_on": "'$due_date'"}' \
	"https://api.github.com/repos/tinder-dmytroryshchuk/milestone/milestones" > json
	sed -n '/{/,/} /p' json > new_milestone_json
	cat new_milestone_json | jq -r ".number" > new_milestone_number
	read NEW_MILESTONE_NUMBER <<< $(awk 'NR==1' new_milestone_number)
fi
rm -f json new_milestone_json new_milestone_number milestones_json milestones_number milestones_title


echo "Get milestone number"
curl https://api.github.com/repos/tinder-dmytroryshchuk/milestone/milestones > file
cat file | jq -r ".[].number" > milestone_number
counter=1
MILESTONE_NUMBER=0
while read milestone_number		
do		
	read pr_nb <<< $(awk 'NR=="'$counter'"' milestone_number)		
	CURRENT_MILESTONE_NUMBER=$(($pr_nb+0))		
	if [ $counter -eq 1 ]; then
		MILESTONE_NUMBER=$CURRENT_MILESTONE_NUMBER
	fi		
	if [ $CURRENT_MILESTONE_NUMBER -lt $MILESTONE_NUMBER ]; then		
		MILESTONE_NUMBER=$CURRENT_MILESTONE_NUMBER
	fi	
	((counter++))		
done < milestone_number
rm -f milestone_number milestones_json file

echo "Get all PRs from current milestone and set V+1"
echo "OLD:"$MILESTONE_NUMBER
echo "NEW:"$NEW_MILESTONE_NUMBER
while [ $MILESTONE_NUMBER -lt $NEW_MILESTONE_NUMBER ]; do
	curl -H "Authorization: token $1" \
	"https://api.github.com/repos/tinder-dmytroryshchuk/milestone/issues?milestone=$MILESTONE_NUMBER" | jq -r ".[].number" > pr_number

	counter=1
	while read pr_number
	do
		read pr_nb <<< $(awk 'NR=="'$counter'"' pr_number)
		echo "== $pr_nb updating... =="
		((counter++))
		curl -H "Authorization: token $1" \
		"https://api.github.com/repos/tinder-dmytroryshchuk/milestone/issues/$pr_nb/labels" | jq -r ".[].name" > label_names
		labelCounter=1
		labelExist=0		
		while read label_names
		do
			read name <<< $(awk 'NR=="'$labelCounter'"' label_names)
			if [ $name == "next-release" ]; then
				labelExist=1
			fi
			((labelCounter++))
		done < label_names
		if [ $labelExist == 0 ]; then
			curl -H "Authorization: token $1" --include --request PATCH --data \
			'{"milestone":"'$NEW_MILESTONE_NUMBER'"}' "https://api.github.com/repos/tinder-dmytroryshchuk/milestone/issues/$pr_nb"
		elif [ $labelExist == 1 ]; then
			curl -H "Authorization: token $1" --include --request PATCH --data \
			'{"base":"'$CURRENT_VERSION'"}' \
			"https://api.github.com/repos/tinder-dmytroryshchuk/milestone/pulls/$pr_nb"
		fi
	done < pr_number
	rm -f pr_number label_names
	MILESTONE_NUMBER=$(($MILESTONE_NUMBER+1))
done

echo "Switching back to develop"
git checkout master
