#!/bin/bash
# pre-tool-destructive-bash.sh - Block dangerous bash commands
# PreToolUse on Bash - Prompts before destructive shell operations

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils/play-sound.sh"

input=$(cat)
command=$(echo "$input" | jq -r '.tool_input.command // ""')

# Dangerous bash command patterns
dangerous_patterns=(
    # rm commands - file/directory deletion
    'rm[[:space:]]+-rf'
    'rm[[:space:]]+-fr'
    'rm[[:space:]]+-r[[:space:]]+-f'
    'rm[[:space:]]+-f[[:space:]]+-r'
    'rm[[:space:]]+--recursive[[:space:]]+--force'
    'rm[[:space:]]+--force[[:space:]]+--recursive'
    'rm[[:space:]]+-r[[:space:]]'
    'rm[[:space:]]+--recursive'
    'rm[[:space:]]+-f[[:space:]]'
    'rm[[:space:]]+--force'
    '\brm[[:space:]]+/'                        # rm on root paths
    '\brm[[:space:]]+\*'                       # rm with wildcards
    '\brm[[:space:]]+\.\.'                     # rm on parent directories

    # Directory operations
    'rmdir[[:space:]]+'

    # Dangerous file operations
    'shred[[:space:]]+'                        # Secure delete
    'srm[[:space:]]+'                          # Secure rm
    'wipe[[:space:]]+'                         # Wipe utility

    # Disk/partition operations
    'mkfs[[:space:]]+'                         # Format filesystem
    'mkfs\.[a-z]+'                             # Format specific filesystem
    'fdisk[[:space:]]+'                        # Partition editor
    'parted[[:space:]]+'                       # Partition editor
    'dd[[:space:]]+if='                        # Disk copy (can overwrite)

    # Permission changes that could be dangerous
    'chmod[[:space:]]+777'                     # World writable
    'chmod[[:space:]]+-R[[:space:]]+777'       # Recursive world writable
    'chmod[[:space:]]+000'                     # Remove all permissions
    'chown[[:space:]]+-R'                      # Recursive ownership change

    # System modification
    'systemctl[[:space:]]+stop'
    'systemctl[[:space:]]+disable'
    'systemctl[[:space:]]+mask'
    'service[[:space:]]+.*[[:space:]]+stop'
    'launchctl[[:space:]]+unload'              # macOS service unload
    'launchctl[[:space:]]+remove'              # macOS service remove

    # Package removal
    'apt[[:space:]]+remove'
    'apt[[:space:]]+purge'
    'apt-get[[:space:]]+remove'
    'apt-get[[:space:]]+purge'
    'yum[[:space:]]+remove'
    'yum[[:space:]]+erase'
    'dnf[[:space:]]+remove'
    'dnf[[:space:]]+erase'
    'brew[[:space:]]+uninstall'
    'brew[[:space:]]+remove'
    'pip[[:space:]]+uninstall'
    'pip3[[:space:]]+uninstall'
    'npm[[:space:]]+uninstall[[:space:]]+-g'   # Global npm uninstall

    # Database destructive operations
    'dropdb[[:space:]]+'                       # PostgreSQL drop database
    'drop[[:space:]]+database'                 # SQL drop database
    'drop[[:space:]]+table'                    # SQL drop table
    'truncate[[:space:]]+table'                # SQL truncate

    # Network/firewall
    'iptables[[:space:]]+-F'                   # Flush iptables
    'iptables[[:space:]]+-X'                   # Delete chains
    'ufw[[:space:]]+disable'                   # Disable firewall
    'pfctl[[:space:]]+-d'                      # Disable pf firewall (macOS)

    # Cron/scheduled tasks
    'crontab[[:space:]]+-r'                    # Remove crontab
    'crontab[[:space:]]+-i?r'                  # Remove crontab variants

    # Process killing
    'kill[[:space:]]+-9[[:space:]]+1\b'        # Kill init/systemd
    'killall[[:space:]]+'                      # Kill by name
    'pkill[[:space:]]+-9'                      # Force kill by pattern

    # SSH/security
    'ssh-keygen[[:space:]]+-R'                 # Remove SSH known host

    # Environment destruction
    'unset[[:space:]]+PATH'
    'export[[:space:]]+PATH='\'\'              # Empty PATH

    # History manipulation
    'history[[:space:]]+-c'                    # Clear history
    '\brm[[:space:]]+.*\.bash_history'
    '\brm[[:space:]]+.*\.zsh_history'

    # System/power commands
    'shutdown[[:space:]]+'
    'reboot([[:space:]]|$)'
    'halt([[:space:]]|$)'
    'poweroff([[:space:]]|$)'
    'init[[:space:]]+[06]'
    'systemctl[[:space:]]+reboot'
    'systemctl[[:space:]]+poweroff'
    'systemctl[[:space:]]+halt'

    # Dangerous piping (remote code execution)
    'curl[[:space:]]+.*\|[[:space:]]*(bash|sh|zsh|ksh)'
    'wget[[:space:]]+.*\|[[:space:]]*(bash|sh|zsh|ksh)'
    'curl[[:space:]]+.*>[[:space:]]*/tmp/.*&&.*(bash|sh)'
    'wget[[:space:]]+.*>[[:space:]]*/tmp/.*&&.*(bash|sh)'

    # Privilege escalation
    'sudo[[:space:]]+'
    '\bsu[[:space:]]+-'
    '\bsu[[:space:]]+root'
    'doas[[:space:]]+'

    # Docker destructive
    'docker[[:space:]]+system[[:space:]]+prune'
    'docker[[:space:]]+volume[[:space:]]+prune'
    'docker[[:space:]]+container[[:space:]]+prune'
    'docker[[:space:]]+image[[:space:]]+prune'
    'docker[[:space:]]+rm[[:space:]]+-f'
    'docker[[:space:]]+rmi[[:space:]]+-f'
    'docker[[:space:]]+stop'
    'docker[[:space:]]+kill'
    'docker-compose[[:space:]]+down[[:space:]]+-v'  # Down with volumes
    'docker[[:space:]]+compose[[:space:]]+down[[:space:]]+-v'
)

for pattern in "${dangerous_patterns[@]}"; do
    if echo "$command" | grep -qiE "$pattern"; then
        play_sound "warning"

        cat << EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask"
  },
  "systemMessage": "Potentially destructive bash command detected. This could delete files, stop services, or modify system state. Allow Claude to proceed?"
}
EOF
        exit 0
    fi
done

exit 0
