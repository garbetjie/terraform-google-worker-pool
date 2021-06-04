#!/usr/bin/env sh

change_name=false

for arg do
  shift
  if [ "$arg" = "--name" ]; then
    change_name=true
  elif [ "$change_name" = true ]; then
    set -- "$@" "${arg}-$(date "+%Y%m%d-%H%M%S.%N")"
    change_name=false
    continue
  fi

  set -- "$@" "$arg"
done

# Execute the original command.
echo "$@"