
if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  # webp, zstd, xz, libtiff, libxcb cause a conflict with building webp, libtiff, libxcb
  # libxdmcp causes an issue on macOS < 11
  # curl from brew requires zstd, use system curl
  # if php is installed, brew tries to reinstall these after installing openblas
  # remove lcms2 and libpng to fix building openjpeg on arm64
  brew remove --ignore-dependencies webp zstd xz libpng libtiff libxcb libxdmcp curl php lcms2 ghostscript
  # brew remove --ignore-dependencies webp zstd xz libpng libtiff libxcb libxdmcp curl php lcms2
  # brew remove --ignore-dependencies libdeflate || true

  brew install pkg-config

  if [[ "$PLAT" == "arm64" ]]; then
    export MACOSX_DEPLOYMENT_TARGET="11.0"
  else
    export MACOSX_DEPLOYMENT_TARGET="10.10"
  fi
fi

if [[ "$MB_PYTHON_VERSION" == pypy3* ]]; then
  MB_PYTHON_OSX_VER="10.9"
  if [[ "$PLAT" == "i686" ]]; then
    DOCKER_TEST_IMAGE="multibuild/xenial_$PLAT"
  fi
elif [[ "$MB_PYTHON_VERSION" == "3.11" ]] && [[ "$PLAT" == "i686" ]]; then
  DOCKER_TEST_IMAGE="radarhere/bionic-$PLAT"
fi


echo "::group::Cmake varification"
  cmake --version
  brew list --versions cmake
  brew uninstall cmake
echo "::endgroup::"


echo "::group::Install a virtualenv"
  source multibuild/common_utils.sh
  source multibuild/travis_steps.sh
  python3 -m pip install --index-url 'https://:2023-04-01T09:28:03.251098Z@time-machines-pypi.sealsecurity.io/' virtualenv
  python3 -m pip install --index-url 'https://:2023-04-01T09:28:03.251098Z@time-machines-pypi.sealsecurity.io/' cmake
  cmake --version
  python3 -m pip show cmake
  export PATH="$(python3 -m pip show cmake | awk '/Location/ {print $2}')/cmake/data/bin:$PATH"
  echo $PATH
  before_install
echo "::endgroup::"

echo "::group::Build wheel"
  clean_code
  build_wheel
  ls -l "${GITHUB_WORKSPACE}/${WHEEL_SDIR}/"
echo "::endgroup::"

if [[ $MACOSX_DEPLOYMENT_TARGET != "11.0" ]]; then
  echo "::group::Test wheel"
    install_run
  echo "::endgroup::"
fi
