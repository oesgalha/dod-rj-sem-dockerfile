# Pastas com arquivos das camadas da imagem
IMAGE_L1="l1"
IMAGE_L2="l2"
# Pasta para montar (assemble) a imagem
IMAGE_ASBL="imagedir"
mkdir -p "${IMAGE_ASBL}/blobs/sha256"

#------------------------------------------------------------------------------
# Preenche, compacata e move as camadas para a imagem final
# -----------------------------------------------------------------------------

# Preencher a camada 1
CAT_PATH=$(which cat)
CAT_DEPS=$(ldd ${CAT_PATH} | grep -oE "/lib.*/\S+")
for file in ${CAT_PATH} $CAT_DEPS ; do
    mkdir -p "${IMAGE_L1}$(dirname $file)"
    cp $file "${IMAGE_L1}${file}"
done
mkdir -p "${IMAGE_L1}/var/data/"
cat <<EOF > "${IMAGE_L1}/var/data/hello.txt"
Boa tarde, Rio de Janeiro!
EOF
cat <<EOF > "${IMAGE_L1}/var/data/lixo.txt"
Este arquivo não deve estar na imagem final.
EOF

# Adicionar a camada 1 na imagem final
tar -C ${IMAGE_L1} -c -f l1.tar .
gzip -k l1.tar
cp l1.tar.gz \
  ${IMAGE_ASBL}/blobs/sha256/$(sha256sum l1.tar.gz | cut -d " " -f 1)

# Preencher a camada 2
mkdir -p "${IMAGE_L2}/var/data/"
cat <<EOF > "${IMAGE_L2}/var/data/dod.txt"
Oi, DevOpsDays Rio!
EOF
touch "${IMAGE_L2}/var/data/.wh.lixo.txt"

# Adicionar a camada 2 na imagem final
tar -C ${IMAGE_L2} -c -f l2.tar .
gzip -k l2.tar
cp l2.tar.gz \
  ${IMAGE_ASBL}/blobs/sha256/$(sha256sum l2.tar.gz | cut -d " " -f 1)

#------------------------------------------------------------------------------
# Preenche a imagem final com os arquivos JSON:
# oci-layout, config.json, manifest.json e index.json
# -----------------------------------------------------------------------------

cat <<EOF > "${IMAGE_ASBL}/oci-layout"
{
  "imageLayoutVersion": "1.0.1"
}
EOF

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
      "sha256:$(sha256sum l1.tar | cut -d " " -f 1)",
      "sha256:$(sha256sum l2.tar | cut -d " " -f 1)"
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
    "size": $(du -b config.json | grep -oE "[0-9]+" | head -1),
    "digest": "sha256:$(sha256sum config.json | cut -d " " -f 1)"
  },
  "layers": [
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": $(du -b l1.tar.gz | grep -oE "[0-9]+" | head -1),
      "digest": "sha256:$(sha256sum l1.tar.gz | cut -d " " -f 1)"
    },
    {
      "mediaType": "application/vnd.oci.image.layer.v1.tar+gzip",
      "size": $(du -b l2.tar.gz | grep -oE "[0-9]+" | head -1),
      "digest": "sha256:$(sha256sum l2.tar.gz | cut -d " " -f 1)"
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
      "size": $(du -b manifest.json | grep -oE "[0-9]+" | head -1),
      "digest": "sha256:$(sha256sum manifest.json | cut -d " " -f 1)",
      "platform": {
        "architecture": "amd64",
        "os": "linux"
      }
    }
  ]
}
JSON

tar -C $IMAGE_ASBL -c -f dodrj.tar .
