# Bazzite (KDE Wayland) Fcitx5 한글 입력기 설정 가이드

Bazzite(Fedora Silverblue/Kinoite 기반)의 KDE Plasma Wayland 환경에서 `fcitx5`와 `fcitx5-hangul`을 통해 한글 입력 및 한/영 전환을 구성하는 How-To 가이드입니다.

---

## 1. 개요 및 배경

리눅스 환경에서는 단순히 시스템 키보드 레이아웃을 한국어(`kr`)로 변경하는 것만으로는 한글 조합(초성+중성+종성)이 되지 않습니다.  
정상적인 한글 입력을 위해서는 **입력기(IME) 데몬(`Fcitx 5`)**과 한글 엔진(`fcitx5-hangul`)이 실행되어 키 입력을 가로채 조합 문자로 전달해야 합니다.

Bazzite에는 `fcitx5`, `fcitx5-hangul`, `fcitx5-qt6`, `fcitx5-gtk4` 등의 패키지가 기본 설치되어 있으므로, 설정 및 세션 연동만 완료하면 즉시 사용 가능합니다.

---

## 2. 설정 단계

### Step 1. KWin Wayland 가상 키보드 / 입력기 연동

KDE Plasma 6 (Wayland)에서는 KWin 컴포지터가 입력기 데몬을 직접 관리하도록 설정해야 합니다.

- **GUI 설정**: `시스템 설정(System Settings)` → `키보드(Keyboard)` → `가상 키보드(Virtual Keyboard)` → **`Fcitx 5 Wayland 실행기`** (또는 `Fcitx 5`) 선택
- **CLI 설정**:
  ```bash
  kwriteconfig6 --file kwinrc --group Wayland --key InputMethod /usr/share/applications/fcitx5-wayland-launcher.desktop
  ```

### Step 2. Fcitx 5 프로필 구성 (영문 + 한글 엔진)

Fcitx 5가 영문 기본 레이아웃과 한글 조합 엔진을 갖도록 프로필을 생성합니다.

- 경로: `~/.config/fcitx5/profile`
```ini
[Groups/0]
# Group Name
Name=Default
# Layout
Default Layout=us
# Default Input Method
DefaultIM=keyboard-us

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=hangul
Layout=

[GroupOrder]
0=Default
```

### Step 3. 한/영 전환 단축키 구성

한/영 키뿐 아니라 101/104키 배열, 랩탑, 블루투스 키보드 등 다양한 환경에 대응할 수 있도록 복수의 트리거 키를 등록합니다.

- **Fcitx 5 공통 단축키 설정** (`~/.config/fcitx5/config`):
```ini
[Hotkey]
EnumerateWithTriggerKeys=True
EnumerateForwardKeys=
EnumerateBackwardKeys=
EnumerateSkipFirst=False

[Hotkey/TriggerKeys]
0=Hangul
1=Shift+space
2=Control+space
3=Alt_R
```

- **한글 엔진 세부 설정** (`~/.config/fcitx5/conf/hangul.conf`):
```ini
[Hangul]
# 2: 두벌식 (Dubeolsik)
Keyboard=2
AutoReorder=True
WordCommit=False

[Hangul/ToggleKey]
0=Hangul
1=Shift+space
2=Alt_R
```

### Step 4. 자동 시작 및 환경 변수 등록

Wayland 세션, Flatpak, XWayland, Electron, 터미널 등 모든 애플리케이션에서 입력기가 일관되게 인식되도록 구성합니다.

1. **자동 실행 등록** (`~/.config/autostart/org.fcitx.Fcitx5.desktop`):
   ```bash
   cp /usr/share/applications/org.fcitx.Fcitx5.desktop ~/.config/autostart/
   ```

2. **세션 환경 변수 등록** (`~/.config/environment.d/fcitx5.conf`):
   ```ini
   GTK_IM_MODULE=fcitx
   QT_IM_MODULE=fcitx
   XMODIFIERS=@im=fcitx
   ```

### Step 5. KDE 키보드 레이아웃 확인

KDE 시스템 설정(`~/.config/kxkbrc`)의 키보드 레이아웃은 한국어(`kr`)가 아닌 **기본 영어(`us`)**로 설정되어 있어야 충돌 없이 Fcitx 5가 한글을 정상 조합합니다.

---

## 3. 검증 및 테스트

1. **데몬 수동 실행/재시작**:
   ```bash
   fcitx5 -d --replace
   ```

2. **입력기 상태 및 토글 확인**:
   ```bash
   # 현재 활성화된 입력기 확인
   fcitx5-remote -n

   # 입력기 토글 테스트 (keyboard-us <-> hangul)
   fcitx5-remote -t && fcitx5-remote -n
   ```

3. **입력 테스트**:
   - 텍스트 입력창에서 **`한/영` 키**, **`오른쪽 Alt`**, 또는 **`Shift + Space`** 를 눌러 한글/영문 전환이 원활하게 동작하는지 확인합니다.

---

## 4. 참고 사항

- 이미 실행 중이던 애플리케이션(브라우저, 터미널 등)은 환경 변수 반영을 위해 재시작해야 할 수 있습니다.
- 세션 전체 적용을 확인하려면 로그아웃 후 다시 로그인하는 것을 권장합니다.
