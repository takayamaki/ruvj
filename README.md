# with_claude_template

Claude Code と devcontainer を使ったプロジェクト開発環境のベーステンプレート。

## 含まれる機能

- **mise** によるツールバージョン管理（Node.js + pnpm プリセット）
- **Claude Code** 自動インストール + 設定ファイルのホスト共有（`~/.claude`・`~/.claude.json` マウント）
- **git-agent** による GITHUB_TOKEN 認証の強制（SSH 鍵・credential store 不要）
- Claude Code の `git` 直接呼び出しをプロジェクトレベルで deny し `git-agent` に統一

## 使い方

1. GitHub で「Use this template」→ 新規リポジトリ作成
2. `.devcontainer/docker-compose.yml` の `container_name` をプロジェクト名に変更
3. `.devcontainer/devcontainer.json` の `name`・`forwardPorts`・`extensions` を埋める
4. `mise.toml` に言語ランタイムを追加（例: `rust = "stable"`）
5. `.devcontainer/Dockerfile` に言語固有の apt パッケージを追加
6. `.claude/CLAUDE.md` のプロジェクト概要を記述
7. ホスト側に `GITHUB_TOKEN` を環境変数として設定
8. devcontainer を開く

## git-agent コマンドについて

agentはgitの直接使用をdenyされており、git-agentコマンドを使用する。
git-agentコマンドはGitHubリポジトリへの読み書きを行う際、HTTPSによるGITHUB_TOKEN認証を強制する。
これによりdevcontainerをVSCodeなどで起動した際のssh-agent転送による広範すぎるpush権限を制限している。

なお、`GITHUB_TOKEN` が未設定の場合は通常の git にフォールバックする。
人間は引き続き `git` を直接呼ぶことができる（意図的なエスケープハッチ）。

## 前提条件

- Docker が動作する Linux 環境（ローカルまたは SSH リモート）
- ホスト側の `~/.claude` と `~/.claude.json` に Claude Code の認証情報が存在すること
- `GITHUB_TOKEN` 環境変数（省略時は push/pull が認証なしになる）
