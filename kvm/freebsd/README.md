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


