FROM archlinux AS builder

RUN pacman -Sy --needed --noconfirm \
      base-devel \
      sudo \
      wget

RUN useradd builduser -m \
 && passwd -d builduser \
 && bash -c "printf 'builduser ALL=(ALL) ALL\n' | tee -a /etc/sudoers "

RUN sudo -u builduser bash -c 'mkdir -p /tmp/build'

RUN sudo -u builduser bash -c ' \
       cd /tmp/build \
    && wget https://aur.archlinux.org/cgit/aur.git/snapshot/f5vpn.tar.gz \
    && tar xzf f5vpn.tar.gz \
    && cd f5vpn \
    && makepkg -s --noconfirm \
    '

FROM archlinux

COPY --from=builder /tmp/build/f5vpn/*.zst .

RUN pacman -Syu --noconfirm \
 && pacman -S --noconfirm ttf-dejavu \
 && pacman -U --noconfirm *.zst \
 && pacman -Sc --noconfirm \
 && rm -rf /var/cache/pacman/pkg

COPY skel/ /etc/skel/
