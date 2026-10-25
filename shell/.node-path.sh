# Put nvm's default node on PATH without loading nvm (fast, no output).
# POSIX sh, so every shell can source it: zsh (.zshenv), bash and sh login
# shells (.profile). Agent hooks and IDE tasks often run under /bin/sh and
# never see the lazy `nvm`/`node` aliases in .zshrc, so they need a real PATH.
# Safe to source more than once; does nothing if nvm is already loaded.

if [ -z "${NVM_BIN:-}" ]; then
  _np_dir="${NVM_DIR:-$HOME/.nvm}"
  if [ -d "$_np_dir/versions/node" ]; then
    # Resolve the default alias through up to three hops (default -> lts/x -> v22.1.0).
    _np_v=$(cat "$_np_dir/alias/default" 2>/dev/null || true)
    for _np_i in 1 2 3; do
      [ -n "$_np_v" ] && [ -f "$_np_dir/alias/$_np_v" ] || break
      _np_v=$(cat "$_np_dir/alias/$_np_v" 2>/dev/null || true)
    done
    _np_v=${_np_v#v}
    # Newest installed version matching the alias (e.g. "22" -> v22.x.y), else newest overall.
    _np_bin=""
    if [ -n "$_np_v" ]; then
      if [ -d "$_np_dir/versions/node/v$_np_v" ]; then
        _np_bin="$_np_dir/versions/node/v$_np_v"
      else
        _np_bin=$(ls -d "$_np_dir/versions/node/v$_np_v".* 2>/dev/null | sort -V | tail -n 1)
      fi
    fi
    [ -n "$_np_bin" ] || _np_bin=$(ls -d "$_np_dir"/versions/node/v* 2>/dev/null | sort -V | tail -n 1)
    if [ -n "$_np_bin" ] && [ -d "$_np_bin/bin" ]; then
      case ":$PATH:" in
        *":$_np_bin/bin:"*) ;;
        *) PATH="$_np_bin/bin:$PATH"; export PATH ;;
      esac
    fi
  fi
  unset _np_dir _np_v _np_i _np_bin
fi
