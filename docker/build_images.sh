
build_docker_image() {
  local directory="$1"

  echo "$directory"

  pushd $directory
  ./build.sh 2>&1 >> build.log || return 1
  docker build . -t "cvmfs/$(basename $directory)" 2>&1 >> docker.log
  popd
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

