
# we create the structure to hold the html pages
mkdir content
pushd content
mkdir fs appliance team
popd

USEROPT="-u $(id -u):$(id -g) -v /etc/passwd:/etc/passwd:ro"

# we create the "main" websites using the docker image included in the repo
pushd web-team
docker build . -t web-team:latest
docker run $USEROPT -v $WORKSPACE/content/team:/build/team --rm web-team:latest bundle exec jekyll build --destination /build/team
popd

pushd web-cernvm
docker build . -t web-cernvm:latest
docker run $USEROPT -v $WORKSPACE/content/appliance:/build/appliance --rm web-cernvm:latest bundle exec jekyll build --destination /build/appliance
popd

pushd web-cvmfs
docker build . -t web-cvmfs:latest
docker run $USEROPT -v $WORKSPACE/content/fs:/build/fs --rm web-cvmfs:latest bundle exec jekyll build --destination /build/fs
popd

# we copy the websites to all the folders
pushd content
cp -r team/* .
popd

