export RBENV_ROOT="$HOME/.rbenv"

set +e

echo ":$PATH:" | grep ":$RBENV_ROOT/bin:" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  export PATH="$RBENV_ROOT/bin:$PATH"
fi

#eval "$(rbenv init --path)"

eval "$(rbenv init -)"

#eval "$(rbenv virtualenv-init -)"
#
#export REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt

