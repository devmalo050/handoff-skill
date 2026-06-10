#!/usr/bin/env bash
set -euo pipefail

# claude.ai / Claude 데스크탑 앱 업로드용 Skill zip 생성.
# 각 zip 내부 구조는 <skill-name>/SKILL.md 가 되도록 skills/ 안에서 압축한다.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS_DIR="$ROOT/skills"
DIST_DIR="$ROOT/dist"

mkdir -p "$DIST_DIR"

found=0
for skill_path in "$SKILLS_DIR"/*/; do
  [ -d "$skill_path" ] || continue
  skill_name="$(basename "$skill_path")"
  if [ ! -f "$skill_path/SKILL.md" ]; then
    echo "skip: $skill_name (SKILL.md 없음)" >&2
    continue
  fi
  zip_path="$DIST_DIR/$skill_name.zip"
  rm -f "$zip_path"
  ( cd "$SKILLS_DIR" && zip -q -r "$zip_path" "$skill_name" -x '*.DS_Store' )
  echo "built: dist/$skill_name.zip"
  found=$((found+1))
done

[ "$found" -gt 0 ] || { echo "오류: skills/ 아래 패키징할 Skill이 없습니다." >&2; exit 1; }
