# handoff — Claude 세션 인계 Skill

긴 작업을 한 세션에서 끝내지 못할 때, **다음 세션이 그대로 이어받을 수 있도록** 세션 상태를 `HANDOFF.md` 한 장으로 압축하는 Agent Skill입니다. **Claude Code와 Claude 데스크탑 앱(claude.ai) 양쪽**에서 동작합니다.

| Skill | 하는 일 |
|---|---|
| `handoff` (`/handoff`) | 현재 세션을 훑어 `HANDOFF.md`로 압축(목표·변경사항·결정·막다른 길·다음 단계). 로컬 환경이면 그 파일만 git 커밋. |
| `handoff-continue` (`/handoff-continue`) | `HANDOFF.md`를 읽고 작업을 이어받음. 핫 스테이트부터 파악하고, 코드 수정 전 사용자 확인. |

핵심 설계:
- **핫 스테이트 우선** — 파일 맨 위 30~60줄만 읽어도 2분 안에 재개 가능
- **실패한 시도 보존** — 다음 세션이 같은 막다른 길을 다시 파지 않게
- **이력은 git에 위임** — `HANDOFF.md` 한 파일만 덮어쓰고, 버전은 커밋으로 관리
- **안전** — 비밀정보 리닥션, 인계받을 때 자동 실행 금지
- **환경 적응** — Claude Code/로컬에선 `HANDOFF.md`를 직접 쓰고 git 커밋, 샌드박스(claude.ai 웹/데스크탑 앱)에선 내용을 출력·다운로드해 사용자가 저장

---

## 설치

### Claude Code

마켓플레이스를 추가하고 설치합니다:

```
/plugin marketplace add devmalo050/handoff-skill
/plugin install handoff@handoff-skill
```

또는 Claude에게 "이 레포를 플러그인으로 설치해줘: devmalo050/handoff-skill" 라고 시키면 알아서 설치합니다.

### Claude 데스크탑 앱

**Customize → Plugins → Add from a repository** 에서 `devmalo050/handoff-skill` 을 넣고, 목록에서 **handoff** 를 Install 합니다. (메뉴 명칭은 앱 버전에 따라 다를 수 있습니다.)

설치 후 새 세션에서 자연어("핸드오프 해줘")로 트리거되고, 슬래시로도 호출됩니다. 데스크탑 앱은 실행 환경에 따라 로컬/휴대 모드로 동작합니다 — 아래 "환경별 동작" 참고.

### 업데이트

마켓플레이스 기반이라 새 버전이 나오면 자동으로 갱신됩니다. 수동 갱신은 `/plugin marketplace update` 입니다.

---

## 환경별 동작

| | 로컬 모드 (Claude Code / MCP 연결 데스크탑) | 휴대 모드 (claude.ai 웹 / 데스크탑 앱) |
|---|---|---|
| `handoff` | `HANDOFF.md` 저장 + git 레포면 그 파일만 커밋 | `HANDOFF.md` 내용을 채팅에 출력 + 다운로드 제공. 저장·커밋은 사용자가 |
| `handoff-continue` | 루트 `HANDOFF.md`/git 이력 직접 읽기 | 사용자가 붙여넣거나 업로드한 핸드오프 내용으로 이어받기 |

Skill은 실행 시 환경을 감지해 자동으로 알맞은 모드로 동작합니다.

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
(claude.ai/데스크탑 앱에서는 "핸드오프 만들어줘, 결제 모듈이 핵심이야" 처럼 자연어로 부르면 됩니다.)

**다음 세션에서 이어받을 때:**
```
/handoff-continue
```
과거 핸드오프 버전 목록을 보려면(git 레포, 로컬 모드):
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

로컬 모드에서 git 레포라면 `HANDOFF.md` **한 파일만** 한정해서 커밋합니다(`git add -- HANDOFF.md`). 작업 중이던 다른 파일은 절대 건드리지 않고, 푸시도 하지 않습니다. 휴대 모드(claude.ai/데스크탑 앱)에서는 저장·커밋 대신 내용을 출력하고 다운로드를 제공합니다.

---

## 파일 구조

```
handoff-skill/                       # 깃헙 레포 = 마켓플레이스
├── .claude-plugin/
│   └── marketplace.json
├── plugins/
│   └── handoff/
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           ├── handoff/SKILL.md
│           └── handoff-continue/SKILL.md
└── README.md
```

---

## 커스터마이즈

Skill은 평범한 마크다운 + YAML frontmatter입니다. `plugins/handoff/skills/*/SKILL.md` 를 열어 프롬프트를 직접 고치면 됩니다. 예:
- 템플릿 섹션 추가/삭제
- 출력 언어 고정 (기본은 "세션에서 쓰던 언어")
- 커밋 동작 끄기 / 커밋 메시지 형식 변경

수정 후 `version` 을 올려 push하면 사용자 측이 자동 업데이트로 받습니다.

---

## 라이선스

MIT
