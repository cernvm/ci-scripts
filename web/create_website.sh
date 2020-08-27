
# we start by cloning the repository that contains the website
git clone https://github.com/cernvm/web-team
git clone https://github.com/cernvm/web-cernvm
git clone https://github.com/cernvm/web-cvmfs

# we create the structure to hold the html pages
mkdir content
pushd content
mkdir fs filesystem cvmfs appliance vm team
popd


# we create the "main" websites using the docker image included in the repo
pushd web-team
docker build . -t web-team:latest
docker run -v $WORKSPACE/content/team:/root/team --rm web-team:latest bundle exec jekyll build --destination /root/team
popd

pushd web-cernvm
docker build . -t web-cernvm:latest
docker run -v $WORKSPACE/content/appliance:/root/appliance --rm web-cernvm:latest bundle exec jekyll build --destination /root/appliance
popd

pushd web-cvmfs
docker build . -t web-cvmfs:latest
docker run -v $WORKSPACE/content/fs:/root/fs --rm web-cvmfs:latest bundle exec jekyll build --destination /root/fs
popd

# we copy the websites to all the folders
pushd content
cp -r appliance/* vm/
cp -r fs/* filesystem/
cp -r fs/* cvmfs/
cp -r team/* .
popd

