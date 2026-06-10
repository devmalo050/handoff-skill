# handoff — Claude Code 세션 인계 커맨드

긴 작업을 한 세션에서 끝내지 못할 때, **다음 세션이 그대로 이어받을 수 있도록** 세션 상태를 `HANDOFF.md` 한 장으로 압축하는 Claude Code 슬래시 커맨드입니다.

| 커맨드 | 하는 일 |
|---|---|
| `/handoff` | 현재 세션을 훑어 프로젝트 루트의 `HANDOFF.md`로 압축(목표·변경사항·결정·막다른 길·다음 단계). git 레포면 그 파일만 커밋. |
| `/handoff-continue` | `HANDOFF.md`를 읽고 작업을 이어받음. 핫 스테이트부터 파악하고, 코드 수정 전 사용자 확인. |

핵심 설계:
- **핫 스테이트 우선** — 파일 맨 위 30~60줄만 읽어도 2분 안에 재개 가능
- **실패한 시도 보존** — 다음 세션이 같은 막다른 길을 다시 파지 않게
- **이력은 git에 위임** — `HANDOFF.md` 한 파일만 덮어쓰고, 버전은 커밋으로 관리
- **안전** — 비밀정보 리닥션, 인계받을 때 자동 실행 금지

---

## 설치 — 프롬프트 한 번

> 아래 블록을 **그대로 복사해서 Claude Code 채팅창에 붙여넣기**만 하면 설치됩니다.

```
handoff 커맨드를 설치해줘. 아래 두 파일을 GitHub raw에서 받아 내 `~/.claude/commands/` 에
같은 파일명으로 저장해줘:

1. https://raw.githubusercontent.com/devmalo050/handoff-skill/main/commands/handoff.md
2. https://raw.githubusercontent.com/devmalo050/handoff-skill/main/commands/handoff-continue.md

~/.claude/commands/ 가 없으면 만들고, 받은 내용을 한 글자도 수정하지 말고 그대로 저장해.
끝나면 저장한 두 파일 경로를 알려줘.
```

설치가 끝나면 새 세션에서 `/handoff`, `/handoff-continue` 가 슬래시 커맨드로 잡힙니다.

---

## 설치 — 수동 (터미널)

```bash
mkdir -p ~/.claude/commands
curl -fsSL https://raw.githubusercontent.com/devmalo050/handoff-skill/main/commands/handoff.md \
  -o ~/.claude/commands/handoff.md
curl -fsSL https://raw.githubusercontent.com/devmalo050/handoff-skill/main/commands/handoff-continue.md \
  -o ~/.claude/commands/handoff-continue.md
```

또는 레포를 클론해서 복사:

```bash
git clone https://github.com/devmalo050/handoff-skill.git
cp handoff-skill/commands/*.md ~/.claude/commands/
```

> **프로젝트 단위로만 쓰고 싶다면** `~/.claude/commands/` 대신 해당 레포의 `.claude/commands/` 에 넣으면 그 프로젝트에서만 커맨드가 보입니다.

---

## 사용법

**세션을 마무리할 때:**
```
/handoff
```
선택 인자로 강조할 내용을 넘길 수 있습니다:
```
/handoff 결제 모듈 리팩터링이 핵심. 테스트는 아직 빨간 상태
```

**다음 세션에서 이어받을 때:**
```
/handoff-continue
```
과거 핸드오프 버전 목록을 보려면(git 레포):
```
/handoff-continue list
```
특정 버전/경로를 지정할 수도 있습니다:
```
/handoff-continue <커밋해시> 또는 <파일경로>
```

---

## 동작 방식

`/handoff` 는 대화 전체를 채굴해 아래 템플릿으로 `HANDOFF.md`를 작성합니다.

```markdown
# HANDOFF — <작업명>

## 🔥 핫 스테이트 (여기만 읽어도 재개 가능)
- 목표 / 현재 상태 / 바로 다음 할 일 / 블로커

## 변경 사항 (이번 세션)        # path + 한 줄 요약 (diff 복붙 금지)
## 결정과 이유                  # 기각한 대안 포함
## 막다른 길 / 실패한 시도       # 가장 가치 높은 정보
## 원시 데이터                  # 에러·수치·재현 절차 그대로
## 열린 스레드 / 블로커
## 다음 단계 (순서대로)
## 핵심 파일 / 위치             # path:line
## 실행 / 테스트
## 참조 (경로/URL만, 복제 금지)
```

git 레포라면 `HANDOFF.md` **한 파일만** 한정해서 커밋합니다(`git add -- HANDOFF.md`). 작업 중이던 다른 파일은 절대 건드리지 않고, 푸시도 하지 않습니다.

---

## 파일 구조

```
handoff-skill/
├── README.md
└── commands/
    ├── handoff.md           # /handoff
    └── handoff-continue.md  # /handoff-continue
```

---

## 커스터마이즈

커맨드는 평범한 마크다운 + YAML frontmatter입니다. `commands/*.md` 를 열어 프롬프트를 직접 고치면 됩니다. 예:
- 템플릿 섹션 추가/삭제
- 출력 언어 고정 (기본은 "세션에서 쓰던 언어")
- 커밋 동작 끄기 / 커밋 메시지 형식 변경

수정 후에는 `~/.claude/commands/` 의 파일을 다시 덮어쓰면 적용됩니다.

---

## 라이선스

MIT
