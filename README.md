# Containers sem Dockerfile

Repositório com exemplos sobre construção de imagens de container sem o uso
de Dockerfile. Usado em apresentação no DevOpsDays RJ 2025.

## Estrutura do repositório

A pasta `bash` tem um exemplo de como montar uma imagem de container apenas com
utilitários de uma distribuição linux básica.

A pasta `sample` tem um exemplo de aplicação em Python com um hello world
usando FastAPI. Ela será usada como exemplo de aplicação empacotada com outras
ferramentas que geram imagens de container.

## Bash

Para criar um tar com uma imagem OCI do exemplo bash:
```
cd bash/
sh build.sh
```

Para carregar e executar a imagem:
```
podman load < dodrj.tar
podman image ls # para descobrir o id da imagem
podman run --rm <imageid>
```

Para rodar com docker:
```
podman save <imageid> | docker load
docker run --rm <imageid>
```

## Cloud Native Buildpacks

Para gerar uma imagem da aplicação `sample` com CNB:
```
pack build sample-cnb --buildpack paketo-buildpacks/python --builder paketobuildpacks/builder-jammy-base --path sample/
docker run -p 8000:8000 sample-cnb
```

## Nixpacks

Para gerar uma imagem da aplicação `sample` com Nixpacks:
```
nixpacks build ./sample/ --name sample-nixpack
docker run -p 8000:8000 sample-nixpack
```

## apko

Para gerar uma imagem da aplicação `sample` com apko + melange:
```
cd sample/
melange keygen
melange build melange.yml --arch amd64 --runner docker --signing-key melange.rsa
apko build apko.yml sample-apko:0.1 sample-apko.tar -k melange.rsa.pub
docker load < sample-apko.tar
docker run -p 8000:8000 sample-apko:0.1-amd64
```

## buildah

Para gerar uma imagem da aplicação `sample` com buildah:
```
sh buildah
podman run -p 8000:8000 --rm localhost/sample-buildah
```
