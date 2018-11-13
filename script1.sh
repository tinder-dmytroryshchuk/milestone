#!/usr/bin/env bash
version=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "mile/mile/Info.plist")

MAJOR="$( cut -d '.' -f 1 <<< "$version" )"
MINOR="$( cut -d '.' -f 2 <<< "$version" )"
PATCH="$( cut -d '.' -f 3 <<< "$version" )"

CURRENT_VERSION=release/${MAJOR}.${MINOR}.0
echo $CURRENT_VERSION

echo "Verify release branch is deleted"
curl https://api.github.com/repos/tinder-dmytroryshchuk/milestone/branches/$CURRENT_VERSION \
-H "Authorization: token $1" | jq -r ".name" > release_exist
read verify <<< $(awk 'NR==1' release_exist)
rm -f release_exist

if [ $verify = $CURRENT_VERSION ]; then
	echo "$CURRENT_VERSION branche still exists"; exit
fi

echo "Bump Version"
NEW_MINOR=$(($MINOR+1))

NEW_VERSION=${MAJOR}.${NEW_MINOR}.0

build_number=$(printf "%d%02d%02d00" "$MAJOR" "$NEW_MINOR" 0)

/usr/libexec/PlistBuddy -c "Set CFBundleVersion $build_number" "mile/mile/Info.plist"
/usr/libexec/PlistBuddy -c "Set CFBundleShortVersionString $NEW_VERSION" "mile/mile/Info.plist"

echo "Committing the change"
git add mile/mile/Info.plist
git commit -m "Preparing for next release $NEW_VERSION"
git push

NEW_BRANCH=release/${MAJOR}.$(($MINOR+1)).0
echo "Creating branch $NEW_BRANCH"
git checkout -b $NEW_BRANCH
echo NEW_BRANCH=${NEW_BRANCH} >new_branch

echo "Pushing"
git push --set-upstream origin $NEW_BRANCH
