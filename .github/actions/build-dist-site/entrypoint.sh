#!/bin/bash



#https://bpaulino.com/entries/10-automating-your-work-with-github-actions

# Exit immediately if a pipeline returns a non-zero status.
# set -e

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

chown -R $(whoami) /github/workspace
chmod -R 777 /github/workspace

export BUNDLER_VERSION='2.0'
gem install bundler

# Build the website using Jekyll
echo "🏋️ Building website..."
 jekyll --version
JEKYLL_ENV=production bundle exec jekyll build --trace
echo "Jekyll build done"

# Now lets go to the generated folder by Jekyll
# and perform everything else from there

if [[ -d "_site" ]]
then
    cd _site
else
    echo "Nem jött létre a könyvtár."
	exit	
fi


echo "☁️ Publishing website"

# We don't need the README.md file on this branch
rm -f README.md

# Now we init a new git repository inside _site
# So we can perform a commit
git config --global user.name "${GITHUB_ACTOR}"
git config --global user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git config --global --add safe.directory /github/workspace/repo/_site

git init
git branch -m master
git add .
git commit -m "Github Actions - $(date)"

echo "☁️ Build branch ready to go. Pushing to Github..."
git push --force $REMOTE_REPO master:gh-pages

echo "☁️ Make Cpanel deploy the newest version..."
curl -H "Authorization: cpanel eleklaszlo:$CPANEL" 'https://eleklaszlo.hu:2083/execute/VersionControlDeployment/create?repository_root=%2fhome%2feleklaszlo%2fpublic_html%2feleklaszlo.hu'


# Now everything is ready.
# Lets just be a good citizen and so some clean-up after ourselves
rm -fr .git
cd ..
rm -rf repo
echo "🎉 New version deployed 🎊"
