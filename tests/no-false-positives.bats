#!/usr/bin/env bats
# A corpus of everyday development commands that must pass every guard
# untouched.
#
# WHY THIS FILE EXISTS SEPARATELY
# -------------------------------
# The per-guard test files check that dangerous things are denied. This one
# checks the failure mode that actually killed the previous version of this
# plugin: firing on ordinary work until someone set enabledPlugins to false and
# lost the protection entirely.
#
# Adding a pattern is cheap. Adding a pattern that blocks `uv sync` costs the
# whole safety layer. Anything added to dangerous-patterns/ must leave this
# file green.

load helpers/hook

# Commands drawn from this repo's own docs, post-create.sh, and the command
# definitions in plugins/*/commands/.
CORPUS=(
    "ls -la"
    "cat README.md"
    "grep -rn TODO src/"
    "find . -name '*.py' -newer setup.py"
    "find . -name '*.pyc' -delete"
    "rg --files-with-matches 'import os'"
    "git status"
    "git diff --stat"
    "git log --oneline -20"
    "git add src/main.py tests/test_main.py"
    "git commit -m 'feat: add thing'"
    "git push -u origin claude/feature-branch"
    "git fetch origin main"
    "git worktree add ../wt-security"
    "git worktree remove ../wt-security"
    "git for-each-ref refs/snapshots/"
    "uv sync"
    "uv run pytest -q"
    "uv run pre-commit run --all-files"
    "uv run uvicorn api.main:app --reload --host 0.0.0.0"
    "uv run playwright install --with-deps chromium"
    "pip install -e ."
    "pip uninstall -y requests"
    "python3 -m pytest tests/ -x"
    "python3 plugins/kokko-janitor/scripts/hotspots.py . --top 10"
    "npm ci --legacy-peer-deps"
    "npm run build"
    "npm run dev"
    "npm prune"
    "npm install -g @github/copilot"
    "node --version"
    "rm -rf node_modules"
    "rm -rf ./dist"
    "rm -rf .venv"
    "rm -rf build/ dist/ *.egg-info"
    "rm -f coverage.xml"
    "rm .pytest_cache -r"
    "rmdir empty-dir"
    "mkdir -p src/api/routers"
    "cp .env.example .env"
    "mv old_name.py new_name.py"
    "touch src/__init__.py"
    "chmod +x scripts/deploy.sh"
    "chmod 755 post-create.sh"
    "sudo apt-get install -y jq"
    "sudo install -m 0755 config/bin/snaps /usr/local/bin/snaps"
    "curl -fsSL https://claude.ai/install.sh | bash"
    "curl -s https://api.example.com/health | jq ."
    "docker compose up -d"
    "docker compose logs -f api"
    "docker build -t myapp:local ."
    "docker ps -a"
    "docker image prune -a"
    "az account show"
    "az group list --output table"
    "az webapp log tail --name myapp --resource-group rg-dev"
    "az acr build --registry myreg --image app:latest ."
    "kubectl get pods -A"
    "kubectl describe deployment api"
    "kubectl logs -f deployment/api"
    "terraform init"
    "terraform plan -out=tfplan"
    "terraform fmt -recursive"
    "aws s3 ls s3://my-bucket/"
    "aws sts get-caller-identity"
    "pkill -f 'uvicorn api.main'"
    "kill -9 48213"
    "killall node"
    "unset http_proxy"
    "export PYTHONPATH=/workspace/src"
    "echo 'export FOO=1' >> ~/.zshrc"
    "source ~/.zshrc"
    "pre-commit run --all-files --show-diff-on-failure"
    "shellcheck --severity=warning hooks/*.sh"
    "markdownlint --fix README.md"
    "bats tests/"
    "jq -r '.plugins[].name' .claude-plugin/marketplace.json"
    "claude plugin validate plugins/kokko-safety/"
    "claude plugin marketplace update kokko-ng-kokko-cmds"
    "gh release view v3.2.0"
    "go clean -modcache"
    "cargo build --release"
    "dotnet build"
    "make test"
    "df -Ph /"
    "du -sh node_modules"
    "wc -l src/*.py"
    "diff -u expected.json actual.json"
    "tar -czf backup.tar.gz src/"
    "zip -r bundle.zip dist/"
    "dd if=/dev/zero of=testfile.bin bs=1M count=10"
)

@test "no everyday command is denied by guard-bash.sh" {
    local failures=()
    for cmd in "${CORPUS[@]}"; do
        local d
        d="$(decision_of guard-bash.sh "$cmd")"
        [[ "$d" == "deny" ]] && failures+=("$cmd")
    done
    if (( ${#failures[@]} )); then
        printf 'guard-bash.sh denied %d everyday command(s):\n' "${#failures[@]}" >&2
        printf '  %s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "no everyday command is denied by guard-cloud.sh" {
    local failures=()
    for cmd in "${CORPUS[@]}"; do
        local d
        d="$(decision_of guard-cloud.sh "$cmd")"
        [[ "$d" == "deny" ]] && failures+=("$cmd")
    done
    if (( ${#failures[@]} )); then
        printf 'guard-cloud.sh denied %d everyday command(s):\n' "${#failures[@]}" >&2
        printf '  %s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "no everyday command is denied by guard-git.sh on a clean tree" {
    local repo failures=()
    repo="$(new_repo)"
    cd "$repo" || return 1
    git checkout -q -b feature/work
    for cmd in "${CORPUS[@]}"; do
        local d
        d="$(decision_of guard-git.sh "$cmd")"
        [[ "$d" == "deny" ]] && failures+=("$cmd")
    done
    cd /tmp || true
    rm -rf "$repo"
    if (( ${#failures[@]} )); then
        printf 'guard-git.sh denied %d everyday command(s):\n' "${#failures[@]}" >&2
        printf '  %s\n' "${failures[@]}" >&2
        return 1
    fi
}

@test "prose mentioning dangerous commands never trips a guard" {
    local prose=(
        "echo 'do not run rm -rf / here'"
        "echo \"az group delete is destructive\""
        "cat docs/runbook.md"
        "grep -rn 'terraform destroy' docs/"
        "echo 'the last digit restore failed'"
        "printf 'kubectl delete namespace prod\\n' > notes.txt"
    )
    for cmd in "${prose[@]}"; do
        for hook in guard-bash.sh guard-cloud.sh; do
            local d
            d="$(decision_of "$hook" "$cmd")"
            if [[ "$d" == "deny" ]]; then
                printf '%s denied prose: %s\n' "$hook" "$cmd" >&2
                return 1
            fi
        done
    done
}
