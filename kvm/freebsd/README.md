# setup FreeBSD

## remote access

```
# sudo vi /etc/ssh/sshd_config

# cat /etc/ssh/sshd_config | grep -e '^PermitRootLogin'
PermitRootLogin yes

# service sshd restart
```

access using password authentication

```
# ssh freebsd -l root
```

## enable public key authentication

create .ssh/authorized_keys

```
# mkdir ~/.ssh
# echo ssh-ed25519 XXXXX... > ~/.ssh/authorized_keys
```

exit and access without password

```
# exit
$ ssh freebsd -l root
```

## disable password authentiction

```
# vi /etc/ssh/sshd_config

# cat /etc/ssh/sshd_config | grep -e '^PasswordAuthentication'
PasswordAuthentication no

# service sshd restart
```


## package update

```
# vi /etc/pkg/FreeBSD.conf

# cat /etc/pkg/FreeBSD.conf | grep 'url:'
  url: "https://pkg.FreeBSD.org/${ABI}/quarterly",
  url: "https://pkg.FreeBSD.org/${ABI}/kmods_quarterly_${VERSION_MINOR}",
  url: "https://pkg.FreeBSD.org/${ABI}/base_release_${VERSION_MINOR}",

# pkg update

# pkg upgrade

# pkg search python3

# pkg install python3-3_4
```

## configure ntp

```
$ sh build.sh ntp
```

# FreeBSD 13 + XFCE + LightDM

## Prepare

### On target (FreeBSD)
  Update package
  ```
  # pkg update
  ```

  Install python39 and sudo

  ```
  # pkg install python39 sudo
  ```

  enable wheel group
  ```
  # visudo
  ...
  %wheel ALL=(ALL:ALL) ALL
  ...
  ```

  execute sudo once
  ```
  $ sudo ls
  ```

### On ansible host
  generate key pair

  ```
  $ sh build.sh key
  ```

  copy id_ed25519.pub to authorized_keys on freebsd


## Deploy
### On ansible host
  ```
  $ sh build.sh
  ```


