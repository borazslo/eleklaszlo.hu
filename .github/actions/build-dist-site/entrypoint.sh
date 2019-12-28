#!/bin/bash



#https://bpaulino.com/entries/10-automating-your-work-with-github-actions



# Exit immediately if a pipeline returns a non-zero status.
set -e

echo "🚀 Starting deployment action"

# Here we are using the variables
# - GITHUB_ACTOR: It is already made available for us by Github. It is the username of whom triggered the action
# - GITHUB_TOKEN: That one was intentionally injected by us in our workflow file.
# Creating the repository URL in this way will allow us to `git push` without providing a password
# All thanks to the GITHUB_TOKEN that will grant us access to the repository
REMOTE_REPO="https://${GITHUB_ACTOR}:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# We need to clone the repo here.
# Remember, our Docker container is practically pristine at this point
git clone $REMOTE_REPO repo
cd repo

# Install all of our dependencies inside the container
# based on the git repository Gemfile
echo "⚡️ Installing project dependencies..."
bundle install

# Build the website using Jekyll
echo "🏋️ Building website..."
JEKYLL_ENV=production bundle exec jekyll build
echo "Jekyll build done"

# Now lets go to the generated folder by Jekyll
# and perform everything else from there
cd _site

echo "☁️ Publishing website"

# We don't need the README.md file on this branch
rm -f README.md

# Now we init a new git repository inside _site
# So we can perform a commit
git init
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"

git add .
# That will create a nice commit message with something like: 
# Github Actions - Fri Sep 6 12:32:22 UTC 2019
git commit -m "Github Actions - $(date)"
echo "Build branch ready to go. Pushing to Github..."
# Force push this update to our gh-pages



git push --force $REMOTE_REPO master:gh-pages

echo "And pushing to eleklaszlo.hu..."

echo "${SSH_PRIVATE_KEY}" > proba.txt
chmod 600 proba.txt

#ssh-add proba.txt
#git push --force ssh://eleklaszlo@eleklaszlo.hu/home/eleklaszlo/eleklaszlo.git master:master

#ssh-add - <<< "${SSH_PRIVATE_KEY}"

#eval "$(ssh-agent -s)"
#
#echo "Próba 1"
ssh-agent bash -c 'ssh-add proba.txt; git push --force ssh://eleklaszlo@eleklaszlo.hu/home/eleklaszlo/eleklaszlo.git master:master'
echo "Próba 2"
#ssh-agent bash -c 'ssh-add proba.txt; git push --force ssh://eleklaszlo@eleklaszlo.hu/home/eleklaszlo/eleklaszlo.git master:master'



echo "ok!"
# Now everything is ready.
# Lets just be a good citizen and so some clean-up after ourselves
rm -fr .git
cd ..
rm -rf repo
echo "🎉 New version deployed 🎊"