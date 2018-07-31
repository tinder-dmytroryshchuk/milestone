# !/usr/bin/env bash -x

# Force expected repository state
# git checkout develop
# git reset --hard origin/develop

# echo "Ensure local repo is up-to-date"
# git remote update --prune origin

echo "Check that some release branch exists"
set -o pipefail
RELEASE_PAIR=`git ls-remote --heads --exit-code origin release/* | tail -n 1`
set +o pipefail
read -r RELEASE_SHA RELEASE_BRANCH <<< ${RELEASE_PAIR}
RELEASE_BRANCH=${RELEASE_BRANCH#refs/heads/}
RELEASE_NUMBER=${RELEASE_BRANCH#release/}
# echo $RELEASE_BRANCH
echo $RELEASE_NUMBER

echo "Get a milestone for PR"
curl https://api.github.com/repos/tinder-dmytroryshchuk/milestone/milestones | jq -r ".[].title" > title_name

read TITLE1 <<< $(awk 'NR==1' title_name)
read TITLE2 <<< $(awk 'NR==2' title_name)

echo "title1: ${TITLE1}"
echo "title2: ${TITLE2}"

version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "mile/mile/Info.plist")

MAJOR="$( cut -d '.' -f 1 <<< "$version" )"
MINOR="$( cut -d '.' -f 2 <<< "$version" )"
PATCH="$( cut -d '.' -f 3 <<< "$version" )"

NEW_MINOR=$(($MINOR+2))

NEW_VERSION=${MAJOR}.${NEW_MINOR}.0

build_number=$(printf "%d%02d%02d00" "$MAJOR" "$NEW_MINOR" 0)

echo "app version: ${version}"
echo "new version: ${NEW_VERSION}"
# echo $MAJOR
# echo $MINOR
# echo $PATCH
# echo $NEW_MINOR
# echo $build_number

if [[ $TITLE1 = $RELEASE_NUMBER ]]; then
	echo "Exist"
	# exit
elif [[ $TITLE2 = $RELEASE_NUMBER ]]; then
	echo "Exist"
	# exit
else
	echo "Nope"
fi

echo "Finish"
