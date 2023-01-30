# shellcheck shell=sh

# get_file [output_path] [url]
get_file() {
    output_path=$1
    url=$2
    return_value=0
    if [ -x "$(command -v wget)" ]; then
        if wget -O "$output_path" "$url"; then
            echo "✔ [wget] Downloaded file: '$output_path'"
        else
            return_value=$?
            log_error "[wget] Failed to download file: '$output_path'"
            rm -f "$output_path"
        fi
    elif [ -x "$(command -v curl)" ]; then
        if curl -sSLf -o "$output_path" "$url"; then
            echo "✔ [curl] Downloaded file: '$output_path'"
        else
            return_value=$?
            log_error "[curl] Failed to download file: '$output_path'"
            rm -f "$output_path"
        fi
    else
        log_error "Missing both 'wget' and 'curl'. Failed to download file: '$url'"
        return_value=55
    fi

    return "$return_value"
}

#
# USAGE: _add_path [include|prepend|append] "dir1" "dir2" ...
#
#   prepend: add/move to beginning
#   append:  add/move to end
#   include: add to end of PATH if not already included [default]
#          that is, don't change position if already in PATH
#
# RETURNS:
#   prepend:  dir2:dir1:OLD_PATH
#   append:   OLD_PATH:dir1:dir2
#
# If called with no paramters, returns PATH with duplicate directories removed
#
_add_path() {
    _list=":$(_unique_list "${PATH:-}"):"

    case "$1" in
    'include' | 'prepend' | 'append')
        _action="$1"
        shift
        ;;
    *)
        _action='include'
        ;;
    esac

    for dir in "$@"; do
        # Remove last occurrence to end
        _left="${_list%:$dir:*}"

        if [ "$_list" = "$_left" ]; then
            # Input list does not contain $dir
            [ "$_action" = 'include' ] && _action='append'
            _right=''
        else
            # Remove start to last occurrence
            _right=":${_list#$_left:$dir:}"
        fi

        # Construct _list with $dir added
        case "$_action" in
        'prepend') _list=":$dir$_left$_right" ;;
        'append') _list="$_left$_right$dir:" ;;
        esac
    done

    # Strip ':' pads
    _list="${_list#:}"
    _list="${_list%:}"

    # Return combined path
    PATH="$_list"
    export PATH
}

#
# USAGE: _unique_list [list]
#
#   list - a colon delimited list.
#
# RETURNS: 'list' with duplicated directories removed
#
_unique_list() {
    _arg_input_list="${1:-}"
    _list=':'

    # Wrap the while loop in '{}' to be able to access the updated _list variable
    # as the while loop is run in a subshell due to the piping to it.
    # https://stackoverflow.com/questions/4667509/shell-variables-set-inside-while-loop-not-visible-outside-of-it
    printf '%s\n' "$_arg_input_list" | tr -s ':' '\n' | {
        while read -r dir; do
            _left="${_list%:"$dir":*}" # remove last occurrence to end
            if [ "$_list" = "$_left" ]; then
                # PATH doesn't contain $dir
                _list="$_list$dir:"
            fi
        done
        # strip ':' pads
        _list="${_list#:}"
        _list="${_list%:}"

        # return
        printf '%s\n' "$_list"
    }
}

_remove_trailing_slash() {
    echo "$1" | sed 's/\/*$//g'
}
