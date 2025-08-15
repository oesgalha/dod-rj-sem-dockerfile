ctrid=$(buildah from python:3.11-slim)
buildah copy $ctrid ./sample /opt/sample
buildah config --workingdir "/opt/sample" $ctrid
buildah run $ctrid -- pip install -r requirements.txt
buildah config --entrypoint "uvicorn app.main:app --host 0.0.0.0 --port 8000" $ctrid
buildah commit $ctrid sample-buildah
