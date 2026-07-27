#!/usr/bin/env bats
# guard-cloud.sh and guard-bash.sh — the pattern-driven guards.
#
# The point of these tests is the second half of each file: the routine
# development commands that MUST NOT be blocked. The old matcher was
# unanchored and case-insensitive, so it fired on prose, on `sudo apt-get
# install`, on `pip uninstall`, and on any command substitution containing
# curl. Those are the regressions worth locking down.

load helpers/hook

# ---------------------------------------------------------------------------
# Cloud: genuine destruction
# ---------------------------------------------------------------------------

@test "az group delete is denied" {
    assert_decision deny guard-cloud.sh "az group delete --name rg-prod --yes"
}

@test "aws s3 rb is denied" {
    assert_decision deny guard-cloud.sh "aws s3 rb s3://my-bucket --force"
}

@test "aws ec2 terminate-instances is denied" {
    assert_decision deny guard-cloud.sh "aws ec2 terminate-instances --instance-ids i-1234"
}

@test "kubectl delete namespace is denied" {
    assert_decision deny guard-cloud.sh "kubectl delete namespace production"
}

@test "terraform destroy is denied" {
    assert_decision deny guard-cloud.sh "terraform destroy -auto-approve"
}

@test "a destructive cloud command after && is still caught" {
    assert_decision deny guard-cloud.sh "az login && az group delete --name rg-prod --yes"
}

@test "a destructive cloud command behind sudo is still caught" {
    assert_decision deny guard-cloud.sh "sudo kubectl delete namespace production"
}

# ---------------------------------------------------------------------------
# Cloud: must not fire
# ---------------------------------------------------------------------------

@test "read-only az commands are allowed" {
    assert_decision allow guard-cloud.sh "az group list --output table"
}

@test "az account show is allowed" {
    assert_decision allow guard-cloud.sh "az account show"
}

@test "kubectl get pods is allowed" {
    assert_decision allow guard-cloud.sh "kubectl get pods -A"
}

@test "terraform plan is allowed" {
    assert_decision allow guard-cloud.sh "terraform plan"
}

@test "prose describing a destructive command is not matched" {
    assert_decision allow guard-cloud.sh "echo 'never run az group delete on prod'"
}

@test "reading a file that documents destructive commands is not matched" {
    assert_decision allow guard-cloud.sh "cat docs/runbook.md | grep 'terraform destroy'"
}

@test "the cloud guard override works" {
    assert_decision allow guard-cloud.sh "CLAUDE_CLOUD_GUARD=off az group delete --name rg-test --yes"
}

# ---------------------------------------------------------------------------
# Bash: genuine destruction
# ---------------------------------------------------------------------------

@test "rm -rf / is denied" {
    assert_decision deny guard-bash.sh "rm -rf /"
}

@test "mkfs is denied" {
    assert_decision deny guard-bash.sh "mkfs.ext4 /dev/sda1"
}

@test "dd to a block device is denied" {
    assert_decision deny guard-bash.sh "dd if=/dev/zero of=/dev/sda"
}

@test "chmod 777 -R is denied" {
    assert_decision deny guard-bash.sh "chmod -R 777 /etc"
}

@test "history -c is denied" {
    assert_decision deny guard-bash.sh "history -c"
}

@test "crontab -r is denied" {
    assert_decision deny guard-bash.sh "crontab -r"
}

@test "deleting TLS material under a path is denied" {
    assert_decision deny guard-bash.sh "rm /etc/ssl/private/server.key"
}

@test "ssh-add -D is denied" {
    assert_decision deny guard-bash.sh "ssh-add -D"
}

# ---------------------------------------------------------------------------
# Bash: must not fire. These are the false positives that got the whole plugin
# switched off.
# ---------------------------------------------------------------------------

@test "sudo apt-get install is allowed - routine in a devcontainer" {
    assert_decision allow guard-bash.sh "sudo apt-get install -y jq"
}

@test "pip uninstall is allowed - not destruction of work" {
    assert_decision allow guard-bash.sh "pip uninstall -y requests"
}

@test "npm prune is allowed" {
    assert_decision allow guard-bash.sh "npm prune"
}

@test "poetry remove is allowed" {
    assert_decision allow guard-bash.sh "poetry remove requests"
}

@test "go clean -modcache is allowed" {
    assert_decision allow guard-bash.sh "go clean -modcache"
}

@test "pkill on a dev server is allowed" {
    assert_decision allow guard-bash.sh "pkill -f 'uvicorn api.main'"
}

@test "kill -9 on a pid is allowed" {
    assert_decision allow guard-bash.sh "kill -9 48213"
}

@test "unsetting a proxy variable is allowed" {
    assert_decision allow guard-bash.sh "unset http_proxy"
}

@test "curl piped to bash is allowed - post-create.sh does exactly this" {
    assert_decision allow guard-bash.sh "curl -fsSL https://claude.ai/install.sh | bash"
}

@test "command substitution with curl is allowed" {
    assert_decision allow guard-bash.sh "VERSION=\$(curl -s https://example.com/version)"
}

@test "appending to .zshrc is allowed" {
    assert_decision allow guard-bash.sh "echo 'export FOO=1' >> ~/.zshrc"
}

@test "removing a build artefact named like a key is allowed" {
    assert_decision allow guard-bash.sh "rm build.key"
}

@test "rm -rf of a project build directory is allowed" {
    assert_decision allow guard-bash.sh "rm -rf ./dist"
}

@test "rm -rf node_modules is allowed" {
    assert_decision allow guard-bash.sh "rm -rf node_modules"
}

@test "uv sync is allowed" {
    assert_decision allow guard-bash.sh "uv sync"
}

@test "prose describing rm -rf / is not matched" {
    assert_decision allow guard-bash.sh "echo 'do not ever run rm -rf / on this box'"
}

@test "an uppercase spelling is not matched (patterns are case-sensitive)" {
    assert_decision allow guard-bash.sh "echo 'RM -RF /'"
}

@test "the bash guard override works" {
    assert_decision allow guard-bash.sh "CLAUDE_BASH_GUARD=off rm -rf /tmp/scratch"
}

# ---------------------------------------------------------------------------
# Robustness
# ---------------------------------------------------------------------------

@test "cloud guard survives empty stdin" {
    run bash -c "printf '' | bash '$SAFETY_HOOKS/guard-cloud.sh'"
    [ "$status" -eq 0 ]
}

@test "bash guard survives empty stdin" {
    run bash -c "printf '' | bash '$SAFETY_HOOKS/guard-bash.sh'"
    [ "$status" -eq 0 ]
}

@test "bash guard survives malformed stdin" {
    run bash -c "printf 'garbage' | bash '$SAFETY_HOOKS/guard-bash.sh'"
    [ "$status" -eq 0 ]
}

@test "denies emit well-formed JSON" {
    assert_valid_json guard-bash.sh "rm -rf /"
    assert_valid_json guard-cloud.sh "terraform destroy -auto-approve"
}

@test "no pattern file leaves a stray temp file behind" {
    before="$(find /tmp -maxdepth 1 -name 'tmp.*' 2>/dev/null | wc -l)"
    run_hook guard-bash.sh "ls -la" >/dev/null
    run_hook guard-bash.sh "rm -rf /" >/dev/null
    after="$(find /tmp -maxdepth 1 -name 'tmp.*' 2>/dev/null | wc -l)"
    [ "$after" -le "$before" ]
}

# ---------------------------------------------------------------------------
# Docker: the line is volumes, not containers.
# ---------------------------------------------------------------------------

@test "docker volume rm is denied" {
    assert_decision deny guard-bash.sh "docker volume rm dind-var-lib-docker-abc"
}

@test "docker system prune --volumes is denied" {
    assert_decision deny guard-bash.sh "docker system prune -a --volumes"
}

@test "docker compose down -v is denied" {
    assert_decision deny guard-bash.sh "docker compose down -v"
}

@test "docker image prune -a is allowed - MANAGING.md recommends it" {
    assert_decision allow guard-bash.sh "docker image prune -a"
}

@test "plain docker system prune is allowed" {
    assert_decision allow guard-bash.sh "docker system prune -a"
}

@test "docker compose down without -v is allowed" {
    assert_decision allow guard-bash.sh "docker compose down"
}

@test "docker stop is allowed" {
    assert_decision allow guard-bash.sh "docker stop api-container"
}

@test "docker rm -f is allowed - containers are rebuildable" {
    assert_decision allow guard-bash.sh "docker rm -f api-container"
}
