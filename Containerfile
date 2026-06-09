# Allow build scripts to be referenced without being copied into the final image
FROM scratch AS ctx
COPY build_files /

# Base Image
FROM ghcr.io/ublue-os/bluefin:stable

## Other possible base images include:
# FROM ghcr.io/ublue-os/bazzite:latest
# FROM ghcr.io/ublue-os/bluefin-nvidia:stable
# 
# ... and so on, here are more base images
# Universal Blue Images: https://github.com/orgs/ublue-os/packages
# Fedora base image: quay.io/fedora/fedora-bootc:41
# CentOS base images: quay.io/centos-bootc/centos-bootc:stream10

# akmods, as per the example in http://github.com/ublue-os/akmods readme
# In case of incompatibilities, where builds fail with a message like
#   nothing provides kernel-uname-r = 7.0.8-100.fc43.x86_64 needed by kmod-wl-6.30.223.271-62.fc43.x86_64"
# do the following:
# 1. Check https://github.com/ublue-os/bluefin/pkgs/container/bluefin/versions?filters%5Bversion_type%5D=tagged
#    for which version is tagged as "stable", and check what the other tags are.
# 2. Check the akmods tag below to see what it targets, and update it if required.
#    For example, a Bluefin image "stable-44.something" should match an akmods
#    image "coreos-stable-44-x86_64"
COPY --from=ghcr.io/ublue-os/akmods:coreos-stable-44-x86_64 / /tmp/akmods-common
RUN find /tmp/akmods-common
RUN dnf install -y /tmp/akmods-common/rpms/ublue-os/ublue-os-akmods*.rpm

# This is the wl driver that supports the Broadcom BCM4360 chip
RUN dnf install -y \
  /tmp/akmods-common/rpms/common/broadcom-wl*.rpm \
  /tmp/akmods-common/rpms/kmods/kmod-wl*.rpm

### [IM]MUTABLE /opt
## Some bootable images, like Fedora, have /opt symlinked to /var/opt, in order to
## make it mutable/writable for users. However, some packages write files to this directory,
## thus its contents might be wiped out when bootc deploys an image, making it troublesome for
## some packages. Eg, google-chrome, docker-desktop.
##
## Uncomment the following line if one desires to make /opt immutable and be able to be used
## by the package manager.

# RUN rm /opt && mkdir /opt

### MODIFICATIONS
## make modifications desired in your image and install packages by modifying the build.sh script
## the following RUN directive does all the things required to run "build.sh" as recommended.

RUN --mount=type=bind,from=ctx,source=/,target=/ctx \
    --mount=type=cache,dst=/var/cache \
    --mount=type=cache,dst=/var/log \
    --mount=type=tmpfs,dst=/tmp \
    /ctx/build.sh
    
### LINTING
## Verify final image and contents are correct.
RUN bootc container lint
