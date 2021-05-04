# Aladdin + F5VPN + Citrix on Linux

This is  my setup which enables  me connecting to Citrix  over VPN, authenticated using  the Aladdin
token device / Gemalto.

It's hacky AF, but...

* Much faster than the Windows crap
* Your host system can use the internet, f5vpn crap doesn't override route tables.
* Less battery, so I enjoy working on my balcony the whole day.
* It's exciting to workaround all this... pile of... 💩!

What happens:

* The token device is read / used by "host" system's web browser
* The VPN client runs containerized
* The Citrix receiver runs on the "host"

Flow: 

1. You go to the f5vpn access site in your Firefox
2. It asks for the token device's password
3. F5VPN crap is launched in a docker container; routes %VERY_SECURE_BANKING_TRAFFIC% through that route
4. Now you can open Citrix dashboard (in the browser), and launch Citrix crap.

Prerequisites:

* You have a decently modern desktop linux distribution (Arch is good)
* You use NetworkManager

## Aladdin

Check which device you have:

```sh
$ lsusb | grep -i aladdin
Bus 001 Device 003: ID 0529:0620 Aladdin Knowledge Systems Token JC
```

### Install

Follow [this excellent guide][aladdin-prereq]. Although instead of [sac-core][sac-core], my token requires
[sac-core-legacy][sac-core-legacy].

You have to locate your firefox profile directory (usually `~/.mozilla/firefox/deadbeef.profile`)

**QUIT THE BROWSER FIRST!!!** Otherwise your security database can be corrupted.

```sh
$ yay -S opensc openct sac-core
$ sudo systemctl enable --now pcscd.service

# Add a new PKCS#11 security device to your Firefox, using the path `/usr/lib/libeTPkcs11.so`
$ modutil -dbdir   ~/.mozilla/firefox/<YOUR_FIREFOX_PROFILE_DIR>/ \
          -add     "Gemalto token" \
          -libfile /usr/lib/libeTPkcs11.so
```

[aladdin-prereq]: https://www.adaltas.com/en/2019/07/12/mount-aladdin-etoken-in-firefox-on-archlinux/
[sac-core]: https://aur.archlinux.org/packages/sac-core/
[sac-core-legacy]: https://aur.archlinux.org/packages/sac-core-legacy/

## F5VPN

At this point you should be able to load your company's F5VPN landing page, and firefox will pop up
a window to ask for your token device credentials.

After entering the password, the "Network Access" category will contain your VPN connections (one
for me); Clicking on it will try to load a URL with `f5-vpn://...` protocol.

Two things needed:

* Installing a containerized version of the F5VPN crap
* Letting Firefox know, what to do with the `f5-vpn://` URL.

### Install

```sh
$ cp skel/.F5Networks/trusted_sites.xml{.example,}

# Edit the xml to define which sites are trusted by the F5VPN client. It should be the same as the
# landing page you already visited in Firefox
$ vim skel/.F5Networks/trusted_sites.xml

$ yay -S x11docker alacritty
$ docker build . -t f5vpn
```

At this point you have a docker image created on your system (`docker image ls | grep f5vpn`). 

### Configure Firefox

A convenience script, [f5vpn-start.sh](f5vpn-start.sh) is ready to configure x11docker using our
previously built image.

1. Copy `f5vpn-start.sh` to your `$PATH` or wherever your Firefox can launch it
2. Edit the file; You have to set `F5VPN_ROUTE` variable which will tell our *host* system that all
   the connections to this subnetwork should be routed through the docker container.
3. Next time Firefox asks what the hell to do with `f5-vpn://` URLs, point it to `f5vpn-start.sh`

Note: You might want to edit `f5vpn-start.sh` to your liking. I'm using alacritty and bash and 
maybe you already have other docker containers so you need to align with the network settings etc.


### Set up static host names

Yeah, since our containerized F5VPN cannot edit hostnames / add DNS entries, the easiest solution is
to add them manually to your `/etc/hosts`:

```
1.2.3.4	citrix-eup.whatever-internal-domain
5.6.7.8	storefront.whatever-internal-domain
```

How to figure these out? Contact me. 😎

## Citrix

At this point, Citrix crap should work. 🎉

Although, some linux-specific config doesn't hurt. Open up `~/.ICAClient/wfclient.ini` and edit to
your liking.

* `KeyboardLayout=(Server Default)` - no funny mapping when you work on a non-english bank
* `MouseSendsControlV=False` - to enable mouse middle click


## Known issues

A lot. It's not nice that we have to figure out those IP addresses ourselves, better solution would
be to set up proper name resolution (through the container).

