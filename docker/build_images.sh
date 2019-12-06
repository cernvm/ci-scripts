
build_docker_image() {
  local directory="$1"

  echo "Working on $directory"

  pushd $directory > /dev/null
  ./build.sh >> build.log 2>&1 || echo "Error on $directory"; return 1
  docker build . -t "cvmfs/$(basename $directory)" >> docker.log 2>&1
  popd > /dev/null
}
export -f build_docker_image

parallel="1"

while getopts "p:" opt; do
  case $opt in 
    p) 
      parallel="$OPTARG"
      ;;
  esac
done

ls images/*/Dockerfile | xargs -n 1 dirname | xargs -n 1 -P "$parallel" -I {} bash -c 'build_docker_image "{}"'

