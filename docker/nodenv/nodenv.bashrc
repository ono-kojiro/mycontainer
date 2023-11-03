export NODENV_ROOT="$HOME/.nodenv"

set +e

echo ":$PATH:" | grep ":$NODENV_ROOT/bin:" > /dev/null 2>&1
if [ $? -ne 0 ]; then
  export PATH="$NODENV_ROOT/bin:$PATH"
fi

eval "$(nodenv init -)"

