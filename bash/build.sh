# Pasta com arquivos seguindo o FHS da imagem final
IMAGE_ROOT="workdir"
# Pasta para montar (assemble) a imagem
IMAGE_ASBL="imagedir"

# Preencher a raiz da imagem final
CAT_PATH=$(which cat)
CAT_DEPS=$(ldd ${CAT_PATH} | grep -oE "/lib.*/\S+")
for file in ${CAT_PATH} $CAT_DEPS ; do
    mkdir -p "${IMAGE_ROOT}$(dirname $file)"
    cp $file "${IMAGE_ROOT}${file}"
done
mkdir -p "${IMAGE_ROOT}/var/data/"
cat <<EOF > "${IMAGE_ROOT}/var/data/hello.txt"
Boa tarde, Rio de Janeiro!
EOF

tar -C ${IMAGE_ROOT} -c -f img.tar .

mkdir -p "${IMAGE_ASBL}/blobs/sha256"
cat <<EOF > "${IMAGE_ASBL}/oci-layout"
{
  "imageLayoutVersion": "1.0.1"
}
EOF
gzip -k img.tar
cp img.tar.gz \
  ${IMAGE_ASBL}/blobs/sha256/$(sha256sum img.tar.gz | cut -d " " -f 1)

cat <<EOF > config.json
{
  "architecture": "amd64",
  "os": "linux",
  "config": {
    "Env": [ "PATH=/usr/bin" ],
    "Entrypoint": [ "/usr/bin/cat" ],
    "Cmd": [ "/var/data/hello.txt" ]
  },
  "rootfs": {
    "type": "layers",
    "diff_ids": [
      "sha256:$(sha256sum img.tar | cut -d " " -f 1)"
    ]
  }
}
EOF
cp config.json \
  ${IMAGE_ASBL}/blobs/sha256/$(sha256sum config.json | cut -d " " -f 1)

cat <<EOF > manifest.json
{
  "schemaVersion": 2,
  "config": {
    "mediaType": "application/vnd.oci.image.config.v1+json",
    "size": $(du -b config.json | grep -oE "[0-9]+"),
    "digest": "sha256:$(sha256sum config.json | cut -d " " -f 1)"
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": $(du -b img.tar.gz | grep -oE "[0-9]+"),
      "digest": "sha256:$(sha256sum img.tar.gz | cut -d " " -f 1)"
    }
  ]
}
EOF
cp manifest.json \
  imagedir/blobs/sha256/$(sha256sum manifest.json | cut -d " " -f 1)


cat <<JSON > imagedir/index.json
{
  "schemaVersion": 2,
  "manifests": [
    {
      "mediaType": "application/vnd.oci.image.manifest.v1+json",
      "size": $(du -b manifest.json | grep -oE "[0-9]+"),
      "digest": "sha256:$(sha256sum manifest.json | cut -d " " -f 1)",
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    }
  ]
}
JSON

tar -C imagedir -c -f oci-cat.tar .
