# env.nu
#
# Installed by:
# version = "0.109.1"
#
# Previously, environment variables were typically configured in `env.nu`.
# In general, most configuration can and should be performed in `config.nu`
# or one of the autoload directories.
#
# This file is generated for backwards compatibility for now.
# It is loaded before config.nu and login.nu
#
# See https://www.nushell.sh/book/configuration.html
#
# Also see `help config env` for more options.
#
# You can remove these comments if you want or leave
# them for future reference.

# $env.path ++= ['C:\Tools\helix']

# use ($nu.default-config-dir)/nu_scripts/custom-completions/git/git-completions.nu *
# use ($nu.default-config-dir)/nu_scripts/custom-completions/eza/eza-completions.nu *



# $env.XDG_CONFIG_HOME = $env.USERPROFILE | path join  '.config'
# $env.XDG_CACHE_HOME = $env.USERPROFILE | path join  '.cache'
# $env.XDG_DATA_HOME = $env.USERPROFILE | path join '.local' 'share'
# $env.XDG_STATE_HOME = $env.USERPROFILE | path join '.local' 'state'
# $env.NUPM_HOME = ($env.XDG_DATA_HOME | path join "nupm")

# $env.NU_LIB_DIRS = [
#     ($env.NUPM_HOME | path join "modules")
# ]

# $env.PATH = (
#     $env.PATH
#         | split row (char esep)
#         | prepend ($env.NUPM_HOME | path join "scripts")
#         | uniq
# )

# use ($nu.default-config-dir)/nu_scripts/themes/nu-themes/wez.nu 
# use ($nu.default-config-dir)/nu_scripts/themes/nu-themes/tokyo-night.nu
# $env.config.color_config = (tokyo-nig

def ll [] {ls -l}
def ltr [] {ls | sort-by modified}
def gs [] {git status}


# alias the built-in ls command to ls-builtins
alias ls-builtin = ls

# List the filenames, sizes, and modification times of items in a directory.
def ls [
    --all (-a),         # Show hidden files
    --long (-l),        # Get all available columns for each entry (slower; columns are platform-dependent)
    --short-names (-s), # Only print the file names, and not the path
    --full-paths (-f),  # display paths as absolute paths
    --du (-d),          # Display the apparent directory size ("disk usage") in place of the directory metadata size
    --directory (-D),   # List the specified directory itself instead of its contents
    --mime-type (-m),   # Show mime-type in type column instead of 'file' (based on filenames only; files' contents are not examined)
    --threads (-t),     # Use multiple threads to list contents. Output will be non-deterministic.
    ...pattern: glob,   # The glob pattern to use.
]: [ nothing -> table ] {
    let pattern = if ($pattern | is-empty) { [ '.' ] } else { $pattern }
    (ls-builtin
        --all=$all
        --long=$long
        --short-names=$short_names
        --full-paths=$full_paths
        --du=$du
        --directory=$directory
        --mime-type=$mime_type
        --threads=$threads
        ...$pattern
    ) | sort-by type name -i
}


# carapace設定用
let carapace_init = ($nu.cache-dir | path join carapace.nu)
if not ($carapace_init | path exists) {
    mkdir ($nu.cache-dir)
    carapace _carapace nushell | save --force $carapace_init
}
