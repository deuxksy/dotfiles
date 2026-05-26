# Coding

## Coding Standards

- 일관성(Consistency): 기존 프로젝트의 코딩 스타일(들여쓰기, 네이밍 컨벤션, 패턴)을 최우선 준수
- 주석: 코드가 `무엇(What)`을 하는지보다 `왜(Why)` 그렇게 작성되었는지에 집중. 뻔한 주석은 작성하지 않음
- 안전성: 에러 핸들링(Error Handling)과 엣지 케이스(Edge Cases)를 항상 고려
- 라이브러리:
  - AI Gateway: [Tailscale Aperture](https://tailscale.com/docs/features/aperture)
  - 알림: [PushOver](https://pushover.net/api)
  - Infra(서버리스): [CloudFlare](https://developers.cloudflare.com/)
- Reference: Library/API 문서, 코드 생성, Setup/Configuration 단계가 필요할 때 **Context7 MCP를 사용자가 명시적으로 요청하지 않아도 우선 사용**

### Simplicity First (Karpathy)

- 요청받은 것만 구현. Speculative 기능/추상화/설정 금지
- 단일 용도 코드에 추상화(Strategy, Factory 등) 금지. 복잡도가 실제로 필요해지면 그때 리팩토링
- 불가능한 시나리오의 에러 핸들링 금지
- 200줄이 50줄이 될 수 있으면 다시 쓴다

**안티패턴: 과도한 추상화**
```
# ❌ "할인 계산 함수 추가해줘" → Strategy Pattern + Factory + Config 클래스 30줄
class DiscountStrategy(ABC):
    @abstractmethod
    def calculate(self, amount: float) -> float: ...

# ✅ 그냥 함수 하나면 충분. 복잡도가 필요해지면 그때 리팩토링
def calculate_discount(amount: float, percent: float) -> float:
    return amount * (percent / 100)
```

**안티패턴: 요청받지 않은 기능 추가**
```
# ❌ "DB에 저장" 요청에 cache, validator, merge, notify까지 추가
class PreferenceManager:
    def save(self, user_id, prefs, merge=True, validate=True, notify=False): ...

# ✅ 요청한 것만
def save_preferences(db, user_id: int, preferences: dict):
    db.execute("UPDATE users SET preferences = ? WHERE id = ?", ...)
```

### Surgical Changes (Karpathy)

- 건드려야 할 것만 건드린다. 인접 코드 "개선" 금지
- 기존 스타일(들여쓰기, 따옴표, 네이밍)을 그대로 유지
- 모든 변경 라인은 사용자 요청에 추적 가능해야 한다
- 내 변경으로 생긴 미사용 import/변수만 정리. 기존 dead code는 삭제하지 않는다

**안티패턴: Drive-by 리팩토링**
```
# ❌ "이메일 빈값 버그 수정" 요청에 → 이메일 검증 강화 + username 검증 추가 + docstring + 주석 변경
# ✅ 빈 이메일 처리하는 라인만 수정. 나머지는 건드리지 않음
```

**안티패턴: 스타일 드리프트**
```
# ❌ "로깅 추가해줘" 요청에 → 따옴표 ''→"" 변경, type hints 추가, docstring 추가, boolean 로직 변경
# ✅ 기존 따옴표/스타일 그대로 유지하고 로깅만 추가
```

## Git

- 보안 점검: `git commit` 전 파일들에 보안 취약 확인
- 커밋 메시지: [Conventional Commits](https://www.conventionalcommits.org) 따른다
  - 커밋 말머리는 영어로 작성, 메시지는 한국어로 작성
- [Semantic Versioning 2.0.0](https://semver.org/) 을 사용 한다.

## Package Managers

- System Package Manager: `apt`, `dnf`, `brew`, `nix` 우선 — 가능하면 OS 패키지 매니저로 설치
- `SDK` 관리는 `mise` 를 사용 한다. 단, NixOS(mo)에서는 mise를 사용하지 않음 — 모든 도구는 Nix 패키지로 관리
- `Node Package Manager`는 `pnpm`, `pnpx` 를 사용 한다. 단, NixOS(mo)에서는 `npm install -g` 불가 — pnpm 글로벌 사용
- `Python Package Manager`는 `uv`, `uvx` 를 사용 한다.
- 그 외: `~/.local/bin`에 수동 설치 (mise/패키지 매니저 미지원 도구)
