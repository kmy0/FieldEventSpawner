git pull --recurse-submodules
git submodule update --init --recursive
pushd deps\fes_util
call build.bat
popd
md bin\reframework
md bin\reframework\plugins
robocopy reframework bin\reframework /mir
robocopy deps\fes_util\bin bin\reframework\plugins fes_util.dll
tar -a -cf FieldEventSpawner.zip -C bin reframework
